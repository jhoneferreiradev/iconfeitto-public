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
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/cliente.dart';
import '../../../shared/models/operacao.dart';
import '../../../shared/models/produto.dart';
import '../pdf/venda_pdf.dart';

class VendaListScreen extends StatefulWidget {
  const VendaListScreen({super.key});

  @override
  State<VendaListScreen> createState() => _VendaListScreenState();
}

class _VendaListScreenState extends State<VendaListScreen> {
  String _busca = '';
  DateTime? _dataFiltro;

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final vendas = repo.vendas.where(_vendaFiltrada).toList()
          ..sort((a, b) => b.data.compareTo(a.data));
        return AppScaffold(
          title: 'Vendas',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/vendas/nova'),
            icon: const Icon(Icons.add),
            label: const Text('Nova venda'),
          ),
          body: Column(
            children: [
              _buildFiltros(context),
              Expanded(
                child: vendas.isEmpty
                    ? const EmptyState(
                        mensagem: 'Nenhum resultado encontrado.',
                        icon: Icons.point_of_sale_outlined,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                        itemCount: vendas.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final venda = vendas[index];
                          final cliente =
                              repo.clientePorId(venda.clienteId)?.nome ??
                              'Cliente removido';
                          return Card(
                            child: ListTile(
                              title: Text(cliente),
                              subtitle: Text(_formatarData(venda.data)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    venda.total.toCurrency(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.print_outlined),
                                    tooltip: 'Imprimir',
                                    onPressed: () => VendaPdf.imprimir(venda),
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
                labelText: 'Buscar produto ou cliente',
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

  bool _vendaFiltrada(Venda venda) {
    if (_dataFiltro != null &&
        (venda.data.year != _dataFiltro!.year ||
            venda.data.month != _dataFiltro!.month ||
            venda.data.day != _dataFiltro!.day)) {
      return false;
    }
    final busca = _busca.trim().toLowerCase();
    if (busca.isEmpty) return true;
    final repo = AppRepository.instance;
    final cliente = repo.clientePorId(venda.clienteId)?.nome.toLowerCase() ?? '';
    return cliente.contains(busca) ||
        venda.itens.any((item) {
          final nome = repo.produtoPorId(item.produtoId)?.nome.toLowerCase() ?? '';
          return nome.contains(busca);
        });
  }
}

class VendaFormScreen extends StatefulWidget {
  const VendaFormScreen({super.key});

  @override
  State<VendaFormScreen> createState() => _VendaFormScreenState();
}

class _VendaFormScreenState extends State<VendaFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;
  final _itens = <int>[0];
  int _proximoId = 1;
  String? _clienteId;

  @override
  Widget build(BuildContext context) {
    final produtos = _repo.produtos
        .where((produto) => produto.ativo && produto.podeSerVendido)
        .toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    final resumo = _calcularResumo();
    return AppScaffold(
      title: 'Nova venda',
      body: FormBuilder(
        key: _formKey,
        onChanged: () => setState(() {}),
        initialValue: {'data': DateTime.now()},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            SectionCard(
              title: 'Dados da venda',
              child: Column(
                children: [
                  const AppDateTimeField(name: 'data', label: 'Data'),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildClienteField()),
                      IconButton(
                        icon: const Icon(Icons.person_add_outlined),
                        tooltip: 'Cadastrar cliente',
                        onPressed: _criarCliente,
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
              label: const Text('Salvar venda'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClienteField() {
    final clientes = _repo.clientes.where((cliente) => cliente.ativo).toList()
      ..sort((a, b) => a.nome.compareTo(b.nome));
    return FormBuilderSearchableDropdownField<String>(
      name: 'cliente',
      label: 'Cliente',
      initialValue: _clienteId,
      items: clientes.map((cliente) => cliente.id).toList(),
      itemBuilder: (id) =>
          clientes.firstWhere((cliente) => cliente.id == id).nome,
      validator: FormBuilderValidators.required(
        errorText: 'Selecione o cliente',
      ),
      onChanged: (id) => _clienteId = id,
    );
  }

  Widget _buildItem(int id, List<Produto> produtos) {
    final valores =
        _formKey.currentState?.instantValue ?? const <String, dynamic>{};
    final produtoId = valores['produto_$id'] as String?;
    final produto = produtoId == null ? null : _repo.produtoPorId(produtoId);
    final quantidade = _numero(valores['quantidade_$id']);
    final precoUnitario = _numero(valores['preco_$id']);
    final unidade = produto == null
        ? null
        : _repo.unidadePorId(produto.unidadeConsumoId);
    String? resumoCusto;
    if (produto != null && unidade != null) {
      final custoUnitario =
          _repo.custoPorUnidadeBase(produto) * unidade.fatorParaBase;
      resumoCusto =
          'Custo: ${(custoUnitario * quantidade).toCurrency()}  •  '
          'Lucro/Prejuízo: ${((precoUnitario - custoUnitario) * quantidade).toCurrency()}';
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
                  items: produtos.map((produto) => produto.id).toList(),
                  itemBuilder: (pid) =>
                      produtos.firstWhere((produto) => produto.id == pid).nome,
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
                  name: 'preco_$id',
                  label: 'Preço unitário',
                  min: 0,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Unidade'),
                  child: Text(unidade?.sigla ?? '-'),
                ),
              ),
            ],
          ),
          if (resumoCusto != null) ...[
            const SizedBox(height: 4),
            Text(resumoCusto, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }

  Widget _buildResumo(_ResumoVenda resumo) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _linhaResumo('Total venda', resumo.total, bold: true),
      _linhaResumo('Total custo', resumo.totalCusto),
      _linhaResumo('Lucro/Prejuízo', resumo.total - resumo.totalCusto, bold: true),
    ],
  );

  Widget _linhaResumo(String label, double valor, {bool bold = false}) {
    final estilo = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: estilo), Text(valor.toCurrency(), style: estilo)],
      ),
    );
  }

  _ResumoVenda _calcularResumo() {
    final valores =
        _formKey.currentState?.instantValue ?? const <String, dynamic>{};
    var total = 0.0;
    var totalCusto = 0.0;
    for (final id in _itens) {
      final produtoId = valores['produto_$id'] as String?;
      final quantidade = _numero(valores['quantidade_$id']);
      final preco = _numero(valores['preco_$id']);
      total += quantidade * preco;
      final produto = produtoId == null ? null : _repo.produtoPorId(produtoId);
      if (produto != null) {
        final unidade = _repo.unidadePorId(produto.unidadeConsumoId);
        totalCusto +=
            _repo.custoPorUnidadeBase(produto) *
            unidade.fatorParaBase *
            quantidade;
      }
    }
    return _ResumoVenda(total: total, totalCusto: totalCusto);
  }

  double _numero(dynamic valor) {
    if (valor is num) return valor.toDouble();
    if (valor is String) return valor.toDouble() ?? 0;
    return 0;
  }

  void _adicionarItem() {
    setState(() => _itens.add(_proximoId++));
  }

  Future<void> _criarCliente() async {
    final nome = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Novo cliente'),
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
    final cliente = Cliente(id: _repo.novoId(), nome: nome, ativo: true);
    await _repo.salvarCliente(cliente);
    _clienteId = cliente.id;
    if (mounted) _formKey.currentState?.fields['cliente']?.didChange(cliente.id);
  }

  Future<void> _salvar() async {
    if (_formKey.currentState?.saveAndValidate() != true) return;
    final valores = _formKey.currentState!.value;
    final itens = _itens.map((id) {
      final produtoId = valores['produto_$id'] as String;
      final produto = _repo.produtoPorId(produtoId)!;
      return ItemOperacao(
        produtoId: produtoId,
        quantidade: _numero(valores['quantidade_$id']),
        valorUnitario: _numero(valores['preco_$id']),
        unidadeId: produto.unidadeConsumoId,
      );
    }).toList();
    await _repo.salvarVenda(
      Venda(
        id: _repo.novoId(),
        data: valores['data'] as DateTime,
        clienteId: valores['cliente'] as String,
        itens: itens,
      ),
    );
    if (mounted) context.pop();
  }
}

class _ResumoVenda {
  final double total;
  final double totalCusto;

  const _ResumoVenda({required this.total, required this.totalCusto});
}

String _formatarData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
