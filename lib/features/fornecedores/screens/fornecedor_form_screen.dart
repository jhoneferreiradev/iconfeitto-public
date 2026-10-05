import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_input_decoration.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/fornecedor.dart';

class FornecedorFormScreen extends StatefulWidget {
  final String? fornecedorId;

  const FornecedorFormScreen({super.key, this.fornecedorId});

  @override
  State<FornecedorFormScreen> createState() => _FornecedorFormScreenState();
}

class _FornecedorFormScreenState extends State<FornecedorFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;
  Fornecedor? _original;

  bool get _isEdicao => widget.fornecedorId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdicao) {
      _original = _repo.fornecedorPorId(widget.fornecedorId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEdicao ? 'Editar fornecedor' : 'Novo fornecedor',
      body: FormBuilder(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        initialValue: {
          'nome': _original?.nome ?? '',
          'ativo': _original?.ativo ?? true,
        },
        child: CenteredListView(
          children: [
            SectionCard(
              title: 'Dados do fornecedor',
              child: Column(
                children: [
                  const AppTextField(
                    name: 'nome',
                    label: 'Nome do fornecedor',
                    icon: Icons.business_outlined,
                  ),
                  const SizedBox(height: 12),
                  FormBuilderSwitch(
                    name: 'ativo',
                    title: const Text('Fornecedor ativo'),
                    decoration: AppInputDecoration.of('Status'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.check),
              label: const Text('Salvar fornecedor'),
            ),
          ],
        ),
      ),
    );
  }

  void _salvar() {
    if (_formKey.currentState?.saveAndValidate() != true) return;
    final valores = _formKey.currentState!.value;
    final nome = (valores['nome'] as String).trim();
    final id = _original?.id ?? _repo.novoId();

    if (_original == null &&
        _repo.fornecedores.any(
          (f) => f.nome.toLowerCase() == nome.toLowerCase(),
        )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Já existe um fornecedor com esse nome.')),
      );
      return;
    }

    _repo.salvarFornecedor(
      Fornecedor(id: id, nome: nome, ativo: valores['ativo'] as bool? ?? true),
    );
    context.pop();
  }
}
