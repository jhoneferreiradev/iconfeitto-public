import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_input_decoration.dart';
import '../../../core/widgets/app_number_field.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/cartao_credito.dart';

class BandeiraFormScreen extends StatefulWidget {
  final String? bandeiraId;

  const BandeiraFormScreen({super.key, this.bandeiraId});

  @override
  State<BandeiraFormScreen> createState() => _BandeiraFormScreenState();
}

class _BandeiraFormScreenState extends State<BandeiraFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;
  BandeiraCartaoCredito? _original;

  bool get _isEdicao => widget.bandeiraId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdicao) _original = _repo.bandeiraPorId(widget.bandeiraId!);
  }

  TipoTaxaBandeira get _tipoTaxaAtual =>
      (_formKey.currentState?.instantValue['tipoTaxa']
          as TipoTaxaBandeira?) ??
      _original?.tipoTaxa ??
      TipoTaxaBandeira.percentual;

  @override
  Widget build(BuildContext context) {
    if (_isEdicao && _original == null) {
      return const AppScaffold(
        title: 'Bandeira não encontrada',
        body: EmptyState(mensagem: 'A bandeira solicitada não existe.'),
      );
    }
    return AppScaffold(
      title: _isEdicao ? 'Editar bandeira' : 'Nova bandeira',
      body: FormBuilder(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: () => setState(() {}),
        initialValue: {
          'nome': _original?.nome ?? '',
          'taxa': formatarParaCampo(_original?.taxa ?? 0),
          'tipoTaxa': _original?.tipoTaxa ?? TipoTaxaBandeira.percentual,
          'diasCompensacao': (_original?.diasCompensacao ?? 1).toString(),
        },
        child: CenteredListView(
          children: [
            SectionCard(
              title: 'Dados da bandeira',
              child: Column(
                children: [
                  const AppTextField(
                    name: 'nome',
                    label: 'Nome da bandeira',
                    icon: Icons.contactless_outlined,
                  ),
                  const SizedBox(height: 12),
                  FormBuilderDropdown<TipoTaxaBandeira>(
                    name: 'tipoTaxa',
                    decoration: AppInputDecoration.of(
                      'Tipo da taxa',
                      icon: Icons.sell_outlined,
                    ),
                    validator: FormBuilderValidators.required(
                      errorText: 'Selecione o tipo da taxa',
                    ),
                    items: [
                      for (final tipo in TipoTaxaBandeira.values)
                        DropdownMenuItem(value: tipo, child: Text(tipo.label)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppNumberField(
                    name: 'taxa',
                    label: _tipoTaxaAtual == TipoTaxaBandeira.percentual
                        ? 'Taxa'
                        : 'Valor fixo',
                    icon: _tipoTaxaAtual == TipoTaxaBandeira.percentual
                        ? Icons.percent
                        : Icons.attach_money,
                    suffixText: _tipoTaxaAtual == TipoTaxaBandeira.percentual
                        ? '%'
                        : 'R\$',
                    min: 0,
                  ),
                  const SizedBox(height: 12),
                  FormBuilderTextField(
                    name: 'diasCompensacao',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: AppInputDecoration.of(
                      'Dias para compensação',
                      icon: Icons.account_balance_outlined,
                    ),
                    validator: FormBuilderValidators.compose([
                      FormBuilderValidators.required(
                        errorText: 'Informe os dias para compensação',
                      ),
                      FormBuilderValidators.integer(
                        errorText: 'Informe um número inteiro',
                      ),
                    ]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dias que o valor recebido no cartão leva para compensar e '
                    'cair na conta (quantos você precisar); calcula a "Data de '
                    'compensação" dos lançamentos a receber. O percentual é '
                    'aplicado sobre cada parcela das vendas no '
                    'cartão; o valor fixo é cobrado uma vez por venda, na '
                    'primeira parcela. Em ambos os casos vai para o campo '
                    '"Taxas e impostos" do lançamento. Alterar não muda '
                    'lançamentos já criados.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.check),
              label: const Text('Salvar bandeira'),
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
    final taxa = (valores['taxa'] as num?)?.toDouble() ?? 0;
    final tipoTaxa = valores['tipoTaxa'] as TipoTaxaBandeira;
    if (tipoTaxa == TipoTaxaBandeira.percentual && taxa > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O percentual não pode passar de 100%.')),
      );
      return;
    }
    final repetida = _repo.bandeirasCartaoCredito.any(
      (b) => b.id != _original?.id && b.nome.toLowerCase() == nome.toLowerCase(),
    );
    if (repetida) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Já existe uma bandeira com esse nome.')),
      );
      return;
    }
    await _repo.salvarBandeiraCartao(
      BandeiraCartaoCredito(
        id: _original?.id ?? _repo.novoId(),
        nome: nome,
        taxa: taxa,
        tipoTaxa: tipoTaxa,
        diasCompensacao: int.parse(valores['diasCompensacao'] as String),
      ),
    );
    if (mounted) context.pop();
  }
}
