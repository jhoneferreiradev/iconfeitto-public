import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_date_time_field.dart';
import '../../../core/widgets/app_number_field.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/form_builder_searchable_dropdown_field.dart';
import '../../../core/widgets/section_card.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/cliente.dart';
import '../../../shared/models/lancamento_financeiro.dart';
import '../../../shared/models/operacao.dart';
import '../../../shared/models/produto.dart';
import '../pdf/venda_pdf.dart';
import '../widgets/pagamento_operacao_section.dart';
import 'venda_list_screen.dart';

class VendaFormScreen extends StatefulWidget {
  final String? vendaId;

  const VendaFormScreen({super.key, this.vendaId});

  @override
  State<VendaFormScreen> createState() => _VendaFormScreenState();
}

class _VendaFormScreenState extends State<VendaFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final _repo = AppRepository.instance;
  final _itens = <int>[];
  int _proximoId = 0;
  String? _clienteId;

  // Recebimento
  final _pagamentoKey = GlobalKey<PagamentoOperacaoSectionState>();
  bool _financeiroBloqueado = false;
  List<LancamentoFinanceiro> _lancamentosExistentes = const [];

  Venda? get _vendaOriginal {
    final id = widget.vendaId;
    if (id == null) return null;
    for (final venda in _repo.vendas) {
      if (venda.id == id) return venda;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final venda = _vendaOriginal;
    _clienteId = venda?.clienteId;
    if (venda == null) {
      _itens.add(_proximoId++);
    } else {
      _lancamentosExistentes = _repo.lancamentosDaVenda(venda.id);
      _financeiroBloqueado = _lancamentosExistentes.any((l) => l.hasQuitacoes);
      for (var i = 0; i < venda.itens.length; i++) {
        _itens.add(_proximoId++);
      }
      // instantValue só fica disponível após o primeiro frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Map<String, dynamic> _valoresIniciais(Venda? venda) {
    final valores = <String, dynamic>{
      'data': venda?.data ?? DateTime.now(),
      'cliente': venda?.clienteId,
    };
    if (venda != null) {
      for (var i = 0; i < venda.itens.length; i++) {
        final item = venda.itens[i];
        valores['produto_$i'] = item.produtoId;
        valores['quantidade_$i'] = formatarParaCampo(item.quantidade);
        valores['preco_$i'] = formatarParaCampo(item.valorUnitario);
      }
    }
    return valores;
  }

  String? _produtoInicial(int id) {
    final venda = _vendaOriginal;
    if (venda == null || id >= venda.itens.length) return null;
    return venda.itens[id].produtoId;
  }

  /// Preenche o preço unitário com o preço de venda cadastrado no produto.
  void _selecionarProduto(int id, String? produtoId) {
    if (produtoId == null) return;
    final produto = _repo.produtoPorId(produtoId);
    if (produto == null || produto.precoVenda <= 0) return;
    _formKey.currentState?.fields['preco_$id']?.didChange(
      formatarParaCampo(produto.precoVenda),
    );
  }

  @override
  Widget build(BuildContext context) {
    final venda = _vendaOriginal;
    if (venda == null && widget.vendaId != null) {
      return const AppScaffold(
        title: 'Venda não encontrada',
        body: EmptyState(mensagem: 'A venda solicitada não existe.'),
      );
    }
    final idsDaVenda = {for (final item in venda?.itens ?? []) item.produtoId};
    final produtos =
        _repo.produtos
            .where(
              (produto) =>
                  idsDaVenda.contains(produto.id) ||
                  (produto.ativo && produto.podeSerVendido),
            )
            .toList()
          ..sort((a, b) => a.nome.compareTo(b.nome));
    final resumo = _calcularResumo();
    return AppScaffold(
      title: venda == null ? 'Nova venda' : 'Editar venda',
      actions: [
        if (venda != null) ...[
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Imprimir',
            onPressed: () => VendaPdf.imprimir(venda),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir venda',
            onPressed: () async {
              final excluida = await confirmarExclusaoVenda(context, venda);
              if (excluida && context.mounted) context.pop();
            },
          ),
        ],
      ],
      body: FormBuilder(
        key: _formKey,
        onChanged: () {
          _pagamentoKey.currentState?.sincronizar();
          setState(() {});
        },
        initialValue: _valoresIniciais(venda),
        child: CenteredListView(
          children: [
            if (_financeiroBloqueado) _buildAvisoBloqueio(),
            ..._protegerTodos([
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
              PagamentoOperacaoSection(
                key: _pagamentoKey,
                formKey: _formKey,
                tipo: TipoLancamentoFinanceiro.receita,
                origem: TipoOperacaoOrigem.venda,
                total: _totalVenda,
                data: _dataVenda,
                existentes: _lancamentosExistentes,
                bloqueado: _financeiroBloqueado,
                editando: venda != null,
              ),
            ]),
            _buildResumo(resumo),
            if (!_financeiroBloqueado) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.check),
                label: const Text('Salvar venda'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static const _mensagemVendaBloqueada =
      'Esta venda possui pagamentos (quitações) nos lançamentos financeiros '
      'e não pode ser editada. Para alterá-la, remova as quitações no '
      'financeiro.';

  /// Com quitação em algum lançamento, a venda inteira fica somente leitura.
  List<Widget> _protegerTodos(List<Widget> widgets) => [
    for (final widget in widgets)
      IgnorePointer(
        ignoring: _financeiroBloqueado,
        child: Opacity(
          opacity: _financeiroBloqueado ? 0.65 : 1,
          child: widget,
        ),
      ),
  ];

  Widget _buildAvisoBloqueio() {
    final cores = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: cores.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: cores.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _mensagemVendaBloqueada,
                style: TextStyle(color: cores.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _totalVenda() => _formKey.currentState == null
      ? (_vendaOriginal?.total ?? 0)
      : _calcularResumo().total;

  DateTime _dataVenda() {
    final valor = _formKey.currentState?.instantValue['data'];
    if (valor is DateTime) return valor;
    return _vendaOriginal?.data ?? DateTime.now();
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
                  initialValue: _produtoInicial(id),
                  items: produtos.map((produto) => produto.id).toList(),
                  itemBuilder: (pid) =>
                      produtos.firstWhere((produto) => produto.id == pid).nome,
                  validator: FormBuilderValidators.required(
                    errorText: 'Selecione o produto',
                  ),
                  onChanged: (pid) => _selecionarProduto(id, pid),
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
      _linhaResumo(
        'Lucro/Prejuízo',
        resumo.total - resumo.totalCusto,
        bold: true,
      ),
    ],
  );

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
    if (mounted)
      _formKey.currentState?.fields['cliente']?.didChange(cliente.id);
  }

  Future<void> _salvar() async {
    if (_financeiroBloqueado) {
      _avisar(_mensagemVendaBloqueada);
      return;
    }
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
    final vendaOriginal = _vendaOriginal;
    final vendaId = vendaOriginal?.id ?? _repo.novoId();
    final dataVenda = valores['data'] as DateTime;
    final clienteId = valores['cliente'] as String;
    final totalVenda = itens.fold<double>(
      0,
      (soma, item) => soma + item.quantidade * item.valorUnitario,
    );

    var lancamentos = <LancamentoFinanceiro>[];
    final pagamento = _pagamentoKey.currentState;
    if (pagamento != null && pagamento.gerarFinanceiro) {
      final cliente = _repo.clientePorId(clienteId);
      if (cliente == null) {
        _avisar('Cliente não encontrado.');
        return;
      }
      final montados = pagamento.montarLancamentos(
        operacaoId: vendaId,
        data: dataVenda,
        pessoaOperacao: _repo.pessoaFinanceiraDoCliente(cliente),
        descricaoBase: 'Venda - ${cliente.nome}',
        valores: valores,
        total: totalVenda,
        avisar: _avisar,
      );
      if (montados == null) return;
      lancamentos = montados;
    }

    final venda = Venda(
      id: vendaId,
      data: dataVenda,
      clienteId: clienteId,
      itens: itens,
      lancamentosFinanceiros: lancamentos,
    );
    try {
      if (vendaOriginal == null) {
        await _repo.salvarVenda(venda);
      } else {
        await _repo.atualizarVenda(venda, atualizarFinanceiro: true);
      }
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
}

class _ResumoVenda {
  final double total;
  final double totalCusto;

  const _ResumoVenda({required this.total, required this.totalCusto});
}

String _formatarData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
