import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../data/dashboard_metrics.dart';
import 'dashboard_common.dart';

const Color _corVendas = Color(0xFFE85D75);
const Color _corCompras = Color(0xFF7C6BD6);

const List<Color> _paleta = [
  Color(0xFFE85D75),
  Color(0xFFFF9F5A),
  Color(0xFF7C6BD6),
  Color(0xFF3DB5A5),
  Color(0xFF5B9BEA),
];

BarTouchTooltipData _tooltipBarras(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return BarTouchTooltipData(
    maxContentWidth: 180,
    tooltipBorderRadius: BorderRadius.circular(12),
    getTooltipColor: (_) => scheme.inverseSurface,
    getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
      '${rodIndex == 0 ? 'Vendas' : 'Compras'}\n${rod.toY.toCurrency()}',
      TextStyle(
        color: scheme.onInverseSurface,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );
}

/// Barras agrupadas de vendas x compras por mês.
class VendasComprasChart extends StatelessWidget {
  final List<ResumoMensal> serie;

  const VendasComprasChart({super.key, required this.serie});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vazio = serie.every((m) => m.vendas == 0 && m.compras == 0);
    final maximo = serie.fold<double>(
      0,
      (m, e) => math.max(m, math.max(e.vendas, e.compras)),
    );
    final teto = tetoDoEixo(maximo);
    return DashCard(
      titulo: 'Vendas x Compras',
      subtitulo:
          'Últimos ${serie.length} meses — veja se o que entra supera o que sai',
      acao: null,
      child: vazio
          ? const SemDados(
              mensagem: 'Registre vendas e compras para acompanhar a evolução mês a mês.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Wrap(
                  spacing: 16,
                  children: [
                    Legenda(cor: _corVendas, texto: 'Vendas'),
                    Legenda(cor: _corCompras, texto: 'Compras'),
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
                          touchTooltipData: _tooltipBarras(context),
                        ),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          horizontalInterval: teto / 4,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: scheme.outlineVariant.withValues(alpha: 0.5),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 44,
                              interval: teto / 4,
                              getTitlesWidget: (v, meta) => v == meta.max
                                  ? const SizedBox.shrink()
                                  : SideTitleWidget(
                                      meta: meta,
                                      child: Text(
                                        moedaCompacta(v),
                                        style: estiloEixo(context),
                                      ),
                                    ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              getTitlesWidget: (v, meta) => SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  mesCurto(serie[v.toInt()].mes),
                                  style: estiloEixo(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var i = 0; i < serie.length; i++)
                            BarChartGroupData(
                              x: i,
                              barsSpace: 4,
                              barRods: [
                                BarChartRodData(
                                  toY: serie[i].vendas * t,
                                  color: _corVendas,
                                  width: 12,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                                BarChartRodData(
                                  toY: serie[i].compras * t,
                                  color: _corCompras,
                                  width: 12,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
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

/// Evolução do faturamento diário, com seletor de período.
class FaturamentoDiarioChart extends StatefulWidget {
  final DashboardMetrics metrics;

  const FaturamentoDiarioChart({super.key, required this.metrics});

  @override
  State<FaturamentoDiarioChart> createState() => _FaturamentoDiarioChartState();
}

class _FaturamentoDiarioChartState extends State<FaturamentoDiarioChart> {
  int _dias = 30;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final serie = widget.metrics.serieDiaria(_dias);
    final total = serie.fold<double>(0, (s, e) => s + e.valor);
    final maximo = serie.fold<double>(0, (m, e) => math.max(m, e.valor));
    final teto = tetoDoEixo(maximo);
    final intervaloX = (_dias / 5).ceilToDouble();
    return DashCard(
      titulo: 'Faturamento diário',
      subtitulo: 'Total no período: ${total.toCurrency()}',
      acao: SegmentedButton<int>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: 7, label: Text('7d')),
          ButtonSegment(value: 30, label: Text('30d')),
          ButtonSegment(value: 90, label: Text('90d')),
        ],
        selected: {_dias},
        onSelectionChanged: (s) => setState(() => _dias = s.first),
      ),
      child: total == 0
          ? const SemDados(
              mensagem: 'Nenhuma venda neste período.',
              icon: Icons.show_chart,
            )
          : SizedBox(
              height: 240,
              child: CrescimentoAnimado(
                builder: (context, t) => LineChart(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  LineChartData(
                    minY: 0,
                    maxY: teto,
                    minX: 0,
                    maxX: (_dias - 1).toDouble(),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      drawVerticalLine: false,
                      horizontalInterval: teto / 4,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: scheme.outlineVariant.withValues(alpha: 0.5),
                        strokeWidth: 1,
                        dashArray: [4, 4],
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBorderRadius: BorderRadius.circular(12),
                        getTooltipColor: (_) => scheme.inverseSurface,
                        getTooltipItems: (spots) => [
                          for (final s in spots)
                            LineTooltipItem(
                              '${diaMes(serie[s.x.toInt()].dia)}\n${s.y.toCurrency()}',
                              TextStyle(
                                color: scheme.onInverseSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          interval: teto / 4,
                          getTitlesWidget: (v, meta) => v == meta.max
                              ? const SizedBox.shrink()
                              : SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    moedaCompacta(v),
                                    style: estiloEixo(context),
                                  ),
                                ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: intervaloX,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i < 0 || i >= serie.length) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                diaMes(serie[i].dia),
                                style: estiloEixo(context),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < serie.length; i++)
                            FlSpot(i.toDouble(), serie[i].valor * t),
                        ],
                        isCurved: true,
                        curveSmoothness: 0.25,
                        preventCurveOverShooting: true,
                        barWidth: 3,
                        color: _corVendas,
                        dotData: FlDotData(show: _dias <= 7),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _corVendas.withValues(alpha: 0.28),
                              _corVendas.withValues(alpha: 0.0),
                            ],
                          ),
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

/// Rosca com a participação dos produtos mais vendidos (últimos 30 dias).
class TopProdutosChart extends StatefulWidget {
  final List<ProdutoVendido> produtos;

  const TopProdutosChart({super.key, required this.produtos});

  @override
  State<TopProdutosChart> createState() => _TopProdutosChartState();
}

class _TopProdutosChartState extends State<TopProdutosChart> {
  int? _tocado;

  @override
  Widget build(BuildContext context) {
    final produtos = widget.produtos;
    final total = produtos.fold<double>(0, (s, p) => s + p.valor);
    final tema = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return DashCard(
      titulo: 'Mais vendidos',
      subtitulo: 'Participação na receita nos últimos 30 dias',
      child: produtos.isEmpty
          ? const SemDados(
              mensagem: 'Os produtos mais vendidos aparecem aqui após as primeiras vendas.',
              icon: Icons.donut_large,
            )
          : Column(
              children: [
                SizedBox(
                  height: 190,
                  child: CrescimentoAnimado(
                    builder: (context, t) => Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          duration: const Duration(milliseconds: 250),
                          PieChartData(
                            startDegreeOffset: -90 - (1 - t) * 120,
                            sectionsSpace: 3,
                            centerSpaceRadius: 58,
                            pieTouchData: PieTouchData(
                              touchCallback: (event, resposta) {
                                final indice = resposta
                                    ?.touchedSection
                                    ?.touchedSectionIndex;
                                final novo =
                                    event.isInterestedForInteractions &&
                                        indice != null &&
                                        indice >= 0
                                    ? indice
                                    : null;
                                if (novo != _tocado) {
                                  setState(() => _tocado = novo);
                                }
                              },
                            ),
                            sections: [
                              for (var i = 0; i < produtos.length; i++)
                                PieChartSectionData(
                                  value: produtos[i].valor,
                                  color: _paleta[i % _paleta.length],
                                  radius: (_tocado == i ? 36 : 30) * t,
                                  showTitle: false,
                                ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _tocado == null
                                  ? total.toCurrency()
                                  : produtos[_tocado!].valor.toCurrency(),
                              style: tema.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _tocado == null
                                  ? 'em vendas'
                                  : '${(produtos[_tocado!].valor / total * 100).toStringAsFixed(0)}% do total',
                              style: tema.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < produtos.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _paleta[i % _paleta.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            produtos[i].nome,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tema.bodyMedium?.copyWith(
                              fontWeight: _tocado == i
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        Text(
                          produtos[i].valor.toCurrency(),
                          style: tema.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
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

/// Barras horizontais de margem de lucro por produto.
class MargensCard extends StatelessWidget {
  final List<MargemProduto> margens;

  const MargensCard({super.key, required this.margens});

  static Color _cor(double percentual) {
    if (percentual < 20) return const Color(0xFFE5484D);
    if (percentual < 40) return const Color(0xFFF5A524);
    return const Color(0xFF2E9E5B);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final maximo = margens.fold<double>(1, (m, e) => math.max(m, e.percentual));
    return DashCard(
      titulo: 'Margem de lucro por produto',
      subtitulo: 'Do menor para o maior — atenção aos que estão em vermelho',
      child: margens.isEmpty
          ? const SemDados(
              mensagem:
                  'Cadastre produtos com preço de venda para ver as margens.',
              icon: Icons.sell_outlined,
            )
          : CrescimentoAnimado(
              builder: (context, t) => Column(
                children: [
                  for (final m in margens)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  m.nome,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tema.bodyMedium,
                                ),
                              ),
                              Text(
                                '${m.percentual.toStringAsFixed(0)}%  •  ${m.lucro.toCurrency()}',
                                style: tema.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: _cor(m.percentual),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value:
                                  (m.percentual.clamp(0, double.infinity) /
                                      maximo) *
                                  t,
                              minHeight: 8,
                              color: _cor(m.percentual),
                              backgroundColor: scheme.surfaceContainerHighest,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
