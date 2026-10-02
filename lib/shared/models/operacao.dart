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

  const Compra({
    required this.id,
    required this.data,
    required this.fornecedorId,
    required this.itens,
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

  const Venda({
    required this.id,
    required this.data,
    required this.clienteId,
    required this.itens,
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

  const Fabricacao({
    required this.id,
    required this.data,
    required this.produtoId,
    required this.quantidade,
    required this.fichaTecnica,
  });
}

enum TipoMovimentoEstoque { compra, venda, consumoFabricacao, producao, ajuste }

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
