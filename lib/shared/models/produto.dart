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
  String unidadeEstoqueId;
  String? unidadeConsumoId;
  List<ItemFichaTecnica> fichaTecnica;

  Produto({
    required this.id,
    required this.nome,
    required this.ativo,
    required this.custoMedio,
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

  double get custoRendimentoUnitario =>
      calcularCustoRendimentoUnitario(rendimentoReceita, custoMedio);

  static double calcularCustoRendimentoUnitario(
    int rendimentoReceita,
    double custoMedio,
  ) {
    return (custoMedio <= 0 || rendimentoReceita <= 0)
        ? 0
        : custoMedio / rendimentoReceita;
  }
}
