import 'item_ficha_tecnica.dart';

class Produto {
  String id;
  String nome;
  bool ativo;
  double custoMedio;
  double saldoEstoque;
  bool podeSerVendido;
  bool podeSerComprado;
  bool possuiFichaTecnica;
  int tempoPreparoMinutos;
  int rendimentoReceita;
  double custoOperacional;
  String unidadeEstoqueId;
  String? unidadeConsumoId;
  List<ItemFichaTecnica> fichaTecnica;

  Produto({
    required this.id,
    required this.nome,
    required this.ativo,
    required this.custoMedio,
    required this.custoOperacional,
    this.saldoEstoque = 0,
    this.podeSerVendido = true,
    this.podeSerComprado = true,
    this.possuiFichaTecnica = false,
    this.tempoPreparoMinutos = 0,
    this.rendimentoReceita = 0,
    required this.unidadeEstoqueId,
    this.unidadeConsumoId,
    required this.fichaTecnica,
  });

  double get custoRendimentoUnitario => calcularCustoRendimentoUnitario(
    rendimentoReceita,
    custoMedio + custoOperacional,
  );

  static double calcularCustoRendimentoUnitario(
    int rendimentoReceita,
    double custoFichaTecnicaComCustoOperacional,
  ) {
    return (custoFichaTecnicaComCustoOperacional <= 0 || rendimentoReceita <= 0)
        ? 0
        : custoFichaTecnicaComCustoOperacional / rendimentoReceita;
  }
}
