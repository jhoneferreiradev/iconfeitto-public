import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/models/produto.dart';
import '../../../shared/models/unidade_medida.dart';

class ProdutoCard extends StatelessWidget {
  final Produto produto;
  final UnidadeMedida unidade;
  final double custoFicha;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProdutoCard({
    super.key,
    required this.produto,
    required this.unidade,
    required this.custoFicha,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  Icons.cake_outlined,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produto.nome,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Custo médio: ${produto.custoMedio.toCurrency()} / ${unidade.sigla}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (produto.fichaTecnica.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Ficha técnica (${produto.fichaTecnica.length} itens): ${custoFicha.toCurrency()}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.primary),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Chip(
                    label: Text(produto.ativo ? 'Ativo' : 'Inativo'),
                    backgroundColor: produto.ativo
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                    labelStyle: TextStyle(
                      color: produto.ativo
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                    side: BorderSide.none,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Excluir',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
