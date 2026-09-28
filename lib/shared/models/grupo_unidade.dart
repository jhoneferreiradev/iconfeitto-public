enum GrupoUnidade { peso, volume, unidade }

extension GrupoUnidadeX on GrupoUnidade {
  String get label => switch (this) {
        GrupoUnidade.peso => 'Peso',
        GrupoUnidade.volume => 'Volume',
        GrupoUnidade.unidade => 'Unidade',
      };
}
