import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/cliente.dart';
import '../models/custo_operacional.dart';
import '../models/empresa.dart';
import '../models/fornecedor.dart';
import '../models/grupo_unidade.dart';
import '../models/item_ficha_tecnica.dart';
import '../models/item_ficha_tecnica_embalagem.dart';
import '../models/operacao.dart';
import '../models/produto.dart';
import '../models/tipo_item.dart';
import '../models/unidade_medida.dart';
import 'database/app_database.dart';

class AppRepository extends ChangeNotifier {
  AppRepository._();
  static final AppRepository instance = AppRepository._();

  // In-memory caches
  final List<UnidadeMedida> unidades = [];
  final List<Fornecedor> fornecedores = [];
  final List<Cliente> clientes = [];
  final List<Produto> produtos = [];
  final List<Compra> compras = [];
  final List<Venda> vendas = [];
  final List<Fabricacao> fabricacoes = [];
  final List<MovimentoEstoque> movimentacoes = [];
  Empresa empresa = const Empresa();

  late final Database _db;
  bool _initialized = false;
  int _contador = 0;

  bool get isInitialized => _initialized;

  String novoId() {
    _contador++;
    return 'id-${DateTime.now().microsecondsSinceEpoch}-$_contador';
  }

  /// Initialize the database and load all data from SQLite.
  Future<void> initialize() async {
    if (_initialized) return;

    _db = await AppDatabase().database;
    await _loadAllData();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _loadAllData() async {
    unidades.clear();
    fornecedores.clear();
    clientes.clear();
    produtos.clear();
    compras.clear();
    vendas.clear();
    fabricacoes.clear();
    movimentacoes.clear();

    // Load unidades
    final unidadesData = await _db.query('unidades_medida');
    for (final row in unidadesData) {
      unidades.add(_unidadeFromRow(row));
    }

    // If no unidades exist, seed them
    if (unidades.isEmpty) {
      await _seedUnidades();
    }

    // Load fornecedores
    final fornecedoresData = await _db.query('fornecedores');
    for (final row in fornecedoresData) {
      fornecedores.add(
        Fornecedor(
          id: row['id'] as String,
          nome: row['nome'] as String,
          ativo: (row['ativo'] as int) == 1,
        ),
      );
    }

    // Load clientes
    final clientesData = await _db.query('clientes');
    for (final row in clientesData) {
      clientes.add(
        Cliente(
          id: row['id'] as String,
          nome: row['nome'] as String,
          ativo: (row['ativo'] as int) == 1,
        ),
      );
    }

    // Load produtos (including ficha técnica)
    final produtosData = await _db.query('produtos');
    for (final row in produtosData) {
      final produtoId = row['id'] as String;
      final fichaTecnicaRows = await _db.query(
        'itens_ficha_tecnica',
        where: 'produtoId = ?',
        whereArgs: [produtoId],
        orderBy: 'id',
      );

      final fichaTecnicaEmbalagemRows = await _db.query(
        'itens_ficha_tecnica_embalagem',
        where: 'produtoId = ?',
        whereArgs: [produtoId],
      );

      final fichaTecnica = [
        for (final fichaRow in fichaTecnicaRows)
          ItemFichaTecnica(
            produtoIngredienteId: fichaRow['produtoIngredienteId'] as String,
            quantidade: fichaRow['quantidade'] as double,
            unidadeId: fichaRow['unidadeId'] as String,
          ),
      ];

      final fichaTecnicaEmbalagem = [
        for (final fichaRow in fichaTecnicaEmbalagemRows)
          ItemFichaTecnicaEmbalagem(
            produtoEmbalagemId: fichaRow['produtoEmbalagemId'] as String,
          ),
      ];

      produtos.add(
        Produto(
          id: produtoId,
          nome: row['nome'] as String,
          ativo: (row['ativo'] as int) == 1,
          custoMedio: row['custoMedio'] as double,
          saldoEstoque: row['saldoEstoque'] as double,
          podeSerVendido: (row['podeSerVendido'] as int) == 1,
          podeSerComprado: (row['podeSerComprado'] as int) == 1,
          tipo: row['tipo'] == null
              ? null
              : TipoItem.fromString(row['tipo'] as String),
          possuiFichaTecnica: (row['possuiFichaTecnica'] as int) == 1,
          tempoPreparoMinutos: row['tempoPreparoMinutos'] as int,
          rendimentoReceita: row['rendimentoReceita'] as int,
          unidadeEstoqueId: row['unidadeEstoqueId'] as String,
          unidadeConsumoId: row['unidadeConsumoId'] as String,
          fichaTecnica: fichaTecnica,
          fichaTecnicaEmbalagem: fichaTecnicaEmbalagem,
          custoOperacional: row['custoOperacional'] as double,
          isEmbalagem: (row['isEmbalagem'] as int) == 1,
          precoVenda: row['precoVenda'] as double,
        ),
      );
    }

    // Load compras (including items)
    final comprasData = await _db.query('compras');
    for (final row in comprasData) {
      final compraId = row['id'] as String;
      final itensData = await _db.query(
        'itens_compra',
        where: 'compraId = ?',
        whereArgs: [compraId],
        orderBy: 'id',
      );
      final itens = [
        for (final itemRow in itensData)
          ItemOperacao(
            produtoId: itemRow['produtoId'] as String,
            quantidade: itemRow['quantidade'] as double,
            valorUnitario: itemRow['valorUnitario'] as double,
            unidadeId: itemRow['unidadeId'] as String,
          ),
      ];

      compras.add(
        Compra(
          id: compraId,
          data: DateTime.parse(row['data'] as String),
          fornecedorId: row['fornecedorId'] as String,
          itens: itens,
        ),
      );
    }

    // Load vendas (including items)
    final vendasData = await _db.query('vendas');
    for (final row in vendasData) {
      final vendaId = row['id'] as String;
      final itensData = await _db.query(
        'itens_venda',
        where: 'vendaId = ?',
        whereArgs: [vendaId],
      );
      final itens = [
        for (final itemRow in itensData)
          ItemOperacao(
            produtoId: itemRow['produtoId'] as String,
            quantidade: itemRow['quantidade'] as double,
            valorUnitario: itemRow['valorUnitario'] as double,
            unidadeId: itemRow['unidadeId'] as String,
          ),
      ];

      vendas.add(
        Venda(
          id: vendaId,
          data: DateTime.parse(row['data'] as String),
          clienteId: row['clienteId'] as String,
          itens: itens,
        ),
      );
    }

    // Load fabricacoes (including items)
    final fabricacoesData = await _db.query('fabricacoes');
    for (final row in fabricacoesData) {
      final fabricacaoId = row['id'] as String;
      final itensData = await _db.query(
        'itens_fabricacao_registro',
        where: 'fabricacaoId = ?',
        whereArgs: [fabricacaoId],
      );
      final fichaTecnica = [
        for (final itemRow in itensData)
          ItemFichaTecnica(
            produtoIngredienteId: itemRow['produtoIngredienteId'] as String,
            quantidade: itemRow['quantidade'] as double,
            unidadeId: itemRow['unidadeId'] as String,
          ),
      ];

      fabricacoes.add(
        Fabricacao(
          id: fabricacaoId,
          data: DateTime.parse(row['data'] as String),
          produtoId: row['produtoId'] as String,
          quantidade: row['quantidade'] as double,
          fichaTecnica: fichaTecnica,
        ),
      );
    }

    // Load movimentos estoque
    final movimentosData = await _db.query('movimentos_estoque');
    for (final row in movimentosData) {
      movimentacoes.add(
        MovimentoEstoque(
          id: row['id'] as String,
          operacaoId: row['operacaoId'] as String?,
          data: DateTime.parse(row['data'] as String),
          produtoId: row['produtoId'] as String,
          tipo: _tipoMovimentoFromString(row['tipo'] as String),
          quantidade: row['quantidade'] as double,
          valorUnitario: row['valorUnitario'] as double,
          unidadeId: row['unidadeId'] as String,
        ),
      );
    }

    // Load empresa
    final empresaData = await _db.query('empresa');
    if (empresaData.isNotEmpty) {
      empresa = Empresa.fromMap(empresaData.first);
      final custosData = await _db.query(
        'custos_operacionais',
        where: 'empresaId = ?',
        whereArgs: [empresa.id],
      );
      empresa = empresa.copy(
        custosOperacionais: [
          for (final row in custosData) CustoOperacional.fromMap(row),
        ],
      );
    } else {
      empresa = const Empresa();
    }

    recalcularEstoque();
  }

  Future<void> _seedUnidades() async {
    const seedData = [
      UnidadeMedida(
        id: 'g',
        nome: 'Grama',
        sigla: 'g',
        grupo: GrupoUnidade.peso,
        fatorParaBase: 1,
      ),
      UnidadeMedida(
        id: 'kg',
        nome: 'Quilograma',
        sigla: 'kg',
        grupo: GrupoUnidade.peso,
        fatorParaBase: 1000,
      ),
      UnidadeMedida(
        id: 'mg',
        nome: 'Miligrama',
        sigla: 'mg',
        grupo: GrupoUnidade.peso,
        fatorParaBase: 0.001,
      ),
      UnidadeMedida(
        id: 'ml',
        nome: 'Mililitro',
        sigla: 'ml',
        grupo: GrupoUnidade.volume,
        fatorParaBase: 1,
      ),
      UnidadeMedida(
        id: 'l',
        nome: 'Litro',
        sigla: 'L',
        grupo: GrupoUnidade.volume,
        fatorParaBase: 1000,
      ),
      UnidadeMedida(
        id: 'xicara',
        nome: 'Xícara',
        sigla: 'xíc',
        grupo: GrupoUnidade.volume,
        fatorParaBase: 240,
      ),
      UnidadeMedida(
        id: 'colher-sopa',
        nome: 'Colher de sopa',
        sigla: 'c.sopa',
        grupo: GrupoUnidade.volume,
        fatorParaBase: 15,
      ),
      UnidadeMedida(
        id: 'colher-cha',
        nome: 'Colher de chá',
        sigla: 'c.chá',
        grupo: GrupoUnidade.volume,
        fatorParaBase: 5,
      ),
      UnidadeMedida(
        id: 'un',
        nome: 'Unidade',
        sigla: 'un',
        grupo: GrupoUnidade.unidade,
        fatorParaBase: 1,
      ),
      UnidadeMedida(
        id: 'dz',
        nome: 'Dúzia',
        sigla: 'dz',
        grupo: GrupoUnidade.unidade,
        fatorParaBase: 12,
      ),
    ];

    for (final unidade in seedData) {
      await _db.insert('unidades_medida', {
        'id': unidade.id,
        'nome': unidade.nome,
        'sigla': unidade.sigla,
        'grupo': unidade.grupo.toString(),
        'fatorParaBase': unidade.fatorParaBase,
      });
      unidades.add(unidade);
    }
  }

  UnidadeMedida unidadePorId(String id) =>
      unidades.firstWhere((u) => u.id == id);

  Produto? produtoPorId(String id) {
    for (final p in produtos) {
      if (p.id == id) return p;
    }
    return null;
  }

  Fornecedor? fornecedorPorId(String id) {
    for (final fornecedor in fornecedores) {
      if (fornecedor.id == id) return fornecedor;
    }
    return null;
  }

  Cliente? clientePorId(String id) {
    for (final cliente in clientes) {
      if (cliente.id == id) return cliente;
    }
    return null;
  }

  List<UnidadeMedida> unidadesDoGrupo(GrupoUnidade grupo) =>
      unidades.where((u) => u.grupo == grupo).toList();

  Future<void> salvarProduto(Produto produto) async {
    final idx = produtos.indexWhere((p) => p.id == produto.id);

    await _db.delete(
      'itens_ficha_tecnica',
      where: 'produtoId = ?',
      whereArgs: [produto.id],
    );

    await _db.delete(
      'itens_ficha_tecnica_embalagem',
      where: 'produtoId = ?',
      whereArgs: [produto.id],
    );

    if (idx >= 0) {
      produtos[idx] = produto;
      await _db.update(
        'produtos',
        _produtoToRow(produto),
        where: 'id = ?',
        whereArgs: [produto.id],
      );
    } else {
      produtos.add(produto);
      await _db.insert('produtos', _produtoToRow(produto));
    }

    for (final item in produto.fichaTecnica) {
      await _db.insert('itens_ficha_tecnica', {
        'produtoId': produto.id,
        'produtoIngredienteId': item.produtoIngredienteId,
        'quantidade': item.quantidade,
        'unidadeId': item.unidadeId,
      });
    }

    for (final item in produto.fichaTecnicaEmbalagem) {
      await _db.insert('itens_ficha_tecnica_embalagem', {
        'produtoId': produto.id,
        'produtoEmbalagemId': item.produtoEmbalagemId,
      });
    }

    notifyListeners();
  }

  Future<void> excluirProduto(String id) async {
    produtos.removeWhere((p) => p.id == id);
    await _db.delete(
      'itens_ficha_tecnica',
      where: 'produtoId = ?',
      whereArgs: [id],
    );
    await _db.delete(
      'itens_ficha_tecnica_embalagem',
      where: 'produtoId = ?',
      whereArgs: [id],
    );
    await _db.delete('produtos', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  Future<void> salvarUnidade(UnidadeMedida unidade) async {
    final idx = unidades.indexWhere((u) => u.id == unidade.id);
    if (idx >= 0) {
      unidades[idx] = unidade;
      await _db.update(
        'unidades_medida',
        {
          'id': unidade.id,
          'nome': unidade.nome,
          'sigla': unidade.sigla,
          'grupo': unidade.grupo.toString(),
          'fatorParaBase': unidade.fatorParaBase,
        },
        where: 'id = ?',
        whereArgs: [unidade.id],
      );
    } else {
      unidades.add(unidade);
      await _db.insert('unidades_medida', {
        'id': unidade.id,
        'nome': unidade.nome,
        'sigla': unidade.sigla,
        'grupo': unidade.grupo.toString(),
        'fatorParaBase': unidade.fatorParaBase,
      });
    }
    notifyListeners();
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
    await _db.delete('unidades_medida', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  Future<void> salvarFornecedor(Fornecedor fornecedor) async {
    final idx = fornecedores.indexWhere((f) => f.id == fornecedor.id);
    if (idx >= 0) {
      fornecedores[idx] = fornecedor;
      await _db.update(
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
      await _db.insert('fornecedores', {
        'id': fornecedor.id,
        'nome': fornecedor.nome,
        'ativo': fornecedor.ativo ? 1 : 0,
      });
    }
    notifyListeners();
  }

  Future<void> excluirFornecedor(String id) async {
    fornecedores.removeWhere((f) => f.id == id);
    await _db.delete('fornecedores', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  Future<void> salvarCliente(Cliente cliente) async {
    final idx = clientes.indexWhere((c) => c.id == cliente.id);
    if (idx >= 0) {
      clientes[idx] = cliente;
      await _db.update(
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
      await _db.insert('clientes', {
        'id': cliente.id,
        'nome': cliente.nome,
        'ativo': cliente.ativo ? 1 : 0,
      });
    }
    notifyListeners();
  }

  Future<void> excluirCliente(String id) async {
    clientes.removeWhere((c) => c.id == id);
    await _db.delete('clientes', where: 'id = ?', whereArgs: [id]);
    notifyListeners();
  }

  Future<void> salvarCompra(Compra compra) async {
    final movimentosNovos = _criarMovimentosCompra(compra);
    final saldosIniciais = _capturarSaldosIniciais(
      movimentosNovos.map((movimento) => movimento.produtoId),
    );
    _validarSaldoEstoque(movimentosNovos);
    await _db.transaction(
      (transaction) => _inserirCompra(transaction, compra, movimentosNovos),
    );
    compras.add(compra);
    movimentacoes.addAll(movimentosNovos);
    recalcularEstoque(
      produtosSemMovimentacoes: movimentosNovos
          .map((movimento) => movimento.produtoId)
          .toSet(),
      saldosIniciais: saldosIniciais,
    );
    await _persistirProdutos();
    notifyListeners();
  }

  Future<void> atualizarCompra(Compra compra) async {
    final indice = compras.indexWhere((existente) => existente.id == compra.id);
    if (indice < 0) {
      throw StateError('A compra que você tentou editar não foi encontrada.');
    }

    final movimentosAntigos = _movimentosDaCompra(compras[indice]);
    final movimentosNovos = _criarMovimentosCompra(compra);
    final idsAntigos = movimentosAntigos
        .map((movimento) => movimento.id)
        .toSet();
    final saldosIniciais = _capturarSaldosIniciais({
      ...movimentosAntigos.map((movimento) => movimento.produtoId),
      ...movimentosNovos.map((movimento) => movimento.produtoId),
    });
    _validarSaldoEstoque(movimentosNovos, removerIds: idsAntigos);
    await _db.transaction((transaction) async {
      for (final movimento in movimentosAntigos) {
        await transaction.delete(
          'movimentos_estoque',
          where: 'id = ?',
          whereArgs: [movimento.id],
        );
      }
      await transaction.delete(
        'itens_compra',
        where: 'compraId = ?',
        whereArgs: [compra.id],
      );
      await transaction.delete(
        'compras',
        where: 'id = ?',
        whereArgs: [compra.id],
      );
      await _inserirCompra(transaction, compra, movimentosNovos);
    });

    movimentacoes.removeWhere((movimento) => idsAntigos.contains(movimento.id));
    movimentacoes.addAll(movimentosNovos);
    compras[indice] = compra;
    recalcularEstoque(
      produtosSemMovimentacoes: {
        ...movimentosAntigos.map((movimento) => movimento.produtoId),
        ...movimentosNovos.map((movimento) => movimento.produtoId),
      },
      saldosIniciais: saldosIniciais,
    );
    await _persistirProdutos();
    notifyListeners();
  }

  Future<void> excluirCompra(String compraId) async {
    final indice = compras.indexWhere((compra) => compra.id == compraId);
    if (indice < 0) return;

    final compra = compras[indice];
    final movimentosDaCompra = _movimentosDaCompra(compra);
    final idsRemovidos = movimentosDaCompra
        .map((movimento) => movimento.id)
        .toSet();
    final saldosIniciais = _capturarSaldosIniciais(
      movimentosDaCompra.map((movimento) => movimento.produtoId),
    );
    _validarSaldoEstoque(const [], removerIds: idsRemovidos);
    await _db.transaction((transaction) async {
      for (final movimento in movimentosDaCompra) {
        await transaction.delete(
          'movimentos_estoque',
          where: 'id = ?',
          whereArgs: [movimento.id],
        );
      }
      await transaction.delete(
        'itens_compra',
        where: 'compraId = ?',
        whereArgs: [compraId],
      );
      await transaction.delete(
        'compras',
        where: 'id = ?',
        whereArgs: [compraId],
      );
    });

    movimentacoes.removeWhere(
      (movimento) => idsRemovidos.contains(movimento.id),
    );
    compras.removeAt(indice);
    recalcularEstoque(
      produtosSemMovimentacoes: movimentosDaCompra
          .map((movimento) => movimento.produtoId)
          .toSet(),
      saldosIniciais: saldosIniciais,
    );
    await _persistirProdutos();
    notifyListeners();
  }

  Future<void> _inserirCompra(
    DatabaseExecutor database,
    Compra compra,
    List<MovimentoEstoque> movimentos,
  ) async {
    await database.insert('compras', {
      'id': compra.id,
      'data': compra.data.toIso8601String(),
      'fornecedorId': compra.fornecedorId,
    });
    for (final item in compra.itens) {
      await database.insert('itens_compra', {
        'compraId': compra.id,
        'produtoId': item.produtoId,
        'quantidade': item.quantidade,
        'valorUnitario': item.valorUnitario,
        'unidadeId': item.unidadeId,
      });
    }
    for (final movimento in movimentos) {
      await database.insert('movimentos_estoque', _movimentoToRow(movimento));
    }
  }

  List<MovimentoEstoque> _criarMovimentosCompra(Compra compra) => [
    for (final item in compra.itens)
      MovimentoEstoque(
        id: novoId(),
        operacaoId: compra.id,
        data: compra.data,
        produtoId: item.produtoId,
        tipo: TipoMovimentoEstoque.compra,
        quantidade: item.quantidade,
        valorUnitario: item.valorUnitario,
        unidadeId: item.unidadeId,
      ),
  ];

  List<MovimentoEstoque> _movimentosDaCompra(Compra compra) {
    final vinculados = movimentacoes
        .where(
          (movimento) =>
              movimento.operacaoId == compra.id &&
              movimento.tipo == TipoMovimentoEstoque.compra,
        )
        .toList();
    if (vinculados.isNotEmpty) {
      if (vinculados.length != compra.itens.length) {
        throw StateError(
          'Não foi possível localizar todas as movimentações da compra.',
        );
      }
      return vinculados;
    }

    final candidatos = movimentacoes
        .where((movimento) => movimento.tipo == TipoMovimentoEstoque.compra)
        .toList();
    final correspondentes = <MovimentoEstoque>[];
    for (final item in compra.itens) {
      final indice = candidatos.indexWhere(
        (movimento) =>
            movimento.produtoId == item.produtoId &&
            movimento.data == compra.data &&
            movimento.quantidade == item.quantidade &&
            movimento.valorUnitario == item.valorUnitario &&
            movimento.unidadeId == item.unidadeId,
      );
      if (indice >= 0) correspondentes.add(candidatos.removeAt(indice));
    }
    if (correspondentes.length != compra.itens.length) {
      throw StateError(
        'Não foi possível localizar todas as movimentações da compra.',
      );
    }
    return correspondentes;
  }

  Future<void> salvarVenda(Venda venda) async {
    final movimentosNovos = <MovimentoEstoque>[];
    for (final item in venda.itens) {
      movimentosNovos.add(
        MovimentoEstoque(
          id: novoId(),
          operacaoId: venda.id,
          data: venda.data,
          produtoId: item.produtoId,
          tipo: TipoMovimentoEstoque.venda,
          quantidade: item.quantidade,
          valorUnitario: item.valorUnitario,
          unidadeId: item.unidadeId,
        ),
      );
    }

    final saldosIniciais = _capturarSaldosIniciais(
      movimentosNovos.map((movimento) => movimento.produtoId),
    );
    _validarSaldoEstoque(movimentosNovos);
    await _db.transaction((transaction) async {
      await transaction.insert('vendas', {
        'id': venda.id,
        'data': venda.data.toIso8601String(),
        'clienteId': venda.clienteId,
      });
      for (final item in venda.itens) {
        await transaction.insert('itens_venda', {
          'vendaId': venda.id,
          'produtoId': item.produtoId,
          'quantidade': item.quantidade,
          'valorUnitario': item.valorUnitario,
          'unidadeId': item.unidadeId,
        });
      }
      for (final movimento in movimentosNovos) {
        await transaction.insert(
          'movimentos_estoque',
          _movimentoToRow(movimento),
        );
      }
    });
    vendas.add(venda);
    movimentacoes.addAll(movimentosNovos);
    recalcularEstoque(saldosIniciais: saldosIniciais);
    await _persistirProdutos();
    notifyListeners();
  }

  Future<void> salvarFabricacao(Fabricacao fabricacao) =>
      salvarFabricacoes([fabricacao]);

  /// Salva várias fabricações na mesma transação. As fabricações devem estar
  /// ordenadas de modo que os itens intermediários venham antes do final.
  Future<void> salvarFabricacoes(List<Fabricacao> lista) async {
    final movimentosNovos = <MovimentoEstoque>[];
    final saldoSimulado = <String, double>{};
    final custoSimulado = <String, double>{};
    double saldoDe(Produto p) => saldoSimulado[p.id] ?? p.saldoEstoque;
    double custoDe(Produto p) => custoSimulado[p.id] ?? p.custoMedio;

    for (final fabricacao in lista) {
      final produto = produtoPorId(fabricacao.produtoId);
      if (produto == null) {
        throw StateError('O produto fabricado não foi encontrado.');
      }
      var custoTotal = 0.0;
      for (final item in fabricacao.fichaTecnica) {
        final ingrediente = produtoPorId(item.produtoIngredienteId);
        if (ingrediente == null) {
          throw StateError(
            'Um ingrediente da ficha técnica não foi encontrado.',
          );
        }
        final quantidade = item.quantidade * fabricacao.quantidade;
        final quantidadeEstoque =
            quantidade *
            unidadePorId(item.unidadeId).fatorParaBase /
            unidadePorId(ingrediente.unidadeEstoqueId).fatorParaBase;
        custoTotal += custoDe(ingrediente) * quantidadeEstoque;
        saldoSimulado[ingrediente.id] =
            saldoDe(ingrediente) - quantidadeEstoque;
        movimentosNovos.add(
          MovimentoEstoque(
            operacaoId: fabricacao.id,
            id: novoId(),
            data: fabricacao.data,
            produtoId: item.produtoIngredienteId,
            tipo: TipoMovimentoEstoque.consumoFabricacao,
            quantidade: quantidade,
            valorUnitario: 0,
            unidadeId: item.unidadeId,
          ),
        );
      }

      final custoUnitario = fabricacao.quantidade == 0
          ? 0.0
          : custoTotal / fabricacao.quantidade;
      final saldoAnterior = saldoDe(produto);
      final saldoPositivo = saldoAnterior > 0 ? saldoAnterior : 0.0;
      final novoSaldo = saldoPositivo + fabricacao.quantidade;
      custoSimulado[produto.id] = novoSaldo <= 0
          ? 0
          : (saldoPositivo * custoDe(produto) +
                    fabricacao.quantidade * custoUnitario) /
                novoSaldo;
      saldoSimulado[produto.id] = saldoAnterior + fabricacao.quantidade;
      movimentosNovos.add(
        MovimentoEstoque(
          operacaoId: fabricacao.id,
          id: novoId(),
          data: fabricacao.data,
          produtoId: fabricacao.produtoId,
          tipo: TipoMovimentoEstoque.producao,
          quantidade: fabricacao.quantidade,
          valorUnitario: custoUnitario,
          unidadeId: produto.unidadeEstoqueId,
        ),
      );
    }

    final saldosIniciais = _capturarSaldosIniciais(
      movimentosNovos.map((movimento) => movimento.produtoId),
    );
    _validarSaldoEstoque(movimentosNovos);
    await _db.transaction((transaction) async {
      for (final fabricacao in lista) {
        await transaction.insert('fabricacoes', {
          'id': fabricacao.id,
          'data': fabricacao.data.toIso8601String(),
          'produtoId': fabricacao.produtoId,
          'quantidade': fabricacao.quantidade,
        });
        for (final item in fabricacao.fichaTecnica) {
          await transaction.insert('itens_fabricacao_registro', {
            'fabricacaoId': fabricacao.id,
            'produtoIngredienteId': item.produtoIngredienteId,
            'quantidade': item.quantidade,
            'unidadeId': item.unidadeId,
          });
        }
      }
      for (final movimento in movimentosNovos) {
        await transaction.insert(
          'movimentos_estoque',
          _movimentoToRow(movimento),
        );
      }
    });
    fabricacoes.addAll(lista);
    movimentacoes.addAll(movimentosNovos);
    recalcularEstoque(saldosIniciais: saldosIniciais);
    await _persistirProdutos();
    notifyListeners();
  }

  Future<void> excluirFabricacao(String fabricacaoId) async {
    final indice = fabricacoes.indexWhere((f) => f.id == fabricacaoId);
    if (indice < 0) return;

    final fabricacao = fabricacoes[indice];
    final movimentosDaFabricacao = _movimentosDaFabricacao(fabricacao);
    final idsRemovidos = movimentosDaFabricacao.map((m) => m.id).toSet();
    final saldosIniciais = _capturarSaldosIniciais(
      movimentosDaFabricacao.map((movimento) => movimento.produtoId),
    );
    _validarSaldoEstoque(const [], removerIds: idsRemovidos);
    await _db.transaction((transaction) async {
      for (final movimento in movimentosDaFabricacao) {
        await transaction.delete(
          'movimentos_estoque',
          where: 'id = ?',
          whereArgs: [movimento.id],
        );
      }
      await transaction.delete(
        'itens_fabricacao_registro',
        where: 'fabricacaoId = ?',
        whereArgs: [fabricacaoId],
      );
      await transaction.delete(
        'fabricacoes',
        where: 'id = ?',
        whereArgs: [fabricacaoId],
      );
    });

    movimentacoes.removeWhere(
      (movimento) => idsRemovidos.contains(movimento.id),
    );
    fabricacoes.removeAt(indice);
    recalcularEstoque(
      produtosSemMovimentacoes: movimentosDaFabricacao
          .map((movimento) => movimento.produtoId)
          .toSet(),
      saldosIniciais: saldosIniciais,
    );
    await _persistirProdutos();
    notifyListeners();
  }

  List<MovimentoEstoque> _movimentosDaFabricacao(Fabricacao fabricacao) {
    final esperado = fabricacao.fichaTecnica.length + 1;
    final vinculados = movimentacoes
        .where((movimento) => movimento.operacaoId == fabricacao.id)
        .toList();
    if (vinculados.isNotEmpty) {
      if (vinculados.length != esperado) {
        throw StateError(
          'Não foi possível localizar todas as movimentações da fabricação.',
        );
      }
      return vinculados;
    }

    // Registros antigos, sem vínculo com a operação.
    final candidatos = movimentacoes
        .where(
          (movimento) =>
              movimento.operacaoId == null &&
              movimento.data == fabricacao.data &&
              (movimento.tipo == TipoMovimentoEstoque.consumoFabricacao ||
                  movimento.tipo == TipoMovimentoEstoque.producao),
        )
        .toList();
    final correspondentes = <MovimentoEstoque>[];
    for (final item in fabricacao.fichaTecnica) {
      final indice = candidatos.indexWhere(
        (movimento) =>
            movimento.tipo == TipoMovimentoEstoque.consumoFabricacao &&
            movimento.produtoId == item.produtoIngredienteId &&
            movimento.unidadeId == item.unidadeId &&
            (movimento.quantidade - item.quantidade * fabricacao.quantidade)
                    .abs() <
                1e-9,
      );
      if (indice >= 0) correspondentes.add(candidatos.removeAt(indice));
    }
    final indiceProducao = candidatos.indexWhere(
      (movimento) =>
          movimento.tipo == TipoMovimentoEstoque.producao &&
          movimento.produtoId == fabricacao.produtoId &&
          (movimento.quantidade - fabricacao.quantidade).abs() < 1e-9,
    );
    if (indiceProducao >= 0) {
      correspondentes.add(candidatos.removeAt(indiceProducao));
    }
    if (correspondentes.length != esperado) {
      throw StateError(
        'Não foi possível localizar todas as movimentações da fabricação.',
      );
    }
    return correspondentes;
  }

  Future<void> ajustarEstoque(
    String produtoId,
    double novoSaldo,
    double novoCusto,
  ) async {
    final produto = produtoPorId(produtoId);
    if (produto == null) return;

    final movimento = MovimentoEstoque(
      id: novoId(),
      data: DateTime.now(),
      produtoId: produtoId,
      tipo: TipoMovimentoEstoque.ajuste,
      quantidade: novoSaldo - produto.saldoEstoque,
      valorUnitario: novoCusto,
      unidadeId: produto.unidadeEstoqueId,
    );

    final saldosIniciais = _capturarSaldosIniciais([produtoId]);
    _validarSaldoEstoque([movimento]);
    await _db.insert('movimentos_estoque', _movimentoToRow(movimento));
    movimentacoes.add(movimento);
    recalcularEstoque(saldosIniciais: saldosIniciais);
    await _persistirProdutos();
    notifyListeners();
  }

  Future<void> salvarEmpresa(Empresa novaEmpresa) async {
    empresa = novaEmpresa.copy(custosOperacionais: empresa.custosOperacionais);
    await _db.delete('empresa');
    await _db.insert('empresa', {
      'id': empresa.id,
      'nome': empresa.nome,
      'cnpjCpf': empresa.cnpjCpf,
      'telefone': empresa.telefone,
      'endereco': empresa.endereco,
      'instagram': empresa.instagram,
      'facebook': empresa.facebook,
      'logoPath': empresa.logoPath,
      'despesasGlobais': empresa.custoOperacionalPorHora,
    });
    notifyListeners();
  }

  Future<void> adicionarCustoOperacional(CustoOperacional custo) async {
    await _db.insert('custos_operacionais', {
      ...custo.toMap(),
      'empresaId': empresa.id,
    });
    empresa = empresa.copy(
      custosOperacionais: [...empresa.custosOperacionais, custo],
    );
    notifyListeners();
  }

  Future<void> removerCustoOperacional(String custoId) async {
    await _db.delete(
      'custos_operacionais',
      where: 'id = ?',
      whereArgs: [custoId],
    );
    empresa = empresa.copy(
      custosOperacionais: empresa.custosOperacionais
          .where((c) => c.id != custoId)
          .toList(),
    );
    notifyListeners();
  }

  void _validarSaldoEstoque(
    List<MovimentoEstoque> movimentosPropostos, {
    Set<String> removerIds = const {},
  }) {
    final produtosAfetados = <String>{
      ...movimentosPropostos.map((movimento) => movimento.produtoId),
      for (final movimento in movimentacoes)
        if (removerIds.contains(movimento.id)) movimento.produtoId,
    };

    for (final produtoId in produtosAfetados) {
      final produto = produtoPorId(produtoId);
      if (produto == null) {
        throw StateError('Um produto da operação não foi encontrado.');
      }
      final eventos = [
        ...movimentacoes.where(
          (movimento) =>
              movimento.produtoId == produtoId &&
              !removerIds.contains(movimento.id),
        ),
        ...movimentosPropostos.where(
          (movimento) => movimento.produtoId == produtoId,
        ),
      ]..sort(_compararMovimentos);

      var saldo = _saldoInicialProduto(produto);
      final fatorUnidadeEstoque = unidadePorId(produto.unidadeEstoqueId)
          .fatorParaBase;
      for (final movimento in eventos) {
        final fatorUnidadeMovimento = unidadePorId(movimento.unidadeId)
            .fatorParaBase;
        final quantidade =
            movimento.quantidade * fatorUnidadeMovimento / fatorUnidadeEstoque;
        final saida = movimento.tipo == TipoMovimentoEstoque.ajuste
            ? -quantidade
            : (movimento.tipo == TipoMovimentoEstoque.compra ||
                  movimento.tipo == TipoMovimentoEstoque.producao)
            ? 0.0
            : quantidade;

        if (saida > 0 && saldo + 1e-9 < saida) {
          throw SaldoEstoqueInsuficienteException(
            produto: produto.nome,
            unidade: unidadePorId(produto.unidadeEstoqueId).sigla,
            disponivel: saldo < 0 ? 0 : saldo,
            solicitado: saida,
            data: movimento.data,
          );
        }

        if (movimento.tipo == TipoMovimentoEstoque.compra ||
            movimento.tipo == TipoMovimentoEstoque.producao) {
          saldo += quantidade;
        } else {
          saldo -= saida;
        }
        if (saldo.abs() < 1e-9) saldo = 0;
      }
    }
  }

  int _compararMovimentos(MovimentoEstoque a, MovimentoEstoque b) {
    final dataComparacao = a.data.compareTo(b.data);
    return dataComparacao != 0 ? dataComparacao : a.id.compareTo(b.id);
  }

  Map<String, double> _capturarSaldosIniciais(Iterable<String> produtoIds) => {
    for (final produtoId in produtoIds)
      if (produtoPorId(produtoId) case final produto?)
        produtoId: _saldoInicialProduto(produto),
  };

  double _saldoInicialProduto(Produto produto) {
    final variacaoMovimentacoes = movimentacoes
        .where((movimento) => movimento.produtoId == produto.id)
        .fold<double>(
          0,
          (saldo, movimento) =>
              saldo + _variacaoEmUnidadeEstoque(produto, movimento),
        );
    return produto.saldoEstoque - variacaoMovimentacoes;
  }

  double _variacaoEmUnidadeEstoque(
    Produto produto,
    MovimentoEstoque movimento,
  ) {
    final fatorEstoque = unidadePorId(produto.unidadeEstoqueId).fatorParaBase;
    final fatorMovimento = unidadePorId(movimento.unidadeId).fatorParaBase;
    final quantidade = movimento.quantidade * fatorMovimento / fatorEstoque;
    if (movimento.tipo == TipoMovimentoEstoque.compra ||
        movimento.tipo == TipoMovimentoEstoque.producao ||
        movimento.tipo == TipoMovimentoEstoque.ajuste) {
      return quantidade;
    }
    return -quantidade;
  }

  void recalcularEstoque({
    Set<String> produtosSemMovimentacoes = const {},
    Map<String, double> saldosIniciais = const {},
  }) {
    final produtosComMovimento = movimentacoes
        .map((movimento) => movimento.produtoId)
        .toSet();
    for (final produto in produtos) {
      if (!produtosComMovimento.contains(produto.id) &&
          !produtosSemMovimentacoes.contains(produto.id)) {
        continue;
      }
      final saldoInicial =
          saldosIniciais[produto.id] ?? _saldoInicialProduto(produto);
      var saldo = saldoInicial;
      var custo = saldo > 0 ? produto.custoMedio : 0.0;
      var valorEstoque = saldo * custo;

      final movimentosProduto =
          movimentacoes
              .where((movimento) => movimento.produtoId == produto.id)
              .toList()
            ..sort(_compararMovimentos);
      for (final movimento in movimentosProduto) {
        final unidadeMovimento = unidadePorId(movimento.unidadeId);
        final unidadeProduto = unidadePorId(produto.unidadeEstoqueId);
        final quantidade =
            movimento.quantidade *
            unidadeMovimento.fatorParaBase /
            unidadeProduto.fatorParaBase;
        final valorUnitario =
            movimento.valorUnitario *
            unidadeProduto.fatorParaBase /
            unidadeMovimento.fatorParaBase;

        if (movimento.tipo == TipoMovimentoEstoque.ajuste) {
          saldo += quantidade;
          valorEstoque += quantidade * valorUnitario;
          custo = valorUnitario;
        } else if (movimento.tipo == TipoMovimentoEstoque.compra ||
            movimento.tipo == TipoMovimentoEstoque.producao) {
          valorEstoque += quantidade * valorUnitario;
          saldo += quantidade;
          if (saldo > 0) custo = valorEstoque / saldo;
        } else {
          valorEstoque = (valorEstoque - quantidade * custo).clamp(
            0,
            double.infinity,
          );
          saldo -= quantidade;
        }
      }

      produto.saldoEstoque = saldo;
      produto.custoMedio = custo;
    }
  }

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
    return embalagem.custoMedio;
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

  /// Get the last 10 movements for a product.
  List<MovimentoEstoque> ultimas10Movimentacoes(String produtoId) {
    final movimentos = movimentacoes
        .where((m) => m.produtoId == produtoId)
        .toList();
    movimentos.sort((a, b) => b.data.compareTo(a.data));
    return movimentos.take(10).toList();
  }

  // Helper methods for persistence
  Future<void> _persistirProdutos() async {
    for (final produto in produtos) {
      await _db.update(
        'produtos',
        {
          'saldoEstoque': produto.saldoEstoque,
          'custoMedio': produto.custoMedio,
        },
        where: 'id = ?',
        whereArgs: [produto.id],
      );
    }
  }

  Map<String, dynamic> _movimentoToRow(MovimentoEstoque movimento) => {
    'id': movimento.id,
    'operacaoId': movimento.operacaoId,
    'data': movimento.data.toIso8601String(),
    'produtoId': movimento.produtoId,
    'tipo': movimento.tipo.toString(),
    'quantidade': movimento.quantidade,
    'valorUnitario': movimento.valorUnitario,
    'unidadeId': movimento.unidadeId,
  };

  Map<String, dynamic> _produtoToRow(Produto produto) => {
    'id': produto.id,
    'nome': produto.nome,
    'ativo': produto.ativo ? 1 : 0,
    'custoMedio': produto.custoMedio,
    'saldoEstoque': produto.saldoEstoque,
    'podeSerVendido': produto.podeSerVendido ? 1 : 0,
    'podeSerComprado': produto.podeSerComprado ? 1 : 0,
    'tipo': produto.tipo.name,
    'possuiFichaTecnica': produto.possuiFichaTecnica ? 1 : 0,
    'tempoPreparoMinutos': produto.tempoPreparoMinutos,
    'unidadeEstoqueId': produto.unidadeEstoqueId,
    'unidadeConsumoId': produto.unidadeConsumoId,
    'rendimentoReceita': produto.rendimentoReceita,
    'custoOperacional': produto.custoOperacional,
    'isEmbalagem': produto.isEmbalagem ? 1 : 0,
    'precoVenda': produto.precoVenda,
  };

  UnidadeMedida _unidadeFromRow(Map<String, dynamic> row) => UnidadeMedida(
    id: row['id'] as String,
    nome: row['nome'] as String,
    sigla: row['sigla'] as String,
    grupo: _grupoUnidadeFromString(row['grupo'] as String),
    fatorParaBase: row['fatorParaBase'] as double,
  );

  GrupoUnidade _grupoUnidadeFromString(String s) {
    if (s.contains('peso')) return GrupoUnidade.peso;
    if (s.contains('volume')) return GrupoUnidade.volume;
    return GrupoUnidade.unidade;
  }

  TipoMovimentoEstoque _tipoMovimentoFromString(String s) {
    if (s.contains('compra')) return TipoMovimentoEstoque.compra;
    if (s.contains('venda')) return TipoMovimentoEstoque.venda;
    if (s.contains('consumoFabricacao')) {
      return TipoMovimentoEstoque.consumoFabricacao;
    }
    if (s.contains('producao')) return TipoMovimentoEstoque.producao;
    return TipoMovimentoEstoque.ajuste;
  }
}
