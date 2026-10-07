import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/responsive.dart';
import '../../dashboard/data/dashboard_metrics.dart';
import '../../dashboard/widgets/dashboard_cards.dart';
import '../data/financeiro_metrics.dart';

/// KPIs financeiros. Na tela de lançamentos mostra todos; no dashboard, só os
/// principais ([completo] = false).
class FinanceiroKpis extends StatelessWidget {
  final ResumoFinanceiro resumo;
  final bool completo;

  const FinanceiroKpis({super.key, required this.resumo, this.completo = true});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ResponsiveCardGrid(
      minItemWidth: 150,
      children: [
        KpiCard(
          titulo: 'A receber',
          icon: Icons.south_west,
          cor: const Color(0xFF2E9E5B),
          valor: resumo.aReceber,
          exibeVariacao: false,
          dica: 'Saldo das receitas ainda não recebidas.',
        ),
        KpiCard(
          titulo: 'A pagar',
          icon: Icons.north_east,
          cor: const Color(0xFFE85D75),
          valor: resumo.aPagar,
          exibeVariacao: false,
          altaEhRuim: true,
          dica: 'Saldo das despesas ainda não pagas.',
        ),
        if (completo)
          KpiCard(
            titulo: 'Saldo previsto',
            icon: Icons.balance_outlined,
            cor: const Color(0xFF7C6BD6),
            valor: resumo.saldoPrevisto,
            exibeVariacao: false,
            dica: 'A receber menos a pagar.',
          ),
        if (completo) ...[
          KpiCard(
            titulo: 'A receber em atraso',
            icon: Icons.schedule_outlined,
            cor: const Color(0xFFFF9F5A),
            valor: resumo.aReceberEmAtraso,
            exibeVariacao: false,
            altaEhRuim: true,
            dica: 'Receitas com vencimento passado e saldo em aberto.',
          ),
          KpiCard(
            titulo: 'A pagar em atraso',
            icon: Icons.warning_amber_outlined,
            cor: scheme.error,
            valor: resumo.aPagarEmAtraso,
            exibeVariacao: false,
            altaEhRuim: true,
            dica: 'Despesas com vencimento passado e saldo em aberto.',
          ),
          KpiCard(
            titulo: 'Recebido no mês',
            icon: Icons.add_circle_outline,
            cor: const Color(0xFF2E9E5B),
            valor: resumo.recebidoMes,
            variacao: DashboardMetrics.variacao(
              resumo.recebidoMes,
              resumo.recebidoMesAnterior,
            ),
            dica: 'Receitas quitadas (recebidas) neste mês.',
          ),
          KpiCard(
            titulo: 'Pago no mês',
            icon: Icons.remove_circle_outline,
            cor: const Color(0xFFE85D75),
            valor: resumo.pagoMes,
            altaEhRuim: true,
            variacao: DashboardMetrics.variacao(
              resumo.pagoMes,
              resumo.pagoMesAnterior,
            ),
            dica: 'Despesas quitadas (pagas) neste mês.',
          ),
        ] else
          KpiCard(
            titulo: 'Em atraso',
            icon: Icons.warning_amber_outlined,
            cor: scheme.error,
            valor: resumo.totalEmAtraso,
            exibeVariacao: false,
            altaEhRuim: true,
            dica: 'Contas a receber e a pagar com vencimento passado.',
          ),
        KpiCard(
          titulo: 'Saldo realizado',
          icon: Icons.account_balance_wallet_outlined,
          cor: const Color(0xFF3A86FF),
          valor: resumo.saldoRealizado,
          exibeVariacao: false,
          dica: 'Tudo o que já foi recebido menos tudo o que já foi pago.',
        ),
      ],
    );
  }
}
