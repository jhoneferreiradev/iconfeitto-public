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
