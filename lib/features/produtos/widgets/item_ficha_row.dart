import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_grouped_dropdown.dart';
import '../../../core/widgets/app_input_decoration.dart';
import '../../../core/widgets/app_searchable_dropdown.dart';
import '../../../shared/models/grupo_unidade.dart';
import '../../../shared/models/item_ficha_tecnica.dart';
import '../../../shared/models/produto.dart';
import '../../../shared/models/unidade_medida.dart';

/// Linha de item da ficha técnica: ingrediente + quantidade + unidade + subtotal.
class ItemFichaRow extends StatefulWidget {
  final ItemFichaTecnica item;
  final List<Produto> ingredientes;
  final List<UnidadeMedida> unidadesCompativeis;
  final double custoLinha;
  final ValueChanged<ItemFichaTecnica> onChanged;
  final VoidCallback onRemover;

  const ItemFichaRow({
    super.key,
    required this.item,
    required this.ingredientes,
    required this.unidadesCompativeis,
    required this.custoLinha,
    required this.onChanged,
    required this.onRemover,
  });

  @override
  State<ItemFichaRow> createState() => _ItemFichaRowState();
}

class _ItemFichaRowState extends State<ItemFichaRow> {
  late TextEditingController _quantidadeController;
  late FocusNode _quantidadeFocusNode;

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

  @override
  Widget build(BuildContext context) {
    final ingredienteSelecionadoValido = widget.ingredientes.any(
      (p) => p.id == widget.item.produtoIngredienteId,
    );
    final unidadeSelecionadaValida = widget.unidadesCompativeis.any(
      (u) => u.id == widget.item.unidadeId,
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
                  label: 'Ingrediente',
                  icon: Icons.egg_alt_outlined,
                  value: ingredienteSelecionadoValido
                      ? widget.item.produtoIngredienteId
                      : null,
                  items: widget.ingredientes.map((p) => p.id).toList(),
                  itemBuilder: (id) =>
                      widget.ingredientes.firstWhere((p) => p.id == id).nome,
                  itemComparator: (a, b) => widget.ingredientes
                      .firstWhere((p) => p.id == a)
                      .nome
                      .compareTo(
                        widget.ingredientes.firstWhere((p) => p.id == b).nome,
                      ),
                  onChanged: (novoId) {
                    if (novoId == null) return;
                    final novoIngrediente = widget.ingredientes.firstWhere(
                      (p) => p.id == novoId,
                    );
                    widget.onChanged(
                      ItemFichaTecnica(
                        produtoIngredienteId: novoId,
                        quantidade: widget.item.quantidade,
                        unidadeId: novoIngrediente.unidadeEstoqueId,
                      ),
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
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _quantidadeController,
                  focusNode: _quantidadeFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: AppInputDecoration.of('Quantidade'),
                  onChanged: (texto) {
                    final selecao = _quantidadeController.selection;
                    final valor = texto.toDouble() ?? 0;
                    widget.onChanged(
                      ItemFichaTecnica(
                        produtoIngredienteId: widget.item.produtoIngredienteId,
                        quantidade: valor,
                        unidadeId: widget.item.unidadeId,
                      ),
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      if (!_quantidadeFocusNode.hasFocus) {
                        _quantidadeFocusNode.requestFocus();
                      }
                      _quantidadeController.selection = selecao;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: AppGroupedDropdown<String>(
                  label: 'Unidade',
                  value: unidadeSelecionadaValida
                      ? widget.item.unidadeId
                      : null,
                  groups: [
                    AppDropdownGroup(
                      name: widget.unidadesCompativeis.isEmpty
                          ? ''
                          : widget.unidadesCompativeis.first.grupo.label,
                      items: widget.unidadesCompativeis
                          .map((u) => u.id)
                          .toList(),
                    ),
                  ],
                  itemBuilder: (id) => widget.unidadesCompativeis
                      .firstWhere((u) => u.id == id)
                      .sigla,
                  itemComparator: (a, b) => widget.unidadesCompativeis
                      .firstWhere((u) => u.id == a)
                      .nome
                      .compareTo(
                        widget.unidadesCompativeis
                            .firstWhere((u) => u.id == b)
                            .nome,
                      ),
                  onChanged: (novaUnidade) {
                    if (novaUnidade == null) return;
                    widget.onChanged(
                      ItemFichaTecnica(
                        produtoIngredienteId: widget.item.produtoIngredienteId,
                        quantidade: widget.item.quantidade,
                        unidadeId: novaUnidade,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
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
