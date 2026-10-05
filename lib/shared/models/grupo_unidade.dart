enum GrupoUnidade { peso, volume, unidade, comprimento }

extension GrupoUnidadeX on GrupoUnidade {
  String get label => switch (this) {
    GrupoUnidade.peso => 'Peso',
    GrupoUnidade.volume => 'Volume',
    GrupoUnidade.unidade => 'Unidade',
    GrupoUnidade.comprimento => 'Comprimento',
  };
}
