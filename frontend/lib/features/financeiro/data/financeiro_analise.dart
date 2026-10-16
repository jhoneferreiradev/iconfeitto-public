import '../../../shared/models/lancamento_financeiro.dart';
import 'financeiro_filtro.dart';

/// Rótulo com valor (fatia de pizza, linha de ranking...).
class ParteDoTotal {
  final String rotulo;
  final double valor;

  const ParteDoTotal(this.rotulo, this.valor);
}

class PontoMensal {
  final DateTime mes;
  final double recebido;
  final double pago;

  /// Resultado (recebido - pago) acumulado até este mês.
  final double saldoAcumulado;

  const PontoMensal({
    required this.mes,
    required this.recebido,
    required this.pago,
    required this.saldoAcumulado,
  });

  double get resultado => recebido - pago;
}

class FaixaVencimento {
  final String rotulo;
  final double aReceber;
  final double aPagar;

  const FaixaVencimento(this.rotulo, this.aReceber, this.aPagar);
}

/// Indicadores financeiros calculados a partir dos lançamentos e do filtro.
///
/// Dois olhares:
/// - **Carteira**: o que ainda está em aberto (a receber/a pagar), de todos os
///   vencimentos; respeita origem, forma e pessoa.
/// - **Período**: o previsto (vencimentos no período) e o realizado
///   (quitações no período), além de custos financeiros e indicadores.
class AnaliseFinanceira {
  final FiltroFinanceiro filtro;
  final IntervaloDatas intervalo;

  // Carteira sem considerar o período
  final double recebidoTodoPeriodo;
  final double pagoTodoPeriodo;
  final double saldoTodoPeriodo;
  final double aReceberTodoPeriodo;
  final double aPagarTodoPeriodo;
  final double aReceberEmAtrasoTodoPeriodo;
  final double aPagarEmAtrasoTodoPeriodo;

  // Carteira considerando apenas o período filtrado
  final double aReceberDentroDoPeriodo;
  final double aPagarDentroDoPeriodo;
  final double aReceberEmAtrasoDentroDoPeriodo;
  final double aPagarEmAtrasoDentroDoPeriodo;

  // Período: previsto
  final double previstoReceitas;
  final double previstoDespesas;
  final int quantidadeLancamentos;

  // Período: realizado
  final double recebido;
  final double pago;
  final double recebidoAnterior;
  final double pagoAnterior;

  // Custos financeiros do período
  final double taxasImpostos;
  final double descontos;
  final double acrescimos;

  // Indicadores (nulos quando não há base de cálculo)
  final double? taxaDeRecebimento;
  final double? inadimplencia;
  final double? prazoMedioRecebimento;

  // Séries e rankings
  final List<PontoMensal> fluxoMensal;
  final List<FaixaVencimento> faixasVencimento;
  final List<ParteDoTotal> recebidoPorForma;
  final List<ParteDoTotal> receitasPorPessoa;
  final List<ParteDoTotal> despesasPorPessoa;
  final List<ParteDoTotal> taxasPorPessoa;

  const AnaliseFinanceira({
    required this.filtro,
    required this.intervalo,

    required this.recebidoTodoPeriodo,
    required this.pagoTodoPeriodo,
    required this.saldoTodoPeriodo,

    required this.aReceberTodoPeriodo,
    required this.aPagarTodoPeriodo,
    required this.aReceberEmAtrasoTodoPeriodo,
    required this.aPagarEmAtrasoTodoPeriodo,
    required this.aReceberDentroDoPeriodo,
    required this.aPagarDentroDoPeriodo,
    required this.aReceberEmAtrasoDentroDoPeriodo,
    required this.aPagarEmAtrasoDentroDoPeriodo,
    required this.previstoReceitas,
    required this.previstoDespesas,
    required this.quantidadeLancamentos,
    required this.recebido,
    required this.pago,
    required this.recebidoAnterior,
    required this.pagoAnterior,
    required this.taxasImpostos,
    required this.descontos,
    required this.acrescimos,
    required this.taxaDeRecebimento,
    required this.inadimplencia,
    required this.prazoMedioRecebimento,
    required this.fluxoMensal,
    required this.faixasVencimento,
    required this.recebidoPorForma,
    required this.receitasPorPessoa,
    required this.despesasPorPessoa,
    required this.taxasPorPessoa,
  });

  double get saldoPrevistoTodoPeriodo =>
      aReceberTodoPeriodo - aPagarTodoPeriodo;
  double get totalEmAtrasoTodoPeriodo =>
      aReceberEmAtrasoTodoPeriodo + aPagarEmAtrasoTodoPeriodo;
  double get totalEmAtrasoDentroDoPeriodo =>
      aReceberEmAtrasoDentroDoPeriodo + aPagarEmAtrasoDentroDoPeriodo;
  double get totalEmAbertoDentroDoPeriodo =>
      aReceberEmAtrasoDentroDoPeriodo + aPagarEmAtrasoDentroDoPeriodo;
  double get saldoPrevistoDentroDoPeriodo =>
      aReceberDentroDoPeriodo - aPagarDentroDoPeriodo;
  double get resultadoRealizado => recebido - pago;
  double get resultadoAnterior => recebidoAnterior - pagoAnterior;
  double get resultadoPrevisto => previstoReceitas - previstoDespesas;

  static DateTime _dia(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  static const _limite = 0.005;

  static double _entreZeroEUm(double valor) =>
      valor < 0 ? 0 : (valor > 1 ? 1 : valor);

  static AnaliseFinanceira calcular({
    required Iterable<LancamentoFinanceiro> lancamentos,
    FiltroFinanceiro filtro = const FiltroFinanceiro(),
    required DateTime agora,
  }) {
    final hoje = _dia(agora);
    final intervalo = filtro.intervalo(agora);
    final anterior = filtro.intervaloAnterior(agora);

    bool passaBase(LancamentoFinanceiro l) {
      final pessoa = filtro.pessoa;
      return (filtro.origem == null || l.tipoOperacaoOriem == filtro.origem) &&
          (pessoa == null ||
              (l.pessoaFinanceiro.id == pessoa.id &&
                  l.pessoaFinanceiro.tipoPessoaFinanceiro ==
                      pessoa.tipoPessoaFinanceiro));
    }

    bool passaForma(LancamentoFinanceiro l) =>
        filtro.forma == null || l.formaPagamento == filtro.forma;
    bool emAberto(LancamentoFinanceiro l) =>
        !l.isEncerrado && l.valorRestante > _limite;
    bool vencido(LancamentoFinanceiro l) =>
        _dia(l.dataVencimento).isBefore(hoje);
    bool passaSituacao(LancamentoFinanceiro l) => switch (filtro.situacao) {
      SituacaoFinanceira.todas => true,
      SituacaoFinanceira.emAberto => emAberto(l),
      SituacaoFinanceira.emAtraso => emAberto(l) && vencido(l),
      SituacaoFinanceira.quitadas => !emAberto(l),
    };

    final base = lancamentos.where(passaBase).toList();

    // Carteira e faixas de vencimento (tudo o que está em aberto).
    var aReceberTodoPeriodo = 0.0,
        aPagarTodoPeriodo = 0.0,
        aReceberAtrasoTodoPeriodo = 0.0,
        aPagarAtrasoTodoPeriodo = 0.0,
        recebidoTodoPeriodo = 0.0,
        pagoTodoPeriodo = 0.0,
        saldoTodoPeriodo = 0.0;
    final faixasReceber = List<double>.filled(6, 0);
    final faixasPagar = List<double>.filled(6, 0);
    int indiceFaixa(LancamentoFinanceiro l) {
      final dias = _dia(l.dataVencimento).difference(hoje).inDays;
      if (dias < 0) return 0;
      if (dias <= 7) return 1;
      if (dias <= 15) return 2;
      if (dias <= 30) return 3;
      if (dias <= 60) return 4;
      return 5;
    }

    for (final l in base.where(passaForma)) {
      if (!emAberto(l)) continue;
      final restante = l.valorRestante;
      final faixa = indiceFaixa(l);
      if (l.isReceita) {
        aReceberTodoPeriodo += restante;
        faixasReceber[faixa] += restante;
        if (vencido(l)) aReceberAtrasoTodoPeriodo += restante;
      } else {
        aPagarTodoPeriodo += restante;
        faixasPagar[faixa] += restante;
        if (vencido(l)) aPagarAtrasoTodoPeriodo += restante;
      }
    }

    for (final l in base.where(passaForma).where((l) => l.hasQuitacoes)) {
      if (l.isReceita) {
        recebidoTodoPeriodo += l.valorQuitado;
      } else {
        pagoTodoPeriodo += l.valorQuitado;
      }
    }
    saldoTodoPeriodo = recebidoTodoPeriodo - pagoTodoPeriodo;

    const rotulosFaixas = [
      'Atrasado',
      '0-7 dias',
      '8-15 dias',
      '16-30 dias',
      '31-60 dias',
      '60+ dias',
    ];

    // Previsto no período (vencimento dentro do intervalo).
    final doPeriodo = base
        .where(passaForma)
        .where((l) => intervalo.contem(l.dataVencimento))
        .where(passaSituacao)
        .toList();
    var previstoReceitas = 0.0,
        previstoDespesas = 0.0,
        aReceberDentroDoPeriodo = 0.0,
        aPagarDentroDoPeriodo = 0.0,
        aReceberEmAtrasoDentroDoPeriodo = 0.0,
        aPagarEmAtrasoDentroDoPeriodo = 0.0;
    var taxas = 0.0, descontos = 0.0, acrescimos = 0.0;
    var abertoReceitas = 0.0, atrasadoReceitas = 0.0;
    final receitasPorPessoa = <String, double>{};
    final despesasPorPessoa = <String, double>{};
    final taxasPorPessoa = <String, double>{};
    for (final l in doPeriodo) {
      final nome = l.pessoaFinanceiro.nome;
      taxas += l.valorTaxasImpostos;
      descontos += l.valorDesconto;
      acrescimos += l.valorAcrescimo;
      if (l.isReceita) {
        previstoReceitas += l.valorTotal;
        receitasPorPessoa.update(
          nome,
          (v) => v + l.valorTotal,
          ifAbsent: () => l.valorTotal,
        );
        if (l.valorTaxasImpostos > _limite) {
          taxasPorPessoa.update(
            nome,
            (v) => v + l.valorTaxasImpostos,
            ifAbsent: () => l.valorTaxasImpostos,
          );
        }
        if (emAberto(l)) {
          abertoReceitas += l.valorRestante;
          aReceberDentroDoPeriodo += l.valorRestante;
          if (vencido(l)) {
            atrasadoReceitas += l.valorRestante;
            aReceberEmAtrasoDentroDoPeriodo += l.valorRestante;
          }
        }
      } else {
        previstoDespesas += l.valorTotal;
        despesasPorPessoa.update(
          nome,
          (v) => v + l.valorTotal,
          ifAbsent: () => l.valorTotal,
        );
        aPagarDentroDoPeriodo += l.valorRestante;
        if (vencido(l)) aPagarEmAtrasoDentroDoPeriodo += l.valorRestante;
      }
    }

    // Realizado: quitações dentro do período (e do período anterior).
    var recebido = 0.0, pago = 0.0, recebidoAnt = 0.0, pagoAnt = 0.0;
    var pesoPrazo = 0.0, somaPrazo = 0.0;
    final porForma = <String, double>{};
    final quitacoesDaBase = <({LancamentoFinanceiro l, Quitacao q})>[];
    for (final l in base) {
      for (final q in l.quitacoes) {
        if (filtro.forma != null && q.formaPagamento != filtro.forma) continue;
        quitacoesDaBase.add((l: l, q: q));
        if (intervalo.contem(q.dataQuitacao)) {
          if (l.isReceita) {
            recebido += q.valorQuitado;
            porForma.update(
              q.formaPagamento.label,
              (v) => v + q.valorQuitado,
              ifAbsent: () => q.valorQuitado,
            );
            final dias = _dia(q.dataQuitacao)
                .difference(_dia(l.dataCriacao))
                .inDays;
            pesoPrazo += q.valorQuitado;
            somaPrazo += dias * q.valorQuitado;
          } else {
            pago += q.valorQuitado;
          }
        } else if (anterior.contem(q.dataQuitacao)) {
          if (l.isReceita) {
            recebidoAnt += q.valorQuitado;
          } else {
            pagoAnt += q.valorQuitado;
          }
        }
      }
    }

    // Fluxo mensal: pelo menos 6 meses, terminando no mês final do período.
    final mesFinal = DateTime(intervalo.fim.year, intervalo.fim.month);
    final mesesDoPeriodo =
        (intervalo.fim.year - intervalo.inicio.year) * 12 +
        intervalo.fim.month -
        intervalo.inicio.month +
        1;
    final quantidadeMeses = mesesDoPeriodo < 6
        ? 6
        : (mesesDoPeriodo > 12 ? 12 : mesesDoPeriodo);
    final pontos = <PontoMensal>[];
    var acumulado = 0.0;
    for (var i = quantidadeMeses - 1; i >= 0; i--) {
      final mes = DateTime(mesFinal.year, mesFinal.month - i);
      var recebidoMes = 0.0, pagoMes = 0.0;
      for (final item in quitacoesDaBase) {
        final data = item.q.dataQuitacao;
        if (data.year != mes.year || data.month != mes.month) continue;
        if (item.l.isReceita) {
          recebidoMes += item.q.valorQuitado;
        } else {
          pagoMes += item.q.valorQuitado;
        }
      }
      acumulado += recebidoMes - pagoMes;
      pontos.add(
        PontoMensal(
          mes: mes,
          recebido: recebidoMes,
          pago: pagoMes,
          saldoAcumulado: acumulado,
        ),
      );
    }

    List<ParteDoTotal> ordenar(Map<String, double> mapa, {int? limite}) {
      final lista =
          mapa.entries.map((e) => ParteDoTotal(e.key, e.value)).toList()
            ..sort((a, b) => b.valor.compareTo(a.valor));
      return limite == null ? lista : lista.take(limite).toList();
    }

    return AnaliseFinanceira(
      filtro: filtro,
      intervalo: intervalo,

      recebidoTodoPeriodo: recebidoTodoPeriodo,
      pagoTodoPeriodo: pagoTodoPeriodo,
      saldoTodoPeriodo: saldoTodoPeriodo,

      aReceberTodoPeriodo: aReceberTodoPeriodo,
      aPagarTodoPeriodo: aPagarTodoPeriodo,
      aReceberEmAtrasoTodoPeriodo: aReceberAtrasoTodoPeriodo,
      aPagarEmAtrasoTodoPeriodo: aPagarAtrasoTodoPeriodo,

      aReceberDentroDoPeriodo: aReceberDentroDoPeriodo,
      aPagarDentroDoPeriodo: aPagarDentroDoPeriodo,
      aReceberEmAtrasoDentroDoPeriodo: aReceberEmAtrasoDentroDoPeriodo,
      aPagarEmAtrasoDentroDoPeriodo: aPagarEmAtrasoDentroDoPeriodo,

      previstoReceitas: previstoReceitas,
      previstoDespesas: previstoDespesas,
      quantidadeLancamentos: doPeriodo.length,
      recebido: recebido,
      pago: pago,
      recebidoAnterior: recebidoAnt,
      pagoAnterior: pagoAnt,
      taxasImpostos: taxas,
      descontos: descontos,
      acrescimos: acrescimos,
      taxaDeRecebimento: previstoReceitas > _limite
          ? _entreZeroEUm(
              (previstoReceitas - abertoReceitas) / previstoReceitas,
            )
          : null,
      inadimplencia: previstoReceitas > _limite
          ? _entreZeroEUm(atrasadoReceitas / previstoReceitas)
          : null,
      prazoMedioRecebimento: pesoPrazo > _limite ? somaPrazo / pesoPrazo : null,
      fluxoMensal: pontos,
      faixasVencimento: [
        for (var i = 0; i < rotulosFaixas.length; i++)
          FaixaVencimento(rotulosFaixas[i], faixasReceber[i], faixasPagar[i]),
      ],
      recebidoPorForma: ordenar(porForma),
      receitasPorPessoa: ordenar(receitasPorPessoa, limite: 5),
      despesasPorPessoa: ordenar(despesasPorPessoa, limite: 5),
      taxasPorPessoa: ordenar(taxasPorPessoa, limite: 5),
    );
  }
}
