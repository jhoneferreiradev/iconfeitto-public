import 'package:iconfeitto/shared/models/lancamento_financeiro.dart';

import 'item_ficha_tecnica.dart';

class ItemOperacao {
  final String produtoId;
  final double quantidade;
  final double valorUnitario;
  final String unidadeId;

  const ItemOperacao({
    required this.produtoId,
    required this.quantidade,
    required this.valorUnitario,
    required this.unidadeId,
  });
}

class Compra {
  final String id;
  final DateTime data;
  final String fornecedorId;
  final List<ItemOperacao> itens;
  final List<LancamentoFinanceiro> lancamentosFinanceiros;

  const Compra({
    required this.id,
    required this.data,
    required this.fornecedorId,
    required this.itens,
    this.lancamentosFinanceiros = const [],
  });

  double get total => itens.fold(
    0,
    (soma, item) => soma + item.quantidade * item.valorUnitario,
  );
}

class Venda {
  final String id;
  final DateTime data;
  final String clienteId;
  final List<ItemOperacao> itens;
  final List<LancamentoFinanceiro> lancamentosFinanceiros;

  const Venda({
    required this.id,
    required this.data,
    required this.clienteId,
    required this.itens,
    this.lancamentosFinanceiros = const [],
  });

  double get total => itens.fold(
    0,
    (soma, item) => soma + item.quantidade * item.valorUnitario,
  );
}

class Fabricacao {
  final String id;
  final DateTime data;
  final String produtoId;
  final double quantidade;
  final List<ItemFichaTecnica> fichaTecnica;

  /// Fabricação principal que gerou esta (preparo da ficha técnica). Ao
  /// excluir a principal, as vinculadas também são excluídas.
  final String? fabricacaoPaiId;

  const Fabricacao({
    required this.id,
    required this.data,
    required this.produtoId,
    required this.quantidade,
    required this.fichaTecnica,
    this.fabricacaoPaiId,
  });
}

enum TipoMovimentoEstoque { compra, venda, consumoFabricacao, producao, ajuste }

class SaldoEstoqueInsuficienteException implements Exception {
  final String produto;
  final String unidade;
  final double disponivel;
  final double solicitado;
  final DateTime data;

  const SaldoEstoqueInsuficienteException({
    required this.produto,
    required this.unidade,
    required this.disponivel,
    required this.solicitado,
    required this.data,
  });

  String get message =>
      'Saldo insuficiente de $produto em ${_dataFormatada(data)}: '
      'disponível ${_decimalLocal(disponivel)} $unidade, '
      'necessário ${_decimalLocal(solicitado)} $unidade.';

  @override
  String toString() => message;
}

String _dataFormatada(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

String _decimalLocal(double valor) =>
    valor.toStringAsFixed(2).replaceAll('.', ',');

class MovimentoEstoque {
  final String id;
  final String? operacaoId;
  final DateTime data;
  final String produtoId;
  final TipoMovimentoEstoque tipo;
  final double quantidade;
  final double valorUnitario;
  final String unidadeId;

  const MovimentoEstoque({
    required this.id,
    this.operacaoId,
    required this.data,
    required this.produtoId,
    required this.tipo,
    required this.quantidade,
    required this.valorUnitario,
    required this.unidadeId,
  });
}
