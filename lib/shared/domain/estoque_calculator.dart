import '../models/operacao.dart';

/// Resultado de um movimento dentro da linha do tempo de um produto.
class PassoEstoque {
  final MovimentoEstoque movimento;

  /// Quantidade do movimento convertida para a unidade de estoque do produto.
  final double quantidade;
  final double saldoAntes;
  final double saldoApos;
  final double custoApos;

  /// Saída maior que o saldo disponível naquele momento.
  final bool violacao;

  const PassoEstoque({
    required this.movimento,
    required this.quantidade,
    required this.saldoAntes,
    required this.saldoApos,
    required this.custoApos,
    required this.violacao,
  });
}

/// Saldo e custo médio finais de um produto, com o passo a passo.
class SimulacaoEstoque {
  final double saldo;
  final double custoMedio;
  final List<PassoEstoque> passos;

  const SimulacaoEstoque({
    required this.saldo,
    required this.custoMedio,
    required this.passos,
  });

  Iterable<PassoEstoque> get violacoes => passos.where((p) => p.violacao);
}

/// Regras de estoque no tempo (sem acesso a banco ou tela).
///
/// O saldo de um produto é sempre o resultado de reproduzir as movimentações,
/// da mais antiga para a mais recente (data completa e, em empate, ordem de
/// registro):
/// - compra e produção somam ao saldo e recalculam o custo médio;
/// - venda, consumo na fabricação e saída para consumo subtraem do saldo;
/// - ajuste é soberano: define o saldo e o custo naquele momento, e nada que
///   aconteceu antes dele (inclusive lançamentos retroativos) altera o que vem
///   depois.
class EstoqueCalculator {
  /// Fator de conversão da unidade para a unidade base do seu grupo.
  final double Function(String unidadeId) fatorDaUnidade;

  const EstoqueCalculator(this.fatorDaUnidade);

  static bool ehEntrada(TipoMovimentoEstoque tipo) =>
      tipo == TipoMovimentoEstoque.compra ||
      tipo == TipoMovimentoEstoque.producao;

  /// Ordem das movimentações: pela data completa e, em empate, pelo id
  /// numérico, que indica a ordem de registro.
  static int comparar(MovimentoEstoque a, MovimentoEstoque b) {
    final dataComparacao = a.data.compareTo(b.data);
    return dataComparacao != 0 ? dataComparacao : _compararIds(a.id, b.id);
  }

  /// Compara ids numericamente (como texto, "9" ficaria depois de "10").
  static int _compararIds(String a, String b) {
    final numeroA = int.tryParse(a);
    final numeroB = int.tryParse(b);
    if (numeroA != null && numeroB != null) return numeroA.compareTo(numeroB);
    return a.compareTo(b);
  }

  SimulacaoEstoque simular({
    required String unidadeEstoqueId,
    required Iterable<MovimentoEstoque> movimentos,
  }) {
    final fatorEstoque = fatorDaUnidade(unidadeEstoqueId);
    final ordenados = movimentos.toList()..sort(comparar);

    var saldo = 0.0;
    var custo = 0.0;
    var valorEstoque = 0.0;
    final passos = <PassoEstoque>[];

    for (final movimento in ordenados) {
      final fatorMovimento = fatorDaUnidade(movimento.unidadeId);
      final quantidade = movimento.quantidade * fatorMovimento / fatorEstoque;
      final valorUnitario =
          movimento.valorUnitario * fatorEstoque / fatorMovimento;
      final saldoAntes = saldo;
      var violacao = false;

      if (movimento.tipo == TipoMovimentoEstoque.ajuste) {
        saldo = quantidade;
        custo = valorUnitario;
        valorEstoque = saldo * custo;
      } else if (ehEntrada(movimento.tipo)) {
        valorEstoque += quantidade * valorUnitario;
        saldo += quantidade;
        if (saldo > 0) custo = valorEstoque / saldo;
      } else {
        violacao = saldo + 1e-9 < quantidade;
        valorEstoque = (valorEstoque - quantidade * custo).clamp(
          0,
          double.infinity,
        );
        saldo -= quantidade;
      }
      if (saldo.abs() < 1e-9) saldo = 0;

      passos.add(
        PassoEstoque(
          movimento: movimento,
          quantidade: quantidade,
          saldoAntes: saldoAntes,
          saldoApos: saldo,
          custoApos: custo,
          violacao: violacao,
        ),
      );
    }

    return SimulacaoEstoque(saldo: saldo, custoMedio: custo, passos: passos);
  }
}
