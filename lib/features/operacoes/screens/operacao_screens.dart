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
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/cliente.dart';
import '../../../shared/models/fornecedor.dart';
import '../../../shared/models/operacao.dart';
import '../../../shared/models/produto.dart';
import '../pdf/compra_pdf.dart';
import '../pdf/venda_pdf.dart';

class OperacaoTipo {
  final bool compra;
  const OperacaoTipo.compra() : compra = true;
  const OperacaoTipo.venda() : compra = false;
}

class OperacaoListScreen extends StatefulWidget {
  final OperacaoTipo tipo;
  const OperacaoListScreen({super.key, required this.tipo});

  @override
  State<OperacaoListScreen> createState() => _OperacaoListScreenState();
}

class _OperacaoListScreenState extends State<OperacaoListScreen> {
  String _busca = '';
  DateTime? _dataFiltro;

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    final titulo = widget.tipo.compra ? 'Compras' : 'Vendas';
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final operacoes = widget.tipo.compra
            ? repo.compras.where(_compraFiltrada).toList()
            : repo.vendas.where(_vendaFiltrada).toList();
        return AppScaffold(
          title: titulo,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(
              widget.tipo.compra ? '/compras/nova' : '/vendas/nova',
            ),
            icon: const Icon(Icons.add),
            label: Text(widget.tipo.compra ? 'Nova compra' : 'Nova venda'),
          ),
          body: Column(
            children: [
              _buildFiltros(context),
              Expanded(
                child: operacoes.isEmpty
                    ? EmptyState(
                        mensagem: 'Nenhum resultado encontrado.',
                        icon: widget.tipo.compra
                            ? Icons.shopping_cart_outlined
                            : Icons.point_of_sale_outlined,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: operacoes.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final data = widget.tipo.compra
                              ? (operacoes[index] as Compra).data
                              : (operacoes[index] as Venda).data;
                          final total = widget.tipo.compra
                              ? (operacoes[index] as Compra).total
                              : (operacoes[index] as Venda).total;
                          final parceiro = widget.tipo.compra
                              ? repo
                                        .fornecedorPorId(
                                          (operacoes[index] as Compra)
                                              .fornecedorId,
                                        )
                                        ?.nome ??
                                    'Fornecedor removido'
                              : repo
                                        .clientePorId(
                                          (operacoes[index] as Venda).clienteId,
                                        )
                                        ?.nome ??
                                    'Cliente removido';
                          return Card(
                            child: ListTile(
                              title: Text(parceiro),
                              subtitle: Text(
                                '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    total.toCurrency(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.print_outlined),
                                    tooltip: 'Imprimir',
                                    onPressed: () => widget.tipo.compra
                                        ? CompraPdf.imprimir(
                                            operacoes[index] as Compra,
                                          )
                                        : VendaPdf.imprimir(
                                            operacoes[index] as Venda,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFiltros(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                labelText: widget.tipo.compra
                    ? 'Buscar produto ou fornecedor'
                    : 'Buscar produto ou cliente',
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

  bool _dataCorresponde(DateTime data) =>
      _dataFiltro == null ||
      (data.year == _dataFiltro!.year &&
          data.month == _dataFiltro!.month &&
          data.day == _dataFiltro!.day);

  bool _textoCorresponde(Iterable<String> valores) {
    final busca = _busca.trim().toLowerCase();
    return busca.isEmpty ||
        valores.any((valor) => valor.toLowerCase().contains(busca));
  }

  bool _compraFiltrada(Compra compra) {
    final fornecedor =
        AppRepository.instance.fornecedorPorId(compra.fornecedorId)?.nome ?? '';
    final produtos = compra.itens.map(
      (item) => AppRepository.instance.produtoPorId(item.produtoId)?.nome ?? '',
    );
    return _dataCorresponde(compra.data) &&
        _textoCorresponde([fornecedor, ...produtos]);
  }

  bool _vendaFiltrada(Venda venda) {
    final cliente =
        AppRepository.instance.clientePorId(venda.clienteId)?.nome ?? '';
    final produtos = venda.itens.map(
      (item) => AppRepository.instance.produtoPorId(item.produtoId)?.nome ?? '',
    );
    return _dataCorresponde(venda.data) &&
        _textoCorresponde([cliente, ...produtos]);
  }
}

class OperacaoFormScreen extends StatefulWidget {
  final OperacaoTipo tipo;
  const OperacaoFormScreen({super.key, required this.tipo});

  @override
  State<OperacaoFormScreen> createState() => _OperacaoFormScreenState();
}

class _OperacaoFormScreenState extends State<OperacaoFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;
  final _itens = <int>[0];
  int _proximoId = 1;
  String? _parceiroId;

  bool get _compra => widget.tipo.compra;

  @override
  Widget build(BuildContext context) {
    final produtos =
        _repo.produtos
            .where(
              (p) =>
                  p.ativo && (_compra ? p.podeSerComprado : p.podeSerVendido),
            )
            .toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));
    final resumo = _calcularResumo();
    return AppScaffold(
      title: _compra ? 'Nova compra' : 'Nova venda',
      body: FormBuilder(
        key: _formKey,
        onChanged: () => setState(() {}),
        initialValue: {'data': DateTime.now()},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            SectionCard(
              title: 'Dados da operação',
              child: Column(
                children: [
                  const AppDateTimeField(name: 'data', label: 'Data'),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildParceiroField()),
                      IconButton(
                        icon: const Icon(Icons.person_add_outlined),
                        tooltip: 'Cadastrar novo',
                        onPressed: _criarParceiro,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Produtos',
              trailing: IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'Adicionar produto',
                onPressed: produtos.isEmpty ? null : _adicionarItem,
              ),
              child: Column(
                children: [for (final id in _itens) _buildItem(id, produtos)],
              ),
            ),
            const SizedBox(height: 12),
            _buildResumo(resumo),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.check),
              label: Text(_compra ? 'Salvar compra' : 'Salvar venda'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParceiroField() {
    if (_compra) {
      final fornecedores = _repo.fornecedores.where((f) => f.ativo).toList()
        ..sort((a, b) => a.nome.compareTo(b.nome));
      return FormBuilderSearchableDropdownField<String>(
        name: 'parceiro',
        label: 'Fornecedor',
        items: fornecedores.map((f) => f.id).toList(),
        itemBuilder: (id) => fornecedores.firstWhere((f) => f.id == id).nome,
        validator: FormBuilderValidators.required(
          errorText: 'Selecione o fornecedor',
        ),
        onChanged: (value) => _parceiroId = value,
      );
    }
    final clientes = _repo.clientes.where((c) => c.ativo).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    return FormBuilderSearchableDropdownField<String>(
      name: 'parceiro',
      label: 'Cliente',
      items: clientes.map((c) => c.id).toList(),
      itemBuilder: (id) => clientes.firstWhere((c) => c.id == id).nome,
      validator: FormBuilderValidators.required(
        errorText: 'Selecione o cliente',
      ),
      onChanged: (value) => _parceiroId = value,
    );
  }

  Widget _buildItem(int id, List<Produto> produtos) {
    final valores =
        _formKey.currentState?.instantValue ?? const <String, dynamic>{};
    final produtoId = valores['produto_$id'] as String?;
    final produto = produtoId == null ? null : _repo.produtoPorId(produtoId);
    final unidade = produto == null
        ? null
        : _repo.unidadePorId(
            _compra
                ? produto.unidadeEstoqueId
                : (produto.unidadeConsumoId ?? produto.unidadeEstoqueId),
          );
    final quantidade = (valores['quantidade_$id'] as double?) ?? 0;
    final valorUnitario = (valores['valor_$id'] as double?) ?? 0;

    String? infoLinha;
    if (_compra && produto != null) {
      final unidadeEstoque = _repo.unidadePorId(produto.unidadeEstoqueId);
      infoLinha =
          'Saldo atual: ${produto.saldoEstoque.toDecimal()} ${unidadeEstoque.sigla}';
    } else if (!_compra && produto != null && unidade != null) {
      final custoUnitario =
          _repo.custoPorUnidadeBase(produto) * unidade.fatorParaBase;
      final custoLinha = custoUnitario * quantidade;
      final lucroLinha = (valorUnitario - custoUnitario) * quantidade;
      infoLinha =
          'Custo: ${custoLinha.toCurrency()}  •  Lucro/Prejuízo: ${lucroLinha.toCurrency()}';
    }

    return Padding(
      key: ValueKey(id),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FormBuilderSearchableDropdownField<String>(
                  name: 'produto_$id',
                  label: 'Produto',
                  items: produtos.map((p) => p.id).toList(),
                  itemBuilder: (pid) =>
                      produtos.firstWhere((p) => p.id == pid).nome,
                  validator: FormBuilderValidators.required(
                    errorText: 'Selecione o produto',
                  ),
                ),
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
                child: AppNumberField(
                  name: 'valor_$id',
                  label: _compra ? 'Custo unitário' : 'Preço unitário',
                  min: 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputDecorator(
                  decoration: AppInputDecoration.of('Unidade'),
                  child: Text(unidade?.sigla ?? '-'),
                ),
              ),
            ],
          ),
          if (infoLinha != null) ...[
            const SizedBox(height: 4),
            Text(infoLinha, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildResumo(_ResumoOperacao resumo) {
    if (_compra) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            resumo.total.toCurrency(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _linhaResumo('Total venda', resumo.total, bold: true),
        _linhaResumo('Total custo', resumo.totalCusto),
        _linhaResumo('Lucro/Prejuízo', resumo.lucro, bold: true),
      ],
    );
  }

  Widget _linhaResumo(String label, double valor, {bool bold = false}) {
    final estilo = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: estilo),
          Text(valor.toCurrency(), style: estilo),
        ],
      ),
    );
  }

  _ResumoOperacao _calcularResumo() {
    final valores =
        _formKey.currentState?.instantValue ?? const <String, dynamic>{};
    var total = 0.0;
    var totalCusto = 0.0;
    for (final id in _itens) {
      final produtoId = valores['produto_$id'] as String?;
      final quantidade = (valores['quantidade_$id'] as double?) ?? 0;
      final valorUnitario = (valores['valor_$id'] as double?) ?? 0;
      total += quantidade * valorUnitario;
      if (!_compra && produtoId != null) {
        final produto = _repo.produtoPorId(produtoId);
        if (produto != null) {
          final unidade = _repo.unidadePorId(
            produto.unidadeConsumoId ?? produto.unidadeEstoqueId,
          );
          totalCusto +=
              _repo.custoPorUnidadeBase(produto) *
              unidade.fatorParaBase *
              quantidade;
        }
      }
    }
    return _ResumoOperacao(total: total, totalCusto: totalCusto);
  }

  void _adicionarItem() {
    setState(() => _itens.insert(0, _proximoId++));
  }

  Future<void> _criarParceiro() async {
    final nome = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(_compra ? 'Novo fornecedor' : 'Novo cliente'),
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
    if (_compra) {
      final fornecedor = Fornecedor(
        id: _repo.novoId(),
        nome: nome,
        ativo: true,
      );
      await _repo.salvarFornecedor(fornecedor);
      _parceiroId = fornecedor.id;
    } else {
      final cliente = Cliente(id: _repo.novoId(), nome: nome, ativo: true);
      await _repo.salvarCliente(cliente);
      _parceiroId = cliente.id;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _formKey.currentState?.patchValue({'parceiro': _parceiroId});
      }
    });
  }

  Future<void> _salvar() async {
    if (_formKey.currentState?.saveAndValidate() != true) return;
    final valores = _formKey.currentState!.value;
    final itens = _itens.map((id) {
      final produtoId = valores['produto_$id'] as String;
      final produto = _repo.produtoPorId(produtoId);
      final unidadeId = produto == null
          ? ''
          : (_compra
                ? produto.unidadeEstoqueId
                : (produto.unidadeConsumoId ?? produto.unidadeEstoqueId));
      return ItemOperacao(
        produtoId: produtoId,
        quantidade: valores['quantidade_$id'] as double,
        valorUnitario: valores['valor_$id'] as double,
        unidadeId: unidadeId,
      );
    }).toList();
    final data = valores['data'] as DateTime;
    if (_compra) {
      await _repo.salvarCompra(
        Compra(
          id: _repo.novoId(),
          data: data,
          fornecedorId: valores['parceiro'] as String,
          itens: itens,
        ),
      );
    } else {
      await _repo.salvarVenda(
        Venda(
          id: _repo.novoId(),
          data: data,
          clienteId: valores['parceiro'] as String,
          itens: itens,
        ),
      );
    }
    if (mounted) {
      context.pop();
    }
  }
}

class _ResumoOperacao {
  final double total;
  final double totalCusto;

  const _ResumoOperacao({required this.total, required this.totalCusto});

  double get lucro => total - totalCusto;
}
