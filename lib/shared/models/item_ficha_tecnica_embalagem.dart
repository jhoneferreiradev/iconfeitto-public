class ItemFichaTecnicaEmbalagem {
  String produtoEmbalagemId;

  ItemFichaTecnicaEmbalagem({required this.produtoEmbalagemId});

  ItemFichaTecnicaEmbalagem copy() =>
      ItemFichaTecnicaEmbalagem(produtoEmbalagemId: produtoEmbalagemId);
}
