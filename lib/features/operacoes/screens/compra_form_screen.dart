import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_date_time_field.dart';
import '../../../core/widgets/app_input_decoration.dart';
import '../../../core/widgets/app_number_field.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/form_builder_searchable_dropdown_field.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/forma_pagamento.dart';
import '../../../shared/models/fornecedor.dart';
import '../../../shared/models/grupo_unidade.dart';
import '../../../shared/models/lancamento_financeiro.dart';
import '../../../shared/models/operacao.dart';
import '../../../shared/models/produto.dart';
import '../../../shared/models/produto_compra_rascunho.dart';
import '../pdf/compra_pdf.dart';
import '../widgets/produto_rascunho_sheet.dart';

class CompraFormScreen extends StatefulWidget {
  final String? compraId;

  const CompraFormScreen({super.key, this.compraId});

  @override
  State<CompraFormScreen> createState() => _CompraFormScreenState();
}

class _CompraFormScreenState extends State<CompraFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;
  final _itens = <int>[];
  final _modoUnitario = <int, bool>{};
  final _rascunhos = <String, ProdutoCompraRascunho>{};
  final _produtoPreSelecionado = <int, String>{};
  String? _fornecedorId;
  int _proximoId = 0;

  // Pagamento
  final _parcelas = <_ParcelaRascunho>[];
  int _proximaParcelaId = 0;
  bool _gerarFinanceiro = true;
  bool _financeiroBloqueado = false;
  bool _parcelasEditadas = false;
  FormaPagamento _forma = FormaPagamento.dinheiro;
  int _numParcelas = 1;
  PessoaFinanceiro? _cartaoSelecionado;
  String _assinaturaParcelas = '';
  List<LancamentoFinanceiro> _lancamentosExistentes = const [];

  Compra? get _compraOriginal {
    final id = widget.compraId;
    if (id == null) return null;
    for (final compra in _repo.compras) {
      if (compra.id == id) return compra;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final compra = _compraOriginal;
    _fornecedorId = compra?.fornecedorId;
    if (compra == null) {
      _itens.add(_proximoId++);
      _regenerarParcelas();
    } else {
      _carregarPagamentoExistente(compra);
      for (var index = 0; index < compra.itens.length; index++) {
        _itens.add(_proximoId);
        _modoUnitario[_proximoId] = true;
        _proximoId++;
      }
      // instantValue só fica disponível após o primeiro frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final compra = _compraOriginal;
    final produtos =
        _repo.produtos
            .where((produto) => produto.ativo && produto.podeSerComprado)
            .toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));
    if (compra == null && widget.compraId != null) {
      return const AppScaffold(
        title: 'Compra não encontrada',
        body: EmptyState(mensagem: 'A compra solicitada não existe.'),
      );
    }
    return AppScaffold(
      title: compra == null ? 'Nova compra' : 'Editar compra',
      actions: [
        if (compra != null) ...[
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Imprimir',
            onPressed: () => CompraPdf.imprimir(compra),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir compra',
            onPressed: () => _excluirCompra(compra),
          ),
        ],
        IconButton(
          icon: const Icon(Icons.straighten),
          tooltip: 'Unidades de medida',
          onPressed: _abrirUnidades,
        ),
      ],
      body: FormBuilder(
        key: _formKey,
        onChanged: () {
          _sincronizarParcelas();
          setState(() {});
        },
        initialValue: _valoresIniciais(compra),
        child: ResponsiveFormLayout(
          primaryFlex: 4,
          secondaryFlex: 7,
          primary: [
            SectionCard(
              title: 'Dados da compra',
              child: Column(
                children: [
                  const AppDateTimeField(name: 'data', label: 'Data'),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildFornecedorField()),
                      IconButton(
                        icon: const Icon(Icons.person_add_outlined),
                        tooltip: 'Cadastrar fornecedor',
                        onPressed: _criarFornecedor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _buildPagamento(),
          ],
          secondary: [
            SectionCard(
              title: 'Itens',
              trailing: IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Adicionar produto',
                onPressed: produtos.isEmpty ? null : _adicionarItem,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _novoProduto,
                      icon: const Icon(Icons.add_box_outlined),
                      label: const Text('Novo produto'),
                    ),
                  ),
                  for (final id in _itens) _buildItem(id, produtos),
                ],
              ),
            ),
          ],
          footer: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTotal(),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.check),
                label: Text(
                  compra == null ? 'Salvar compra' : 'Salvar alterações',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _valoresIniciais(Compra? compra) {
    final valores = <String, dynamic>{
      'data': compra?.data ?? DateTime.now(),
      'fornecedor': compra?.fornecedorId,
      'forma_pagamento': _forma,
      'parcelas': _numParcelas,
    };
    if (compra != null) {
      for (var index = 0; index < compra.itens.length; index++) {
        final id = index;
        final item = compra.itens[index];
        valores['produto_$id'] = item.produtoId;
        valores['quantidade_$id'] = _comoTexto(item.quantidade);
        valores['valor_unitario_$id'] = _comoTexto(item.valorUnitario);
        valores['unidade_$id'] = _unidadeInicial(item);
      }
    }
    return valores;
  }

  String? _unidadeInicial(ItemOperacao item) {
    final produto = _repo.produtoPorId(item.produtoId);
    if (produto == null) return null;
    final unidadeConsumo = _repo.unidadePorId(produto.unidadeConsumoId);
    final unidadeSelecionada = _repo.unidadePorId(item.unidadeId);
    return unidadeSelecionada.grupo == unidadeConsumo.grupo
        ? unidadeSelecionada.id
        : unidadeConsumo.id;
  }

  String _comoTexto(double valor) {
    final partes = valor.toStringAsFixed(8).split('.');
    final decimais = partes[1].replaceFirst(RegExp(r'0+$'), '');
    final inteiro = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return decimais.isEmpty ? inteiro : '$inteiro,$decimais';
  }

  Widget _buildFornecedorField() {
    final fornecedores = _repo.fornecedores.where((f) => f.ativo).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    return FormBuilderSearchableDropdownField<String>(
      name: 'fornecedor',
      label: 'Fornecedor',
      initialValue: _fornecedorId,
      items: fornecedores.map((fornecedor) => fornecedor.id).toList(),
      itemBuilder: (id) =>
          fornecedores.firstWhere((fornecedor) => fornecedor.id == id).nome,
      validator: FormBuilderValidators.required(
        errorText: 'Selecione o fornecedor',
      ),
      onChanged: (id) => _fornecedorId = id,
    );
  }

  Widget _buildItem(int id, List<Produto> produtos) {
    final valores =
        _formKey.currentState?.instantValue ?? const <String, dynamic>{};
    final produtoId = valores['produto_$id'] as String?;
    final produto = produtoId == null ? null : _produtoPorId(produtoId);
    final rascunho = produtoId == null ? null : _rascunhos[produtoId];
    final quantidade = _numero(valores['quantidade_$id']);
    final unitario = _modoUnitario[id] ?? true;
    final valorEditado = _numero(
      valores[unitario ? 'valor_unitario_$id' : 'valor_total_$id'],
    );
    final total = unitario ? valorEditado * quantidade : valorEditado;
    final valorUnitario = unitario
        ? valorEditado
        : (quantidade > 0 ? valorEditado / quantidade : 0.0);
    final unidades = produto == null ? <String>[] : _unidadesCompra(produto);
    final unidadeConsumo = produto == null
        ? null
        : _repo.unidadePorId(produto.unidadeConsumoId);
    final valorUnidadeSelecionada = valores['unidade_$id'] as String?;
    final unidadeSelecionada = unidades.contains(valorUnidadeSelecionada)
        ? valorUnidadeSelecionada
        : (unidades.contains(unidadeConsumo?.id)
              ? unidadeConsumo?.id
              : (unidades.isEmpty ? null : unidades.first));
    final saldo = produto == null
        ? null
        : '${produto.saldoEstoque.toDecimal()} ${_repo.unidadePorId(produto.unidadeEstoqueId).sigla}';

    return Padding(
      key: ValueKey(id),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: FormBuilderSearchableDropdownField<String>(
                  name: 'produto_$id',
                  label: 'Item',
                  initialValue: _produtoInicial(id),
                  items: [
                    ...produtos.map((produto) => produto.id),
                    ..._rascunhos.keys,
                  ],
                  itemBuilder: (pid) => _produtoPorId(pid)?.nome ?? '',
                  validator: FormBuilderValidators.required(
                    errorText: 'Selecione o produto',
                  ),
                  onChanged: (novoProdutoId) =>
                      _selecionarProduto(id, novoProdutoId),
                ),
              ),
              if (rascunho != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar novo produto',
                  onPressed: () => _editarRascunho(rascunho),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remover produto',
                onPressed: _itens.length == 1
                    ? null
                    : () => setState(() => _itens.remove(id)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AppNumberField(
                  name: 'quantidade_$id',
                  label: 'Quantidade',
                  min: 0.0001,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FormBuilderSearchableDropdownField<String>(
                  name: 'unidade_$id',
                  label: 'Unidade',
                  initialValue: unidadeSelecionada,
                  items: unidades,
                  itemBuilder: (unidadeId) =>
                      _repo.unidadePorId(unidadeId).nome,
                  validator: (value) =>
                      value == null ? 'Selecione a unidade' : null,
                ),
              ),
            ],
          ),
          if (produto != null && unidadeConsumo != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Unidades disponíveis do grupo ${unidadeConsumo.grupo.label.toLowerCase()}.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('Valor unitário')),
              ButtonSegment(value: false, label: Text('Valor total')),
            ],
            selected: {unitario},
            onSelectionChanged: (selecionados) {
              final novoModoUnitario = selecionados.first;
              final formulario = _formKey.currentState;
              final quantidade = _numero(
                formulario?.instantValue['quantidade_$id'],
              );
              final valorAtual = _numero(
                formulario?.instantValue[unitario
                    ? 'valor_unitario_$id'
                    : 'valor_total_$id'],
              );
              final novoValor =
                  (quantidade <= 0
                          ? 0
                          : novoModoUnitario
                          ? (valorAtual / quantidade * 100).truncate() / 100
                          : valorAtual * quantidade)
                      .toDouble();

              formulario
                  ?.fields[novoModoUnitario
                      ? 'valor_unitario_$id'
                      : 'valor_total_$id']
                  ?.didChange(_comoTexto(novoValor));
              setState(() => _modoUnitario[id] = novoModoUnitario);
            },
          ),
          const SizedBox(height: 8),
          Visibility(
            visible: unitario,
            maintainState: true,
            child: AppNumberField(
              name: 'valor_unitario_$id',
              label: 'Valor unitário',
              min: 0,
              required: unitario,
            ),
          ),
          Visibility(
            visible: !unitario,
            maintainState: true,
            child: AppNumberField(
              name: 'valor_total_$id',
              label: 'Valor total',
              min: 0,
              required: !unitario,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            unitario
                ? 'Valor total: ${total.toCurrency()}'
                : 'Valor unitário: ${valorUnitario.toCurrency()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (saldo != null) ...[
            const SizedBox(height: 4),
            Text(
              'Saldo atual: $saldo',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  String? _produtoInicial(int id) {
    final preSelecionado = _produtoPreSelecionado[id];
    if (preSelecionado != null) return preSelecionado;
    final compra = _compraOriginal;
    if (compra == null || id >= compra.itens.length) return null;
    return compra.itens[id].produtoId;
  }

  Produto? _produtoPorId(String id) {
    final rascunho = _rascunhos[id];
    if (rascunho != null) {
      return rascunho.paraProduto(unidadeEstoqueId: rascunho.unidadeConsumoId);
    }
    return _repo.produtoPorId(id);
  }

  Future<void> _novoProduto() async {
    final rascunho = await mostrarProdutoRascunhoSheet(context);
    if (rascunho == null || !mounted) return;
    _rascunhos[rascunho.id] = rascunho;
    final formulario = _formKey.currentState;
    final vazio = _itens.cast<int?>().firstWhere(
      (id) => formulario?.fields['produto_$id']?.value == null,
      orElse: () => null,
    );
    if (vazio != null) {
      setState(() {});
      formulario?.fields['produto_$vazio']?.didChange(rascunho.id);
    } else {
      final novoId = _proximoId++;
      setState(() {
        _produtoPreSelecionado[novoId] = rascunho.id;
        _itens.insert(0, novoId);
      });
    }
  }

  Future<void> _editarRascunho(ProdutoCompraRascunho rascunho) async {
    final editado = await mostrarProdutoRascunhoSheet(
      context,
      rascunho: rascunho,
    );
    if (editado == null || !mounted) return;
    setState(() => _rascunhos[editado.id] = editado);
    for (final id in _itens) {
      final campo = _formKey.currentState?.fields['produto_$id'];
      if (campo?.value == editado.id) _selecionarProduto(id, editado.id);
    }
  }

  Future<void> _abrirUnidades() async {
    await context.push('/unidades');
    if (mounted) setState(() {});
  }

  Future<void> _excluirCompra(Compra compra) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir compra?'),
        content: const Text(
          'A compra e seus lançamentos financeiros serão removidos e o estoque e o custo médio serão recalculados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted) return;
    try {
      await _repo.excluirCompra(compra.id);
      if (mounted) context.pop();
    } on SaldoEstoqueInsuficienteException catch (error) {
      _avisar(error.message);
    } on StateError catch (error) {
      _avisar(error.message);
    }
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  List<String> _unidadesCompra(Produto produto) {
    final unidadeConsumo = _repo.unidadePorId(produto.unidadeConsumoId);
    return _repo
        .unidadesDoGrupo(unidadeConsumo.grupo)
        .map((unidade) => unidade.id)
        .toList();
  }

  void _selecionarProduto(int id, String? produtoId) {
    if (produtoId == null) return;
    final produto = _produtoPorId(produtoId);
    if (produto == null) return;
    final unidades = _unidadesCompra(produto);
    final atual = _formKey.currentState?.fields['unidade_$id']?.value;
    if (!unidades.contains(atual)) {
      _formKey.currentState?.fields['unidade_$id']?.didChange(
        produto.unidadeConsumoId,
      );
    }
  }

  Widget _buildTotal() {
    final total = _totalCompra();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Total da compra',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          total.toCurrency(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  double _numero(dynamic valor) {
    if (valor is num) return valor.toDouble();
    if (valor is String) return valor.toDouble() ?? 0;
    return 0;
  }

  void _adicionarItem() {
    setState(() => _itens.insert(0, _proximoId++));
  }

  Future<void> _criarFornecedor() async {
    final nome = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Novo fornecedor'),
          content: SizedBox(
            width: 480,
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
    if (nome == null || nome.isEmpty) return;
    final fornecedor = Fornecedor(id: _repo.novoId(), nome: nome, ativo: true);
    await _repo.salvarFornecedor(fornecedor);
    _fornecedorId = fornecedor.id;
    if (mounted) {
      _formKey.currentState?.fields['fornecedor']?.didChange(fornecedor.id);
    }
  }

  // ---------------------------------------------------------------------------
  // Pagamento
  // ---------------------------------------------------------------------------

  void _carregarPagamentoExistente(Compra compra) {
    _lancamentosExistentes = _repo.lancamentosDaCompra(compra.id);
    _gerarFinanceiro = _lancamentosExistentes.isNotEmpty;
    if (!_gerarFinanceiro) return;

    _financeiroBloqueado = _lancamentosExistentes.any((l) => l.hasQuitacoes);
    final primeiro = _lancamentosExistentes.first;
    _forma =
        primeiro.formaPagamento ??
        (primeiro.isCartaoCredito
            ? FormaPagamento.cartaoCredito
            : FormaPagamento.dinheiro);
    if (primeiro.isCartaoCredito) _cartaoSelecionado = primeiro.pessoaFinanceiro;
    _numParcelas = _lancamentosExistentes.length;
    for (final lancamento in _lancamentosExistentes) {
      _parcelas.add(
        _ParcelaRascunho(
          id: _proximaParcelaId++,
          vencimento: lancamento.dataVencimento,
          valor: lancamento.valorLancamento,
        ),
      );
    }
    // Preserva o que já foi lançado até o usuário pedir para redistribuir.
    _parcelasEditadas = true;
  }

  Widget _buildPagamento() {
    final editandoComLancamentos =
        _compraOriginal != null && _lancamentosExistentes.isNotEmpty;
    return SectionCard(
      title: 'Pagamento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Lançar no financeiro'),
            subtitle: Text(
              editandoComLancamentos
                  ? 'Desativar remove os lançamentos desta compra.'
                  : 'Gera as contas a pagar desta compra.',
            ),
            value: _gerarFinanceiro,
            onChanged: _financeiroBloqueado
                ? null
                : (valor) => setState(() {
                    _gerarFinanceiro = valor;
                    if (valor) {
                      _parcelasEditadas = false;
                      _regenerarParcelas();
                    }
                  }),
          ),
          if (_gerarFinanceiro && _financeiroBloqueado)
            ..._buildResumoBloqueado()
          else if (_gerarFinanceiro)
            ..._buildCamposPagamento(),
        ],
      ),
    );
  }

  List<Widget> _buildResumoBloqueado() {
    final tema = Theme.of(context).textTheme;
    final total = _lancamentosExistentes.length;
    return [
      Text(
        'Já existem pagamentos registrados nestes lançamentos. Para alterá-los, '
        'use a tela do financeiro.',
        style: tema.bodySmall,
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < total; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${i + 1}/$total · vence em '
                  '${_lancamentosExistentes[i].dataVencimento.toFormattedDate()}'
                  ' · ${_lancamentosExistentes[i].statusLancamento.label}',
                ),
              ),
              Text(_lancamentosExistentes[i].valorLancamento.toCurrency()),
            ],
          ),
        ),
    ];
  }

  List<Widget> _buildCamposPagamento() {
    final tema = Theme.of(context);
    final cartoes = _repo.pessoasCartaoCredito;
    final maxParcelas = _numParcelas > 24 ? _numParcelas : 24;
    final somaCentavos = _parcelas.fold<int>(
      0,
      (soma, parcela) => soma + _centavos(_valorParcela(parcela)),
    );
    final diferenca = _centavos(_totalCompra()) - somaCentavos;

    return [
      FormBuilderDropdown<FormaPagamento>(
        name: 'forma_pagamento',
        decoration: AppInputDecoration.of(
          'Forma de pagamento',
          icon: Icons.payments_outlined,
        ),
        validator: FormBuilderValidators.required(
          errorText: 'Selecione a forma de pagamento',
        ),
        onChanged: (forma) =>
            setState(() => _forma = forma ?? FormaPagamento.dinheiro),
        items: [
          for (final forma in FormaPagamento.values)
            DropdownMenuItem(value: forma, child: Text(forma.label)),
        ],
      ),
      if (_forma == FormaPagamento.cartaoCredito) ...[
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormBuilderSearchableDropdownField<PessoaFinanceiro>(
                name: 'cartao_credito',
                label: 'Cartão de crédito',
                initialValue: _cartaoSelecionado,
                items: cartoes,
                itemBuilder: (cartao) => cartao.nome,
                validator: FormBuilderValidators.required(
                  errorText: 'Selecione o cartão',
                ),
                onChanged: (cartao) => _cartaoSelecionado = cartao,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_card_outlined),
              tooltip: 'Cadastrar cartão',
              onPressed: _criarCartao,
            ),
          ],
        ),
      ],
      const SizedBox(height: 12),
      FormBuilderDropdown<int>(
        name: 'parcelas',
        decoration: AppInputDecoration.of(
          'Parcelamento',
          icon: Icons.format_list_numbered,
        ),
        onChanged: (quantidade) => setState(() {
          _numParcelas = quantidade ?? 1;
          _parcelasEditadas = false;
          _regenerarParcelas();
        }),
        items: [
          for (var i = 1; i <= maxParcelas; i++)
            DropdownMenuItem(
              value: i,
              child: Text(i == 1 ? 'Parcela única' : '${i}x'),
            ),
        ],
      ),
      const SizedBox(height: 12),
      for (var i = 0; i < _parcelas.length; i++) _buildParcela(i),
      Text(
        'Soma das parcelas: ${(somaCentavos / 100).toCurrency()}',
        style: tema.textTheme.bodyMedium,
      ),
      if (diferenca != 0)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            diferenca > 0
                ? 'Faltam ${(diferenca / 100).toCurrency()} para chegar ao total da compra.'
                : 'As parcelas passam ${(-diferenca / 100).toCurrency()} do total da compra.',
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.error,
            ),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() {
            _parcelasEditadas = false;
            _regenerarParcelas();
          }),
          icon: const Icon(Icons.refresh),
          label: const Text('Redistribuir valores e datas'),
        ),
      ),
    ];
  }

  Widget _buildParcela(int indice) {
    final parcela = _parcelas[indice];
    return Padding(
      key: ValueKey('parcela_${parcela.id}'),
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: 40,
              child: Text(
                '${indice + 1}/${_parcelas.length}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: AppDateTimeField(
              name: 'parcela_venc_${parcela.id}',
              label: 'Vencimento',
              initialValue: parcela.vencimento,
              onChanged: (_) => _parcelasEditadas = true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppNumberField(
              name: 'parcela_valor_${parcela.id}',
              label: 'Valor',
              min: 0.01,
              initialValue: formatarParaCampo(parcela.valor),
              onChanged: (_) => _parcelasEditadas = true,
            ),
          ),
        ],
      ),
    );
  }

  /// Recalcula as parcelas a partir do total, da quantidade e da data da
  /// compra. A última parcela absorve a diferença de centavos.
  void _regenerarParcelas() {
    final quantidade = _numParcelas < 1 ? 1 : _numParcelas;
    final centavos = _centavos(_totalCompra());
    final base = centavos ~/ quantidade;
    final dataBase = _somenteData(_dataCompra());
    _parcelas
      ..clear()
      ..addAll([
        for (var i = 0; i < quantidade; i++)
          _ParcelaRascunho(
            id: _proximaParcelaId++,
            vencimento: _somarMeses(dataBase, i),
            valor:
                (i == quantidade - 1 ? centavos - base * (quantidade - 1) : base) /
                100,
          ),
      ]);
    _assinaturaParcelas = _assinaturaAtual();
  }

  /// Acompanha mudanças no total/data da compra e redistribui as parcelas,
  /// desde que o usuário não as tenha editado manualmente.
  void _sincronizarParcelas() {
    if (!_gerarFinanceiro || _financeiroBloqueado) return;
    final assinatura = _assinaturaAtual();
    if (assinatura == _assinaturaParcelas) return;
    if (_parcelasEditadas) {
      _assinaturaParcelas = assinatura;
      return;
    }
    _regenerarParcelas();
  }

  String _assinaturaAtual() =>
      '${_centavos(_totalCompra())}|${_somenteData(_dataCompra())}';

  double _totalCompra() {
    final formulario = _formKey.currentState;
    if (formulario == null) return _compraOriginal?.total ?? 0;
    final valores = formulario.instantValue;
    return _itens.fold<double>(0, (soma, id) {
      final quantidade = _numero(valores['quantidade_$id']);
      final unitario = _modoUnitario[id] ?? true;
      final valor = _numero(
        valores[unitario ? 'valor_unitario_$id' : 'valor_total_$id'],
      );
      return soma + (unitario ? quantidade * valor : valor);
    });
  }

  DateTime _dataCompra() {
    final valor = _formKey.currentState?.instantValue['data'];
    if (valor is DateTime) return valor;
    return _compraOriginal?.data ?? DateTime.now();
  }

  double _valorParcela(_ParcelaRascunho parcela) {
    final valores = _formKey.currentState?.instantValue;
    final campo = 'parcela_valor_${parcela.id}';
    if (valores == null || !valores.containsKey(campo)) return parcela.valor;
    return _numero(valores[campo]);
  }

  int _centavos(double valor) => (valor * 100).round();

  DateTime _somenteData(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  DateTime _somarMeses(DateTime base, int meses) {
    final indice = base.month - 1 + meses;
    final ano = base.year + indice ~/ 12;
    final mes = indice % 12 + 1;
    final ultimoDia = DateTime(ano, mes + 1, 0).day;
    return DateTime(ano, mes, base.day > ultimoDia ? ultimoDia : base.day);
  }

  Future<void> _criarCartao() async {
    final nome = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Novo cartão de crédito'),
          content: SizedBox(
            width: 480,
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome do cartão'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
    if (nome == null || nome.isEmpty) return;
    final cartao = _repo.salvarCartaoCredito(nome);
    _cartaoSelecionado = cartao;
    if (mounted) {
      setState(() {});
      _formKey.currentState?.fields['cartao_credito']?.didChange(cartao);
    }
  }

  /// Gera um lançamento por parcela. O primeiro é o "pai" dos demais.
  /// Retorna null (após avisar o usuário) se os dados forem inconsistentes.
  List<LancamentoFinanceiro>? _montarLancamentos({
    required String compraId,
    required DateTime data,
    required String fornecedorId,
    required Map<String, dynamic> valores,
    required double total,
  }) {
    final fornecedor = _repo.fornecedorPorId(fornecedorId);
    if (fornecedor == null) {
      _avisar('Fornecedor não encontrado.');
      return null;
    }

    final forma = valores['forma_pagamento'] as FormaPagamento;
    // Cartão de crédito: a pessoa é o cartão (paga-se a fatura). Nas demais
    // formas, a pessoa é o fornecedor da compra.
    final pessoa = forma == FormaPagamento.cartaoCredito
        ? valores['cartao_credito'] as PessoaFinanceiro
        : _repo.pessoaFinanceiraDoFornecedor(fornecedor);

    final parcelas = [
      for (final parcela in _parcelas)
        (
          vencimento: valores['parcela_venc_${parcela.id}'] as DateTime,
          valor: _centavos(_numero(valores['parcela_valor_${parcela.id}'])),
        ),
    ];
    if (parcelas.isEmpty || parcelas.any((parcela) => parcela.valor <= 0)) {
      _avisar('Informe um valor maior que zero em todas as parcelas.');
      return null;
    }
    final somaCentavos = parcelas.fold<int>(0, (soma, p) => soma + p.valor);
    if (somaCentavos != _centavos(total)) {
      _avisar(
        'A soma das parcelas (${(somaCentavos / 100).toCurrency()}) difere do '
        'total da compra (${total.toCurrency()}).',
      );
      return null;
    }

    final lancamentos = <LancamentoFinanceiro>[];
    LancamentoFinanceiro? pai;
    for (var i = 0; i < parcelas.length; i++) {
      final lancamento = LancamentoFinanceiro(
        id: _repo.novoId(),
        pessoaFinanceiro: pessoa,
        tipoLancamento: TipoLancamentoFinanceiro.despesa,
        lancamentoPai: pai,
        statusLancamento: StatusLancamentoFinanceiro.pendente,
        tipoOperacaoOriem: TipoOperacaoOrigem.compra,
        dataCriacao: data,
        dataVencimento: parcelas[i].vencimento,
        descricao: parcelas.length == 1
            ? 'Compra - ${fornecedor.nome}'
            : 'Compra - ${fornecedor.nome} (${i + 1}/${parcelas.length})',
        valorLancamento: parcelas[i].valor / 100,
        operacaoOrigemId: compraId,
        formaPagamento: forma,
        quitacoes: [],
      );
      pai ??= lancamento;
      lancamentos.add(lancamento);
    }
    return lancamentos;
  }

  Future<void> _salvar() async {
    if (_formKey.currentState?.saveAndValidate() != true) return;
    final valores = _formKey.currentState!.value;
    final itens = <ItemOperacao>[];
    for (final id in _itens) {
      final produtoId = valores['produto_$id'] as String;
      final quantidade = _numero(valores['quantidade_$id']);
      final unitario = _modoUnitario[id] ?? true;
      final informado = _numero(
        valores[unitario ? 'valor_unitario_$id' : 'valor_total_$id'],
      );
      final valorUnitario = unitario
          ? informado
          : (quantidade > 0 ? informado / quantidade : 0.0);
      itens.add(
        ItemOperacao(
          produtoId: produtoId,
          quantidade: quantidade,
          valorUnitario: valorUnitario,
          unidadeId: valores['unidade_$id'] as String,
        ),
      );
    }

    final compraOriginal = _compraOriginal;
    final compraId = compraOriginal?.id ?? _repo.novoId();
    final dataCompra = valores['data'] as DateTime;
    final fornecedorId = valores['fornecedor'] as String;
    final totalCompra = itens.fold<double>(
      0,
      (soma, item) => soma + item.quantidade * item.valorUnitario,
    );

    var lancamentos = <LancamentoFinanceiro>[];
    if (_gerarFinanceiro && !_financeiroBloqueado) {
      final montados = _montarLancamentos(
        compraId: compraId,
        data: dataCompra,
        fornecedorId: fornecedorId,
        valores: valores,
        total: totalCompra,
      );
      if (montados == null) return;
      lancamentos = montados;
    }

    final compra = Compra(
      id: compraId,
      data: dataCompra,
      fornecedorId: fornecedorId,
      itens: itens,
      lancamentosFinanceiros: lancamentos,
    );
    try {
      final novosProdutos = <String>[];
      final unidadePorRascunho = <String, String>{};
      for (final item in itens) {
        if (_rascunhos.containsKey(item.produtoId)) {
          unidadePorRascunho.putIfAbsent(item.produtoId, () => item.unidadeId);
        }
      }
      try {
        for (final entrada in unidadePorRascunho.entries) {
          await _repo.salvarProduto(
            _rascunhos[entrada.key]!.paraProduto(
              unidadeEstoqueId: entrada.value,
            ),
          );
          novosProdutos.add(entrada.key);
        }
        if (compraOriginal == null) {
          await _repo.salvarCompra(compra);
        } else {
          await _repo.atualizarCompra(
            compra,
            atualizarFinanceiro: !_financeiroBloqueado,
          );
        }
      } catch (_) {
        for (final produtoId in novosProdutos) {
          await _repo.excluirProduto(produtoId);
        }
        rethrow;
      }
      if (mounted) context.pop();
    } on SaldoEstoqueInsuficienteException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _ParcelaRascunho {
  final int id;
  final DateTime vencimento;
  final double valor;

  const _ParcelaRascunho({
    required this.id,
    required this.vencimento,
    required this.valor,
  });
}
