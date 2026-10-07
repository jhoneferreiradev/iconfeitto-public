import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_input_decoration.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/cartao_credito.dart';
import '../widgets/cartao_dialogs.dart';

class CartaoFormScreen extends StatefulWidget {
  final String? cartaoId;

  const CartaoFormScreen({super.key, this.cartaoId});

  @override
  State<CartaoFormScreen> createState() => _CartaoFormScreenState();
}

class _CartaoFormScreenState extends State<CartaoFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;
  CartaoCredito? _original;

  bool get _isEdicao => widget.cartaoId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdicao) _original = _repo.cartaoPorId(widget.cartaoId!);
  }

  CartaoCredito _cartaoAtual() {
    final valores = _formKey.currentState?.instantValue;
    return CartaoCredito(
      id: _original?.id ?? '',
      nome: '',
      diaVencimento:
          (valores?['diaVencimento'] as int?) ?? _original?.diaVencimento ?? 10,
      diasFechamento:
          (valores?['diasFechamento'] as int?) ??
          _original?.diasFechamento ??
          7,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isEdicao && _original == null) {
      return const AppScaffold(
        title: 'Cartão não encontrado',
        body: EmptyState(mensagem: 'O cartão solicitado não existe.'),
      );
    }
    final atual = _cartaoAtual();
    final hoje = DateTime.now();
    final vencimento = atual.vencimentoDaFatura(hoje);
    final aviso = avisoDiaVencimento(atual.diaVencimento);
    return AppScaffold(
      title: _isEdicao ? 'Editar cartão' : 'Novo cartão',
      body: FormBuilder(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: () => setState(() {}),
        initialValue: {
          'nome': _original?.nome ?? '',
          'diaVencimento': _original?.diaVencimento ?? 10,
          'diasFechamento': _original?.diasFechamento ?? 7,
        },
        child: CenteredListView(
          children: [
            SectionCard(
              title: 'Dados do cartão',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppTextField(
                    name: 'nome',
                    label: 'Nome do cartão',
                    icon: Icons.credit_card_outlined,
                  ),
                  const SizedBox(height: 12),
                  FormBuilderDropdown<int>(
                    name: 'diaVencimento',
                    decoration: AppInputDecoration.of(
                      'Dia de vencimento da fatura',
                      icon: Icons.event_outlined,
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: 'Informe o dia de vencimento',
                    ),
                    items: [
                      for (var dia = 1; dia <= 31; dia++)
                        DropdownMenuItem(value: dia, child: Text('Dia $dia')),
                    ],
                  ),
                  if (aviso != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        aviso,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 12),
                  FormBuilderDropdown<int>(
                    name: 'diasFechamento',
                    decoration: AppInputDecoration.of(
                      'Dias para fechamento (antes do vencimento)',
                      icon: Icons.lock_clock_outlined,
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: 'Informe os dias para fechamento',
                    ),
                    items: [
                      for (var dias = 0; dias <= 30; dias++)
                        DropdownMenuItem(
                          value: dias,
                          child: Text(dias == 1 ? '1 dia' : '$dias dias'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Exemplo: uma compra feita hoje (${hoje.toFormattedDate()}) '
                    'entra na fatura que vence em ${vencimento.toFormattedDate()}. '
                    'Compras no dia do fechamento ou depois vão para a fatura '
                    'seguinte.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.check),
              label: const Text('Salvar cartão'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _salvar() async {
    if (_formKey.currentState?.saveAndValidate() != true) return;
    final valores = _formKey.currentState!.value;
    final nome = (valores['nome'] as String).trim();
    final repetido = _repo.cartoesCredito.any(
      (c) => c.id != _original?.id && c.nome.toLowerCase() == nome.toLowerCase(),
    );
    if (repetido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Já existe um cartão com esse nome.')),
      );
      return;
    }
    await _repo.salvarCartaoCredito(
      CartaoCredito(
        id: _original?.id ?? _repo.novoId(),
        nome: nome,
        diaVencimento: valores['diaVencimento'] as int,
        diasFechamento: valores['diasFechamento'] as int,
      ),
    );
    if (mounted) context.pop();
  }
}
