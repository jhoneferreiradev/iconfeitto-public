import 'item_ficha_tecnica.dart';
import 'item_ficha_tecnica_embalagem.dart';

class Produto {
  String id;
  String nome;
  bool ativo;
  double custoMedio;
  double saldoEstoque;
  bool podeSerVendido;
  bool podeSerComprado;
  bool possuiFichaTecnica;
  bool isEmbalagem;
  int tempoPreparoMinutos;
  int rendimentoReceita;
  double custoOperacional;
  String unidadeEstoqueId;
  String unidadeConsumoId;
  List<ItemFichaTecnica> fichaTecnica;
  List<ItemFichaTecnicaEmbalagem> fichaTecnicaEmbalagem;
  double precoVenda;

  Produto({
    required this.id,
    required this.nome,
    required this.ativo,
    required this.custoMedio,
    required this.custoOperacional,
    this.saldoEstoque = 0,
    this.podeSerVendido = true,
    this.podeSerComprado = true,
    this.isEmbalagem = false,
    this.possuiFichaTecnica = false,
    this.tempoPreparoMinutos = 0,
    this.rendimentoReceita = 0,
    required this.unidadeEstoqueId,
    required this.unidadeConsumoId,
    required this.fichaTecnica,
    required this.fichaTecnicaEmbalagem,
    this.precoVenda = 0,
  });
}

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

  CalculadoraPrecoVendaProduto({
    required this.custos,
    required this.margemLucro,
  });

  double get lucroReal => (custos.custoRendimentoUnitario == 0 || margemLucro == 0)
      ? 0
      : precoVenda - custos.custoRendimentoUnitario;

  double get precoVenda =>
      (custos.custoRendimentoUnitario == 0 || margemLucro == 0)
      ? 0
      : custos.custoRendimentoUnitario +
            (custos.custoRendimentoUnitario * (margemLucro / 100));

  factory CalculadoraPrecoVendaProduto.calcularMargemLucro({
    required CalculadoraCustoProduto custos,
    required double precoVenda,
  }) {
    final lucro =
        (precoVenda == 0 || custos.custoRendimentoUnitario == 0)
        ? 0.0
        : precoVenda - custos.custoRendimentoUnitario;

    final novaMargemLucro = lucro == 0
        ? 0.0
        : (lucro / custos.custoRendimentoUnitario) * 100;

    return CalculadoraPrecoVendaProduto(
      custos: custos,
      margemLucro: novaMargemLucro,
    );
  }

  CalculadoraPrecoVendaProduto recalcular({double? margemLucro}) {
    return CalculadoraPrecoVendaProduto(
      custos: custos,
      margemLucro: margemLucro ?? this.margemLucro,
    );
  }
}
