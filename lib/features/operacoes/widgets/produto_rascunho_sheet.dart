import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:iconfeitto/core/theme/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_grouped_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/form_builder_grouped_dropdown_field.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/grupo_unidade.dart';
import '../../../shared/models/produto_compra_rascunho.dart';

/// Abre o formulário simplificado de novo produto a partir do rodapé.
/// Retorna o rascunho (novo ou editado) sem persistir nada.
Future<ProdutoCompraRascunho?> mostrarProdutoRascunhoSheet(
  BuildContext context, {
  ProdutoCompraRascunho? rascunho,
}) {
  return showModalBottomSheet<ProdutoCompraRascunho>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ProdutoRascunhoSheet(rascunho: rascunho),
  );
}

class _ProdutoRascunhoSheet extends StatefulWidget {
  final ProdutoCompraRascunho? rascunho;

  const _ProdutoRascunhoSheet({this.rascunho});

  @override
  State<_ProdutoRascunhoSheet> createState() => _ProdutoRascunhoSheetState();
}

class _ProdutoRascunhoSheetState extends State<_ProdutoRascunhoSheet> {
  static const _unidadeEmbalagem = 'un';

  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;
  late bool _isEmbalagem = widget.rascunho?.isEmbalagem ?? false;

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
          initialValue: {
            'nome': rascunho?.nome,
            'isEmbalagem': rascunho?.isEmbalagem ?? false,
            'podeSerVendido': rascunho?.podeSerVendido ?? false,
          },
          child: Column(
            spacing: AppSpacing.md,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                rascunho == null ? 'Novo produto' : 'Editar novo produto',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const AppTextField(
                name: 'nome',
                label: 'Nome',
                icon: Icons.cake_outlined,
              ),
              FormBuilderSwitch(
                name: 'isEmbalagem',
                title: const Text('É embalagem'),
                onChanged: (valor) =>
                    setState(() => _isEmbalagem = valor ?? false),
              ),
              FormBuilderSwitch(
                name: 'podeSerVendido',
                title: const Text('Pode ser vendido'),
              ),
              if (!_isEmbalagem)
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
    final unidadeConsumoId = _isEmbalagem
        ? _unidadeEmbalagem
        : valores['unidadeConsumoId'] as String;
    Navigator.pop(
      context,
      ProdutoCompraRascunho(
        id: existente?.id ?? _repo.novoId(),
        nome: (valores['nome'] as String).trim(),
        isEmbalagem: _isEmbalagem,
        podeSerVendido: valores['podeSerVendido'] as bool? ?? false,
        unidadeConsumoId: unidadeConsumoId,
      ),
    );
  }
}
