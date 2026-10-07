/// Como a bandeira/banco cobra pelo recebimento no cartão.
enum TipoTaxaBandeira {
  percentual('Percentual (%)'),
  valorFixo('Valor fixo (R\$)');

  const TipoTaxaBandeira(this.label);
  final String label;
}

/// Bandeira do cartão (Visa, Master...). A [taxa] é um percentual (ex.: 2,99)
/// ou um valor fixo em reais, conforme [tipoTaxa]; [diasCompensacao] é quantos
/// dias o valor leva para compensar e cair na conta (sem limite).
class BandeiraCartaoCredito {
  final String id;
  final String nome;
  final double taxa;
  final TipoTaxaBandeira tipoTaxa;
  final int diasCompensacao;

  const BandeiraCartaoCredito({
    required this.id,
    required this.nome,
    required this.taxa,
    this.tipoTaxa = TipoTaxaBandeira.percentual,
    this.diasCompensacao = 1,
  });

  /// Data em que uma parcela com [vencimento] compensa na conta.
  DateTime calcularCompensacao(DateTime vencimento) {
    final dia = DateTime(vencimento.year, vencimento.month, vencimento.day);
    return dia.add(Duration(days: diasCompensacao));
  }

  /// Taxa de uma parcela de [valor], arredondada para centavos. O percentual
  /// incide sobre cada parcela; o valor fixo é cobrado uma única vez por
  /// venda, na primeira parcela.
  double calcularTaxa(double valor, {bool primeiraParcela = true}) {
    switch (tipoTaxa) {
      case TipoTaxaBandeira.percentual:
        return (valor * taxa).round() / 100;
      case TipoTaxaBandeira.valorFixo:
        return primeiraParcela ? (taxa * 100).round() / 100 : 0;
    }
  }
}

/// Cartão de crédito próprio (usado nas compras). A fatura vence todo mês no
/// [diaVencimento] e fecha [diasFechamento] dias antes do vencimento.
class CartaoCredito {
  final String id;
  final String nome;
  final int diaVencimento;
  final int diasFechamento;

  const CartaoCredito({
    required this.id,
    required this.nome,
    this.diaVencimento = 10,
    this.diasFechamento = 7,
  });

  /// Dia [dia] do mês [mes]/[ano]; em meses mais curtos (ex.: 29, 30 ou 31
  /// em fevereiro) usa o último dia do mês, evitando que o `DateTime` "vire"
  /// para o mês seguinte.
  static DateTime diaNoMes(int ano, int mes, int dia) {
    final normalizado = DateTime(ano, mes);
    final ultimoDia = DateTime(normalizado.year, normalizado.month + 1, 0).day;
    return DateTime(
      normalizado.year,
      normalizado.month,
      dia > ultimoDia ? ultimoDia : dia,
    );
  }

  /// Vencimento da fatura em que a compra feita em [dataCompra] entra.
  /// Compras no dia do fechamento (ou depois) caem na fatura seguinte.
  DateTime vencimentoDaFatura(DateTime dataCompra) {
    final compra = DateTime(dataCompra.year, dataCompra.month, dataCompra.day);
    // Começa um mês antes: com fechamento longo, a fatura do mês anterior
    // ainda pode estar aberta para a compra.
    for (var deslocamento = -1; deslocamento <= 12; deslocamento++) {
      final vencimento = diaNoMes(
        compra.year,
        compra.month + deslocamento,
        diaVencimento,
      );
      final fechamento = vencimento.subtract(Duration(days: diasFechamento));
      if (compra.isBefore(fechamento)) return vencimento;
    }
    return diaNoMes(compra.year, compra.month + 1, diaVencimento);
  }

  /// Vencimento da parcela [indice] (0 = primeira) de uma compra feita em
  /// [dataCompra]: uma parcela por fatura.
  DateTime vencimentoDaParcela(DateTime dataCompra, int indice) {
    final primeira = vencimentoDaFatura(dataCompra);
    return diaNoMes(primeira.year, primeira.month + indice, diaVencimento);
  }
}
