import 'item_ficha_tecnica.dart';
import 'item_ficha_tecnica_embalagem.dart';
import 'tipo_item.dart';

class Item {
  String id;
  String nome;
  bool ativo;
  double custoMedio;
  double saldoEstoque;
  TipoItem tipo;
  bool possuiFichaTecnica;
  int tempoPreparoMinutos;
  int rendimentoReceita;
  double custoOperacional;
  String unidadeEstoqueId;
  String unidadeConsumoId;
  List<ItemFichaTecnica> fichaTecnica;
  List<ItemFichaTecnicaEmbalagem> fichaTecnicaEmbalagem;
  double precoVenda;

  Item({
    required this.id,
    required this.nome,
    required this.ativo,
    required this.custoMedio,
    required this.custoOperacional,
    this.saldoEstoque = 0,
    TipoItem? tipo,
    bool? podeSerVendido,
    bool? podeSerComprado,
    bool? isEmbalagem,
    this.possuiFichaTecnica = false,
    this.tempoPreparoMinutos = 0,
    this.rendimentoReceita = 0,
    required this.unidadeEstoqueId,
    required this.unidadeConsumoId,
    required this.fichaTecnica,
    required this.fichaTecnicaEmbalagem,
    this.precoVenda = 0,
  }) : tipo =
           tipo ??
           _inferirTipo(
             isEmbalagem: isEmbalagem ?? false,
             podeSerVendido: podeSerVendido ?? true,
             podeSerComprado: podeSerComprado ?? true,
             possuiFichaTecnica: possuiFichaTecnica,
           );

  bool get podeSerVendido => tipo == TipoItem.produto;
  bool get podeSerComprado => TipoItem.tiposCompra.contains(tipo);
  bool get isEmbalagem => tipo == TipoItem.embalagem;

  static TipoItem _inferirTipo({
    required bool isEmbalagem,
    required bool podeSerVendido,
    required bool podeSerComprado,
    required bool possuiFichaTecnica,
  }) {
    if (isEmbalagem) return TipoItem.embalagem;
    if (podeSerVendido) return TipoItem.produto;
    if (possuiFichaTecnica) return TipoItem.preparo;
    if (podeSerComprado) return TipoItem.insumo;
    return TipoItem.produto;
  }
}

typedef Produto = Item;

class CalculadoraCustoProduto {
  final int rendimentoReceita;
  final double custoFichaTecnica;
  final double custoOperacional;
  final double custoUnitarioEmbalagem;

  CalculadoraCustoProduto({
    required this.rendimentoReceita,
    required this.custoFichaTecnica,
    required this.custoOperacional,
    required this.custoUnitarioEmbalagem,
  });

  double get custoReceitaTotal =>
      custoFichaTecnica +
      custoOperacional +
      (custoUnitarioEmbalagem * rendimentoReceita);

  double get custoRendimentoUnitario =>
      (custoReceitaTotal <= 0 || rendimentoReceita <= 0)
      ? 0
      : custoReceitaTotal / rendimentoReceita;

  double get custoTotalEmbalagem => custoUnitarioEmbalagem * rendimentoReceita;
}

class CalculadoraPrecoVendaProduto {
  final CalculadoraCustoProduto custos;
  final double margemLucro;
  final double? precoVendaInformado;

  CalculadoraPrecoVendaProduto({
    required this.custos,
    required this.margemLucro,
    this.precoVendaInformado,
  });

  double get lucroReal => precoVenda - custos.custoRendimentoUnitario;

  double get precoVenda {
    if (custos.custoRendimentoUnitario == 0) {
      return precoVendaInformado ?? 0;
    }
    return custos.custoRendimentoUnitario +
        (custos.custoRendimentoUnitario * (margemLucro / 100));
  }

  factory CalculadoraPrecoVendaProduto.calcularMargemLucro({
    required CalculadoraCustoProduto custos,
    required double precoVenda,
  }) {
    final lucro = (precoVenda == 0 || custos.custoRendimentoUnitario == 0)
        ? 0.0
        : precoVenda - custos.custoRendimentoUnitario;

    final novaMargemLucro = lucro == 0
        ? 0.0
        : (lucro / custos.custoRendimentoUnitario) * 100;

    return CalculadoraPrecoVendaProduto(
      custos: custos,
      margemLucro: novaMargemLucro,
      precoVendaInformado: precoVenda,
    );
  }

  CalculadoraPrecoVendaProduto recalcular({
    double? margemLucro,
    CalculadoraCustoProduto? custos,
  }) {
    return CalculadoraPrecoVendaProduto(
      custos: custos ?? this.custos,
      margemLucro: margemLucro ?? this.margemLucro,
      precoVendaInformado: precoVendaInformado,
    );
  }
}
