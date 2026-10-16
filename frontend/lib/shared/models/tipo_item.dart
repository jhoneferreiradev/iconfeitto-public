enum TipoItem {
  produto('Produto'),
  insumo('Insumo'),
  material('Material'),
  embalagem('Embalagem'),
  preparo('Preparo');

  final String label;

  const TipoItem(this.label);

  static const tiposCompra = [
    TipoItem.insumo,
    TipoItem.material,
    TipoItem.embalagem,
  ];

  static const tiposFabricacao = [TipoItem.produto, TipoItem.preparo];
  static const tiposFichaTecnica = [TipoItem.insumo, TipoItem.material, TipoItem.preparo];

  static TipoItem fromString(String? valor) => TipoItem.values.firstWhere(
    (tipo) => tipo.name == valor,
    orElse: () => TipoItem.produto,
  );
}