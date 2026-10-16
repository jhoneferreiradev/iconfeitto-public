import 'package:flutter/foundation.dart';

import '../domain/estoque_calculator.dart';
import '../models/cartao_credito.dart';
import '../models/cliente.dart';
import '../models/custo_operacional.dart';
import '../models/empresa.dart';
import '../models/fornecedor.dart';
import '../models/grupo_unidade.dart';
import '../models/item_ficha_tecnica.dart';
import '../models/item_ficha_tecnica_embalagem.dart';
import '../models/lancamento_financeiro.dart';
import '../models/operacao.dart';
import '../models/produto.dart';
import '../models/unidade_medida.dart';
import 'database/app_database.dart';
import 'repository/andamento_venda_service.dart';
import 'repository/cadastros_service.dart';
import 'repository/cartoes_service.dart';
import 'repository/compras_service.dart';
import 'repository/custo_ficha_tecnica_service.dart';
import 'repository/data_loader.dart';
import 'repository/empresa_service.dart';
import 'repository/estoque_service.dart';
import 'repository/fabricacao_service.dart';
import 'repository/lancamentos_service.dart';
import 'repository/pessoas_financeiras_service.dart';
import 'repository/repository_context.dart';
import 'repository/vendas_service.dart';

/// Ponto único de acesso aos dados do app (padrão fachada).
///
/// Não tem regra de negócio: cada operação é delegada ao serviço do assunto
/// (estoque, compras, vendas, financeiro...), que fica em `repository/`. Os
/// serviços dividem o mesmo [RepositoryContext] (banco e caches em memória) e
/// dependem uns dos outros só por construtor, na ordem declarada abaixo.
class AppRepository extends ChangeNotifier {
  AppRepository._();
  static final AppRepository instance = AppRepository._();

  late final RepositoryContext _context = RepositoryContext(
    notificar: notifyListeners,
  );
  late final EstoqueService _estoque = EstoqueService(_context);
  late final LancamentosService _lancamentos = LancamentosService(_context);
  late final PessoasFinanceirasService _pessoas = PessoasFinanceirasService(_context);
  late final CustoFichaTecnicaService _custos = CustoFichaTecnicaService(_context);
  late final CadastrosService _cadastros = CadastrosService(_context);
  late final EmpresaService _empresa = EmpresaService(_context);
  late final CartoesService _cartoes = CartoesService(
    _context,
    pessoasService: _pessoas,
  );
  late final FabricacaoService _fabricacao = FabricacaoService(
    _context,
    estoqueService: _estoque,
  );
  late final ComprasService _compras = ComprasService(
    _context,
    estoqueService: _estoque,
    lancamentosService: _lancamentos,
  );
  late final VendasService _vendas = VendasService(
    _context,
    estoqueService: _estoque,
    lancamentosService: _lancamentos,
  );
  late final AndamentoVendaService _andamento = AndamentoVendaService(
    _context,
    estoqueService: _estoque,
    fabricacaoService: _fabricacao,
    vendasService: _vendas,
  );
  late final DataLoader _loader = DataLoader(_context, estoqueService: _estoque);

  bool _inicializado = false;

  bool get isInitialized => _inicializado;

  /// Abre o banco e carrega todos os dados para a memória.
  Future<void> initialize() async {
    if (_inicializado) return;

    _context.db = await AppDatabase().database;
    await _loader.carregarTudo();
    _inicializado = true;
    notifyListeners();
  }

  String novoId() => _context.novoId();

  // Caches em memória (somente leitura para as telas).
  List<UnidadeMedida> get unidades => _context.unidades;
  List<Fornecedor> get fornecedores => _context.fornecedores;
  List<Cliente> get clientes => _context.clientes;
  List<Produto> get produtos => _context.produtos;
  List<Compra> get compras => _context.compras;
  List<Venda> get vendas => _context.vendas;
  List<Fabricacao> get fabricacoes => _context.fabricacoes;
  List<MovimentoEstoque> get movimentacoes => _context.movimentacoes;
  List<LancamentoFinanceiro> get lancamentosFinanceiros => _context.lancamentosFinanceiros;
  List<PessoaFinanceiro> get pessoasFinanceiro => _context.pessoasFinanceiro;
  List<CartaoCredito> get cartoesCredito => _context.cartoesCredito;
  List<BandeiraCartaoCredito> get bandeirasCartaoCredito => _context.bandeirasCartaoCredito;
  Empresa get empresa => _context.empresa;
  set empresa(Empresa valor) => _context.empresa = valor;

  // Consultas por id.
  UnidadeMedida unidadePorId(String id) => _context.unidadePorId(id);

  Produto? produtoPorId(String id) => _context.produtoPorId(id);

  LancamentoFinanceiro? lancamentoFinanceiroPorId(String id) =>
      _context.lancamentoFinanceiroPorId(id);

  Fornecedor? fornecedorPorId(String id) => _context.fornecedorPorId(id);

  Cliente? clientePorId(String id) => _context.clientePorId(id);

  List<UnidadeMedida> unidadesDoGrupo(GrupoUnidade grupo) =>
      _context.unidadesDoGrupo(grupo);

  CartaoCredito? cartaoPorId(String id) => _context.cartaoPorId(id);

  BandeiraCartaoCredito? bandeiraPorId(String id) =>
      _context.bandeiraPorId(id);

  // ---------------------------------------------------------------------------
  // Cadastros
  // ---------------------------------------------------------------------------
  Future<void> salvarProduto(Produto produto) =>
      _cadastros.salvarProduto(produto);

  Future<void> excluirProduto(String id) => _cadastros.excluirProduto(id);

  Future<void> salvarUnidade(UnidadeMedida unidade) =>
      _cadastros.salvarUnidade(unidade);

  Future<void> excluirUnidade(String id) => _cadastros.excluirUnidade(id);

  Future<void> salvarFornecedor(Fornecedor fornecedor) =>
      _cadastros.salvarFornecedor(fornecedor);

  Future<void> excluirFornecedor(String id) =>
      _cadastros.excluirFornecedor(id);

  Future<void> salvarCliente(Cliente cliente) =>
      _cadastros.salvarCliente(cliente);

  Future<void> excluirCliente(String id) => _cadastros.excluirCliente(id);

  Future<void> salvarEmpresa(Empresa novaEmpresa) =>
      _empresa.salvarEmpresa(novaEmpresa);

  Future<void> adicionarCustoOperacional(CustoOperacional custo) =>
      _empresa.adicionarCustoOperacional(custo);

  Future<void> removerCustoOperacional(String custoId) =>
      _empresa.removerCustoOperacional(custoId);

  // ---------------------------------------------------------------------------
  // Custos da ficha técnica
  // ---------------------------------------------------------------------------
  double custoPorUnidadeBase(Produto produto) =>
      _custos.custoPorUnidadeBase(produto);

  double custoItemFicha(ItemFichaTecnica item) => _custos.custoItemFicha(item);

  double custoItemFichaEmbalagem(ItemFichaTecnicaEmbalagem item) =>
      _custos.custoItemFichaEmbalagem(item);

  double custoEmbalagem(Produto produto) => _custos.custoEmbalagem(produto);

  double custoTotalFicha(Produto produto) => _custos.custoTotalFicha(produto);

  // ---------------------------------------------------------------------------
  // Estoque
  // ---------------------------------------------------------------------------
  void recalcularEstoque({Set<String> produtosSemMovimentacoes = const {}}) =>
      _estoque.recalcular(produtosSemMovimentacoes: produtosSemMovimentacoes);

  Future<void> ajustarEstoque(
    String produtoId,
    double novoSaldo,
    double novoCusto, {
    DateTime? data,
  }) => _estoque.ajustar(produtoId, novoSaldo, novoCusto, data: data);

  Future<void> registrarConsumo(
    String produtoId,
    double quantidade, {
    DateTime? data,
  }) => _estoque.registrarConsumo(produtoId, quantidade, data: data);

  List<PassoEstoque> ultimasMovimentacoes(String produtoId, {int limite = 10}) =>
      _estoque.ultimasMovimentacoes(produtoId, limite: limite);

  // ---------------------------------------------------------------------------
  // Compras
  // ---------------------------------------------------------------------------
  Future<void> salvarCompra(Compra compra) => _compras.salvarCompra(compra);

  Future<void> atualizarCompra(
    Compra compra, {
    bool atualizarFinanceiro = false,
  }) => _compras.atualizarCompra(
    compra,
    atualizarFinanceiro: atualizarFinanceiro,
  );

  Future<void> excluirCompra(String compraId) =>
      _compras.excluirCompra(compraId);

  // ---------------------------------------------------------------------------
  // Vendas e andamento da venda
  // ---------------------------------------------------------------------------
  Future<void> salvarVenda(Venda venda) => _vendas.salvarVenda(venda);

  Future<void> atualizarVenda(
    Venda venda, {
    bool atualizarFinanceiro = false,
  }) => _vendas.atualizarVenda(venda, atualizarFinanceiro: atualizarFinanceiro);

  Future<void> excluirVenda(String vendaId) => _vendas.excluirVenda(vendaId);

  Future<void> atualizarFinanceiroDaVenda(
    String vendaId,
    List<LancamentoFinanceiro> lancamentos,
  ) => _vendas.atualizarFinanceiroDaVenda(vendaId, lancamentos);

  Future<void> alterarStatusVenda(String vendaId, StatusVenda novo) =>
      _andamento.alterarStatusVenda(vendaId, novo);

  Future<void> iniciarProducaoVenda(String vendaId) =>
      _andamento.iniciarProducaoVenda(vendaId);

  Future<void> entregarVenda(String vendaId, DateTime dataEntregue) =>
      _andamento.entregarVenda(vendaId, dataEntregue);

  Future<void> reabrirVenda(String vendaId) =>
      _andamento.reabrirVenda(vendaId);

  // ---------------------------------------------------------------------------
  // Fabricações
  // ---------------------------------------------------------------------------
  Future<void> salvarFabricacao(Fabricacao fabricacao) =>
      _fabricacao.salvarFabricacao(fabricacao);

  /// Salva várias fabricações na mesma transação. As fabricações devem estar
  /// ordenadas de modo que os itens intermediários venham antes do final.
  Future<void> salvarFabricacoes(List<Fabricacao> lista) =>
      _fabricacao.salvarFabricacoes(lista);

  List<Fabricacao> fabricacoesVinculadas(String fabricacaoId) =>
      _fabricacao.fabricacoesVinculadas(fabricacaoId);

  Future<void> excluirFabricacao(String fabricacaoId) =>
      _fabricacao.excluirFabricacao(fabricacaoId);

  // ---------------------------------------------------------------------------
  // Lançamentos financeiros
  // ---------------------------------------------------------------------------
  Future<void> salvarLancamentoFinanceiro(LancamentoFinanceiro lancamento) =>
      _lancamentos.salvarLancamentoFinanceiro(lancamento);

  Future<void> excluirLancamentoFinanceiro(LancamentoFinanceiro lancamento) =>
      _lancamentos.excluirLancamentoFinanceiro(lancamento);

  List<LancamentoFinanceiro> lancamentosDaOperacao(
    TipoOperacaoOrigem origem,
    String operacaoId,
  ) => _lancamentos.lancamentosDaOperacao(origem, operacaoId);

  List<LancamentoFinanceiro> lancamentosDaCompra(String compraId) =>
      _lancamentos.lancamentosDaCompra(compraId);

  List<LancamentoFinanceiro> lancamentosDaVenda(String vendaId) =>
      _lancamentos.lancamentosDaVenda(vendaId);

  PessoaFinanceiro pessoaFinanceiraDoFornecedor(Fornecedor fornecedor) =>
      _pessoas.pessoaFinanceiraDoFornecedor(fornecedor);

  PessoaFinanceiro pessoaFinanceiraDoCliente(Cliente cliente) =>
      _pessoas.pessoaFinanceiraDoCliente(cliente);

  List<PessoaFinanceiro> get pessoasCartaoCredito =>
      _pessoas.pessoasCartaoCredito;

  List<PessoaFinanceiro> get pessoasBandeiraCartao =>
      _pessoas.pessoasBandeiraCartao;

  // ---------------------------------------------------------------------------
  // Cartões de crédito e bandeiras
  // ---------------------------------------------------------------------------
  Future<PessoaFinanceiro> salvarCartaoCredito(CartaoCredito cartao) =>
      _cartoes.salvarCartaoCredito(cartao);

  Future<void> excluirCartaoCredito(String id) =>
      _cartoes.excluirCartaoCredito(id);

  Future<PessoaFinanceiro> salvarBandeiraCartao(
    BandeiraCartaoCredito bandeira,
  ) => _cartoes.salvarBandeiraCartao(bandeira);

  Future<void> excluirBandeiraCartao(String id) =>
      _cartoes.excluirBandeiraCartao(id);
}
