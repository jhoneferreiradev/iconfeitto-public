import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_date_time_field.dart';
import '../../../core/widgets/app_number_field.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/form_builder_searchable_dropdown_field.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/fornecedor.dart';
import '../../../shared/models/grupo_unidade.dart';
import '../../../shared/models/operacao.dart';
import '../../../shared/models/produto.dart';
import '../../../shared/models/produto_compra_rascunho.dart';
import '../pdf/compra_pdf.dart';
import '../widgets/produto_rascunho_sheet.dart';

String _formatarDataCompra(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

class CompraListScreen extends StatefulWidget {
  const CompraListScreen({super.key});

  @override
  State<CompraListScreen> createState() => _CompraListScreenState();
}

class _CompraListScreenState extends State<CompraListScreen> {
  String _busca = '';
  DateTime? _dataFiltro;

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final compras = repo.compras.where(_compraFiltrada).toList()
          ..sort((a, b) => b.data.compareTo(a.data));
        return AppScaffold(
          title: 'Compras',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/compras/nova'),
            icon: const Icon(Icons.add),
            label: const Text('Nova compra'),
          ),
          body: Column(
            children: [
              _buildFiltros(context),
              Expanded(
                child: compras.isEmpty
                    ? const EmptyState(
                        mensagem: 'Nenhum resultado encontrado.',
                        icon: Icons.shopping_cart_outlined,
                      )
                    : SingleChildScrollView(
                        child: ContentWidth(
                          child: ResponsiveCardGrid(
                            children: [
                              for (final compra in compras)
                                _buildCardCompra(context, repo, compra),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardCompra(
    BuildContext context,
    AppRepository repo,
    Compra compra,
  ) {
    final fornecedor =
        repo.fornecedorPorId(compra.fornecedorId)?.nome ??
        'Fornecedor removido';
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(fornecedor),
        subtitle: Text(_formatarDataCompra(compra.data)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              compra.total.toCurrency(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Imprimir',
              onPressed: () => CompraPdf.imprimir(compra),
            ),
            PopupMenuButton<String>(
              tooltip: 'Ações da compra',
              onSelected: (acao) {
                if (acao == 'editar') {
                  context.push('/compras/${compra.id}/editar');
                } else {
                  _confirmarExclusao(compra);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(value: 'excluir', child: Text('Excluir')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros(BuildContext context) {
    return ContentWidth(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar produto ou fornecedor',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busca.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _busca = ''),
                      ),
              ),
              onChanged: (value) => setState(() => _busca = value),
            ),
          ),
          IconButton(
            icon: Icon(
              _dataFiltro == null
                  ? Icons.event_outlined
                  : Icons.event_available,
            ),
            tooltip: 'Filtrar por data',
            onPressed: () async {
              final data = await showDatePicker(
                context: context,
                initialDate: _dataFiltro ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (data != null) setState(() => _dataFiltro = data);
            },
          ),
          if (_dataFiltro != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Limpar data',
              onPressed: () => setState(() => _dataFiltro = null),
            ),
        ],
      ),
    );
  }

  bool _compraFiltrada(Compra compra) {
    if (_dataFiltro != null &&
        (compra.data.year != _dataFiltro!.year ||
            compra.data.month != _dataFiltro!.month ||
            compra.data.day != _dataFiltro!.day)) {
      return false;
    }
    final busca = _busca.trim().toLowerCase();
    if (busca.isEmpty) return true;
    final repo = AppRepository.instance;
    final fornecedor =
        repo.fornecedorPorId(compra.fornecedorId)?.nome.toLowerCase() ?? '';
    return fornecedor.contains(busca) ||
        compra.itens.any((item) {
          final nome =
              repo.produtoPorId(item.produtoId)?.nome.toLowerCase() ?? '';
          return nome.contains(busca);
        });
  }

  Future<void> _confirmarExclusao(Compra compra) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir compra?'),
        content: const Text(
          'A compra será removida e o estoque e o custo médio serão recalculados.',
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
      await AppRepository.instance.excluirCompra(compra.id);
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
    } else {
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
        onChanged: () => setState(() {}),
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
          'A compra será removida e o estoque e o custo médio serão recalculados.',
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
    final valores =
        _formKey.currentState?.instantValue ?? const <String, dynamic>{};
    final total = _itens.fold<double>(0, (soma, id) {
      final quantidade = _numero(valores['quantidade_$id']);
      final unitario = _modoUnitario[id] ?? true;
      final valor = _numero(
        valores[unitario ? 'valor_unitario_$id' : 'valor_total_$id'],
      );
      return soma + (unitario ? quantidade * valor : valor);
    });
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
    final compra = Compra(
      id: compraOriginal?.id ?? _repo.novoId(),
      data: valores['data'] as DateTime,
      fornecedorId: valores['fornecedor'] as String,
      itens: itens,
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
          await _repo.atualizarCompra(compra);
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
