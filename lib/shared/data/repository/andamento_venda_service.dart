import '../../models/operacao.dart';
import 'estoque_service.dart';
import 'fabricacao_service.dart';
import 'repository_component.dart';
import 'row_mappers.dart';
import 'vendas_service.dart';

/// Andamento da venda: produção, entrega, retirada, cancelamento e
/// reabertura. O estoque do produto final só se move na entrega.
class AndamentoVendaService extends RepositoryComponent {
  final EstoqueService estoqueService;
  final FabricacaoService fabricacaoService;
  final VendasService vendasService;

  AndamentoVendaService(
    super.context, {
    required this.estoqueService,
    required this.fabricacaoService,
    required this.vendasService,
  });

  /// Mudança de status que não mexe no estoque (aguardando retirada, em
  /// percurso, cancelada). Produção e entrega têm métodos próprios.
  Future<void> alterarStatusVenda(String vendaId, StatusVenda novo) async {
    if (novo == StatusVenda.emProducao || novo == StatusVenda.entregue) {
      throw StateError('Use a ação específica para produzir ou entregar.');
    }
    final indice = vendasService.indiceDaVenda(vendaId);
    final venda = vendas[indice];
    if (!venda.proximosStatus.contains(novo)) {
      throw StateError(
        'Não é possível passar de "${venda.status.label}" para '
        '"${novo.label}".',
      );
    }
    final atualizada = venda.copyWith(status: novo);
    await db.transaction((transaction) => vendasService.gravarStatus(transaction, atualizada));
    vendas[indice] = atualizada;
    notificar();
  }

  /// Inicia a produção de uma venda programada: fabrica os produtos (e seus
  /// preparos) do pedido, consumindo os insumos do estoque.
  Future<void> iniciarProducaoVenda(String vendaId) async {
    final indice = vendasService.indiceDaVenda(vendaId);
    final venda = vendas[indice];
    if (venda.tipo != TipoVenda.programada ||
        venda.status != StatusVenda.pedido) {
      throw StateError(
        'A produção só pode ser iniciada em uma venda programada com o '
        'pedido recebido.',
      );
    }
    final data = DateTime.now();
    final fabricacoesDaVenda = <Fabricacao>[];
    for (final item in venda.itens) {
      final produto = produtoPorId(item.produtoId);
      if (!fabricacaoService.temFichaDeFabricacao(produto)) continue;
      final quantidade =
          item.quantidade *
          unidadePorId(item.unidadeId).fatorParaBase /
          unidadePorId(produto!.unidadeEstoqueId).fatorParaBase;

      // Preparos da ficha técnica (inclusive preparos dentro de preparos),
      // fabricados antes do produto final e todos vinculados a ele.
      final principalId = novoId();
      for (final preparo in fabricacaoService.planejarPreparos(produto, quantidade)) {
        fabricacoesDaVenda.add(
          Fabricacao(
            id: novoId(),
            data: data,
            produtoId: preparo.produtoId,
            quantidade: preparo.quantidade,
            fabricacaoPaiId: principalId,
            vendaId: venda.id,
            fichaTecnica: produtoPorId(preparo.produtoId)!.fichaTecnica
                .map((itemFicha) => itemFicha.copy())
                .toList(),
          ),
        );
      }
      fabricacoesDaVenda.add(
        Fabricacao(
          id: principalId,
          data: data,
          produtoId: produto.id,
          quantidade: quantidade,
          vendaId: venda.id,
          fichaTecnica: produto.fichaTecnica
              .map((itemFicha) => itemFicha.copy())
              .toList(),
        ),
      );
    }

    // Valida o saldo dos insumos antes de alterar qualquer coisa.
    if (fabricacoesDaVenda.isNotEmpty) {
      await fabricacaoService.salvarFabricacoes(fabricacoesDaVenda);
    }
    final atualizada = venda.copyWith(status: StatusVenda.emProducao);
    await db.transaction((transaction) => vendasService.gravarStatus(transaction, atualizada));
    vendas[indice] = atualizada;
    notificar();
  }

  /// Registra a entrega: a venda passa a "entregue" e o produto final sai do
  /// estoque na data da entrega.
  Future<void> entregarVenda(String vendaId, DateTime dataEntregue) async {
    final indice = vendasService.indiceDaVenda(vendaId);
    final venda = vendas[indice];
    if (!venda.proximosStatus.contains(StatusVenda.entregue)) {
      throw StateError(
        'Uma venda "${venda.status.label}" não pode ser marcada como '
        'entregue.',
      );
    }
    final entregue = venda.copyWith(
      status: StatusVenda.entregue,
      dataEntregue: dataEntregue,
    );
    final movimentosNovos = vendasService.criarMovimentos(entregue);
    estoqueService.validarSaldo(movimentosNovos);
    await db.transaction((transaction) async {
      await vendasService.gravarStatus(transaction, entregue);
      for (final movimento in movimentosNovos) {
        await transaction.insert('movimentos_estoque', movimentoParaLinha(movimento));
      }
    });
    vendas[indice] = entregue;
    movimentacoes.addAll(movimentosNovos);
    estoqueService.recalcular();
    await estoqueService.persistirProdutos();
    notificar();
  }

  /// Desfaz a entrega (devolvendo o produto ao estoque) ou reabre uma venda
  /// cancelada.
  Future<void> reabrirVenda(String vendaId) async {
    final indice = vendasService.indiceDaVenda(vendaId);
    final venda = vendas[indice];
    if (venda.status != StatusVenda.entregue &&
        venda.status != StatusVenda.cancelada) {
      throw StateError('Esta venda não está entregue nem cancelada.');
    }
    final temProducao = fabricacoes.any((f) => f.vendaId == venda.id);
    final destino = venda.tipo == TipoVenda.programada && temProducao
        ? (venda.entregue ? StatusVenda.aguardandoRetirada : StatusVenda.emProducao)
        : StatusVenda.pedido;
    final reaberta = venda.copyWith(status: destino, limparDataEntregue: true);

    final movimentosAntigos = vendasService.movimentosDa(venda);
    final idsAntigos = movimentosAntigos.map((m) => m.id).toSet();
    final produtosAfetados = movimentosAntigos.map((m) => m.produtoId).toSet();
    estoqueService.validarSaldo(const [], removerIds: idsAntigos);
    await db.transaction((transaction) async {
      for (final movimento in movimentosAntigos) {
        await transaction.delete(
          'movimentos_estoque',
          where: 'id = ?',
          whereArgs: [movimento.id],
        );
      }
      await vendasService.gravarStatus(transaction, reaberta);
    });
    movimentacoes.removeWhere((movimento) => idsAntigos.contains(movimento.id));
    vendas[indice] = reaberta;
    estoqueService.recalcular(
      produtosSemMovimentacoes: produtosAfetados,
    );
    await estoqueService.persistirProdutos();
    notificar();
  }
}
