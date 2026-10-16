import '../../../core/utils/data_registro.dart';
import '../../domain/estoque_calculator.dart';
import '../../models/operacao.dart';
import 'repository_component.dart';
import 'row_mappers.dart';

/// Estoque: validação de saldo ao longo do tempo, recálculo de saldo e custo
/// médio, ajustes, saídas para consumo e histórico de movimentações.
class EstoqueService extends RepositoryComponent {
  EstoqueService(super.context);

  late final EstoqueCalculator _estoque = EstoqueCalculator(
    (unidadeId) => unidadePorId(unidadeId).fatorParaBase,
  );

  /// Garante que as movimentações propostas (e a retirada de [removerIds])
  /// não deixem nenhuma saída sem saldo. A conferência é feita na linha do
  /// tempo completa do produto, depois de aplicar tudo de uma vez; só valem
  /// como erro as saídas que ficariam sem saldo por causa desta mudança.
  void validarSaldo(
    List<MovimentoEstoque> movimentosPropostos, {
    Set<String> removerIds = const {},
  }) {
    final produtosAfetados = <String>{
      ...movimentosPropostos.map((movimento) => movimento.produtoId),
      for (final movimento in movimentacoes)
        if (removerIds.contains(movimento.id)) movimento.produtoId,
    };

    for (final produtoId in produtosAfetados) {
      final produto = produtoPorId(produtoId);
      if (produto == null) {
        throw StateError('Um produto da operação não foi encontrado.');
      }
      final atuais = movimentacoes
          .where((movimento) => movimento.produtoId == produtoId)
          .toList();
      final violacoesAntes = _estoque
          .simular(
            unidadeEstoqueId: produto.unidadeEstoqueId,
            movimentos: atuais,
          )
          .violacoes
          .map((passo) => passo.movimento.id)
          .toSet();
      final depois = _estoque.simular(
        unidadeEstoqueId: produto.unidadeEstoqueId,
        movimentos: [
          ...atuais.where((movimento) => !removerIds.contains(movimento.id)),
          ...movimentosPropostos.where(
            (movimento) => movimento.produtoId == produtoId,
          ),
        ],
      );
      for (final passo in depois.violacoes) {
        if (violacoesAntes.contains(passo.movimento.id)) continue;
        throw SaldoEstoqueInsuficienteException(
          produto: produto.nome,
          unidade: unidadePorId(produto.unidadeEstoqueId).sigla,
          disponivel: passo.saldoAntes < 0 ? 0 : passo.saldoAntes,
          solicitado: passo.quantidade,
          data: passo.movimento.data,
        );
      }
    }
  }

  /// Recalcula saldo e custo médio reproduzindo as movimentações de cada
  /// produto. Produtos sem movimentação só são recalculados se estiverem em
  /// [produtosSemMovimentacoes] (por exemplo, quando perderam a última).
  void recalcular({Set<String> produtosSemMovimentacoes = const {}}) {
    final produtosComMovimento = movimentacoes
        .map((movimento) => movimento.produtoId)
        .toSet();
    for (final produto in produtos) {
      if (!produtosComMovimento.contains(produto.id) &&
          !produtosSemMovimentacoes.contains(produto.id)) {
        continue;
      }
      final simulacao = _estoque.simular(
        unidadeEstoqueId: produto.unidadeEstoqueId,
        movimentos: movimentacoes.where(
          (movimento) => movimento.produtoId == produto.id,
        ),
      );
      produto.saldoEstoque = simulacao.saldo;
      produto.custoMedio = simulacao.custoMedio;
    }
  }

  /// Últimas movimentações do produto (da mais recente para a mais antiga),
  /// com o saldo e o custo médio resultantes depois de cada uma.
  List<PassoEstoque> ultimasMovimentacoes(String produtoId, {int limite = 10}) {
    final produto = produtoPorId(produtoId);
    if (produto == null) return const [];
    final simulacao = _estoque.simular(
      unidadeEstoqueId: produto.unidadeEstoqueId,
      movimentos: movimentacoes.where((m) => m.produtoId == produtoId),
    );
    return simulacao.passos.reversed.take(limite).toList();
  }

  // Helper methods for persistence
  Future<void> persistirProdutos() async {
    for (final produto in produtos) {
      await db.update(
        'produtos',
        {
          'saldoEstoque': produto.saldoEstoque,
          'custoMedio': produto.custoMedio,
        },
        where: 'id = ?',
        whereArgs: [produto.id],
      );
    }
  }

  /// Ajuste de saldo e custo médio. É uma operação soberana: define o saldo
  /// e o custo do produto no momento em que acontece, e o que veio antes dela
  /// (inclusive lançamentos retroativos) não altera o que vem depois.
  ///
  /// Sem [data] (ou com a data de hoje) o ajuste vale a partir de agora. Em
  /// uma data passada ele vale ao fim daquele dia.
  Future<void> ajustar(
    String produtoId,
    double novoSaldo,
    double novoCusto, {
    DateTime? data,
  }) async {
    final produto = produtoPorId(produtoId);
    if (produto == null) return;
    if (novoSaldo < 0 || novoCusto < 0) {
      throw StateError('Informe um saldo e um custo maiores ou iguais a zero.');
    }

    await _registrarMovimentoAvulso(
      MovimentoEstoque(
        id: novoId(),
        data: _momentoDoAjuste(data),
        produtoId: produtoId,
        tipo: TipoMovimentoEstoque.ajuste,
        quantidade: novoSaldo,
        valorUnitario: novoCusto,
        unidadeId: produto.unidadeEstoqueId,
      ),
    );
  }

  /// Saída de estoque para consumo próprio, na unidade de estoque do produto.
  /// A [data] pode ser retroativa; o horário é o do registro.
  Future<void> registrarConsumo(
    String produtoId,
    double quantidade, {
    DateTime? data,
  }) async {
    final produto = produtoPorId(produtoId);
    if (produto == null) return;
    if (quantidade <= 0) {
      throw StateError('Informe uma quantidade maior que zero.');
    }

    await _registrarMovimentoAvulso(
      MovimentoEstoque(
        id: novoId(),
        data: dataComHorarioDeRegistro(data ?? DateTime.now()),
        produtoId: produtoId,
        tipo: TipoMovimentoEstoque.consumo,
        quantidade: quantidade,
        valorUnitario: produto.custoMedio,
        unidadeId: produto.unidadeEstoqueId,
      ),
    );
  }

  DateTime _momentoDoAjuste(DateTime? data) {
    final agora = DateTime.now();
    if (data == null) return agora;
    final dia = DateTime(data.year, data.month, data.day);
    final hoje = DateTime(agora.year, agora.month, agora.day);
    if (dia.isAfter(hoje)) {
      throw StateError('A data do ajuste não pode ser futura.');
    }
    if (dia == hoje) return agora;
    return DateTime(dia.year, dia.month, dia.day, 23, 59, 59, 999);
  }

  Future<void> _registrarMovimentoAvulso(MovimentoEstoque movimento) async {
    validarSaldo([movimento]);
    await db.insert('movimentos_estoque', movimentoParaLinha(movimento));
    movimentacoes.add(movimento);
    recalcular();
    await persistirProdutos();
    notificar();
  }
}
