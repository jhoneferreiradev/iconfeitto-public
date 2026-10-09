// ignore_for_file: must_be_immutable

import 'package:equatable/equatable.dart';

import 'forma_pagamento.dart';

class PessoaFinanceiro extends Equatable {
  final String id;
  final String nome;
  final TipoPessoaFinanceiro tipoPessoaFinanceiro;

  const PessoaFinanceiro({
    required this.id,
    required this.nome,
    required this.tipoPessoaFinanceiro,
  });

  @override
  List<Object?> get props => [id, nome, tipoPessoaFinanceiro];
}

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

enum TipoLancamentoFinanceiro {
  receita("Receita"),
  despesa("Despesa");

  const TipoLancamentoFinanceiro(this.label);
  final String label;
}

extension TipoLancamentoFinanceiroExtension on TipoLancamentoFinanceiro {
  String get label {
    switch (this) {
      case TipoLancamentoFinanceiro.receita:
        return "Receita";
      case TipoLancamentoFinanceiro.despesa:
        return "Despesa";
    }
  }
}

enum TipoOperacaoOrigem { compra, venda, avulso }

enum StatusLancamentoFinanceiro {
  pendente("Pendente"),
  quitado("Quitado"),
  parcialmenteQuitado("Parcialmente quitado"),
  encerrado("Encerrado");

  const StatusLancamentoFinanceiro(this.label);
  final String label;
}

enum TipoPessoaFinanceiro {
  cliente("Cliente"),
  fornecedor("Fornecedor"),
  cartaoCredito("Cartão de crédito"),
  bandeiraCartaoCredito("Bandeira"),
  empresaCorrente("Empresa");

  const TipoPessoaFinanceiro(this.label);
  final String label;
}

class LancamentoFinanceiro extends Equatable {
  String id;
  PessoaFinanceiro pessoaFinanceiro;
  TipoLancamentoFinanceiro tipoLancamento;
  LancamentoFinanceiro? lancamentoPai;
  StatusLancamentoFinanceiro statusLancamento;
  TipoOperacaoOrigem tipoOperacaoOriem;
  DateTime dataCriacao;
  DateTime dataVencimento;
  String descricao;
  double valorLancamento;
  double valorDesconto;
  double valorAcrescimo;
  double valorTaxasImpostos;
  DateTime? dataCompensacao;
  String? observacao;
  String operacaoOrigemId;
  FormaPagamento? formaPagamento;
  List<Quitacao> quitacoes;

  LancamentoFinanceiro({
    required this.id,
    required this.pessoaFinanceiro,
    required this.tipoLancamento,
    required this.dataCriacao,
    required this.dataVencimento,
    required this.descricao,
    required this.valorLancamento,
    this.valorDesconto = 0,
    this.valorAcrescimo = 0,
    this.valorTaxasImpostos = 0,
    this.dataCompensacao,
    this.observacao,
    this.lancamentoPai,
    required this.statusLancamento,
    required this.operacaoOrigemId,
    required this.tipoOperacaoOriem,
    this.formaPagamento,
    List<Quitacao>? quitacoes,
  }) : quitacoes = quitacoes ?? <Quitacao>[];

  bool get isReceita => tipoLancamento == TipoLancamentoFinanceiro.receita;
  bool get isDespesa => tipoLancamento == TipoLancamentoFinanceiro.despesa;

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

  /// Valor a pagar/receber: valor menos desconto, mais acréscimo, com as taxas
  /// e impostos reduzindo a receita (o que se recebe) e somando à despesa.
  double get valorTotal => calcularValorTotal(
    tipo: tipoLancamento,
    valor: valorLancamento,
    desconto: valorDesconto,
    acrescimo: valorAcrescimo,
    taxasImpostos: valorTaxasImpostos,
  );

  static double calcularValorTotal({
    required TipoLancamentoFinanceiro tipo,
    required double valor,
    double desconto = 0,
    double acrescimo = 0,
    double taxasImpostos = 0,
  }) {
    final taxas = tipo == TipoLancamentoFinanceiro.receita
        ? -taxasImpostos
        : taxasImpostos;
    return valor - desconto + acrescimo + taxas;
  }

  double get valorRestante => valorTotal - valorQuitado;
  DateTime get dataUltimaQuitacao =>
      quitacoes.isEmpty ? dataCriacao : quitacoesOrdenadas.last.dataQuitacao;

  bool get isAtrasado => DateTime.now().isAfter(dataVencimento) && !isQuitado;
  bool get isVencido => DateTime.now().isAfter(dataVencimento);

  bool get isCliente =>
      pessoaFinanceiro.tipoPessoaFinanceiro == TipoPessoaFinanceiro.cliente;
  bool get isFornecedor =>
      pessoaFinanceiro.tipoPessoaFinanceiro == TipoPessoaFinanceiro.fornecedor;
  bool get isCartaoCredito =>
      pessoaFinanceiro.tipoPessoaFinanceiro ==
      TipoPessoaFinanceiro.cartaoCredito;
  bool get isBandeiraCartaoCredito =>
      pessoaFinanceiro.tipoPessoaFinanceiro ==
      TipoPessoaFinanceiro.bandeiraCartaoCredito;

  void atualizarQuitacao(int idxQuitacao, Quitacao quitacao) {
    quitacoes[idxQuitacao] = quitacao;
    _atualizarStatusAposQuitacao();
  }

  void adicionarQuitacao(Quitacao quitacao) {
    quitacoes.add(quitacao);
    _atualizarStatusAposQuitacao();
  }

  void _atualizarStatusAposQuitacao() {
    if (valorQuitado >= valorTotal - 0.005) {
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
    pessoaFinanceiro,
    tipoLancamento,
    lancamentoPai,
    statusLancamento,
    tipoOperacaoOriem,
    dataCriacao,
    dataVencimento,
    descricao,
    valorLancamento,
    valorDesconto,
    valorAcrescimo,
    valorTaxasImpostos,
    dataCompensacao,
    observacao,
    operacaoOrigemId,
    formaPagamento,
    quitacoes,
  ];
}
