import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/responsive.dart';
import '../../../shared/data/app_repository.dart';
import '../../dashboard/data/dashboard_metrics.dart';
import '../../dashboard/widgets/dashboard_cards.dart';
import '../../dashboard/widgets/dashboard_common.dart';
import '../data/financeiro_analise.dart';
import '../data/financeiro_filtro.dart';
import '../widgets/financeiro_charts.dart';
import '../widgets/financeiro_filtro_bar.dart';
import '../widgets/financeiro_kpis.dart';

/// Análise financeira: indicadores, gráficos e filtros para entender a
/// carteira (o que está em aberto) e o resultado de um período.
class FinanceiroAnaliseScreen extends StatefulWidget {
  const FinanceiroAnaliseScreen({super.key});

  @override
  State<FinanceiroAnaliseScreen> createState() =>
      _FinanceiroAnaliseScreenState();
}

class _FinanceiroAnaliseScreenState extends State<FinanceiroAnaliseScreen> {
  final _repo = AppRepository.instance;
  var _filtro = const FiltroFinanceiro();

  static String _percentual(double valor) =>
      '${valor.toStringAsFixed(1).replaceAll('.', ',')}%';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _repo,
      builder: (context, _) {
        final analise = AnaliseFinanceira.calcular(
          lancamentos: _repo.lancamentosFinanceiros,
          filtro: _filtro,
          agora: DateTime.now(),
        );
        final periodo =
            '${analise.intervalo.inicio.toFormattedDate()} a '
            '${analise.intervalo.fim.toFormattedDate()}';

        final blocos = <Widget>[
          FinanceiroFiltroBar(
            filtro: _filtro,
            pessoas: _repo.pessoasFinanceiro,
            aoAlterar: (filtro) => setState(() => _filtro = filtro),
          ),
          _carteira(analise),
          _resultado(analise, periodo),
          _indicadores(analise),
          LinhaResponsiva(
            esquerda: FluxoCaixaChart(pontos: analise.fluxoMensal),
            direita: SaldoAcumuladoChart(pontos: analise.fluxoMensal),
          ),
          LinhaResponsiva(
            esquerda: VencimentosChart(faixas: analise.faixasVencimento),
            direita: FormasPagamentoChart(partes: analise.recebidoPorForma),
          ),
          LinhaResponsiva(
            flexEsquerda: 1,
            flexDireita: 1,
            esquerda: RankingCard(
              titulo: 'Receitas por pessoa',
              subtitulo: 'Maiores valores previstos no período',
              partes: analise.receitasPorPessoa,
              cor: corReceita,
            ),
            direita: RankingCard(
              titulo: 'Despesas por pessoa',
              subtitulo: 'Maiores valores previstos no período',
              partes: analise.despesasPorPessoa,
              cor: corDespesa,
            ),
          ),
          if (analise.taxasPorPessoa.isNotEmpty)
            RankingCard(
              titulo: 'Taxas e impostos nas receitas',
              subtitulo: 'Quanto cada bandeira/pessoa custou no período',
              partes: analise.taxasPorPessoa,
              cor: corAlerta,
            ),
        ];

        return AppScaffold(
          title: 'Análise financeira',
          body: SingleChildScrollView(
            child: ContentWidth(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < blocos.length; i++) ...[
                    if (i > 0) const SizedBox(height: 20),
                    blocos[i].entranceAnimation(i),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _carteira(AnaliseFinanceira a) => SecaoKpis(
    titulo: 'Carteira em aberto',
    subtitulo:
        'Saldo ainda não quitado, de todos os vencimentos '
        '(não depende do período)',
    rows: [
      [
        KpiCard(
          titulo: 'Recebido (todo período)',
          icon: Icons.south_west,
          cor: corReceita,
          valor: a.recebidoTodoPeriodo,
          exibeVariacao: false,
          dica: 'Saldo recebido em todo o período',
        ),
        KpiCard(
          titulo: 'Pago (todo período)',
          icon: Icons.north_east,
          cor: corDespesa,
          valor: a.pagoTodoPeriodo,
          exibeVariacao: false,
          dica: 'Saldo pago em todo o período',
        ),
        KpiCard(
          titulo: 'Saldo (todo período)',
          icon: Icons.balance_outlined,
          cor: corRoxa,
          valor: a.saldoTodoPeriodo,
          exibeVariacao: false,
          dica: 'Saldo em todo o período.',
        ),
      ],

      [
        KpiCard(
          titulo: 'A receber',
          icon: Icons.south_west,
          cor: corReceita,
          valor: a.aReceberTodoPeriodo,
          exibeVariacao: false,
          dica: 'Saldo das receitas ainda não recebidas.',
        ),
        KpiCard(
          titulo: 'A pagar',
          icon: Icons.north_east,
          cor: corDespesa,
          valor: a.aPagarTodoPeriodo,
          exibeVariacao: false,
          dica: 'Saldo das despesas ainda não pagas.',
        ),
        KpiCard(
          titulo: 'Saldo previsto',
          icon: Icons.balance_outlined,
          cor: corRoxa,
          valor: a.saldoPrevistoTodoPeriodo,
          exibeVariacao: false,
          dica: 'A receber menos a pagar.',
        ),
      ],
      [
        KpiCard(
          titulo: 'A receber em atraso',
          icon: Icons.schedule_outlined,
          cor: corAlerta,
          valor: a.aReceberEmAtrasoTodoPeriodo,
          exibeVariacao: false,
          dica: 'Receitas com vencimento passado e saldo em aberto.',
        ),
        KpiCard(
          titulo: 'A pagar em atraso',
          icon: Icons.warning_amber_outlined,
          cor: Theme.of(context).colorScheme.error,
          valor: a.aPagarEmAtrasoTodoPeriodo,
          exibeVariacao: false,
          dica: 'Despesas com vencimento passado e saldo em aberto.',
        ),
      ],
    ],
  );

  Widget _resultado(AnaliseFinanceira a, String periodo) => SecaoKpis(
    titulo: 'Resultado do período',
    subtitulo:
        '$periodo · variação em relação ao período anterior · '
        '${a.quantidadeLancamentos} lançamentos previstos',
    rows: [
      [
        KpiCard(
          titulo: 'A receber',
          icon: Icons.add_circle_outline,
          cor: corReceita,
          valor: a.aReceberDentroDoPeriodo,
          exibeVariacao: false,
          dica: 'Receitas em aberto dentro do período.',
        ),
        KpiCard(
          titulo: 'A pagar',
          icon: Icons.remove_circle_outline,
          cor: corDespesa,
          valor: a.aPagarDentroDoPeriodo,
          altaEhRuim: true,
          exibeVariacao: false,
          dica: 'Despesas em aberto dentro do período.',
        ),
        KpiCard(
          titulo: 'Saldo previsto',
          icon: Icons.balance_outlined,
          cor: corRoxa,
          valor: a.saldoPrevistoDentroDoPeriodo,
          exibeVariacao: false,
          dica: 'A receber menos a pagar dentro do período.',
        ),
      ],
      [
        KpiCard(
          titulo: 'Recebido',
          icon: Icons.add_circle_outline,
          cor: corReceita,
          valor: a.recebido,
          variacao: DashboardMetrics.variacao(a.recebido, a.recebidoAnterior),
          dica: 'Receitas quitadas dentro do período.',
        ),
        KpiCard(
          titulo: 'Pago',
          icon: Icons.remove_circle_outline,
          cor: corDespesa,
          valor: a.pago,
          altaEhRuim: true,
          variacao: DashboardMetrics.variacao(a.pago, a.pagoAnterior),
          dica: 'Despesas quitadas dentro do período.',
        ),
        KpiCard(
          titulo: 'Resultado realizado',
          icon: Icons.account_balance_wallet_outlined,
          cor: corNeutra,
          valor: a.resultadoRealizado,
          variacao: DashboardMetrics.variacao(
            a.resultadoRealizado,
            a.resultadoAnterior,
          ),
          dica: 'Recebido menos pago no período.',
        ),
      ],
      [
        KpiCard(
          titulo: 'A receber em atraso',
          icon: Icons.schedule_outlined,
          cor: corAlerta,
          valor: a.aReceberEmAtrasoDentroDoPeriodo,
          exibeVariacao: false,
          dica: 'Receitas com vencimento passado e saldo em aberto.',
        ),
        KpiCard(
          titulo: 'A pagar em atraso',
          icon: Icons.warning_amber_outlined,
          cor: Theme.of(context).colorScheme.error,
          valor: a.aPagarEmAtrasoDentroDoPeriodo,
          exibeVariacao: false,
          dica: 'Despesas com vencimento passado e saldo em aberto.',
        ),
      ],
    ],
  );

  Widget _indicadores(AnaliseFinanceira a) => SecaoKpis(
    titulo: 'Indicadores e custos financeiros',
    subtitulo: 'Sobre os lançamentos com vencimento no período',
    rows: [
      [
        if (a.taxaDeRecebimento != null)
          KpiCard(
            titulo: 'Taxa de recebimento',
            icon: Icons.task_alt_outlined,
            cor: corReceita,
            valor: a.taxaDeRecebimento! * 100,
            formatar: _percentual,
            exibeVariacao: false,
            dica: 'Parte das receitas previstas que já foi recebida.',
          ),
        if (a.inadimplencia != null)
          KpiCard(
            titulo: 'Inadimplência',
            icon: Icons.report_gmailerrorred_outlined,
            cor: Theme.of(context).colorScheme.error,
            valor: a.inadimplencia! * 100,
            formatar: _percentual,
            exibeVariacao: false,
            dica: 'Parte das receitas previstas vencida e ainda em aberto.',
          ),
        // if (a.prazoMedioRecebimento != null)
        //   KpiCard(
        //     titulo: 'Prazo médio de recebimento',
        //     icon: Icons.hourglass_bottom_outlined,
        //     cor: corRoxa,
        //     valor: a.prazoMedioRecebimento!,
        //     formatar: (v) => '${v.round()} dias',
        //     exibeVariacao: false,
        //     dica:
        //         'Dias entre a criação do lançamento e o recebimento, '
        //         'ponderado pelo valor.',
        //   ),
        KpiCard(
          titulo: 'Taxas e impostos',
          icon: Icons.percent,
          cor: corAlerta,
          valor: a.taxasImpostos,
          exibeVariacao: false,
          dica: 'Taxas de bandeira e impostos dos lançamentos do período.',
        ),
        // KpiCard(
        //   titulo: 'Descontos',
        //   icon: Icons.sell_outlined,
        //   cor: corNeutra,
        //   valor: a.descontos,
        //   exibeVariacao: false,
        //   dica: 'Descontos aplicados nos lançamentos do período.',
        // ),
        // KpiCard(
        //   titulo: 'Acréscimos',
        //   icon: Icons.add_chart_outlined,
        //   cor: corRoxa,
        //   valor: a.acrescimos,
        //   exibeVariacao: false,
        //   dica: 'Juros, multas e outros acréscimos do período.',
        // ),
      ],
    ],
  );
}
