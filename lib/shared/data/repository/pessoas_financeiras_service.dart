import '../../models/cliente.dart';
import '../../models/fornecedor.dart';
import '../../models/lancamento_financeiro.dart';
import 'repository_component.dart';

/// Pessoas financeiras (clientes, fornecedores, cartões e bandeiras) que
/// aparecem nos lançamentos.
class PessoasFinanceirasService extends RepositoryComponent {
  PessoasFinanceirasService(super.context);

  /// Pessoa financeira do fornecedor (cria e registra se ainda não existir,
  /// pois fornecedores cadastrados depois do carregamento não estão na lista).
  PessoaFinanceiro pessoaFinanceiraDoFornecedor(Fornecedor fornecedor) {
    for (final pessoa in pessoasFinanceiro) {
      if (pessoa.id == fornecedor.id &&
          pessoa.tipoPessoaFinanceiro == TipoPessoaFinanceiro.fornecedor) {
        return pessoa;
      }
    }
    final pessoa = PessoaFinanceiro(
      id: fornecedor.id,
      nome: fornecedor.nome,
      tipoPessoaFinanceiro: TipoPessoaFinanceiro.fornecedor,
    );
    pessoasFinanceiro.add(pessoa);
    return pessoa;
  }

  /// Pessoa financeira do cliente (cria e registra se ainda não existir).
  PessoaFinanceiro pessoaFinanceiraDoCliente(Cliente cliente) {
    for (final pessoa in pessoasFinanceiro) {
      if (pessoa.id == cliente.id &&
          pessoa.tipoPessoaFinanceiro == TipoPessoaFinanceiro.cliente) {
        return pessoa;
      }
    }
    final pessoa = PessoaFinanceiro(
      id: cliente.id,
      nome: cliente.nome,
      tipoPessoaFinanceiro: TipoPessoaFinanceiro.cliente,
    );
    pessoasFinanceiro.add(pessoa);
    return pessoa;
  }

  List<PessoaFinanceiro> get pessoasCartaoCredito => pessoasFinanceiro
      .where((p) => p.tipoPessoaFinanceiro == TipoPessoaFinanceiro.cartaoCredito)
      .toList();

  List<PessoaFinanceiro> get pessoasBandeiraCartao => pessoasFinanceiro
      .where(
        (p) =>
            p.tipoPessoaFinanceiro == TipoPessoaFinanceiro.bandeiraCartaoCredito,
      )
      .toList();

  void validarSemLancamentos(
    String id,
    TipoPessoaFinanceiro tipo,
    String descricao,
  ) {
    final emUso = lancamentosFinanceiros.any(
      (l) =>
          l.pessoaFinanceiro.id == id &&
          l.pessoaFinanceiro.tipoPessoaFinanceiro == tipo,
    );
    if (emUso) {
      throw StateError(
        'Este $descricao possui lançamentos financeiros e não pode ser '
        'excluído.',
      );
    }
  }

  /// Mantém a lista de pessoas financeiras (e os lançamentos já gravados com
  /// o nome antigo) em dia depois de criar/renomear um cartão ou bandeira.
  Future<PessoaFinanceiro> sincronizar(
    String id,
    String nome,
    TipoPessoaFinanceiro tipo,
  ) async {
    final pessoa = PessoaFinanceiro(
      id: id,
      nome: nome,
      tipoPessoaFinanceiro: tipo,
    );
    final indice = pessoasFinanceiro.indexWhere(
      (p) => p.id == id && p.tipoPessoaFinanceiro == tipo,
    );
    if (indice >= 0) {
      pessoasFinanceiro[indice] = pessoa;
    } else {
      pessoasFinanceiro.add(pessoa);
    }
    for (final lancamento in lancamentosFinanceiros) {
      final atual = lancamento.pessoaFinanceiro;
      if (atual.id == id && atual.tipoPessoaFinanceiro == tipo) {
        lancamento.pessoaFinanceiro = pessoa;
      }
    }
    await db.update(
      'lancamentos_financeiros',
      {'pessoaNome': nome},
      where: 'pessoaId = ? AND pessoaTipo = ?',
      whereArgs: [id, tipo.name],
    );
    return pessoa;
  }
}
