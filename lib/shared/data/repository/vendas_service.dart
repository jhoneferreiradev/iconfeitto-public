import 'package:sqflite/sqflite.dart';

import '../../models/lancamento_financeiro.dart';
import '../../models/operacao.dart';
import 'estoque_service.dart';
import 'lancamentos_service.dart';
import 'repository_component.dart';
import 'row_mappers.dart';

/// Vendas: itens, saída de estoque na entrega e lançamentos a receber.
class VendasService extends RepositoryComponent {
  final EstoqueService estoqueService;
  final LancamentosService lancamentosService;

  VendasService(
    super.context, {
    required this.estoqueService,
    required this.lancamentosService,
  });

  Future<void> salvarVenda(Venda venda) async {
    final movimentosNovos = criarMovimentos(venda);
    estoqueService.validarSaldo(movimentosNovos);
    await db.transaction((transaction) async {
      await _inserirVenda(transaction, venda, movimentosNovos);
      for (final lancamento in venda.lancamentosFinanceiros) {
        await lancamentosService.gravar(transaction, lancamento);
      }
    });
    vendas.add(venda);
    lancamentosService.registrarEmMemoria(venda.lancamentosFinanceiros);
    movimentacoes.addAll(movimentosNovos);
    estoqueService.recalcular();
    await estoqueService.persistirProdutos();
    notificar();
  }

  Future<void> atualizarVenda(
    Venda venda, {
    bool atualizarFinanceiro = false,
  }) async {
    final indice = vendas.indexWhere((existente) => existente.id == venda.id);
    if (indice < 0) {
      throw StateError('A venda que você tentou editar não foi encontrada.');
    }
    if (lancamentosService.lancamentosDaVenda(venda.id).any((l) => l.hasQuitacoes)) {
      throw StateError(
        'Esta venda possui lançamentos financeiros com pagamentos '
        '(quitações) e não pode ser editada. Remova as quitações antes.',
      );
    }

    if (!vendas[indice].itensEditaveis) {
      throw StateError(
        'Só é possível editar os itens de uma venda com o pedido recebido. '
        'Reabra a venda para alterá-la.',
      );
    }
    final movimentosAntigos = movimentosDa(vendas[indice]);
    final movimentosNovos = criarMovimentos(venda);
    final idsAntigos = movimentosAntigos
        .map((movimento) => movimento.id)
        .toSet();
    final produtosAfetados = {
      ...movimentosAntigos.map((movimento) => movimento.produtoId),
      ...movimentosNovos.map((movimento) => movimento.produtoId),
    };
    estoqueService.validarSaldo(movimentosNovos, removerIds: idsAntigos);
    await db.transaction((transaction) async {
      await _removerVendaDoBanco(transaction, venda.id, movimentosAntigos);
      await _inserirVenda(transaction, venda, movimentosNovos);
      if (atualizarFinanceiro) {
        await lancamentosService.excluirDoBanco(
          transaction,
          TipoOperacaoOrigem.venda,
          venda.id,
        );
        for (final lancamento in venda.lancamentosFinanceiros) {
          await lancamentosService.gravar(transaction, lancamento);
        }
      }
    });

    movimentacoes.removeWhere((movimento) => idsAntigos.contains(movimento.id));
    movimentacoes.addAll(movimentosNovos);
    vendas[indice] = venda;
    if (atualizarFinanceiro) {
      lancamentosService.removerDaOperacao(TipoOperacaoOrigem.venda, venda.id);
      lancamentosService.registrarEmMemoria(venda.lancamentosFinanceiros);
    }
    estoqueService.recalcular(
      produtosSemMovimentacoes: produtosAfetados,
    );
    await estoqueService.persistirProdutos();
    notificar();
  }

  Future<void> excluirVenda(String vendaId) async {
    final indice = vendas.indexWhere((venda) => venda.id == vendaId);
    if (indice < 0) return;

    if (lancamentosService.lancamentosDaVenda(vendaId).any((l) => l.hasQuitacoes)) {
      throw StateError(
        'Esta venda possui lançamentos financeiros com pagamentos '
        'registrados. Exclua as quitações antes de excluir a venda.',
      );
    }
    if (const [
      StatusVenda.emProducao,
      StatusVenda.aguardandoRetirada,
      StatusVenda.emEntrega,
    ].contains(vendas[indice].status)) {
      throw StateError(
        'Esta venda está em andamento. Cancele a venda antes de excluí-la.',
      );
    }
    final movimentosDaVenda = movimentosDa(vendas[indice]);
    final idsRemovidos = movimentosDaVenda
        .map((movimento) => movimento.id)
        .toSet();
    final produtosAfetados = movimentosDaVenda
        .map((movimento) => movimento.produtoId)
        .toSet();
    estoqueService.validarSaldo(const [], removerIds: idsRemovidos);
    await db.transaction(
      (transaction) async {
        await _removerVendaDoBanco(transaction, vendaId, movimentosDaVenda);
        await lancamentosService.excluirDoBanco(
          transaction,
          TipoOperacaoOrigem.venda,
          vendaId,
        );
      },
    );

    movimentacoes.removeWhere(
      (movimento) => idsRemovidos.contains(movimento.id),
    );
    vendas.removeAt(indice);
    lancamentosService.removerDaOperacao(TipoOperacaoOrigem.venda, vendaId);
    estoqueService.recalcular(
      produtosSemMovimentacoes: produtosAfetados,
    );
    await estoqueService.persistirProdutos();
    notificar();
  }

  /// Troca só os lançamentos financeiros da venda (usado quando a venda já
  /// andou e seus itens não podem mais ser editados).
  Future<void> atualizarFinanceiroDaVenda(
    String vendaId,
    List<LancamentoFinanceiro> lancamentos,
  ) async {
    indiceDaVenda(vendaId);
    if (lancamentosService.lancamentosDaVenda(vendaId).any((l) => l.hasQuitacoes)) {
      throw StateError(
        'Esta venda possui lançamentos com pagamentos (quitações) e não pode '
        'ter o financeiro alterado.',
      );
    }
    await db.transaction((transaction) async {
      await lancamentosService.excluirDoBanco(
        transaction,
        TipoOperacaoOrigem.venda,
        vendaId,
      );
      for (final lancamento in lancamentos) {
        await lancamentosService.gravar(transaction, lancamento);
      }
    });
    lancamentosService.removerDaOperacao(TipoOperacaoOrigem.venda, vendaId);
    lancamentosService.registrarEmMemoria(lancamentos);
    notificar();
  }

  Future<void> _removerVendaDoBanco(
    DatabaseExecutor database,
    String vendaId,
    List<MovimentoEstoque> movimentos,
  ) async {
    for (final movimento in movimentos) {
      await database.delete(
        'movimentos_estoque',
        where: 'id = ?',
        whereArgs: [movimento.id],
      );
    }
    await database.delete(
      'itens_venda',
      where: 'vendaId = ?',
      whereArgs: [vendaId],
    );
    await database.delete('vendas', where: 'id = ?', whereArgs: [vendaId]);
  }

  Future<void> _inserirVenda(
    DatabaseExecutor database,
    Venda venda,
    List<MovimentoEstoque> movimentos,
  ) async {
    await database.insert('vendas', {
      'id': venda.id,
      'data': venda.data.toIso8601String(),
      'clienteId': venda.clienteId,
      'tipo': venda.tipo.name,
      'status': venda.status.name,
      'dataEntrega': venda.dataEntrega?.toIso8601String(),
      'dataEntregue': venda.dataEntregue?.toIso8601String(),
    });
    for (final item in venda.itens) {
      await database.insert('itens_venda', {
        'vendaId': venda.id,
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

  /// O produto final só sai do estoque quando a venda é entregue, na data da
  /// entrega. Antes disso (pedido, produção, retirada, percurso) não há saída.
  List<MovimentoEstoque> criarMovimentos(Venda venda) => [
    if (venda.entregue)
      for (final item in venda.itens)
      MovimentoEstoque(
        id: novoId(),
        operacaoId: venda.id,
        data: venda.dataReferencia,
        produtoId: item.produtoId,
        tipo: TipoMovimentoEstoque.venda,
        quantidade: item.quantidade,
        valorUnitario: item.valorUnitario,
        unidadeId: item.unidadeId,
      ),
  ];

  List<MovimentoEstoque> movimentosDa(Venda venda) {
    if (!venda.entregue) return const [];
    final vinculados = movimentacoes
        .where(
          (movimento) =>
              movimento.operacaoId == venda.id &&
              movimento.tipo == TipoMovimentoEstoque.venda,
        )
        .toList();
    if (vinculados.isNotEmpty) {
      if (vinculados.length != venda.itens.length) {
        throw StateError(
          'Não foi possível localizar todas as movimentações da venda.',
        );
      }
      return vinculados;
    }

    // Registros antigos, sem vínculo com a operação.
    final candidatos = movimentacoes
        .where(
          (movimento) =>
              movimento.operacaoId == null &&
              movimento.tipo == TipoMovimentoEstoque.venda,
        )
        .toList();
    final correspondentes = <MovimentoEstoque>[];
    for (final item in venda.itens) {
      final indice = candidatos.indexWhere(
        (movimento) =>
            movimento.produtoId == item.produtoId &&
            movimento.data == venda.dataReferencia &&
            movimento.quantidade == item.quantidade &&
            movimento.valorUnitario == item.valorUnitario &&
            movimento.unidadeId == item.unidadeId,
      );
      if (indice >= 0) correspondentes.add(candidatos.removeAt(indice));
    }
    if (correspondentes.length != venda.itens.length) {
      throw StateError(
        'Não foi possível localizar todas as movimentações da venda.',
      );
    }
    return correspondentes;
  }

  // ---------------------------------------------------------------------------
  // Andamento da venda
  // ---------------------------------------------------------------------------

  int indiceDaVenda(String vendaId) {
    final indice = vendas.indexWhere((venda) => venda.id == vendaId);
    if (indice < 0) throw StateError('A venda não foi encontrada.');
    return indice;
  }

  Future<void> gravarStatus(
    DatabaseExecutor database,
    Venda venda,
  ) => database.update(
    'vendas',
    {
      'status': venda.status.name,
      'dataEntregue': venda.dataEntregue?.toIso8601String(),
    },
    where: 'id = ?',
    whereArgs: [venda.id],
  );
}
