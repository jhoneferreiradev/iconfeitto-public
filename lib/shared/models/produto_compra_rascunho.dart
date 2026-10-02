import 'produto.dart';

/// Produto informado durante uma compra que só é persistido ao salvá-la.
class ProdutoCompraRascunho {
  final String id;
  String nome;
  bool isEmbalagem;
  bool podeSerVendido;
  String unidadeConsumoId;

  ProdutoCompraRascunho({
    required this.id,
    required this.nome,
    required this.isEmbalagem,
    required this.podeSerVendido,
    required this.unidadeConsumoId,
  });

  /// Cria o produto definitivo; a unidade de estoque é a usada na compra.
  Produto paraProduto({required String unidadeEstoqueId}) {
    return Produto(
      id: id,
      nome: nome,
      ativo: true,
      custoMedio: 0,
      custoOperacional: 0,
      podeSerComprado: true,
      podeSerVendido: podeSerVendido,
      isEmbalagem: isEmbalagem,
      unidadeEstoqueId: unidadeEstoqueId,
      unidadeConsumoId: unidadeConsumoId,
      fichaTecnica: [],
      fichaTecnicaEmbalagem: [],
    );
  }
}
