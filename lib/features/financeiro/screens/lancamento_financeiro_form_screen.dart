import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:iconfeitto/core/widgets/app_date_time_field.dart';
import 'package:iconfeitto/core/widgets/form_builder_searchable_dropdown_field.dart';
import 'package:iconfeitto/shared/models/lancamento_financeiro.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_input_decoration.dart';
import '../../../core/widgets/app_number_field.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/forma_pagamento.dart';
import '../widgets/quitacao_row.dart';

class LancamentoFinanceiroFormScreen extends StatefulWidget {
  final String? lancamentoId;
  const LancamentoFinanceiroFormScreen({super.key, this.lancamentoId});

  @override
  State<LancamentoFinanceiroFormScreen> createState() =>
      _LancamentoFinanceiroFormScreenState();
}

class _LancamentoFinanceiroFormScreenState
    extends State<LancamentoFinanceiroFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;

  late final List<PessoaFinanceiro> _pessoasFinanceiro;
  late final LancamentoFinanceiro? _lancamentoOriginal;
  late final Map<String, dynamic> _dadosIniciais;
  late List<Quitacao> _quitacoes;

  late List<Key> _chavesQuitacoes;

  bool get _isEdicao => widget.lancamentoId != null;

  @override
  void initState() {
    super.initState();
    _pessoasFinanceiro = _repo.pessoasFinanceiro;
    final id = widget.lancamentoId;
    final original = id == null ? null : _repo.lancamentoFinanceiroPorId(id);

    _lancamentoOriginal = original;

    _quitacoes = original?.quitacoes ?? [];
    _chavesQuitacoes = _gerarChaves(_quitacoes.length);

    _dadosIniciais = _montarDadosIniciais(original);
  }

  List<Key> _gerarChaves(int quantidade) =>
      List.generate(quantidade, (_) => UniqueKey());

  Map<String, dynamic> _montarDadosIniciais(LancamentoFinanceiro? l) {
    return {
      'descricao': l?.descricao,
      'pessoaFinanceiro': l?.pessoaFinanceiro,
      'statusLancamento': l?.statusLancamento,
      'tipoLancamento': l?.tipoLancamento,
      'valorLancamento': (l?.valorLancamento ?? 0.0).toDecimal(),
      'observacao': l?.observacao ?? '',
      'dataCriacao': (l?.dataCriacao ?? DateTime.now()),
      'dataVencimento': (l?.dataVencimento ?? DateTime.now()),
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEdicao ? 'Editar lançamento' : 'Novo lançamento',
      actions: [
        if (_isEdicao)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir lançamento',
            onPressed: _excluirLancamento,
          ),
      ],
      body: FormBuilder(
        key: _formKey,
        initialValue: _dadosIniciais,
        child: ResponsiveFormLayout(
          padding: AppSpacing.screenPadding,
          primaryFlex: 5,
          secondaryFlex: 6,
          primary: [
            _buildDadosDoLancamento(),
            FilledButton.icon(
              onPressed: () => _salvar(
                onSuccess: (_) {
                  if (mounted) context.pop();
                },
              ),
              icon: const Icon(Icons.check),
              label: const Text('Salvar lançamento'),
            ),
          ],
          secondary: [_buildQuitacoes()],
        ),
      ),
    );
  }

  Widget _buildDadosDoLancamento() {
    Widget buildCampoValor() {
      return AppNumberField(
        name: "valorLancamento",
        label: 'Valor do lançamento',
        min: 0,
        onChanged: (_) => _atualizarValores(),
      );
    }

    Widget buildCampoDataCriacao() {
      return const AppDateTimeField(
        name: 'dataCriacao',
        label: 'Data de criação',
        inputType: InputType.date,
      );
    }

    Widget buildCampoDataVencimento() {
      return const AppDateTimeField(
        name: 'dataVencimento',
        label: 'Data de vencimento',
        inputType: InputType.date,
      );
    }

    return SectionCard(
      key: GlobalKey(),
      title: 'Dados do lançamento',
      child: Column(
        spacing: AppSpacing.md,
        children: [
          FormBuilderSearchableDropdownField<PessoaFinanceiro>(
            name: 'pessoaFinanceiro',
            label: 'Pessoa',
            initialValue: _lancamentoOriginal?.pessoaFinanceiro,
            items: _pessoasFinanceiro,
            itemBuilder: (pessoa) {
              final pessoaLabel =
                  "${pessoa.tipoPessoaFinanceiro.label} :: ${pessoa.nome}";

              return pessoaLabel;
            },
            validator: FormBuilderValidators.required(
              errorText: 'Selecione a pessoa',
            ),
            onChanged: (pessoa) {
              _formKey.currentState?.fields['pessoaFinanceiroI']?.setValue(
                pessoa,
              );
            },
          ),
          const AppTextField(
            name: 'descricao',
            label: 'Descrição',
            icon: Icons.cake_outlined,
          ),
          Row(
            spacing: AppSpacing.md,
            children: [
              Expanded(
                child: FormBuilderDropdown<TipoLancamentoFinanceiro>(
                  name: 'tipoLancamento',
                  decoration: AppInputDecoration.of(
                    'Tipo do lançamento',
                    icon: Icons.category_outlined,
                  ),
                  validator: FormBuilderValidators.required(
                    errorText: 'Selecione o tipo do item',
                  ),
                  items: TipoLancamentoFinanceiro.values
                      .map(
                        (tipo) => DropdownMenuItem(
                          value: tipo,
                          child: Text(tipo.label),
                        ),
                      )
                      .toList(),
                  onChanged: _alterarTipo,
                ),
              ),

              Expanded(
                child: FormBuilderDropdown<StatusLancamentoFinanceiro>(
                  name: 'statusLancamento',
                  decoration: AppInputDecoration.of(
                    'Status do lançamento',
                    icon: Icons.category_outlined,
                  ),
                  validator: FormBuilderValidators.required(
                    errorText: 'Selecione o tipo do item',
                  ),
                  items: StatusLancamentoFinanceiro.values
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        ),
                      )
                      .toList(),
                  onChanged: _alterarStatus,
                ),
              ),
            ],
          ),

          Row(
            spacing: AppSpacing.md,
            children: [
              Expanded(child: buildCampoDataCriacao()),
              Expanded(child: buildCampoDataVencimento()),
            ],
          ),
          buildCampoValor(),
        ],
      ),
    );
  }

  void _alterarTipo(TipoLancamentoFinanceiro? value) {}

  void _alterarStatus(StatusLancamentoFinanceiro? value) {}

  Widget _buildQuitacoes() {
    return SectionCard(
      title: 'Quitações',
      trailing: Wrap(
        children: [
          TextButton.icon(
            onPressed: _adicionarQuitacao,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar quitação'),
          ),
        ],
      ),
      child: ListView.builder(
        itemCount: _quitacoes.length,
        shrinkWrap: true,
        itemBuilder: (context, index) => _buildLinhaQuitacao(index),
      ),
    );
  }

  Widget _buildLinhaQuitacao(int i) {
    final quitacao = _quitacoes[i];

    return QuitacaoRow(
      key: _chavesQuitacoes[i],
      quitacao: quitacao,
      onChanged: (novo) => _alterarItens(() {}),
      onRemover: () => _alterarItens(() {
        _quitacoes.removeAt(i);
        _chavesQuitacoes.removeAt(i);
      }),
    );
  }

  void _adicionarQuitacao() {
    _alterarItens(() {
      _quitacoes.insert(
        0,
        Quitacao(
          dataQuitacao: DateTime.now(),
          valorQuitado: 0,
          id: _repo.novoId(),
          formaPagamento: FormaPagamento.dinheiro,
          lancamentoId: _lancamentoOriginal?.id ?? '',
        ),
      );
      _chavesQuitacoes.insert(0, UniqueKey());
    });
    setState(() {});
  }

  void _alterarItens(VoidCallback alteracao) {
    alteracao();
    _atualizarValores();
    setState(() {});
  }

  void _atualizarValores() {}

  Future<void> _salvar({
    required ValueChanged<LancamentoFinanceiro> onSuccess,
  }) async {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) {
      _mostrarMensagem('Revise os campos obrigatórios do lançamento.');
      return;
    }

    try {
      final lancamento = _montarLancamento(form.value);
      _repo.salvarLancamentoFinanceiro(lancamento);
      onSuccess(lancamento);
    } catch (error) {
      _mostrarMensagem('Não foi possível salvar o lançamento: $error');
    }
  }

  LancamentoFinanceiro _montarLancamento(Map<String, dynamic> valores) {
    return LancamentoFinanceiro(
      id: _lancamentoOriginal?.id ?? _repo.novoId(),
      descricao: valores['descricao']?.toString().trim() ?? '',
      statusLancamento:
          valores['statusLancamento'] as StatusLancamentoFinanceiro,
      dataCriacao: valores['dataCriacao'] as DateTime,
      dataVencimento: valores['dataVencimento'] as DateTime,
      valorLancamento: numeroOuZero(valores['valorLancamento']),
      tipoLancamento: valores['tipoLancamento'] as TipoLancamentoFinanceiro,
      observacao: '',
      quitacoes: _quitacoes,
      pessoaFinanceiro: valores['pessoaFinanceiro'] as PessoaFinanceiro,
      operacaoOrigemId: 'null',
      tipoOperacaoOriem:
          _lancamentoOriginal?.tipoOperacaoOriem ?? TipoOperacaoOrigem.avulso,
    );
  }

  Future<void> _excluirLancamento() async {
    final lancamento = _lancamentoOriginal;
    if (lancamento == null) return;

    final confirmar = await confirmarExclusao(
      context,
      titulo: 'Excluir lançamento',
      mensagem: 'Deseja excluir o lançamento? Essa ação não pode ser desfeita.',
    );
    if (!confirmar) return;

    await _repo.excluirLancamentoFinanceiro(lancamento);
    if (mounted) context.pop();
  }

  void _mostrarMensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }
}
