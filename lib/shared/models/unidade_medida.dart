import 'grupo_unidade.dart';

class UnidadeMedida {
  final String id;
  final String nome;
  final String sigla;
  final GrupoUnidade grupo;
  // Quantas unidades "base" do grupo equivalem a 1 desta unidade.
  // Ex.: grupo peso tem "g" como base (fator 1); "kg" tem fator 1000.
  final double fatorParaBase;

  const UnidadeMedida({
    required this.id,
    required this.nome,
    required this.sigla,
    required this.grupo,
    required this.fatorParaBase,
  });
}
