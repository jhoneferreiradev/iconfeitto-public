import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:iconfeitto/core/theme/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_grouped_dropdown.dart';
import '../../../core/widgets/app_input_decoration.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_builder_grouped_dropdown_field.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/grupo_unidade.dart';
import '../../../shared/models/produto_compra_rascunho.dart';
import '../../../shared/models/tipo_item.dart';

/// Abre o formulário simplificado de novo item a partir do formulário de compra.
/// Retorna o rascunho (novo ou editado) sem persistir nada.
Future<ProdutoCompraRascunho?> mostrarProdutoRascunhoSheet(
  BuildContext context, {
  ProdutoCompraRascunho? rascunho,
  List<TipoItem> tipos = TipoItem.tiposCompra,
}) {
  return showModalBottomSheet<ProdutoCompraRascunho>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        _ProdutoRascunhoSheet(rascunho: rascunho, tipos: tipos),
  );
}

class _ProdutoRascunhoSheet extends StatefulWidget {
  final ProdutoCompraRascunho? rascunho;
  final List<TipoItem> tipos;

  const _ProdutoRascunhoSheet({this.rascunho, required this.tipos});

  @override
  State<_ProdutoRascunhoSheet> createState() => _ProdutoRascunhoSheetState();
}

class _ProdutoRascunhoSheetState extends State<_ProdutoRascunhoSheet> {
  static const _unidadeEmbalagem = 'un';

  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;
  late TipoItem _tipo = widget.rascunho?.tipo ?? widget.tipos.first;

  @override
  Widget build(BuildContext context) {
    final rascunho = widget.rascunho;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: FormBuilder(
          key: _formKey,
          initialValue: {'nome': rascunho?.nome, 'tipo': _tipo},
          child: Column(
            spacing: AppSpacing.md,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                rascunho == null ? 'Novo item' : 'Editar novo item',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const AppTextField(
                name: 'nome',
                label: 'Nome',
                icon: Icons.inventory_2_outlined,
              ),
              FormBuilderDropdown<TipoItem>(
                name: 'tipo',
                decoration: AppInputDecoration.of(
                  'Tipo',
                  icon: Icons.category_outlined,
                ),
                validator: FormBuilderValidators.required(
                  errorText: 'Selecione o tipo',
                ),
                items: widget.tipos
                    .map(
                      (tipo) => DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo.label),
                      ),
                    )
                    .toList(),
                onChanged: (tipo) {
                  if (tipo != null) setState(() => _tipo = tipo);
                },
              ),
              if (_tipo != TipoItem.embalagem)
                FormBuilderGroupedDropdownField<String>(
                  name: 'unidadeConsumoId',
                  label: 'Unidade de consumo',
                  icon: Icons.sell,
                  initialValue: rascunho?.unidadeConsumoId,
                  validator: FormBuilderValidators.required(
                    errorText: 'Selecione a unidade',
                  ),
                  groups: _grupos(),
                  itemBuilder: (id) => _repo.unidadePorId(id).sigla,
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _confirmar,
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<AppDropdownGroup<String>> _grupos() {
    final grupos = <AppDropdownGroup<String>>[];
    for (final grupo in GrupoUnidade.values) {
      final unidades = _repo.unidadesDoGrupo(grupo)
        ..sort((a, b) => a.nome.compareTo(b.nome));
      if (unidades.isEmpty) continue;
      grupos.add(
        AppDropdownGroup<String>(
          name: grupo.label,
          items: unidades.map((u) => u.id).toList(),
        ),
      );
    }
    return grupos;
  }

  void _confirmar() {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) return;
    final valores = form.value;
    final existente = widget.rascunho;
    final unidadeConsumoId = _tipo == TipoItem.embalagem
        ? _unidadeEmbalagem
        : valores['unidadeConsumoId'] as String;
    Navigator.pop(
      context,
      ProdutoCompraRascunho(
        id: existente?.id ?? _repo.novoId(),
        nome: (valores['nome'] as String).trim(),
        tipo: _tipo,
        unidadeConsumoId: unidadeConsumoId,
      ),
    );
  }
}
