import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:iconfeitto/core/widgets/app_date_time_field.dart';
import 'package:iconfeitto/core/widgets/form_builder_searchable_dropdown_field.dart';
import 'package:iconfeitto/features/dashboard/widgets/dashboard_cards.dart';
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

  /// Lançamento gerado por uma operação (ex.: compra): pessoa, tipo, valor e
  /// forma de pagamento acompanham a operação de origem e não são editáveis.
  bool get _vinculadoAOperacao {
    final original = _lancamentoOriginal;
    return original != null &&
        original.tipoOperacaoOriem != TipoOperacaoOrigem.avulso;
  }

  bool get _dadosBloqueados => _vinculadoAOperacao || _quitacoes.isNotEmpty;
  late StatusLancamentoFinanceiro _statusLancamento;

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
    _statusLancamento =
        original?.statusLancamento ?? StatusLancamentoFinanceiro.pendente;
  }

  List<Key> _gerarChaves(int quantidade) =>
      List.generate(quantidade, (_) => UniqueKey());

  Map<String, dynamic> _montarDadosIniciais(LancamentoFinanceiro? l) {
    return {
      'descricao': l?.descricao,
      'pessoaFinanceiro': l?.pessoaFinanceiro,
      'tipoLancamento': l?.tipoLancamento,
      'valorLancamento': (l?.valorLancamento ?? 0.0).toDecimal(),
      'valorDesconto': (l?.valorDesconto ?? 0.0).toDecimal(),
      'valorAcrescimo': (l?.valorAcrescimo ?? 0.0).toDecimal(),
      'formaPagamento': l?.formaPagamento,
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
        if (_isEdicao && !_vinculadoAOperacao)
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
        readOnly: _dadosBloqueados,
        onChanged: (_) => _aoAlterarValores(),
      );
    }

    Widget buildCampoDataCriacao() {
      return AppDateTimeField(
        name: 'dataCriacao',
        readOnly: _quitacoes.isNotEmpty,
        label: 'Data de criação',
        inputType: InputType.date,
      );
    }

    Widget buildCampoDataVencimento() {
      return AppDateTimeField(
        name: 'dataVencimento',
        readOnly: _quitacoes.isNotEmpty,
        label: 'Data de vencimento',
        inputType: InputType.date,
        onChanged: (value) {
          setState(() {});
        },
      );
    }

    return SectionCard(
      title: 'Dados do lançamento',
      child: Column(
        spacing: AppSpacing.md,
        children: [
          if (_vinculadoAOperacao)
            Row(
              spacing: AppSpacing.sm,
              children: [
                const Icon(Icons.lock_outline, size: 18),
                Expanded(
                  child: Text(
                    'Pessoa, tipo, valor e forma de pagamento vêm da operação '
                    'de origem e não podem ser alterados aqui.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          FormBuilderSearchableDropdownField<PessoaFinanceiro>(
            name: 'pessoaFinanceiro',
            label: 'Pessoa',
            readOnly: _dadosBloqueados,
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
          AppTextField(
            name: 'descricao',
            label: 'Descrição',
            readOnly: _quitacoes.isNotEmpty,
            icon: Icons.cake_outlined,
          ),
          Row(
            spacing: AppSpacing.md,
            children: [
              Expanded(
                child: FormBuilderDropdown<TipoLancamentoFinanceiro>(
                  enabled: !_dadosBloqueados,
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
                ),
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Status do lançamento",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _statusLancamento.label,
                            textAlign: TextAlign.start,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _statusLancamento =
                                  StatusLancamentoFinanceiro.encerrado;
                            });
                          },
                          child: const Text('Encerrar'),
                        ),
                      ],
                    ),
                  ],
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
          FormBuilderDropdown<FormaPagamento>(
            enabled: !_dadosBloqueados,
            name: 'formaPagamento',
            decoration: AppInputDecoration.of(
              'Forma de pagamento',
              icon: Icons.payments_outlined,
            ),
            items: [
              if (!_vinculadoAOperacao)
                const DropdownMenuItem<FormaPagamento>(
                  value: null,
                  child: Text('Não informada'),
                ),
              for (final forma in FormaPagamento.values)
                DropdownMenuItem(value: forma, child: Text(forma.label)),
            ],
          ),
          buildCampoValor(),
          Row(
            spacing: AppSpacing.md,
            children: [
              Expanded(
                child: AppNumberField(
                  name: 'valorDesconto',
                  label: 'Desconto',
                  required: false,
                  min: 0,
                  onChanged: (_) => _aoAlterarValores(),
                ),
              ),
              Expanded(
                child: AppNumberField(
                  name: 'valorAcrescimo',
                  label: 'Acréscimo',
                  required: false,
                  min: 0,
                  onChanged: (_) => _aoAlterarValores(),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor final',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                valorFinal.toCurrency(),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuitacoes() {
    final totalPendenteOuExcedente = valorFinal - totalQuitado;
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
      child: Column(
        spacing: AppSpacing.md,
        children: [
          Row(
            spacing: AppSpacing.md,
            children: [
              Expanded(
                child: KpiCard(
                  titulo: 'Total quitado',
                  icon: Icons.attach_money_rounded,
                  cor: Colors.green,
                  valor: totalQuitado,
                  dica: "",
                  exibeVariacao: false,
                ),
              ),

              Expanded(
                child: totalPendenteOuExcedente >= 0
                    ? KpiCard(
                        titulo: 'Total pendente',
                        icon: Icons.attach_money_rounded,
                        cor: Colors.red,
                        valor: totalPendenteOuExcedente,
                        dica: "",
                        exibeVariacao: false,
                      )
                    : KpiCard(
                        titulo: 'Total excedente',
                        icon: Icons.attach_money_rounded,
                        cor: Colors.orange,
                        valor: totalPendenteOuExcedente.abs(),
                        dica: "",
                        exibeVariacao: false,
                      ),
              ),
            ],
          ),

          ListView.separated(
            itemCount: _quitacoes.length,
            shrinkWrap: true,
            separatorBuilder: (context, index) => AppSpacing.mediumGap,
            itemBuilder: (context, index) => _buildLinhaQuitacao(index),
          ),
        ],
      ),
    );
  }

  double get totalQuitado {
    return _quitacoes.fold<double>(
      0,
      (previousValue, element) => previousValue + element.valorQuitado,
    );
  }

  double get valorLancamento =>
      getNumeroDoFormulario(_formKey, 'valorLancamento');

  double get valorDesconto => getNumeroDoFormulario(_formKey, 'valorDesconto');

  double get valorAcrescimo =>
      getNumeroDoFormulario(_formKey, 'valorAcrescimo');

  /// Valor do lançamento menos desconto mais acréscimo.
  double get valorFinal => valorLancamento - valorDesconto + valorAcrescimo;

  Widget _buildLinhaQuitacao(int i) {
    final quitacao = _quitacoes[i];

    return QuitacaoRow(
      key: _chavesQuitacoes[i],
      quitacao: quitacao,
      onChanged: (novo) => _alterarQuitacao(() {
        _quitacoes[i] = novo;
        setState(() {});
      }),
      onRemover: () => _alterarQuitacao(() {
        _quitacoes.removeAt(i);
        _chavesQuitacoes.removeAt(i);
        setState(() {});
      }),
    );
  }

  void _adicionarQuitacao() {
    final valorRestante = valorFinal - totalQuitado;

    setState(() {
      _alterarQuitacao(() {
        _quitacoes.insert(
          0,
          Quitacao(
            dataQuitacao: DateTime.now(),
            valorQuitado: (valorRestante > 0) ? valorRestante : 0,
            id: _repo.novoId(),
            formaPagamento:
                (_formKey.currentState?.fields['formaPagamento']?.value
                    as FormaPagamento?) ??
                FormaPagamento.dinheiro,
            lancamentoId: _lancamentoOriginal?.id ?? '',
          ),
        );
        _chavesQuitacoes.insert(0, UniqueKey());
      });
    });
  }

  void _alterarQuitacao(VoidCallback alteracao) {
    alteracao();
    _atualizarValores();
  }

  /// Reage a mudanças de valor/desconto/acréscimo sem reabrir um lançamento
  /// já encerrado manualmente.
  void _aoAlterarValores() {
    setState(() {
      if (_statusLancamento != StatusLancamentoFinanceiro.encerrado) {
        _atualizarValores();
      }
    });
  }

  void _atualizarValores() {
    final valorLancamento = valorFinal;

    if (totalQuitado >= valorLancamento - 0.005) {
      _statusLancamento = StatusLancamentoFinanceiro.quitado;
    } else if (totalQuitado > 0) {
      _statusLancamento = StatusLancamentoFinanceiro.parcialmenteQuitado;
    } else {
      _statusLancamento = StatusLancamentoFinanceiro.pendente;
    }
  }

  Future<void> _salvar({
    required ValueChanged<LancamentoFinanceiro> onSuccess,
  }) async {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) {
      _mostrarMensagem('Revise os campos obrigatórios do lançamento.');
      return;
    }

    if (valorFinal < 0) {
      _mostrarMensagem(
        'O desconto não pode ser maior que o valor do lançamento somado ao '
        'acréscimo.',
      );
      return;
    }

    try {
      final lancamento = _montarLancamento(form.value);
      await _repo.salvarLancamentoFinanceiro(lancamento);
      onSuccess(lancamento);
    } catch (error) {
      _mostrarMensagem('Não foi possível salvar o lançamento: $error');
    }
  }

  LancamentoFinanceiro _montarLancamento(Map<String, dynamic> valores) {
    final original = _lancamentoOriginal;
    // Em lançamentos vinculados a uma operação, os dados de origem vêm do
    // lançamento original, nunca do formulário.
    final vinculado = _vinculadoAOperacao && original != null;
    return LancamentoFinanceiro(
      id: original?.id ?? _repo.novoId(),
      descricao: valores['descricao']?.toString().trim() ?? '',
      statusLancamento: _statusLancamento,
      dataCriacao: valores['dataCriacao'] as DateTime,
      dataVencimento: valores['dataVencimento'] as DateTime,
      valorLancamento: vinculado
          ? original!.valorLancamento
          : numeroOuZero(valores['valorLancamento']),
      valorDesconto: numeroOuZero(valores['valorDesconto']),
      valorAcrescimo: numeroOuZero(valores['valorAcrescimo']),
      tipoLancamento: vinculado
          ? original!.tipoLancamento
          : valores['tipoLancamento'] as TipoLancamentoFinanceiro,
      formaPagamento: vinculado
          ? original!.formaPagamento
          : valores['formaPagamento'] as FormaPagamento?,
      observacao: original?.observacao ?? '',
      quitacoes: _quitacoes,
      pessoaFinanceiro: vinculado
          ? original!.pessoaFinanceiro
          : valores['pessoaFinanceiro'] as PessoaFinanceiro,
      lancamentoPai: original?.lancamentoPai,
      operacaoOrigemId: original?.operacaoOrigemId ?? 'null',
      tipoOperacaoOriem: original?.tipoOperacaoOriem ?? TipoOperacaoOrigem.avulso,
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
