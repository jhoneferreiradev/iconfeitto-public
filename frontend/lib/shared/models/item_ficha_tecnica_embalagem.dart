class ItemFichaTecnicaEmbalagem {
  String produtoEmbalagemId;
  double quantidade;
  String unidadeId;

  ItemFichaTecnicaEmbalagem({
    required this.produtoEmbalagemId,
    required this.quantidade,
    required this.unidadeId,
  });

  ItemFichaTecnicaEmbalagem copy() => ItemFichaTecnicaEmbalagem(
    produtoEmbalagemId: produtoEmbalagemId,
    quantidade: quantidade,
    unidadeId: unidadeId,
  );
}
