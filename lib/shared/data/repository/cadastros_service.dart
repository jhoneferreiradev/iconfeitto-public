import '../../models/cliente.dart';
import '../../models/fornecedor.dart';
import '../../models/produto.dart';
import '../../models/unidade_medida.dart';
import 'repository_component.dart';
import 'row_mappers.dart';

/// Cadastros básicos: produtos, unidades de medida, fornecedores e clientes.
class CadastrosService extends RepositoryComponent {
  CadastrosService(super.context);

  Future<void> salvarProduto(Produto produto) async {
    final idx = produtos.indexWhere((p) => p.id == produto.id);

    await db.delete(
      'itens_ficha_tecnica',
      where: 'produtoId = ?',
      whereArgs: [produto.id],
    );

    if (idx >= 0) {
      produtos[idx] = produto;
      await db.update(
        'produtos',
        produtoParaLinha(produto),
        where: 'id = ?',
        whereArgs: [produto.id],
      );
    } else {
      produtos.add(produto);
      await db.insert('produtos', produtoParaLinha(produto));
    }

    for (final item in produto.fichaTecnica) {
      await db.insert('itens_ficha_tecnica', {
        'produtoId': produto.id,
        'produtoIngredienteId': item.produtoIngredienteId,
        'quantidade': item.quantidade,
        'unidadeId': item.unidadeId,
      });
    }

    for (final item in produto.fichaTecnicaEmbalagem) {
      await db.insert('itens_ficha_tecnica', {
        'produtoId': produto.id,
        'produtoIngredienteId': item.produtoEmbalagemId,
        'quantidade': item.quantidade,
        'unidadeId': item.unidadeId,
      });
    }

    notificar();
  }

  Future<void> excluirProduto(String id) async {
    produtos.removeWhere((p) => p.id == id);
    await db.delete(
      'itens_ficha_tecnica',
      where: 'produtoId = ?',
      whereArgs: [id],
    );
    // await db.delete(
    //   'itens_ficha_tecnica_embalagem',
    //   where: 'produtoId = ?',
    //   whereArgs: [id],
    // );
    await db.delete('produtos', where: 'id = ?', whereArgs: [id]);
    notificar();
  }

  Future<void> salvarUnidade(UnidadeMedida unidade) async {
    final idx = unidades.indexWhere((u) => u.id == unidade.id);
    if (idx >= 0) {
      unidades[idx] = unidade;
      await db.update(
        'unidades_medida',
        {
          'id': unidade.id,
          'nome': unidade.nome,
          'sigla': unidade.sigla,
          'grupo': unidade.grupo.name,
          'fatorParaBase': unidade.fatorParaBase,
        },
        where: 'id = ?',
        whereArgs: [unidade.id],
      );
    } else {
      unidades.add(unidade);
      await db.insert('unidades_medida', {
        'id': unidade.id,
        'nome': unidade.nome,
        'sigla': unidade.sigla,
        'grupo': unidade.grupo.name,
        'fatorParaBase': unidade.fatorParaBase,
      });
    }
    notificar();
  }

  Future<void> excluirUnidade(String id) async {
    final emUso = produtos.any(
      (p) =>
          p.unidadeEstoqueId == id ||
          p.fichaTecnica.any((i) => i.unidadeId == id),
    );
    if (emUso) {
      throw Exception(
        'Esta unidade está em uso em algum produto e não pode ser excluída.',
      );
    }
    unidades.removeWhere((u) => u.id == id);
    await db.delete('unidades_medida', where: 'id = ?', whereArgs: [id]);
    notificar();
  }

  Future<void> salvarFornecedor(Fornecedor fornecedor) async {
    final idx = fornecedores.indexWhere((f) => f.id == fornecedor.id);
    if (idx >= 0) {
      fornecedores[idx] = fornecedor;
      await db.update(
        'fornecedores',
        {
          'id': fornecedor.id,
          'nome': fornecedor.nome,
          'ativo': fornecedor.ativo ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [fornecedor.id],
      );
    } else {
      fornecedores.add(fornecedor);
      await db.insert('fornecedores', {
        'id': fornecedor.id,
        'nome': fornecedor.nome,
        'ativo': fornecedor.ativo ? 1 : 0,
      });
    }
    notificar();
  }

  Future<void> excluirFornecedor(String id) async {
    fornecedores.removeWhere((f) => f.id == id);
    await db.delete('fornecedores', where: 'id = ?', whereArgs: [id]);
    notificar();
  }

  Future<void> salvarCliente(Cliente cliente) async {
    final idx = clientes.indexWhere((c) => c.id == cliente.id);
    if (idx >= 0) {
      clientes[idx] = cliente;
      await db.update(
        'clientes',
        {
          'id': cliente.id,
          'nome': cliente.nome,
          'ativo': cliente.ativo ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [cliente.id],
      );
    } else {
      clientes.add(cliente);
      await db.insert('clientes', {
        'id': cliente.id,
        'nome': cliente.nome,
        'ativo': cliente.ativo ? 1 : 0,
      });
    }
    notificar();
  }

  Future<void> excluirCliente(String id) async {
    clientes.removeWhere((c) => c.id == id);
    await db.delete('clientes', where: 'id = ?', whereArgs: [id]);
    notificar();
  }
}
