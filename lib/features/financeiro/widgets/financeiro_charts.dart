import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../dashboard/widgets/dashboard_common.dart';
import '../data/financeiro_analise.dart';
import 'financeiro_kpis.dart';

const List<Color> _paleta = [
  Color(0xFFE85D75),
  Color(0xFFFF9F5A),
  Color(0xFF7C6BD6),
  Color(0xFF3DB5A5),
  Color(0xFF5B9BEA),
  Color(0xFF9AA0A6),
];

FlGridData _grade(BuildContext context, double teto) {
  final scheme = Theme.of(context).colorScheme;
  return FlGridData(
    drawVerticalLine: false,
    horizontalInterval: teto / 4,
    getDrawingHorizontalLine: (_) => FlLine(
      color: scheme.outlineVariant.withValues(alpha: 0.5),
      strokeWidth: 1,
      dashArray: [4, 4],
    ),
  );
}

AxisTitles _eixoEsquerdo(BuildContext context, double teto) => AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 48,
    interval: teto / 4,
    getTitlesWidget: (v, meta) => v == meta.max
        ? const SizedBox.shrink()
        : SideTitleWidget(
            meta: meta,
            child: Text(moedaCompacta(v), style: estiloEixo(context)),
          ),
  ),
);

AxisTitles _eixoInferior(
  BuildContext context,
  String Function(int indice) rotulo,
) => AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 30,
    getTitlesWidget: (v, meta) => SideTitleWidget(
      meta: meta,
      child: Text(rotulo(v.toInt()), style: estiloEixo(context)),
    ),
  ),
);

BarTouchTooltipData _tooltipBarras(
  BuildContext context,
  List<String> nomes,
) {
  final scheme = Theme.of(context).colorScheme;
  return BarTouchTooltipData(
    maxContentWidth: 190,
    tooltipBorderRadius: BorderRadius.circular(12),
    getTooltipColor: (_) => scheme.inverseSurface,
    getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
      '${nomes[rodIndex]}\n${rod.toY.toCurrency()}',
      TextStyle(
        color: scheme.onInverseSurface,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );
}

BarChartRodData _haste(double valor, Color cor) => BarChartRodData(
  toY: valor,
  color: cor,
  width: 12,
  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
);

/// Recebido x pago por mês.
class FluxoCaixaChart extends StatelessWidget {
  final List<PontoMensal> pontos;

  const FluxoCaixaChart({super.key, required this.pontos});

  @override
  Widget build(BuildContext context) {
    final vazio = pontos.every((p) => p.recebido == 0 && p.pago == 0);
    final maximo = pontos.fold<double>(
      0,
      (m, p) => math.max(m, math.max(p.recebido, p.pago)),
    );
    final teto = tetoDoEixo(maximo);
    return DashCard(
      titulo: 'Recebido x Pago',
      subtitulo: 'Quitações dos últimos ${pontos.length} meses',
      child: vazio
          ? const SemDados(
              mensagem: 'Quando houver quitações, o fluxo mensal aparece aqui.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Wrap(
                  spacing: 16,
                  children: [
                    Legenda(cor: corReceita, texto: 'Recebido'),
                    Legenda(cor: corDespesa, texto: 'Pago'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 240,
                  child: CrescimentoAnimado(
                    builder: (context, t) => BarChart(
                      duration: const Duration(milliseconds: 300),
                      BarChartData(
                        maxY: teto,
                        alignment: BarChartAlignment.spaceAround,
                        barTouchData: BarTouchData(
                          touchTooltipData: _tooltipBarras(context, const [
                            'Recebido',
                            'Pago',
                          ]),
                        ),
                        gridData: _grade(context, teto),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          leftTitles: _eixoEsquerdo(context, teto),
                          bottomTitles: _eixoInferior(
                            context,
                            (i) => mesCurto(pontos[i].mes),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < pontos.length; i++)
                            BarChartGroupData(
                              x: i,
                              barsSpace: 4,
                              barRods: [
                                _haste(pontos[i].recebido * t, corReceita),
                                _haste(pontos[i].pago * t, corDespesa),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Resultado (recebido - pago) acumulado mês a mês.
class SaldoAcumuladoChart extends StatelessWidget {
  final List<PontoMensal> pontos;

  const SaldoAcumuladoChart({super.key, required this.pontos});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vazio = pontos.every((p) => p.recebido == 0 && p.pago == 0);
    final maior = pontos.fold<double>(
      0,
      (m, p) => math.max(m, p.saldoAcumulado),
    );
    final menor = pontos.fold<double>(
      0,
      (m, p) => math.min(m, p.saldoAcumulado),
    );
    final amplitude = tetoDoEixo(math.max(maior, -menor));
    final minimo = menor < 0 ? -amplitude : 0.0;
    final maximo = amplitude;
    return DashCard(
      titulo: 'Resultado acumulado',
      subtitulo: 'Recebido menos pago, somado mês a mês',
      child: vazio
          ? const SemDados(
              mensagem: 'O saldo acumulado aparece quando houver quitações.',
            )
          : SizedBox(
              height: 270,
              child: CrescimentoAnimado(
                builder: (context, t) => LineChart(
                  duration: const Duration(milliseconds: 300),
                  LineChartData(
                    minY: minimo,
                    maxY: maximo,
                    gridData: _grade(context, maximo - minimo),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: _eixoEsquerdo(context, maximo - minimo),
                      bottomTitles: _eixoInferior(
                        context,
                        (i) => mesCurto(pontos[i].mes),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBorderRadius: BorderRadius.circular(12),
                        getTooltipColor: (_) => scheme.inverseSurface,
                        getTooltipItems: (spots) => [
                          for (final spot in spots)
                            LineTooltipItem(
                              spot.y.toCurrency(),
                              TextStyle(
                                color: scheme.onInverseSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < pontos.length; i++)
                            FlSpot(i.toDouble(), pontos[i].saldoAcumulado * t),
                        ],
                        isCurved: true,
                        color: corNeutra,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: corNeutra.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// Saldo em aberto por faixa de vencimento (posição atual).
class VencimentosChart extends StatelessWidget {
  final List<FaixaVencimento> faixas;

  const VencimentosChart({super.key, required this.faixas});

  @override
  Widget build(BuildContext context) {
    final vazio = faixas.every((f) => f.aReceber == 0 && f.aPagar == 0);
    final maximo = faixas.fold<double>(
      0,
      (m, f) => math.max(m, math.max(f.aReceber, f.aPagar)),
    );
    final teto = tetoDoEixo(maximo);
    return DashCard(
      titulo: 'Contas em aberto por vencimento',
      subtitulo: 'Posição atual: o que vence em cada prazo',
      child: vazio
          ? const SemDados(mensagem: 'Nenhuma conta em aberto.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Wrap(
                  spacing: 16,
                  children: [
                    Legenda(cor: corReceita, texto: 'A receber'),
                    Legenda(cor: corDespesa, texto: 'A pagar'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 240,
                  child: CrescimentoAnimado(
                    builder: (context, t) => BarChart(
                      duration: const Duration(milliseconds: 300),
                      BarChartData(
                        maxY: teto,
                        alignment: BarChartAlignment.spaceAround,
                        barTouchData: BarTouchData(
                          touchTooltipData: _tooltipBarras(context, const [
                            'A receber',
                            'A pagar',
                          ]),
                        ),
                        gridData: _grade(context, teto),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          leftTitles: _eixoEsquerdo(context, teto),
                          bottomTitles: _eixoInferior(
                            context,
                            (i) => faixas[i].rotulo.replaceAll(' dias', 'd'),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < faixas.length; i++)
                            BarChartGroupData(
                              x: i,
                              barsSpace: 4,
                              barRods: [
                                _haste(faixas[i].aReceber * t, corReceita),
                                _haste(faixas[i].aPagar * t, corDespesa),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Participação de cada forma de pagamento no que foi recebido.
class FormasPagamentoChart extends StatelessWidget {
  final List<ParteDoTotal> partes;

  const FormasPagamentoChart({super.key, required this.partes});

  @override
  Widget build(BuildContext context) {
    final total = partes.fold<double>(0, (s, p) => s + p.valor);
    return DashCard(
      titulo: 'Recebido por forma de pagamento',
      subtitulo: 'Receitas quitadas no período',
      child: total <= 0
          ? const SemDados(
              mensagem: 'Nenhum recebimento no período selecionado.',
              icon: Icons.donut_large_outlined,
            )
          : Column(
              children: [
                SizedBox(
                  height: 180,
                  child: CrescimentoAnimado(
                    builder: (context, t) => PieChart(
                      duration: const Duration(milliseconds: 300),
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 54,
                        sections: [
                          for (var i = 0; i < partes.length; i++)
                            PieChartSectionData(
                              value: partes[i].valor * t + 0.0001,
                              color: _paleta[i % _paleta.length],
                              radius: 28,
                              showTitle: false,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < partes.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Legenda(
                            cor: _paleta[i % _paleta.length],
                            texto: partes[i].rotulo,
                          ),
                        ),
                        Text(
                          '${partes[i].valor.toCurrency()}  '
                          '(${(partes[i].valor / total * 100).toStringAsFixed(0)}%)',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

/// Ranking com barras horizontais (maiores valores primeiro).
class RankingCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final List<ParteDoTotal> partes;
  final Color cor;
  final String mensagemVazia;

  const RankingCard({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.partes,
    required this.cor,
    this.mensagemVazia = 'Sem dados no período selecionado.',
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final maior = partes.fold<double>(0, (m, p) => math.max(m, p.valor));
    return DashCard(
      titulo: titulo,
      subtitulo: subtitulo,
      child: partes.isEmpty || maior <= 0
          ? SemDados(mensagem: mensagemVazia, altura: 120)
          : Column(
              children: [
                for (final parte in partes)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                parte.rotulo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tema.textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              parte.valor.toCurrency(),
                              style: tema.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: parte.valor / maior,
                            minHeight: 8,
                            color: cor,
                            backgroundColor: cor.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
