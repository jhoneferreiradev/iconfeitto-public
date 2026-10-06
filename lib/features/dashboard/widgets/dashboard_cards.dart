import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../data/dashboard_metrics.dart';
import 'dashboard_common.dart';

/// Faixa de boas-vindas com o resumo do mês.
class DashboardHero extends StatelessWidget {
  final String? nomeEmpresa;
  final DashboardMetrics metrics;

  const DashboardHero({super.key, this.nomeEmpresa, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tema = Theme.of(context).textTheme;
    final nome = (nomeEmpresa ?? '').trim();
    final resumo = metrics.quantidadeVendasMes == 0
        ? 'Ainda não há vendas em ${mesLongo(metrics.agora)}. '
              'Que tal registrar a primeira?'
        : 'Em ${mesLongo(metrics.agora)} você já faturou '
              '${metrics.faturamentoMes.toCurrency()} em '
              '${metrics.quantidadeVendasMes} '
              '${metrics.quantidadeVendasMes == 1 ? 'venda' : 'vendas'}.';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.tertiary, 0.7)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -30,
            child: Icon(
              Icons.cake,
              size: 170,
              color: scheme.onPrimary.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dataPorExtenso(metrics.agora).toUpperCase(),
                  style: tema.labelMedium?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.85),
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  nome.isEmpty
                      ? '${saudacao(DateTime.now())}!'
                      : '${saudacao(DateTime.now())}, $nome!',
                  style: tema.headlineSmall?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Text(
                    resumo,
                    style: tema.bodyLarge?.copyWith(
                      color: scheme.onPrimary.withValues(alpha: 0.92),
                    ),
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

/// Indicador do mês com variação em relação ao mês anterior.
class KpiCard extends StatelessWidget {
  final String titulo;
  final IconData icon;
  final Color cor;
  final double valor;
  final String Function(double valor) formatar;
  final double? variacao;
  final bool exibeVariacao;

  /// Quando `true`, aumentar o valor é ruim (ex.: gastos com compras).
  final bool altaEhRuim;
  final String dica;

  const KpiCard({
    super.key,
    required this.titulo,
    required this.icon,
    required this.cor,
    required this.valor,
    this.formatar = formatarMoeda,
    this.variacao,
    this.exibeVariacao = true,
    this.altaEhRuim = false,
    required this.dica,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tema = Theme.of(context).textTheme;
    return Tooltip(
      message: dica,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 20, color: cor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tema.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ValorAnimado(
                valor: valor,
                formatar: formatar,
                style: tema.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              if (exibeVariacao) _Variacao(variacao: variacao, altaEhRuim: altaEhRuim),
            ],
          ),
        ),
      ),
    );
  }
}

class _Variacao extends StatelessWidget {
  final double? variacao;
  final bool altaEhRuim;

  const _Variacao({required this.variacao, required this.altaEhRuim});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme.bodySmall;
    final v = variacao;
    if (v == null) {
      return Text(
        'Sem comparação com o mês anterior',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: estilo?.copyWith(color: scheme.onSurfaceVariant),
      );
    }
    final subiu = v >= 0;
    final bom = subiu != altaEhRuim;
    final cor = v.abs() < 0.05
        ? scheme.onSurfaceVariant
        : (bom ? const Color(0xFF2E9E5B) : scheme.error);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                subiu ? Icons.arrow_upward : Icons.arrow_downward,
                size: 12,
                color: cor,
              ),
              const SizedBox(width: 2),
              Text(
                '${v.abs().toStringAsFixed(0)}%',
                style: estilo?.copyWith(
                  color: cor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'vs. mês anterior',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: estilo?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Atalho para uma ação frequente.
class AcaoRapida extends StatelessWidget {
  final String titulo;
  final String descricao;
  final IconData icon;
  final String rota;

  const AcaoRapida({
    super.key,
    required this.titulo,
    required this.descricao,
    required this.icon,
    required this.rota,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tema = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer.withValues(alpha: 0.45),
      child: InkWell(
        onTap: () => context.push(rota),
        child: SizedBox(
          height: 132,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: scheme.onPrimary),
                ),
                const Spacer(),
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tema.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                Text(
                  descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tema.bodySmall?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
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
