import 'produto.dart';
import 'tipo_item.dart';

/// Item informado durante uma compra que só é persistido ao salvá-la.
class ProdutoCompraRascunho {
  final String id;
  String nome;
  TipoItem tipo;
  String unidadeConsumoId;

  ProdutoCompraRascunho({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.unidadeConsumoId,
  });

  /// Cria o item definitivo, normalizando embalagens para unidade individual.
  Produto paraProduto({required String unidadeEstoqueId}) {
    final unidadeEmbalagem = tipo == TipoItem.embalagem;
    return Produto(
      id: id,
      nome: nome,
      ativo: true,
      custoMedio: 0,
      custoOperacional: 0,
      tipo: tipo,
      unidadeEstoqueId: unidadeEmbalagem ? 'un' : unidadeEstoqueId,
      unidadeConsumoId: unidadeEmbalagem ? 'un' : unidadeConsumoId,
      fichaTecnica: [],
      fichaTecnicaEmbalagem: [],
    );
  }
}
