import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_grouped_dropdown.dart';
import '../../../core/widgets/app_input_decoration.dart';
import '../../../shared/models/grupo_unidade.dart';
import '../../../shared/models/item_ficha_tecnica_embalagem.dart';
import '../../../shared/models/produto.dart';
import '../../../shared/models/unidade_medida.dart';
import 'item_ficha_card.dart';

/// Linha de item da ficha técnica: ingrediente + quantidade + unidade + subtotal.
class ItemFichaEmbalagemRow extends StatefulWidget {
  final ItemFichaTecnicaEmbalagem item;
  final List<Produto> embalagens;
  final List<UnidadeMedida> unidadesCompativeis;
  final double custoLinha;
  final ValueChanged<ItemFichaTecnicaEmbalagem> onChanged;
  final VoidCallback onRemover;
  final VoidCallback? onMoverParaCima;
  final VoidCallback? onMoverParaBaixo;
  final VoidCallback? onEditarNovoItem;

  const ItemFichaEmbalagemRow({
    super.key,
    required this.item,
    required this.embalagens,
    required this.unidadesCompativeis,
    required this.custoLinha,
    required this.onChanged,
    required this.onRemover,
    this.onMoverParaCima,
    this.onMoverParaBaixo,
    this.onEditarNovoItem,
  });

  @override
  State<ItemFichaEmbalagemRow> createState() => _ItemFichaEmbalagemRowState();
}

class _ItemFichaEmbalagemRowState extends State<ItemFichaEmbalagemRow> {
  late final TextEditingController _quantidadeController;
  late final FocusNode _quantidadeFocusNode;

  @override
  void initState() {
    super.initState();
    _quantidadeController = TextEditingController(
      text: widget.item.quantidade == 0
          ? ''
          : formatarNumero(widget.item.quantidade),
    );
    _quantidadeFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _quantidadeFocusNode.dispose();
    super.dispose();
  }

  ItemFichaTecnicaEmbalagem _copiarItem({
    String? produtoEmbalagemId,
    double? quantidade,
    String? unidadeId,
  }) {
    return ItemFichaTecnicaEmbalagem(
      produtoEmbalagemId: produtoEmbalagemId ?? widget.item.produtoEmbalagemId,
      quantidade: quantidade ?? widget.item.quantidade,
      unidadeId: unidadeId ?? widget.item.unidadeId,
    );
  }

  void _selecionarIngrediente(String novoId) {
    final ingrediente = widget.embalagens.firstWhere((p) => p.id == novoId);
    widget.onChanged(
      _copiarItem(
        produtoEmbalagemId: novoId,
        unidadeId: ingrediente.unidadeConsumoId,
      ),
    );
  }

  void _alterarQuantidade(String texto) {
    final selecao = _quantidadeController.selection;
    widget.onChanged(_copiarItem(quantidade: texto.toDouble() ?? 0));

    // O pai reconstrói a linha; devolve foco e cursor ao campo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_quantidadeFocusNode.hasFocus) _quantidadeFocusNode.requestFocus();
      _quantidadeController.selection = selecao;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ItemFichaCard(
      custoLinha: widget.custoLinha,
      onRemover: widget.onRemover,
      acoes: [
        if (widget.onEditarNovoItem != null)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar novo item',
            onPressed: widget.onEditarNovoItem,
          ),
        IconButton(
          icon: const Icon(Icons.arrow_upward),
          tooltip: 'Mover para cima',
          onPressed: widget.onMoverParaCima,
        ),
        IconButton(
          icon: const Icon(Icons.arrow_downward),
          tooltip: 'Mover para baixo',
          onPressed: widget.onMoverParaBaixo,
        ),
      ],
      seletor: SeletorDeProduto(
        label: 'Ingrediente',
        produtos: widget.embalagens,
        selecionadoId: widget.item.produtoEmbalagemId,
        onChanged: _selecionarIngrediente,
      ),
      children: [
        Row(
          spacing: AppSpacing.sm,
          children: [
            Expanded(flex: 2, child: _buildQuantidade()),
            Expanded(flex: 2, child: _buildUnidade()),
          ],
        ),
      ],
    );
  }

  Widget _buildQuantidade() {
    return TextFormField(
      controller: _quantidadeController,
      focusNode: _quantidadeFocusNode,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: AppInputDecoration.of('Quantidade'),
      onChanged: _alterarQuantidade,
    );
  }

  Widget _buildUnidade() {
    final unidades = widget.unidadesCompativeis;
    final selecionadaValida = unidades.any(
      (u) => u.id == widget.item.unidadeId,
    );
    UnidadeMedida porId(String id) => unidades.firstWhere((u) => u.id == id);

    return AppGroupedDropdown<String>(
      label: 'Unidade',
      value: selecionadaValida ? widget.item.unidadeId : null,
      groups: [
        AppDropdownGroup(
          name: unidades.isEmpty ? '' : unidades.first.grupo.label,
          items: unidades.map((u) => u.id).toList(),
        ),
      ],
      itemBuilder: (id) => porId(id).sigla,
      itemComparator: (a, b) => porId(a).nome.compareTo(porId(b).nome),
      onChanged: (novaUnidade) {
        if (novaUnidade != null) {
          widget.onChanged(_copiarItem(unidadeId: novaUnidade));
        }
      },
    );
  }
}
