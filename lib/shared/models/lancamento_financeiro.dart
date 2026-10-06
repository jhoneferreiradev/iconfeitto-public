import 'forma_pagamento.dart';

import 'package:equatable/equatable.dart';

class Quitacao extends Equatable implements Comparable<Quitacao> {
  String id;
  DateTime dataQuitacao;
  double valorQuitado;
  FormaPagamento formaPagamento;
  String lancamentoId;

  Quitacao({
    required this.id,
    required this.dataQuitacao,
    required this.valorQuitado,
    required this.formaPagamento,
    required this.lancamentoId,
  });

  bool get isDinheiro => formaPagamento == FormaPagamento.dinheiro;
  bool get isCartaoCredito => formaPagamento == FormaPagamento.cartaoCredito;
  bool get isCartaoDebito => formaPagamento == FormaPagamento.cartaoDebito;
  bool get isPix => formaPagamento == FormaPagamento.pix;

  @override
  int compareTo(Quitacao other) {
    return dataQuitacao.compareTo(other.dataQuitacao);
  }

  @override
  List<Object?> get props => [
    id,
    dataQuitacao,
    valorQuitado,
    formaPagamento,
    lancamentoId,
  ];
}

enum TipoLancamentoFinanceiro { receita, despesa }

enum TipoOperacaoOriem { compra, venda }

enum StatusLancamentoFinanceiro {
  pendente,
  quitado,
  parcialmenteQuitado,
  encerrado,
}

enum TipoPessoaFinanceiro {
  cliente,
  fornecedor,
  cartaoCredito,
  bandeiraCartaoCredito,
}

class LancamentoFinanceiro extends Equatable {
  String id;
  TipoPessoaFinanceiro tipoPessoaFinanceiro;
  String pessoaId;
  TipoLancamentoFinanceiro tipoLancamento;
  LancamentoFinanceiro? lancamentoPai;
  StatusLancamentoFinanceiro statusLancamento;
  TipoOperacaoOriem tipoOperacaoOriem;
  DateTime dataCriacao;
  DateTime dataVencimento;
  String descricao;
  double valor;
  String? observacao;
  int operacaoId;
  List<Quitacao> quitacoes;

  LancamentoFinanceiro({
    required this.id,
    required this.tipoPessoaFinanceiro,
    required this.pessoaId,
    required this.tipoLancamento,
    required this.dataCriacao,
    required this.dataVencimento,
    required this.descricao,
    required this.valor,
    this.observacao,
    this.lancamentoPai,
    required this.statusLancamento,
    required this.operacaoId,
    required this.tipoOperacaoOriem,
    this.quitacoes = const [],
  });

  bool get isPendente =>
      statusLancamento == StatusLancamentoFinanceiro.pendente;
  bool get isQuitado => statusLancamento == StatusLancamentoFinanceiro.quitado;
  bool get isParcialmenteQuitado =>
      statusLancamento == StatusLancamentoFinanceiro.parcialmenteQuitado;
  bool get isEncerrado =>
      statusLancamento == StatusLancamentoFinanceiro.encerrado;

  List<Quitacao> get quitacoesOrdenadas {
    final lista = List<Quitacao>.from(quitacoes);
    lista.sort();
    return lista;
  }

  bool get hasQuitacoes => quitacoes.isNotEmpty;
  double get valorQuitado =>
      quitacoes.fold(0.0, (sum, quitacao) => sum + quitacao.valorQuitado);
  double get valorRestante => valor - valorQuitado;
  DateTime get dataUltimaQuitacao =>
      quitacoes.isEmpty ? dataCriacao : quitacoesOrdenadas.last.dataQuitacao;

  bool get isAtrasado => DateTime.now().isAfter(dataVencimento) && !isQuitado;
  bool get isVencido => DateTime.now().isAfter(dataVencimento);

  bool get isCliente => tipoPessoaFinanceiro == TipoPessoaFinanceiro.cliente;
  bool get isFornecedor =>
      tipoPessoaFinanceiro == TipoPessoaFinanceiro.fornecedor;
  bool get isCartaoCredito =>
      tipoPessoaFinanceiro == TipoPessoaFinanceiro.cartaoCredito;
  bool get isBandeiraCartaoCredito =>
      tipoPessoaFinanceiro == TipoPessoaFinanceiro.bandeiraCartaoCredito;

  void atualizarQuitacao(int idxQuitacao, Quitacao quitacao) {
    quitacoes[idxQuitacao] = quitacao;
    _atualizarStatusAposQuitacao();
  }

  void adicionarQuitacao(Quitacao quitacao) {
    quitacoes.add(quitacao);
    _atualizarStatusAposQuitacao();
  }

  void _atualizarStatusAposQuitacao() {
    if (valorQuitado >= valor) {
      statusLancamento = StatusLancamentoFinanceiro.quitado;
    } else if (valorQuitado > 0) {
      statusLancamento = StatusLancamentoFinanceiro.parcialmenteQuitado;
    } else {
      statusLancamento = StatusLancamentoFinanceiro.pendente;
    }
  }

  @override
  List<Object?> get props => [
    id,
    tipoPessoaFinanceiro,
    pessoaId,
    tipoLancamento,
    lancamentoPai,
    statusLancamento,
    tipoOperacaoOriem,
    dataCriacao,
    dataVencimento,
    descricao,
    valor,
    observacao,
    operacaoId,
    quitacoes,
  ];
}
