import '../../models/item_ficha_tecnica.dart';
import '../../models/item_ficha_tecnica_embalagem.dart';
import '../../models/produto.dart';
import 'repository_component.dart';

/// Custos da ficha técnica: insumos, embalagens e custo total por produto.
class CustoFichaTecnicaService extends RepositoryComponent {
  CustoFichaTecnicaService(super.context);

  double custoPorUnidadeBase(Produto produto) {
    final unidadeId = produto.possuiFichaTecnica
        ? produto.unidadeConsumoId
        : produto.unidadeEstoqueId;
    final unidade = unidadePorId(unidadeId);
    if (unidade.fatorParaBase == 0) return 0;
    final custo = produto.possuiFichaTecnica
        ? CalculadoraCustoProduto(
            rendimentoReceita: produto.rendimentoReceita,
            custoFichaTecnica: custoTotalFicha(produto),
            custoOperacional: produto.custoOperacional,
            custoUnitarioEmbalagem: custoEmbalagem(produto),
          ).custoRendimentoUnitario
        : produto.custoMedio;
    return custo / unidade.fatorParaBase;
  }

  double custoItemFicha(ItemFichaTecnica item) {
    final ingrediente = produtoPorId(item.produtoIngredienteId);
    if (ingrediente == null) return 0;
    final unidadeItem = unidadePorId(item.unidadeId);
    final custoBase = custoPorUnidadeBase(ingrediente);
    return custoBase * item.quantidade * unidadeItem.fatorParaBase;
  }

  double custoItemFichaEmbalagem(ItemFichaTecnicaEmbalagem item) {
    final embalagem = produtoPorId(item.produtoEmbalagemId);
    if (embalagem == null) return 0;
    final unidadeItem = unidadePorId(item.unidadeId);
    final custoBase = custoPorUnidadeBase(embalagem);
    return custoBase * item.quantidade * unidadeItem.fatorParaBase;
  }

  double custoEmbalagem(Produto produto) {
    return produto.fichaTecnicaEmbalagem.fold(
      0,
      (sum, item) => sum + custoItemFichaEmbalagem(item),
    );
  }

  double custoTotalFicha(Produto produto) => produto.fichaTecnica.fold(
    0.0,
    (soma, item) => soma + custoItemFicha(item),
  );
}
