import '../../../shared/models/forma_pagamento.dart';
import '../../../shared/models/lancamento_financeiro.dart';

enum PeriodoFinanceiro {
  esteMes('Este mês'),
  mesAnterior('Mês anterior'),
  ultimos30('Últimos 30 dias'),
  ultimos90('Últimos 90 dias'),
  proximos30('Próximos 30 dias'),
  esteAno('Este ano'),
  personalizado('Personalizado');

  const PeriodoFinanceiro(this.label);
  final String label;
}

/// Situação do lançamento usada para filtrar o que é "previsto".
enum SituacaoFinanceira {
  todas('Todas'),
  emAberto('Em aberto'),
  emAtraso('Em atraso'),
  quitadas('Quitadas');

  const SituacaoFinanceira(this.label);
  final String label;
}

/// Intervalo de datas (dias inteiros, inclusive nas duas pontas).
class IntervaloDatas {
  final DateTime inicio;
  final DateTime fim;

  const IntervaloDatas(this.inicio, this.fim);

  bool contem(DateTime data) {
    final dia = DateTime(data.year, data.month, data.day);
    return !dia.isBefore(inicio) && !dia.isAfter(fim);
  }

  int get dias => fim.difference(inicio).inDays + 1;
}

const Object _naoInformado = Object();

/// Filtros da análise financeira.
///
/// O período vale para o vencimento dos lançamentos (previsto) e para a data
/// das quitações (realizado). Origem, forma de pagamento e pessoa valem para
/// tudo; a situação vale apenas para o que é previsto no período.
class FiltroFinanceiro {
  final PeriodoFinanceiro periodo;
  final DateTime? inicioPersonalizado;
  final DateTime? fimPersonalizado;
  final TipoOperacaoOrigem? origem;
  final FormaPagamento? forma;
  final SituacaoFinanceira situacao;
  final PessoaFinanceiro? pessoa;

  const FiltroFinanceiro({
    this.periodo = PeriodoFinanceiro.esteMes,
    this.inicioPersonalizado,
    this.fimPersonalizado,
    this.origem,
    this.forma,
    this.situacao = SituacaoFinanceira.todas,
    this.pessoa,
  });

  /// Há algum filtro além do período padrão?
  bool get alterado =>
      periodo != PeriodoFinanceiro.esteMes ||
      origem != null ||
      forma != null ||
      pessoa != null ||
      situacao != SituacaoFinanceira.todas;

  FiltroFinanceiro copyWith({
    PeriodoFinanceiro? periodo,
    DateTime? inicioPersonalizado,
    DateTime? fimPersonalizado,
    Object? origem = _naoInformado,
    Object? forma = _naoInformado,
    SituacaoFinanceira? situacao,
    Object? pessoa = _naoInformado,
  }) => FiltroFinanceiro(
    periodo: periodo ?? this.periodo,
    inicioPersonalizado: inicioPersonalizado ?? this.inicioPersonalizado,
    fimPersonalizado: fimPersonalizado ?? this.fimPersonalizado,
    origem: identical(origem, _naoInformado)
        ? this.origem
        : origem as TipoOperacaoOrigem?,
    forma: identical(forma, _naoInformado)
        ? this.forma
        : forma as FormaPagamento?,
    situacao: situacao ?? this.situacao,
    pessoa: identical(pessoa, _naoInformado)
        ? this.pessoa
        : pessoa as PessoaFinanceiro?,
  );

  static DateTime _dia(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  IntervaloDatas intervalo(DateTime agora) {
    final hoje = _dia(agora);
    switch (periodo) {
      case PeriodoFinanceiro.esteMes:
        return IntervaloDatas(
          DateTime(hoje.year, hoje.month),
          DateTime(hoje.year, hoje.month + 1, 0),
        );
      case PeriodoFinanceiro.mesAnterior:
        return IntervaloDatas(
          DateTime(hoje.year, hoje.month - 1),
          DateTime(hoje.year, hoje.month, 0),
        );
      case PeriodoFinanceiro.ultimos30:
        return IntervaloDatas(
          DateTime(hoje.year, hoje.month, hoje.day - 29),
          hoje,
        );
      case PeriodoFinanceiro.ultimos90:
        return IntervaloDatas(
          DateTime(hoje.year, hoje.month, hoje.day - 89),
          hoje,
        );
      case PeriodoFinanceiro.proximos30:
        return IntervaloDatas(
          hoje,
          DateTime(hoje.year, hoje.month, hoje.day + 29),
        );
      case PeriodoFinanceiro.esteAno:
        return IntervaloDatas(
          DateTime(hoje.year),
          DateTime(hoje.year, 12, 31),
        );
      case PeriodoFinanceiro.personalizado:
        final inicio = _dia(
          inicioPersonalizado ?? DateTime(hoje.year, hoje.month),
        );
        final fim = _dia(
          fimPersonalizado ?? DateTime(hoje.year, hoje.month + 1, 0),
        );
        return fim.isBefore(inicio)
            ? IntervaloDatas(fim, inicio)
            : IntervaloDatas(inicio, fim);
    }
  }

  /// Período imediatamente anterior, usado para comparar (mês contra mês,
  /// ano contra ano ou o mesmo número de dias logo antes).
  IntervaloDatas intervaloAnterior(DateTime agora) {
    final atual = intervalo(agora);
    switch (periodo) {
      case PeriodoFinanceiro.esteMes:
      case PeriodoFinanceiro.mesAnterior:
        return IntervaloDatas(
          DateTime(atual.inicio.year, atual.inicio.month - 1),
          DateTime(atual.inicio.year, atual.inicio.month, 0),
        );
      case PeriodoFinanceiro.esteAno:
        return IntervaloDatas(
          DateTime(atual.inicio.year - 1),
          DateTime(atual.inicio.year - 1, 12, 31),
        );
      default:
        final fim = DateTime(
          atual.inicio.year,
          atual.inicio.month,
          atual.inicio.day - 1,
        );
        final inicio = DateTime(fim.year, fim.month, fim.day - (atual.dias - 1));
        return IntervaloDatas(inicio, fim);
    }
  }
}
