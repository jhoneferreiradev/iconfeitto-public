import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_input_decoration.dart';
import '../../../core/widgets/app_number_field.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/grupo_unidade.dart';
import '../../../shared/models/unidade_medida.dart';

class UnidadeFormScreen extends StatefulWidget {
  final String? unidadeId;
  const UnidadeFormScreen({super.key, this.unidadeId});

  @override
  State<UnidadeFormScreen> createState() => _UnidadeFormScreenState();
}

class _UnidadeFormScreenState extends State<UnidadeFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;
  UnidadeMedida? _original;

  bool get _isEdicao => widget.unidadeId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdicao) {
      _original = _repo.unidadePorId(widget.unidadeId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEdicao ? 'Editar unidade' : 'Nova unidade',
      body: FormBuilder(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        initialValue: {
          'nome': _original?.nome ?? '',
          'sigla': _original?.sigla ?? '',
          'grupo': _original?.grupo ?? GrupoUnidade.peso,
          'fatorParaBase': _original == null
              ? ''
              : _original!.fatorParaBase.toDecimal(),
        },
        child: ResponsiveFormLayout(
          singleColumnMaxWidth: 640,
          primary: [
            SectionCard(
              title: 'Dados da unidade',
              child: Column(
                children: [
                  const AppTextField(
                    name: 'nome',
                    label: 'Nome',
                    icon: Icons.label_outline,
                  ),
                  const SizedBox(height: 12),
                  const AppTextField(
                    name: 'sigla',
                    label: 'Sigla',
                    icon: Icons.short_text,
                  ),
                  const SizedBox(height: 12),
                  FormBuilderDropdown<GrupoUnidade>(
                    name: 'grupo',
                    enabled: !_isEdicao,
                    decoration: AppInputDecoration.of(
                      'Grupo',
                      icon: Icons.category_outlined,
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: 'Selecione o grupo',
                    ),
                    items: GrupoUnidade.values
                        .map(
                          (g) =>
                              DropdownMenuItem(value: g, child: Text(g.label)),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  AppNumberField(
                    name: 'fatorParaBase',
                    label: 'Equivalência para unidade base',
                    icon: Icons.swap_horiz,
                    min: 0.0001,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ex.: se a base do grupo peso é grama, 1 kg = 1000. Use 1 para a própria unidade base do grupo.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
          footer: FilledButton.icon(
            onPressed: _salvar,
            icon: const Icon(Icons.check),
            label: const Text('Salvar unidade'),
          ),
        ),
      ),
    );
  }

  void _salvar() {
    if (_formKey.currentState?.saveAndValidate() != true) return;
    final valores = _formKey.currentState!.value;
    final sigla = (valores['sigla'] as String).trim();
    final id = _original?.id ?? _repo.novoId();

    if (_original == null &&
        _repo.unidades.any(
          (u) => u.sigla.toLowerCase() == sigla.toLowerCase(),
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Já existe uma unidade com essa sigla.')),
      );
      return;
    }

    final unidade = UnidadeMedida(
      id: id,
      nome: (valores['nome'] as String).trim(),
      sigla: sigla,
      grupo: valores['grupo'] as GrupoUnidade,
      fatorParaBase: valores['fatorParaBase'] as double,
    );
    _repo.salvarUnidade(unidade);
    context.pop();
  }
}
