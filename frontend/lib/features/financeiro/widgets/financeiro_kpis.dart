import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/responsive.dart';
import '../../dashboard/data/dashboard_metrics.dart';
import '../../dashboard/widgets/dashboard_cards.dart';
import '../data/financeiro_analise.dart';

const Color corReceita = Color(0xFF2E9E5B);
const Color corDespesa = Color(0xFFE85D75);
const Color corNeutra = Color(0xFF3A86FF);
const Color corAlerta = Color(0xFFFF9F5A);
const Color corRoxa = Color(0xFF7C6BD6);

/// Bloco de indicadores com título (e legenda opcional) acima dos cartões.
class SecaoKpis extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final Widget? acao;
  late List<List<Widget>> rows;
  final double larguraMinima;

  SecaoKpis({
    super.key,
    required this.titulo,
    List<List<Widget>>? rows,
    this.subtitulo,
    this.acao,
    List<Widget>? children,
    this.larguraMinima = 160,
  }) {
    if (children != null && children.isNotEmpty) {
      this.rows = [children];
    } else {
      this.rows = rows ?? [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: tema.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitulo != null)
                    Text(
                      subtitulo!,
                      style: tema.textTheme.bodySmall?.copyWith(
                        color: tema.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),

            ?acao,
          ],
        ),
        const SizedBox(height: 10),
        ResponsiveCardGrid(minItemWidth: larguraMinima, rows: rows),
      ],
    );
  }
}

/// Indicadores financeiros resumidos, usados na lista de lançamentos e no
/// dashboard. A análise completa (com filtros e gráficos) fica em
/// `/financeiro/analise`.
class FinanceiroKpis extends StatelessWidget {
  final AnaliseFinanceira analise;

  /// `true` na lista de lançamentos; `false` no dashboard (versão enxuta).
  final bool completo;

  const FinanceiroKpis({
    super.key,
    required this.analise,
    this.completo = true,
  });

  @override
  Widget build(BuildContext context) {
    return SecaoKpis(
      titulo: 'Financeiro',
      subtitulo: completo
          ? 'Posição atual e movimento do mês'
          : 'Posição atual e resultado do mês',
      acao: TextButton.icon(
        onPressed: () => context.push('/financeiro/analise'),
        icon: const Icon(Icons.insights_outlined),
        label: const Text('Análise completa'),
      ),
      rows: [
        [
          KpiCard(
            titulo: 'A receber',
            icon: Icons.south_west,
            cor: corReceita,
            valor: analise.aReceberDentroDoPeriodo,
            exibeVariacao: false,
            dica: 'Saldo das receitas ainda não recebidas no mês atual.',
          ),
          KpiCard(
            titulo: 'A pagar',
            icon: Icons.north_east,
            cor: corDespesa,
            valor: analise.aPagarDentroDoPeriodo,
            exibeVariacao: false,
            dica: 'Saldo das despesas ainda não pagas no mês atual.',
          ),
          KpiCard(
            titulo: 'Saldo previsto',
            icon: Icons.balance_outlined,
            cor: corRoxa,
            valor: analise.saldoPrevistoDentroDoPeriodo,
            exibeVariacao: false,
            dica: 'A receber menos a pagar no mês.',
          ),
        ],
        if (completo)
          [
            KpiCard(
              titulo: 'Recebido no mês',
              icon: Icons.add_circle_outline,
              cor: corReceita,
              valor: analise.recebido,
              variacao: DashboardMetrics.variacao(
                analise.recebido,
                analise.recebidoAnterior,
              ),
              dica: 'Receitas quitadas (recebidas) neste mês.',
            ),
            KpiCard(
              titulo: 'Pago no mês',
              icon: Icons.remove_circle_outline,
              cor: corDespesa,
              valor: analise.pago,
              altaEhRuim: true,
              variacao: DashboardMetrics.variacao(
                analise.pago,
                analise.pagoAnterior,
              ),
              dica: 'Despesas quitadas (pagas) neste mês.',
            ),

            KpiCard(
              titulo: 'Saldo realizado do mês',
              icon: Icons.account_balance_wallet_outlined,
              cor: corNeutra,
              valor: analise.resultadoRealizado,
              variacao: DashboardMetrics.variacao(
                analise.resultadoRealizado,
                analise.resultadoAnterior,
              ),
              dica: 'Recebido menos pago neste mês.',
            ),
          ],
      ],
    );
  }
}
