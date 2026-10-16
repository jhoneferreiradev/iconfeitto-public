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

enum TipoVenda {
  /// Pedido feito com antecedência: tem data de entrega e passa pela produção.
  programada('Programada'),

  /// Vende o que já foi fabricado (estoque), sem produção própria do pedido.
  prontaEntrega('Pronta entrega');

  const TipoVenda(this.label);
  final String label;
}

/// Andamento da venda. O estoque do produto final só é movimentado ao
/// chegar em [entregue]; insumos e preparos são movimentados na produção.
enum StatusVenda {
  pedido('Pedido recebido'),
  emProducao('Em produção'),
  aguardandoRetirada('Aguardando retirada'),
  emEntrega('Em percurso'),
  entregue('Entregue'),
  cancelada('Cancelada');

  const StatusVenda(this.label);
  final String label;
}

class Venda {
  final String id;

  /// Data do pedido.
  final DateTime data;
  final String clienteId;
  final List<ItemOperacao> itens;
  final List<LancamentoFinanceiro> lancamentosFinanceiros;
  final TipoVenda tipo;
  final StatusVenda status;

  /// Data combinada para entrega/retirada (vendas programadas).
  final DateTime? dataEntrega;

  /// Momento em que a venda foi entregue; é a data da saída de estoque.
  final DateTime? dataEntregue;

  const Venda({
    required this.id,
    required this.data,
    required this.clienteId,
    required this.itens,
    this.lancamentosFinanceiros = const [],
    this.tipo = TipoVenda.prontaEntrega,
    this.status = StatusVenda.pedido,
    this.dataEntrega,
    this.dataEntregue,
  });

  Venda copyWith({
    StatusVenda? status,
    DateTime? dataEntregue,
    bool limparDataEntregue = false,
  }) => Venda(
    id: id,
    data: data,
    clienteId: clienteId,
    itens: itens,
    lancamentosFinanceiros: lancamentosFinanceiros,
    tipo: tipo,
    status: status ?? this.status,
    dataEntrega: dataEntrega,
    dataEntregue: limparDataEntregue ? null : (dataEntregue ?? this.dataEntregue),
  );

  bool get entregue => status == StatusVenda.entregue;

  /// Itens, cliente e datas só podem ser alterados antes de a venda andar.
  bool get itensEditaveis => status == StatusVenda.pedido;

  /// Data usada em relatórios: a da entrega, quando já ocorreu.
  DateTime get dataReferencia => dataEntregue ?? data;

  /// Próximos status possíveis a partir do atual (a entrega e a produção
  /// têm tratamento próprio por mexerem no estoque).
  List<StatusVenda> get proximosStatus {
    switch (status) {
      case StatusVenda.pedido:
        return tipo == TipoVenda.programada
            ? const [StatusVenda.emProducao, StatusVenda.cancelada]
            : const [
                StatusVenda.aguardandoRetirada,
                StatusVenda.emEntrega,
                StatusVenda.entregue,
                StatusVenda.cancelada,
              ];
      case StatusVenda.emProducao:
        return const [
          StatusVenda.aguardandoRetirada,
          StatusVenda.emEntrega,
          StatusVenda.entregue,
          StatusVenda.cancelada,
        ];
      case StatusVenda.aguardandoRetirada:
        return const [
          StatusVenda.emEntrega,
          StatusVenda.entregue,
          StatusVenda.cancelada,
        ];
      case StatusVenda.emEntrega:
        return const [
          StatusVenda.aguardandoRetirada,
          StatusVenda.entregue,
          StatusVenda.cancelada,
        ];
      case StatusVenda.entregue:
      case StatusVenda.cancelada:
        return const [];
    }
  }

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

  /// Venda programada que originou esta fabricação (início da produção).
  final String? vendaId;

  const Fabricacao({
    required this.id,
    required this.data,
    required this.produtoId,
    required this.quantidade,
    required this.fichaTecnica,
    this.fabricacaoPaiId,
    this.vendaId,
  });
}

enum TipoMovimentoEstoque {
  compra('Compra'),
  venda('Venda'),
  consumoFabricacao('Consumo (fabricação)'),
  producao('Produção'),

  /// Define o saldo e o custo médio do produto naquele momento.
  ajuste('Ajuste'),

  /// Saída de produto para consumo próprio (sem venda nem fabricação).
  consumo('Saída para consumo');

  const TipoMovimentoEstoque(this.label);
  final String label;
}

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
