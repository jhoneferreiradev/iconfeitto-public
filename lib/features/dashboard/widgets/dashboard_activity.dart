import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/models/produto.dart';
import '../data/dashboard_metrics.dart';
import 'dashboard_common.dart';

class AtividadesCard extends StatelessWidget {
  final List<Atividade> atividades;

  const AtividadesCard({super.key, required this.atividades});

  static (IconData, Color) _visual(TipoAtividade tipo) => switch (tipo) {
    TipoAtividade.venda => (Icons.point_of_sale, const Color(0xFFE85D75)),
    TipoAtividade.compra => (Icons.shopping_cart, const Color(0xFF7C6BD6)),
    TipoAtividade.fabricacao => (Icons.soup_kitchen, const Color(0xFFFF9F5A)),
  };

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return DashCard(
      titulo: 'Atividades recentes',
      subtitulo: 'Últimos registros de vendas, compras e fabricações',
      child: atividades.isEmpty
          ? const SemDados(
              mensagem:
                  'Nada por aqui ainda. Use os atalhos acima para começar.',
              icon: Icons.history,
              altura: 140,
            )
          : Column(
              children: [
                for (final a in atividades)
                  Builder(
                    builder: (context) {
                      final (icone, cor) = _visual(a.tipo);
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: a.rota == null
                            ? null
                            : () => context.push(a.rota!),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(icone, size: 18, color: cor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.titulo,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: tema.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      diaMes(a.data),
                                      style: tema.bodySmall?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (a.valor != null)
                                Text(
                                  a.valor!.toCurrency(),
                                  style: tema.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}

class EstoqueCard extends StatelessWidget {
  final double valorEmEstoque;
  final int totalItens;
  final List<Produto> semSaldo;

  const EstoqueCard({
    super.key,
    required this.valorEmEstoque,
    required this.totalItens,
    required this.semSaldo,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    const verde = Color(0xFF2E9E5B);
    return DashCard(
      titulo: 'Saúde do estoque',
      subtitulo: 'Insumos, materiais e embalagens',
      acao: TextButton(
        onPressed: () => context.go('/estoque'),
        child: const Text('Ver estoque'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valor em estoque',
            style: tema.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          ValorAnimado(
            valor: valorEmEstoque,
            style: tema.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          if (totalItens == 0)
            Text(
              'Cadastre insumos e registre compras para acompanhar o estoque.',
              style: tema.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          else if (semSaldo.isEmpty)
            Row(
              children: [
                const Icon(Icons.check_circle, color: verde, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tudo certo: nenhum item zerado entre $totalItens cadastrados.',
                    style: tema.bodyMedium,
                  ),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: scheme.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${semSaldo.length} ${semSaldo.length == 1 ? 'item sem saldo' : 'itens sem saldo'} — hora de comprar?',
                    style: tema.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in semSaldo.take(6))
                  Chip(
                    label: Text(item.nome),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: scheme.errorContainer.withValues(
                      alpha: 0.5,
                    ),
                    side: BorderSide.none,
                  ),
                if (semSaldo.length > 6)
                  Chip(
                    label: Text('+${semSaldo.length - 6}'),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
