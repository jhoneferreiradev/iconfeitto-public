import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:iconfeitto/core/widgets/app_date_time_field.dart';
import 'package:iconfeitto/shared/models/lancamento_financeiro.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_grouped_dropdown.dart';
import '../../../core/widgets/app_input_decoration.dart';
import '../../../core/widgets/app_number_field.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/form_builder_grouped_dropdown_field.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/forma_pagamento.dart';
import '../../../shared/models/grupo_unidade.dart';
import '../../../shared/models/item_ficha_tecnica.dart';
import '../../../shared/models/item_ficha_tecnica_embalagem.dart';
import '../../../shared/models/produto.dart';
import '../../../shared/models/produto_compra_rascunho.dart';
import '../../../shared/models/tipo_item.dart';
import '../../operacoes/widgets/produto_rascunho_sheet.dart';
import '../pdf/lancamento_financeiro_pdf.dart';
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

  late final LancamentoFinanceiro? _lancamentoOriginal;
  late final Map<String, dynamic> _dadosIniciais;
  late List<Quitacao> _quitacoes;

  late List<Key> _chavesQuitacoes;
  late TipoLancamentoFinanceiro _tipo;

  bool get _isEdicao => widget.lancamentoId != null;

  // ---------------------------------------------------------------------------
  // Ciclo de vida
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    final id = widget.lancamentoId;
    final original = id == null ? null : _repo.lancamentoFinanceiroPorId(id);

    _lancamentoOriginal = original;
    _tipo = original?.tipoLancamento ?? TipoLancamentoFinanceiro.receita;

    _quitacoes = original?.quitacoes ?? [];
    _chavesQuitacoes = _gerarChaves(_quitacoes.length);

    _dadosIniciais = _montarDadosIniciais(original);
  }

  List<Key> _gerarChaves(int quantidade) =>
      List.generate(quantidade, (_) => UniqueKey());

  Map<String, dynamic> _montarDadosIniciais(LancamentoFinanceiro? l) {
    return {
      'descricao': l?.descricao ?? '',
      'status': l?.statusLancamento ?? StatusLancamentoFinanceiro.pendente,
      'tipoLancamento': l?.tipoLancamento ?? TipoLancamentoFinanceiro.receita,
      'valor': (l?.valor ?? 0.0).toDecimal(),
      'observacao': l?.observacao ?? '',
      'dataCriacao': (l?.dataCriacao ?? DateTime.now()).toFormattedDate(),
      'dataVencimento': (l?.dataVencimento ?? DateTime.now()).toFormattedDate(),
    };
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
          primary: [_buildDadosDoLancamento()],
          secondary: [
          ],
          footer: FilledButton.icon(
            onPressed: () => _salvar(
              onSuccess: (_) {
                if (mounted) context.pop();
              },
            ),
            icon: const Icon(Icons.check),
            label: const Text('Salvar item'),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Seções
  // ---------------------------------------------------------------------------

  Widget _buildDadosDoLancamento() {
    return SectionCard(
      key: GlobalKey(),
      title: 'Dados do lançamento',
      child: Column(
        spacing: AppSpacing.sm,
        children: [
          const AppTextField(
            name: 'descricao',
            label: 'Descrição',
            icon: Icons.cake_outlined,
          ),
          FormBuilderDropdown<TipoLancamentoFinanceiro>(
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
                  (tipo) =>
                      DropdownMenuItem(value: tipo, child: Text(tipo.label)),
                )
                .toList(),
            onChanged: _alterarTipo,
          ),
          FormBuilderDropdown<StatusLancamentoFinanceiro>(
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
        ],
      ),
    );
  }

  /// Linha de campos lado a lado, com largura proporcional a [flex].
  Widget _linha(List<Widget> filhos, {List<int> flex = const []}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        for (var i = 0; i < filhos.length; i++)
          Expanded(flex: i < flex.length ? flex[i] : 1, child: filhos[i]),
      ],
    );
  }

  Widget _buildSwitch(
    String name,
    String titulo, {
    bool? initialValue,
    ValueChanged<bool?>? onChanged,
  }) {
    return FormBuilderSwitch(
      name: name,
      title: Text(titulo),
      initialValue: initialValue,
      onChanged: onChanged,
    );
  }

  /// Seção com botão "Adicionar item" (embalagem e ficha técnica).
  Widget _buildSecaoItens({
    required String titulo,
    required List<Produto> disponiveis,
    required VoidCallback onAdicionar,
    required VoidCallback onNovoItem,
    required Widget child,
  }) {
    return SectionCard(
      title: titulo,
      trailing: Wrap(
        children: [
          TextButton.icon(
            onPressed: onNovoItem,
            icon: const Icon(Icons.fiber_new_outlined),
            label: const Text('Novo item'),
          ),
          TextButton.icon(
            onPressed: disponiveis.isEmpty ? null : onAdicionar,
            icon: const Icon(Icons.add),
            label: const Text('Adicionar item'),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Lista de linhas de itens com mensagens de estado vazio.
  /// [buildLinha] pode devolver null para ignorar um item inválido.
  Widget _buildListaItens({
    required List<Produto> disponiveis,
    required int quantidade,
    required String mensagemSemProdutos,
    required String mensagemVazia,
    required Widget? Function(int index) buildLinha,
  }) {
    if (disponiveis.isEmpty) return Text(mensagemSemProdutos);
    if (quantidade == 0) return Text(mensagemVazia);

    final linhas = <Widget>[];
    for (var i = 0; i < quantidade; i++) {
      final linha = buildLinha(i);
      if (linha != null) linhas.add(linha);
    }
    return Column(spacing: AppSpacing.md, children: linhas);
  }

  Widget _buildLinhaCusto(String titulo, String explicacao, double valor) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      title: Row(
        children: [
          Expanded(child: Text(titulo, style: textTheme.bodyLarge)),
          Text(valor.toCurrency(), style: textTheme.bodyLarge),
        ],
      ),
      subtitle: Text(
        explicacao,
        style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildCampoValor(String name, String label) {
    return AppNumberField(
      name: name,
      label: label,
      required: false,
      min: 0,
      onChanged: (_) => _atualizarValores(),
    );
  }

  Widget _buildCampoDataCriacao() {
    return const AppDateTimeField(
      name: 'dataCriacao',
      label: 'Data de criação',
      inputType: InputType.date,
    );
  }

  Widget _buildCampoDataVencimento() {
    return const AppDateTimeField(
      name: 'dataVencimento',
      label: 'Data de vencimento',
      inputType: InputType.date,
    );
  }

  // ---------------------------------------------------------------------------
  // Preço de venda
  // ---------------------------------------------------------------------------

  List<AppDropdownGroup<String>> _gruposDeUnidades() {
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

  void _alterarTipo(TipoLancamentoFinanceiro? value) {}

  void _alterarStatus(StatusLancamentoFinanceiro? value) {}

  Widget? _buildLinhaIngrediente(int i) {
    final quitacao = _quitacoes[i];

    return QuitacaoRow(
      key: _chavesQuitacoes[i],
      quitacao: quitacao,
      onChanged: (novo) => _alterarItens(() => _quitacoes[i] = novo),
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
          valorQuitado: 0, id: '',
          formaPagamento: FormaPagamento.dinheiro,
          lancamentoId: _lancamentoOriginal!.id,
        ),
      );
      _chavesQuitacoes.insert(0, UniqueKey());
    });
  }

  /// Aplica a alteração nas listas de itens e recalcula os custos.
  void _alterarItens(VoidCallback alteracao) {
    alteracao();
    _atualizarValores();
  }

  // ---------------------------------------------------------------------------
  // Cálculo de custos
  // ---------------------------------------------------------------------------

  void _atualizarValores() {
  }

  double _lerNumero(String campo) {
    return _numero(_formKey.currentState?.fields[campo]?.value);
  }

  /// Converte o valor bruto de um campo (num ou texto pt-BR) em double.
  static double _numero(dynamic valor) {
    return switch (valor) {
      num n => n.toDouble(),
      String s => s.toDouble() ?? 0.0,
      _ => 0.0,
    };
  }

  // ---------------------------------------------------------------------------
  // Ações
  // ---------------------------------------------------------------------------
  void _imprimirLancamento() {
    // _salvar(onSuccess: LancamentoFinanceiroPdf);
  }

  Future<void> _salvar({required ValueChanged<LancamentoFinanceiro> onSuccess}) async {
    final form = _formKey.currentState;
    if (form == null || !form.saveAndValidate()) {
      _mostrarMensagem('Revise os campos obrigatórios do item.');
      return;
    }

    try {
      final lancamento = _montarLancamento(form.value);
      onSuccess(lancamento);
    } catch (error) {
      _mostrarMensagem('Não foi possível salvar o item: $error');
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
      valor: _numero(valores['valor']),
      tipoLancamento: valores['tipoLancamento'] as TipoLancamentoFinanceiro,
      observacao: valores['observacao']?.toString().trim() ?? '',
      quitacoes: _quitacoes,
      tipoPessoaFinanceiro: TipoPessoaFinanceiro.cliente,
      pessoaId: '',
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
      mensagem:
          'Deseja excluir "${lancamento.descricao}"? Essa ação não pode ser desfeita.',
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
