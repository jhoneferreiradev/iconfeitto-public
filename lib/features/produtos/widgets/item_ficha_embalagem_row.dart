import 'package:material_ui/material_ui.dart';

import '../../../shared/models/item_ficha_tecnica_embalagem.dart';
import '../../../shared/models/produto.dart';
import 'item_ficha_card.dart';

/// Linha de item de embalagem: produto de embalagem + subtotal.
class ItemFichaEmbalagemRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ItemFichaCard(
      custoLinha: custoLinha,
      onRemover: onRemover,
      seletor: SeletorDeProduto(
        label: 'Item da embalagem',
        produtos: embalagens,
        selecionadoId: item.produtoEmbalagemId,
        onChanged: (novoId) =>
            onChanged(ItemFichaTecnicaEmbalagem(produtoEmbalagemId: novoId)),
      ),
    );
  }
}
