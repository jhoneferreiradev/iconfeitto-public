import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_input_decoration.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/cliente.dart';

class ClienteFormScreen extends StatefulWidget {
  final String? clienteId;

  const ClienteFormScreen({super.key, this.clienteId});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;
  Cliente? _original;

  @override
  void initState() {
    super.initState();
    if (widget.clienteId != null)
      _original = _repo.clientePorId(widget.clienteId!);
  }

  @override
  Widget build(BuildContext context) {
    final edicao = widget.clienteId != null;
    return AppScaffold(
      title: edicao ? 'Editar cliente' : 'Novo cliente',
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
              title: 'Dados do cliente',
              child: Column(
                children: [
                  const AppTextField(
                    name: 'nome',
                    label: 'Nome do cliente',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  FormBuilderSwitch(
                    name: 'ativo',
                    title: const Text('Cliente ativo'),
                    decoration: AppInputDecoration.of('Status'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.check),
              label: const Text('Salvar cliente'),
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
    if (_original == null &&
        _repo.clientes.any((c) => c.nome.toLowerCase() == nome.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Já existe um cliente com esse nome.')),
      );
      return;
    }
    _repo.salvarCliente(
      Cliente(
        id: _original?.id ?? _repo.novoId(),
        nome: nome,
        ativo: valores['ativo'] as bool? ?? true,
      ),
    );
    context.pop();
  }
}
