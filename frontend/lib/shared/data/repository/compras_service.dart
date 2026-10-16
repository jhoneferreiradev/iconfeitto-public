import 'package:sqflite/sqflite.dart';

import '../../models/lancamento_financeiro.dart';
import '../../models/operacao.dart';
import 'estoque_service.dart';
import 'lancamentos_service.dart';
import 'repository_component.dart';
import 'row_mappers.dart';

/// Compras: entrada de estoque e lançamentos a pagar.
class ComprasService extends RepositoryComponent {
  final EstoqueService estoqueService;
  final LancamentosService lancamentosService;

  ComprasService(
    super.context, {
    required this.estoqueService,
    required this.lancamentosService,
  });

  Future<void> salvarCompra(Compra compra) async {
    final movimentosNovos = _criarMovimentosCompra(compra);
    estoqueService.validarSaldo(movimentosNovos);
    await db.transaction((transaction) async {
      await _inserirCompra(transaction, compra, movimentosNovos);
      for (final lancamento in compra.lancamentosFinanceiros) {
        await lancamentosService.gravar(transaction, lancamento);
      }
    });
    compras.add(compra);
    movimentacoes.addAll(movimentosNovos);
    estoqueService.recalcular(
      produtosSemMovimentacoes: movimentosNovos
          .map((movimento) => movimento.produtoId)
          .toSet(),
    );
    await estoqueService.persistirProdutos();

    lancamentosService.registrarEmMemoria(compra.lancamentosFinanceiros);

    notificar();
  }

  Future<void> atualizarCompra(
    Compra compra, {
    bool atualizarFinanceiro = false,
  }) async {
    final indice = compras.indexWhere((existente) => existente.id == compra.id);
    if (indice < 0) {
      throw StateError('A compra que você tentou editar não foi encontrada.');
    }
    if (lancamentosService.lancamentosDaCompra(compra.id).any((l) => l.hasQuitacoes)) {
      throw StateError(
        'Esta compra possui lançamentos financeiros com pagamentos '
        '(quitações) e não pode ser editada. Remova as quitações antes.',
      );
    }

    final movimentosAntigos = _movimentosDaCompra(compras[indice]);
    final movimentosNovos = _criarMovimentosCompra(compra);
    final idsAntigos = movimentosAntigos
        .map((movimento) => movimento.id)
        .toSet();
    estoqueService.validarSaldo(movimentosNovos, removerIds: idsAntigos);
    await db.transaction((transaction) async {
      for (final movimento in movimentosAntigos) {
        await transaction.delete(
          'movimentos_estoque',
          where: 'id = ?',
          whereArgs: [movimento.id],
        );
      }
      await transaction.delete(
        'itens_compra',
        where: 'compraId = ?',
        whereArgs: [compra.id],
      );
      await transaction.delete(
        'compras',
        where: 'id = ?',
        whereArgs: [compra.id],
      );
      await _inserirCompra(transaction, compra, movimentosNovos);
      if (atualizarFinanceiro) {
        await lancamentosService.excluirDoBanco(transaction, TipoOperacaoOrigem.compra, compra.id);
        for (final lancamento in compra.lancamentosFinanceiros) {
          await lancamentosService.gravar(transaction, lancamento);
        }
      }
    });

    movimentacoes.removeWhere((movimento) => idsAntigos.contains(movimento.id));
    movimentacoes.addAll(movimentosNovos);
    compras[indice] = compra;
    estoqueService.recalcular(
      produtosSemMovimentacoes: {
        ...movimentosAntigos.map((movimento) => movimento.produtoId),
        ...movimentosNovos.map((movimento) => movimento.produtoId),
      },
    );
    await estoqueService.persistirProdutos();

    if (atualizarFinanceiro) {
      lancamentosService.removerDaOperacao(TipoOperacaoOrigem.compra, compra.id);
      lancamentosService.registrarEmMemoria(compra.lancamentosFinanceiros);
    }

    notificar();
  }

  Future<void> excluirCompra(String compraId) async {
    final indice = compras.indexWhere((compra) => compra.id == compraId);
    if (indice < 0) return;

    final compra = compras[indice];
    if (lancamentosService.lancamentosDaCompra(compraId).any((l) => l.hasQuitacoes)) {
      throw StateError(
        'Esta compra possui lançamentos financeiros com pagamentos '
        'registrados. Exclua as quitações antes de excluir a compra.',
      );
    }
    final movimentosDaCompra = _movimentosDaCompra(compra);
    final idsRemovidos = movimentosDaCompra
        .map((movimento) => movimento.id)
        .toSet();
    estoqueService.validarSaldo(const [], removerIds: idsRemovidos);
    await db.transaction((transaction) async {
      for (final movimento in movimentosDaCompra) {
        await transaction.delete(
          'movimentos_estoque',
          where: 'id = ?',
          whereArgs: [movimento.id],
        );
      }
      await transaction.delete(
        'itens_compra',
        where: 'compraId = ?',
        whereArgs: [compraId],
      );
      await transaction.delete(
        'compras',
        where: 'id = ?',
        whereArgs: [compraId],
      );
      await lancamentosService.excluirDoBanco(transaction, TipoOperacaoOrigem.compra, compraId);
    });

    movimentacoes.removeWhere(
      (movimento) => idsRemovidos.contains(movimento.id),
    );
    compras.removeAt(indice);
    lancamentosService.removerDaOperacao(TipoOperacaoOrigem.compra, compraId);
    estoqueService.recalcular(
      produtosSemMovimentacoes: movimentosDaCompra
          .map((movimento) => movimento.produtoId)
          .toSet(),
    );
    await estoqueService.persistirProdutos();
    notificar();
  }

  Future<void> _inserirCompra(
    DatabaseExecutor database,
    Compra compra,
    List<MovimentoEstoque> movimentos,
  ) async {
    await database.insert('compras', {
      'id': compra.id,
      'data': compra.data.toIso8601String(),
      'fornecedorId': compra.fornecedorId,
    });
    for (final item in compra.itens) {
      await database.insert('itens_compra', {
        'compraId': compra.id,
        'produtoId': item.produtoId,
        'quantidade': item.quantidade,
        'valorUnitario': item.valorUnitario,
        'unidadeId': item.unidadeId,
      });
    }
    for (final movimento in movimentos) {
      await database.insert('movimentos_estoque', movimentoParaLinha(movimento));
    }
  }

  List<MovimentoEstoque> _criarMovimentosCompra(Compra compra) => [
    for (final item in compra.itens)
      MovimentoEstoque(
        id: novoId(),
        operacaoId: compra.id,
        data: compra.data,
        produtoId: item.produtoId,
        tipo: TipoMovimentoEstoque.compra,
        quantidade: item.quantidade,
        valorUnitario: item.valorUnitario,
        unidadeId: item.unidadeId,
      ),
  ];

  List<MovimentoEstoque> _movimentosDaCompra(Compra compra) {
    final vinculados = movimentacoes
        .where(
          (movimento) =>
              movimento.operacaoId == compra.id &&
              movimento.tipo == TipoMovimentoEstoque.compra,
        )
        .toList();
    if (vinculados.isNotEmpty) {
      if (vinculados.length != compra.itens.length) {
        throw StateError(
          'Não foi possível localizar todas as movimentações da compra.',
        );
      }
      return vinculados;
    }

    final candidatos = movimentacoes
        .where((movimento) => movimento.tipo == TipoMovimentoEstoque.compra)
        .toList();
    final correspondentes = <MovimentoEstoque>[];
    for (final item in compra.itens) {
      final indice = candidatos.indexWhere(
        (movimento) =>
            movimento.produtoId == item.produtoId &&
            movimento.data == compra.data &&
            movimento.quantidade == item.quantidade &&
            movimento.valorUnitario == item.valorUnitario &&
            movimento.unidadeId == item.unidadeId,
      );
      if (indice >= 0) correspondentes.add(candidatos.removeAt(indice));
    }
    if (correspondentes.length != compra.itens.length) {
      throw StateError(
        'Não foi possível localizar todas as movimentações da compra.',
      );
    }
    return correspondentes;
  }
}
