import 'package:sqflite/sqflite.dart';

import '../../models/lancamento_financeiro.dart';
import 'repository_component.dart';

/// Lançamentos financeiros e quitações: persistência, cache em memória e
/// consulta dos lançamentos gerados por uma operação (compra/venda).
class LancamentosService extends RepositoryComponent {
  LancamentosService(super.context);

  Future<void> salvarLancamentoFinanceiro(
    LancamentoFinanceiro lancamento,
  ) async {
    for (final quitacao in lancamento.quitacoes) {
      quitacao.lancamentoId = lancamento.id;
    }
    await db.transaction(
      (transaction) => gravar(transaction, lancamento),
    );
    _guardarLancamentoEmMemoria(lancamento);
    notificar();
  }

  /// Lançamentos vinculados a uma operação (ex.: compra) só são excluídos
  /// junto com ela, para manter a ligação com os dados da origem.
  Future<void> excluirLancamentoFinanceiro(
    LancamentoFinanceiro lancamento,
  ) async {
    if (lancamento.tipoOperacaoOriem != TipoOperacaoOrigem.avulso) {
      throw StateError(
        'Este lançamento está vinculado a uma operação e só pode ser '
        'excluído por ela.',
      );
    }
    await db.transaction((transaction) async {
      await transaction.delete(
        'quitacoes',
        where: 'lancamentoId = ?',
        whereArgs: [lancamento.id],
      );
      await transaction.delete(
        'lancamentos_financeiros',
        where: 'id = ?',
        whereArgs: [lancamento.id],
      );
    });
    lancamentosFinanceiros.removeWhere((l) => l.id == lancamento.id);
    notificar();
  }

  Future<void> gravar(
    DatabaseExecutor database,
    LancamentoFinanceiro lancamento,
  ) async {
    await database.insert('lancamentos_financeiros', {
      'id': lancamento.id,
      'pessoaId': lancamento.pessoaFinanceiro.id,
      'pessoaTipo': lancamento.pessoaFinanceiro.tipoPessoaFinanceiro.name,
      'pessoaNome': lancamento.pessoaFinanceiro.nome,
      'tipoLancamento': lancamento.tipoLancamento.name,
      'lancamentoPaiId': lancamento.lancamentoPai?.id,
      'statusLancamento': lancamento.statusLancamento.name,
      'tipoOperacaoOrigem': lancamento.tipoOperacaoOriem.name,
      'operacaoOrigemId': lancamento.operacaoOrigemId,
      'formaPagamento': lancamento.formaPagamento?.name,
      'dataCriacao': lancamento.dataCriacao.toIso8601String(),
      'dataVencimento': lancamento.dataVencimento.toIso8601String(),
      'descricao': lancamento.descricao,
      'observacao': lancamento.observacao,
      'valorLancamento': lancamento.valorLancamento,
      'valorDesconto': lancamento.valorDesconto,
      'valorAcrescimo': lancamento.valorAcrescimo,
      'valorTaxasImpostos': lancamento.valorTaxasImpostos,
      'dataCompensacao': lancamento.dataCompensacao?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await database.delete(
      'quitacoes',
      where: 'lancamentoId = ?',
      whereArgs: [lancamento.id],
    );
    for (final quitacao in lancamento.quitacoes) {
      await database.insert('quitacoes', {
        'id': quitacao.id,
        'lancamentoId': lancamento.id,
        'dataQuitacao': quitacao.dataQuitacao.toIso8601String(),
        'valorQuitado': quitacao.valorQuitado,
        'formaPagamento': quitacao.formaPagamento.name,
      });
    }
  }

  Future<void> excluirDoBanco(
    DatabaseExecutor database,
    TipoOperacaoOrigem origem,
    String operacaoId,
  ) async {
    for (final lancamento in lancamentosDaOperacao(origem, operacaoId)) {
      await database.delete(
        'quitacoes',
        where: 'lancamentoId = ?',
        whereArgs: [lancamento.id],
      );
      await database.delete(
        'lancamentos_financeiros',
        where: 'id = ?',
        whereArgs: [lancamento.id],
      );
    }
  }

  void _guardarLancamentoEmMemoria(LancamentoFinanceiro lancamento) {
    final indice = lancamentosFinanceiros.indexWhere(
      (l) => l.id == lancamento.id,
    );
    if (indice >= 0) {
      lancamentosFinanceiros[indice] = lancamento;
    } else {
      lancamentosFinanceiros.add(lancamento);
    }
    // Parcelas que apontavam para a versão anterior do lançamento pai.
    for (final outro in lancamentosFinanceiros) {
      if (outro.lancamentoPai?.id == lancamento.id) {
        outro.lancamentoPai = lancamento;
      }
    }
  }

  void registrarEmMemoria(List<LancamentoFinanceiro> lancamentos) {
    for (final lancamento in lancamentos) {
      for (final quitacao in lancamento.quitacoes) {
        quitacao.lancamentoId = lancamento.id;
      }
      _guardarLancamentoEmMemoria(lancamento);
    }
  }

  /// Lançamentos financeiros gerados por uma operação (compra ou venda):
  /// pai primeiro, depois as demais parcelas por vencimento.
  List<LancamentoFinanceiro> lancamentosDaOperacao(
    TipoOperacaoOrigem origem,
    String operacaoId,
  ) {
    final lista = lancamentosFinanceiros
        .where(
          (l) =>
              l.tipoOperacaoOriem == origem && l.operacaoOrigemId == operacaoId,
        )
        .toList();
    lista.sort((a, b) {
      if (a.lancamentoPai == null && b.lancamentoPai != null) return -1;
      if (a.lancamentoPai != null && b.lancamentoPai == null) return 1;
      return a.dataVencimento.compareTo(b.dataVencimento);
    });
    return lista;
  }

  List<LancamentoFinanceiro> lancamentosDaCompra(String compraId) =>
      lancamentosDaOperacao(TipoOperacaoOrigem.compra, compraId);

  List<LancamentoFinanceiro> lancamentosDaVenda(String vendaId) =>
      lancamentosDaOperacao(TipoOperacaoOrigem.venda, vendaId);

  void removerDaOperacao(
    TipoOperacaoOrigem origem,
    String operacaoId,
  ) {
    final ids = lancamentosDaOperacao(
      origem,
      operacaoId,
    ).map((l) => l.id).toSet();
    lancamentosFinanceiros.removeWhere((l) => ids.contains(l.id));
  }
}
