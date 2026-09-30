import 'package:iconfeitto/shared/models/item_ficha_tecnica_embalagem.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_searchable_dropdown.dart';
import '../../../shared/models/produto.dart';

/// Linha de item da ficha técnica: ingrediente + quantidade + unidade + subtotal.
class ItemFichaEmbalagemRow extends StatefulWidget {
  final ItemFichaTecnicaEmbalagem item;
  final double custoLinha;
  final List<Produto> embalagens;
  final ValueChanged<ItemFichaTecnicaEmbalagem> onChanged;
  final VoidCallback onRemover;

  const ItemFichaEmbalagemRow({
    super.key,
    required this.item,
    required this.custoLinha,
    required this.embalagens,
    required this.onChanged,
    required this.onRemover,
  });

  @override
  State<ItemFichaEmbalagemRow> createState() => _ItemFichaEmbalagemRowState();
}

class _ItemFichaEmbalagemRowState extends State<ItemFichaEmbalagemRow> {
  @override
  Widget build(BuildContext context) {
    final ingredienteSelecionadoValido = widget.embalagens.any(
      (p) => p.id == widget.item.produtoEmbalagemId,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppSearchableDropdown<String>(
                  label: 'Item da embalagem',
                  icon: Icons.egg_alt_outlined,
                  value: ingredienteSelecionadoValido
                      ? widget.item.produtoEmbalagemId
                      : null,
                  items: widget.embalagens.map((p) => p.id).toList(),
                  itemBuilder: (id) =>
                      widget.embalagens.firstWhere((p) => p.id == id).nome,
                  itemComparator: (a, b) => widget.embalagens
                      .firstWhere((p) => p.id == a)
                      .nome
                      .compareTo(
                        widget.embalagens.firstWhere((p) => p.id == b).nome,
                      ),
                  onChanged: (novoId) {
                    if (novoId == null) return;
                    widget.onChanged(
                      ItemFichaTecnicaEmbalagem(produtoEmbalagemId: novoId),
                    );
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Remover item',
                onPressed: widget.onRemover,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Subtotal: ${widget.custoLinha.toCurrency()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
