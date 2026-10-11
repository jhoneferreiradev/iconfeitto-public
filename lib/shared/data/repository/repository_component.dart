import 'package:sqflite/sqflite.dart';

import '../../models/cartao_credito.dart';
import '../../models/cliente.dart';
import '../../models/empresa.dart';
import '../../models/fornecedor.dart';
import '../../models/grupo_unidade.dart';
import '../../models/lancamento_financeiro.dart';
import '../../models/operacao.dart';
import '../../models/produto.dart';
import '../../models/unidade_medida.dart';
import 'repository_context.dart';

/// Base dos serviços do repositório: dá acesso ao contexto compartilhado (banco,
/// caches, ids e consultas por id) sem que cada serviço precise repetir isso.
abstract class RepositoryComponent {
  final RepositoryContext context;

  const RepositoryComponent(this.context);

  Database get db => context.db;

  List<UnidadeMedida> get unidades => context.unidades;
  List<Fornecedor> get fornecedores => context.fornecedores;
  List<Cliente> get clientes => context.clientes;
  List<Produto> get produtos => context.produtos;
  List<Compra> get compras => context.compras;
  List<Venda> get vendas => context.vendas;
  List<Fabricacao> get fabricacoes => context.fabricacoes;
  List<MovimentoEstoque> get movimentacoes => context.movimentacoes;
  List<LancamentoFinanceiro> get lancamentosFinanceiros => context.lancamentosFinanceiros;
  List<PessoaFinanceiro> get pessoasFinanceiro => context.pessoasFinanceiro;
  List<CartaoCredito> get cartoesCredito => context.cartoesCredito;
  List<BandeiraCartaoCredito> get bandeirasCartaoCredito => context.bandeirasCartaoCredito;

  Empresa get empresa => context.empresa;
  set empresa(Empresa valor) => context.empresa = valor;

  String novoId() => context.novoId();

  void notificar() => context.notificar();

  UnidadeMedida unidadePorId(String id) => context.unidadePorId(id);
  Produto? produtoPorId(String id) => context.produtoPorId(id);
  LancamentoFinanceiro? lancamentoFinanceiroPorId(String id) =>
      context.lancamentoFinanceiroPorId(id);
  Fornecedor? fornecedorPorId(String id) => context.fornecedorPorId(id);
  Cliente? clientePorId(String id) => context.clientePorId(id);
  List<UnidadeMedida> unidadesDoGrupo(GrupoUnidade grupo) =>
      context.unidadesDoGrupo(grupo);
  CartaoCredito? cartaoPorId(String id) => context.cartaoPorId(id);
  BandeiraCartaoCredito? bandeiraPorId(String id) =>
      context.bandeiraPorId(id);
}
