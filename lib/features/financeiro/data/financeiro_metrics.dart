import '../../../shared/models/lancamento_financeiro.dart';

/// Indicadores financeiros calculados a partir dos lançamentos e das quitações.
class ResumoFinanceiro {
  /// Saldo ainda a receber / a pagar (já descontadas as quitações).
  final double aReceber;
  final double aPagar;

  /// Parte do saldo acima cujo vencimento já passou.
  final double aReceberEmAtraso;
  final double aPagarEmAtraso;

  /// Quitações (encerramentos) de receitas e despesas no mês e no anterior.
  final double recebidoMes;
  final double pagoMes;
  final double recebidoMesAnterior;
  final double pagoMesAnterior;

  /// Tudo o que já foi recebido menos tudo o que já foi pago (quitações).
  final double saldoRealizado;

  const ResumoFinanceiro({
    required this.aReceber,
    required this.aPagar,
    required this.aReceberEmAtraso,
    required this.aPagarEmAtraso,
    required this.recebidoMes,
    required this.pagoMes,
    required this.recebidoMesAnterior,
    required this.pagoMesAnterior,
    required this.saldoRealizado,
  });

  double get saldoPrevisto => aReceber - aPagar;
  double get totalEmAtraso => aReceberEmAtraso + aPagarEmAtraso;

  factory ResumoFinanceiro.calcular({
    required Iterable<LancamentoFinanceiro> lancamentos,
    required DateTime agora,
  }) {
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final inicioMes = DateTime(agora.year, agora.month);
    final inicioMesAnterior = DateTime(agora.year, agora.month - 1);
    bool noMes(DateTime data, DateTime inicio) =>
        data.year == inicio.year && data.month == inicio.month;

    var aReceber = 0.0;
    var aPagar = 0.0;
    var aReceberEmAtraso = 0.0;
    var aPagarEmAtraso = 0.0;
    for (final lancamento in lancamentos) {
      if (lancamento.isEncerrado) continue;
      final restante = lancamento.valorRestante;
      if (restante <= 0.005) continue;
      final vencimento = lancamento.dataVencimento;
      final emAtraso = DateTime(
        vencimento.year,
        vencimento.month,
        vencimento.day,
      ).isBefore(hoje);
      if (lancamento.isReceita) {
        aReceber += restante;
        if (emAtraso) aReceberEmAtraso += restante;
      } else {
        aPagar += restante;
        if (emAtraso) aPagarEmAtraso += restante;
      }
    }

    var recebidoMes = 0.0;
    var pagoMes = 0.0;
    var recebidoMesAnterior = 0.0;
    var pagoMesAnterior = 0.0;
    var saldoRealizado = 0.0;
    for (final lancamento in lancamentos) {
      for (final quitacao in lancamento.quitacoes) {
        final valor = quitacao.valorQuitado;
        saldoRealizado += lancamento.isReceita ? valor : -valor;
        if (noMes(quitacao.dataQuitacao, inicioMes)) {
          if (lancamento.isReceita) {
            recebidoMes += valor;
          } else {
            pagoMes += valor;
          }
        } else if (noMes(quitacao.dataQuitacao, inicioMesAnterior)) {
          if (lancamento.isReceita) {
            recebidoMesAnterior += valor;
          } else {
            pagoMesAnterior += valor;
          }
        }
      }
    }

    return ResumoFinanceiro(
      aReceber: aReceber,
      aPagar: aPagar,
      aReceberEmAtraso: aReceberEmAtraso,
      aPagarEmAtraso: aPagarEmAtraso,
      recebidoMes: recebidoMes,
      pagoMes: pagoMes,
      recebidoMesAnterior: recebidoMesAnterior,
      pagoMesAnterior: pagoMesAnterior,
      saldoRealizado: saldoRealizado,
    );
  }
}
