import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_input_decoration.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/custo_operacional.dart';
import '../../../shared/models/empresa.dart';

class EmpresaFormScreen extends StatefulWidget {
  const EmpresaFormScreen({super.key});

  @override
  State<EmpresaFormScreen> createState() => _EmpresaFormScreenState();
}

class _EmpresaFormScreenState extends State<EmpresaFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final AppRepository _repo = AppRepository.instance;

  Empresa get _empresaOriginal => _repo.empresa;

  void _pickImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de logo será implementada em breve'),
      ),
    );
  }

  Future<void> _salvarEmpresa() async {
    if (!_formKey.currentState!.saveAndValidate()) {
      return;
    }

    final values = _formKey.currentState!.value;
    final novaEmpresa = Empresa(
      id: _empresaOriginal.id,
      nome: values['nome']?.toString(),
      cnpjCpf: values['cnpjCpf']?.toString(),
      telefone: values['telefone']?.toString(),
      endereco: values['endereco']?.toString(),
      instagram: values['instagram']?.toString(),
      facebook: values['facebook']?.toString(),
      logoPath: _empresaOriginal.logoPath,
    );

    await _repo.salvarEmpresa(novaEmpresa);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empresa salva com sucesso!')),
      );
      context.pop();
    }
  }

  Future<void> _adicionarCustoOperacional() async {
    final nomeController = TextEditingController();
    final valorController = TextEditingController();

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo custo operacional'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome'),
              autofocus: true,
            ),
            TextField(
              controller: valorController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Valor'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (confirmado != true) return;

    final nome = nomeController.text.trim();
    final valor = valorController.text.toDouble() ?? 0;
    if (nome.isEmpty) return;

    await _repo.adicionarCustoOperacional(
      CustoOperacional(id: _repo.novoId(), nome: nome, valor: valor),
    );
  }

  Future<void> _removerCustoOperacional(CustoOperacional custo) async {
    final confirmar = await confirmarExclusao(
      context,
      titulo: 'Excluir custo operacional',
      mensagem:
          'Deseja excluir "${custo.nome}"? Essa ação não pode ser desfeita.',
    );
    if (confirmar) await _repo.removerCustoOperacional(custo.id);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _repo,
      builder: (context, _) {
        return AppScaffold(
          title: 'Cadastro da Empresa',
          body: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: FormBuilder(
              key: _formKey,
              initialValue: {
                'nome': _empresaOriginal.nome ?? '',
                'cnpjCpf': _empresaOriginal.cnpjCpf ?? '',
                'telefone': _empresaOriginal.telefone ?? '',
                'endereco': _empresaOriginal.endereco ?? '',
                'instagram': _empresaOriginal.instagram ?? '',
                'facebook': _empresaOriginal.facebook ?? '',
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo placeholder
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.borderRadiusMd,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.md),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text('Escolher Logo'),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  // Form fields
                  FormBuilderTextField(
                    name: 'nome',
                    decoration: AppInputDecoration.of('Nome da Empresa'),
                    validator: FormBuilderValidators.required(),
                  ),
                  AppSpacing.fieldGap,

                  FormBuilderTextField(
                    name: 'cnpjCpf',
                    decoration: AppInputDecoration.of('CNPJ / CPF'),
                  ),
                  AppSpacing.fieldGap,

                  FormBuilderTextField(
                    name: 'telefone',
                    decoration: AppInputDecoration.of('Telefone'),
                  ),
                  AppSpacing.fieldGap,

                  FormBuilderTextField(
                    name: 'endereco',
                    decoration: AppInputDecoration.of('Endereço'),
                    maxLines: 2,
                  ),
                  AppSpacing.fieldGap,

                  FormBuilderTextField(
                    name: 'instagram',
                    decoration: AppInputDecoration.of('Instagram'),
                  ),
                  AppSpacing.fieldGap,

                  FormBuilderTextField(
                    name: 'facebook',
                    decoration: AppInputDecoration.of('Facebook'),
                  ),
                  SizedBox(height: AppSpacing.lg),

                  _buildCustosOperacionaisSection(),
                  SizedBox(height: AppSpacing.lg),

                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: _salvarEmpresa,
                            child: const Text('Salvar'),
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => context.pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustosOperacionaisSection() {
    final custos = _empresaOriginal.custosOperacionais;
    return SectionCard(
      title: 'Custos Operacionais',
      trailing: IconButton(
        icon: const Icon(Icons.add_circle_outline),
        tooltip: 'Adicionar custo operacional',
        onPressed: _adicionarCustoOperacional,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (custos.isEmpty)
            const EmptyState(
              mensagem: 'Nenhum custo operacional cadastrado.',
              icon: Icons.request_quote_outlined,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: custos.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final custo = custos[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(custo.nome),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(custo.valor.toCurrency()),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Excluir',
                        onPressed: () => _removerCustoOperacional(custo),
                      ),
                    ],
                  ),
                );
              },
            ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Total: ${_empresaOriginal.custoOperacionalPorHora.toCurrency()}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
