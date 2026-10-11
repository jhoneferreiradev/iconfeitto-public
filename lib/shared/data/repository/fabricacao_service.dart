import '../../models/operacao.dart';
import '../../models/produto.dart';
import '../../models/tipo_item.dart';
import 'estoque_service.dart';
import 'repository_component.dart';
import 'row_mappers.dart';

/// Fabricações (cozinha): consumo de insumos, produção e planejamento dos
/// preparos da ficha técnica.
class FabricacaoService extends RepositoryComponent {
  final EstoqueService estoqueService;

  FabricacaoService(
    super.context, {
    required this.estoqueService,
  });

  Future<void> salvarFabricacao(Fabricacao fabricacao) =>
      salvarFabricacoes([fabricacao]);

  /// Salva várias fabricações na mesma transação. As fabricações devem estar
  /// ordenadas de modo que os itens intermediários venham antes do final.
  Future<void> salvarFabricacoes(List<Fabricacao> lista) async {
    final movimentosNovos = <MovimentoEstoque>[];
    final saldoSimulado = <String, double>{};
    final custoSimulado = <String, double>{};
    double saldoDe(Produto p) => saldoSimulado[p.id] ?? p.saldoEstoque;
    double custoDe(Produto p) => custoSimulado[p.id] ?? p.custoMedio;

    for (final fabricacao in lista) {
      final produto = produtoPorId(fabricacao.produtoId);
      if (produto == null) {
        throw StateError('O produto fabricado não foi encontrado.');
      }
      var custoTotal = 0.0;
      for (final item in fabricacao.fichaTecnica) {
        final ingrediente = produtoPorId(item.produtoIngredienteId);
        if (ingrediente == null) {
          throw StateError(
            'Um ingrediente da ficha técnica não foi encontrado.',
          );
        }
        final quantidade = item.quantidade * fabricacao.quantidade;
        final quantidadeEstoque =
            quantidade *
            unidadePorId(item.unidadeId).fatorParaBase /
            unidadePorId(ingrediente.unidadeEstoqueId).fatorParaBase;
        custoTotal += custoDe(ingrediente) * quantidadeEstoque;
        saldoSimulado[ingrediente.id] =
            saldoDe(ingrediente) - quantidadeEstoque;
        movimentosNovos.add(
          MovimentoEstoque(
            operacaoId: fabricacao.id,
            id: novoId(),
            data: fabricacao.data,
            produtoId: item.produtoIngredienteId,
            tipo: TipoMovimentoEstoque.consumoFabricacao,
            quantidade: quantidade,
            valorUnitario: 0,
            unidadeId: item.unidadeId,
          ),
        );
      }

      final custoUnitario = fabricacao.quantidade == 0
          ? 0.0
          : custoTotal / fabricacao.quantidade;
      final saldoAnterior = saldoDe(produto);
      final saldoPositivo = saldoAnterior > 0 ? saldoAnterior : 0.0;
      final novoSaldo = saldoPositivo + fabricacao.quantidade;
      custoSimulado[produto.id] = novoSaldo <= 0
          ? 0
          : (saldoPositivo * custoDe(produto) +
                    fabricacao.quantidade * custoUnitario) /
                novoSaldo;
      saldoSimulado[produto.id] = saldoAnterior + fabricacao.quantidade;
      movimentosNovos.add(
        MovimentoEstoque(
          operacaoId: fabricacao.id,
          id: novoId(),
          data: fabricacao.data,
          produtoId: fabricacao.produtoId,
          tipo: TipoMovimentoEstoque.producao,
          quantidade: fabricacao.quantidade,
          valorUnitario: custoUnitario,
          unidadeId: produto.unidadeEstoqueId,
        ),
      );
    }

    estoqueService.validarSaldo(movimentosNovos);
    await db.transaction((transaction) async {
      for (final fabricacao in lista) {
        await transaction.insert('fabricacoes', {
          'id': fabricacao.id,
          'data': fabricacao.data.toIso8601String(),
          'produtoId': fabricacao.produtoId,
          'quantidade': fabricacao.quantidade,
          'fabricacaoPaiId': fabricacao.fabricacaoPaiId,
          'vendaId': fabricacao.vendaId,
        });
        for (final item in fabricacao.fichaTecnica) {
          await transaction.insert('itens_fabricacao_registro', {
            'fabricacaoId': fabricacao.id,
            'produtoIngredienteId': item.produtoIngredienteId,
            'quantidade': item.quantidade,
            'unidadeId': item.unidadeId,
          });
        }
      }
      for (final movimento in movimentosNovos) {
        await transaction.insert(
          'movimentos_estoque',
          movimentoParaLinha(movimento),
        );
      }
    });
    fabricacoes.addAll(lista);
    movimentacoes.addAll(movimentosNovos);
    estoqueService.recalcular();
    await estoqueService.persistirProdutos();
    notificar();
  }

  /// Fabricações geradas a partir de [fabricacaoId] (preparos da ficha
  /// técnica), incluindo os níveis seguintes.
  List<Fabricacao> fabricacoesVinculadas(String fabricacaoId) {
    final vinculadas = <Fabricacao>[];
    final pendentes = [fabricacaoId];
    while (pendentes.isNotEmpty) {
      final paiId = pendentes.removeLast();
      for (final fabricacao in fabricacoes) {
        if (fabricacao.fabricacaoPaiId == paiId &&
            !vinculadas.any((v) => v.id == fabricacao.id)) {
          vinculadas.add(fabricacao);
          pendentes.add(fabricacao.id);
        }
      }
    }
    return vinculadas;
  }

  /// Exclui a fabricação e todas as vinculadas a ela.
  Future<void> excluirFabricacao(String fabricacaoId) async {
    final indice = fabricacoes.indexWhere((f) => f.id == fabricacaoId);
    if (indice < 0) return;

    final fabricacao = fabricacoes[indice];
    final paiId = fabricacao.fabricacaoPaiId;
    if (paiId != null && fabricacoes.any((f) => f.id == paiId)) {
      throw StateError(
        'Esta fabricação foi gerada por outra. '
        'Exclua a fabricação principal para removê-la.',
      );
    }

    final removidas = [fabricacao, ...fabricacoesVinculadas(fabricacaoId)];
    final idsDasFabricacoes = removidas.map((f) => f.id).toSet();
    final movimentosRemovidos = [
      for (final f in removidas) ..._movimentosDaFabricacao(f),
    ];
    final idsRemovidos = movimentosRemovidos.map((m) => m.id).toSet();
    final produtosAfetados = movimentosRemovidos
        .map((movimento) => movimento.produtoId)
        .toSet();
    estoqueService.validarSaldo(const [], removerIds: idsRemovidos);
    await db.transaction((transaction) async {
      for (final movimento in movimentosRemovidos) {
        await transaction.delete(
          'movimentos_estoque',
          where: 'id = ?',
          whereArgs: [movimento.id],
        );
      }
      for (final id in idsDasFabricacoes) {
        await transaction.delete(
          'itens_fabricacao_registro',
          where: 'fabricacaoId = ?',
          whereArgs: [id],
        );
        await transaction.delete(
          'fabricacoes',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });

    movimentacoes.removeWhere(
      (movimento) => idsRemovidos.contains(movimento.id),
    );
    fabricacoes.removeWhere((f) => idsDasFabricacoes.contains(f.id));
    estoqueService.recalcular(
      produtosSemMovimentacoes: produtosAfetados,
    );
    await estoqueService.persistirProdutos();
    notificar();
  }

  List<MovimentoEstoque> _movimentosDaFabricacao(Fabricacao fabricacao) {
    final esperado = fabricacao.fichaTecnica.length + 1;
    final vinculados = movimentacoes
        .where((movimento) => movimento.operacaoId == fabricacao.id)
        .toList();
    if (vinculados.isNotEmpty) {
      if (vinculados.length != esperado) {
        throw StateError(
          'Não foi possível localizar todas as movimentações da fabricação.',
        );
      }
      return vinculados;
    }

    // Registros antigos, sem vínculo com a operação.
    final candidatos = movimentacoes
        .where(
          (movimento) =>
              movimento.operacaoId == null &&
              movimento.data == fabricacao.data &&
              (movimento.tipo == TipoMovimentoEstoque.consumoFabricacao ||
                  movimento.tipo == TipoMovimentoEstoque.producao),
        )
        .toList();
    final correspondentes = <MovimentoEstoque>[];
    for (final item in fabricacao.fichaTecnica) {
      final indice = candidatos.indexWhere(
        (movimento) =>
            movimento.tipo == TipoMovimentoEstoque.consumoFabricacao &&
            movimento.produtoId == item.produtoIngredienteId &&
            movimento.unidadeId == item.unidadeId &&
            (movimento.quantidade - item.quantidade * fabricacao.quantidade)
                    .abs() <
                1e-9,
      );
      if (indice >= 0) correspondentes.add(candidatos.removeAt(indice));
    }
    final indiceProducao = candidatos.indexWhere(
      (movimento) =>
          movimento.tipo == TipoMovimentoEstoque.producao &&
          movimento.produtoId == fabricacao.produtoId &&
          (movimento.quantidade - fabricacao.quantidade).abs() < 1e-9,
    );
    if (indiceProducao >= 0) {
      correspondentes.add(candidatos.removeAt(indiceProducao));
    }
    if (correspondentes.length != esperado) {
      throw StateError(
        'Não foi possível localizar todas as movimentações da fabricação.',
      );
    }
    return correspondentes;
  }

  bool temFichaDeFabricacao(Produto? produto) =>
      produto != null &&
      TipoItem.tiposFabricacao.contains(produto.tipo) &&
      produto.possuiFichaTecnica &&
      produto.fichaTecnica.isNotEmpty;

  /// Preparos necessários para fabricar [quantidade] (na unidade de estoque)
  /// de [produto], em todos os níveis da ficha técnica. A lista vem na ordem
  /// de fabricação: um preparo só aparece depois dos preparos que ele usa, e
  /// cada preparo aparece uma única vez, com a quantidade somada.
  List<({String produtoId, double quantidade})> planejarPreparos(
    Produto produto,
    double quantidade,
  ) {
    final totais = <String, double>{};

    void acumular(Produto atual, double quantidadeAtual, List<String> caminho) {
      for (final itemFicha in atual.fichaTecnica) {
        final ingrediente = produtoPorId(itemFicha.produtoIngredienteId);
        if (!temFichaDeFabricacao(ingrediente)) continue;
        if (caminho.contains(ingrediente!.id)) {
          throw StateError(
            'A ficha técnica de "${ingrediente.nome}" usa ele mesmo '
            '(direta ou indiretamente).',
          );
        }
        final necessaria =
            itemFicha.quantidade *
            quantidadeAtual *
            unidadePorId(itemFicha.unidadeId).fatorParaBase /
            unidadePorId(ingrediente.unidadeEstoqueId).fatorParaBase;
        totais.update(
          ingrediente.id,
          (total) => total + necessaria,
          ifAbsent: () => necessaria,
        );
        acumular(ingrediente, necessaria, [...caminho, ingrediente.id]);
      }
    }

    acumular(produto, quantidade, [produto.id]);

    final ordem = <String>[];
    final visitados = <String>{};
    void visitar(Produto atual) {
      for (final itemFicha in atual.fichaTecnica) {
        final ingrediente = produtoPorId(itemFicha.produtoIngredienteId);
        if (!temFichaDeFabricacao(ingrediente)) continue;
        if (visitados.add(ingrediente!.id)) {
          visitar(ingrediente);
          ordem.add(ingrediente.id);
        }
      }
    }

    visitar(produto);
    return [
      for (final id in ordem)
        if ((totais[id] ?? 0) > 0) (produtoId: id, quantidade: totais[id]!),
    ];
  }
}
