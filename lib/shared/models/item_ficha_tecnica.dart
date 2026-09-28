class ItemFichaTecnica {
  String produtoIngredienteId;
  double quantidade;
  String unidadeId;

  ItemFichaTecnica({
    required this.produtoIngredienteId,
    required this.quantidade,
    required this.unidadeId,
  });

  ItemFichaTecnica copy() => ItemFichaTecnica(
    produtoIngredienteId: produtoIngredienteId,
    quantidade: quantidade,
    unidadeId: unidadeId,
  );
}
