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

/// Estado compartilhado do repositório: caches em memória, conexão com o
/// banco, geração de ids, aviso de mudanças e consultas simples por id.
///
/// Os serviços (compras, vendas, estoque...) recebem este contexto e cuidam
/// cada um de um assunto; o contexto não tem regra de negócio.
class RepositoryContext {
  RepositoryContext({required void Function() notificar})
    : _notificar = notificar;

  final void Function() _notificar;

  final List<UnidadeMedida> unidades = [];
  final List<Fornecedor> fornecedores = [];
  final List<Cliente> clientes = [];
  final List<Produto> produtos = [];
  final List<Compra> compras = [];
  final List<Venda> vendas = [];
  final List<Fabricacao> fabricacoes = [];
  final List<MovimentoEstoque> movimentacoes = [];
  final List<LancamentoFinanceiro> lancamentosFinanceiros = [];
  final List<PessoaFinanceiro> pessoasFinanceiro = [];
  final List<CartaoCredito> cartoesCredito = [];
  final List<BandeiraCartaoCredito> bandeirasCartaoCredito = [];
  Empresa empresa = const Empresa();

  late Database db;
  int _ultimoIdGerado = 0;

  String novoId() {
    final agora = DateTime.now().microsecondsSinceEpoch;
    _ultimoIdGerado = agora > _ultimoIdGerado ? agora : _ultimoIdGerado + 1;
    return _ultimoIdGerado.toString();
  }

  /// Avisa os ouvintes (telas) de que os dados mudaram.
  void notificar() => _notificar();

  UnidadeMedida unidadePorId(String id) =>
      unidades.firstWhere((u) => u.id == id);

  Produto? produtoPorId(String id) {
    for (final p in produtos) {
      if (p.id == id) return p;
    }
    return null;
  }

  LancamentoFinanceiro? lancamentoFinanceiroPorId(String id) {
    for (final l in lancamentosFinanceiros) {
      if (l.id == id) return l;
    }
    return null;
  }

  Fornecedor? fornecedorPorId(String id) {
    for (final fornecedor in fornecedores) {
      if (fornecedor.id == id) return fornecedor;
    }
    return null;
  }

  Cliente? clientePorId(String id) {
    for (final cliente in clientes) {
      if (cliente.id == id) return cliente;
    }
    return null;
  }

  List<UnidadeMedida> unidadesDoGrupo(GrupoUnidade grupo) =>
      unidades.where((u) => u.grupo == grupo).toList();

  CartaoCredito? cartaoPorId(String id) {
    for (final cartao in cartoesCredito) {
      if (cartao.id == id) return cartao;
    }
    return null;
  }

  BandeiraCartaoCredito? bandeiraPorId(String id) {
    for (final bandeira in bandeirasCartaoCredito) {
      if (bandeira.id == id) return bandeira;
    }
    return null;
  }
}
