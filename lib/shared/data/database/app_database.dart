import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _database;

  factory AppDatabase() => _instance;

  AppDatabase._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'iconfeitto.db');

    return openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Unidades de medida (base data, not mutable typically)
    await db.execute('''
      CREATE TABLE unidades_medida (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        sigla TEXT NOT NULL,
        grupo TEXT NOT NULL,
        fatorParaBase REAL NOT NULL
      )
    ''');

    // Produtos
    await _createProdutosTable(db);

    // Ficha técnica (bill of materials)
    await db.execute('''
      CREATE TABLE itens_ficha_tecnica (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        produtoId TEXT NOT NULL,
        produtoIngredienteId TEXT NOT NULL,
        quantidade REAL NOT NULL,
        unidadeId TEXT NOT NULL,
        FOREIGN KEY (produtoId) REFERENCES produtos(id),
        FOREIGN KEY (produtoIngredienteId) REFERENCES produtos(id),
        FOREIGN KEY (unidadeId) REFERENCES unidades_medida(id)
      )
    ''');

    // Fornecedores (suppliers)
    await db.execute('''
      CREATE TABLE fornecedores (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        ativo INTEGER NOT NULL
      )
    ''');

    // Clientes (clients)
    await db.execute('''
      CREATE TABLE clientes (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        ativo INTEGER NOT NULL
      )
    ''');

    // Compras (purchases)
    await db.execute('''
      CREATE TABLE compras (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        fornecedorId TEXT NOT NULL,
        FOREIGN KEY (fornecedorId) REFERENCES fornecedores(id)
      )
    ''');

    // Itens de compra
    await db.execute('''
      CREATE TABLE itens_compra (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        compraId TEXT NOT NULL,
        produtoId TEXT NOT NULL,
        quantidade REAL NOT NULL,
        valorUnitario REAL NOT NULL,
        unidadeId TEXT NOT NULL,
        FOREIGN KEY (compraId) REFERENCES compras(id),
        FOREIGN KEY (produtoId) REFERENCES produtos(id),
        FOREIGN KEY (unidadeId) REFERENCES unidades_medida(id)
      )
    ''');

    // Vendas (sales)
    await db.execute('''
      CREATE TABLE vendas (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        clienteId TEXT NOT NULL,
        FOREIGN KEY (clienteId) REFERENCES clientes(id)
      )
    ''');

    // Itens de venda
    await db.execute('''
      CREATE TABLE itens_venda (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vendaId TEXT NOT NULL,
        produtoId TEXT NOT NULL,
        quantidade REAL NOT NULL,
        valorUnitario REAL NOT NULL,
        unidadeId TEXT NOT NULL,
        FOREIGN KEY (vendaId) REFERENCES vendas(id),
        FOREIGN KEY (produtoId) REFERENCES produtos(id),
        FOREIGN KEY (unidadeId) REFERENCES unidades_medida(id)
      )
    ''');

    // Fabricação (manufacturing/production)
    await db.execute('''
      CREATE TABLE fabricacoes (
        id TEXT PRIMARY KEY,
        data TEXT NOT NULL,
        produtoId TEXT NOT NULL,
        quantidade REAL NOT NULL,
        FOREIGN KEY (produtoId) REFERENCES produtos(id)
      )
    ''');

    // Itens da fabricação (bill of materials for a specific production run)
    await db.execute('''
      CREATE TABLE itens_fabricacao_registro (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fabricacaoId TEXT NOT NULL,
        produtoIngredienteId TEXT NOT NULL,
        quantidade REAL NOT NULL,
        unidadeId TEXT NOT NULL,
        FOREIGN KEY (fabricacaoId) REFERENCES fabricacoes(id),
        FOREIGN KEY (produtoIngredienteId) REFERENCES produtos(id),
        FOREIGN KEY (unidadeId) REFERENCES unidades_medida(id)
      )
    ''');

    // Stock movements history
    await db.execute('''
      CREATE TABLE movimentos_estoque (
        id TEXT PRIMARY KEY,
        operacaoId TEXT,
        data TEXT NOT NULL,
        produtoId TEXT NOT NULL,
        tipo TEXT NOT NULL,
        quantidade REAL NOT NULL,
        valorUnitario REAL NOT NULL,
        unidadeId TEXT NOT NULL,
        FOREIGN KEY (produtoId) REFERENCES produtos(id),
        FOREIGN KEY (unidadeId) REFERENCES unidades_medida(id)
      )
    ''');

    // Company info (single row)
    await db.execute('''
      CREATE TABLE empresa (
        id TEXT PRIMARY KEY,
        nome TEXT,
        cnpjCpf TEXT,
        telefone TEXT,
        endereco TEXT,
        instagram TEXT,
        facebook TEXT,
        logoPath TEXT,
        despesasGlobais REAL NOT NULL
      )
    ''');

    await _createCustosOperacionaisTable(db);
    await _createFichaTecnicaEmbalagem(db);
  }

  /// Schema atual da tabela de produtos (v5+). [nome] permite criar uma
  /// tabela temporária durante a migração.
  Future<void> _createProdutosTable(Database db, {String nome = 'produtos'}) {
    return db.execute('''
      CREATE TABLE $nome (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        ativo INTEGER NOT NULL,
        custoMedio REAL NOT NULL,
        saldoEstoque REAL NOT NULL,
        podeSerVendido INTEGER NOT NULL,
        podeSerComprado INTEGER NOT NULL,
        possuiFichaTecnica INTEGER NOT NULL,
        tempoPreparoMinutos INTEGER NOT NULL,
        rendimentoReceita INTEGER NOT NULL,
        custoOperacional REAL NOT NULL,
        unidadeEstoqueId TEXT NOT NULL,
        unidadeConsumoId TEXT NOT NULL,
        isEmbalagem INTEGER NOT NULL DEFAULT 0,
        custoEmbalagem REAL NOT NULL DEFAULT 0,
        precoVenda REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (unidadeEstoqueId) REFERENCES unidades_medida(id),
        FOREIGN KEY (unidadeConsumoId) REFERENCES unidades_medida(id)
      )
    ''');
  }

  Future<void> _createCustosOperacionaisTable(Database db) async {
    // Custos operacionais da empresa (add/remove only)
    await db.execute('''
      CREATE TABLE custos_operacionais (
        id TEXT PRIMARY KEY,
        empresaId TEXT NOT NULL,
        nome TEXT NOT NULL,
        valor REAL NOT NULL,
        FOREIGN KEY (empresaId) REFERENCES empresa(id)
      )
    ''');
  }

  Future<void> _createFichaTecnicaEmbalagem(Database db) async {
    // Embalagem
    await db.execute('''
      CREATE TABLE itens_ficha_tecnica_embalagem (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        produtoId TEXT NOT NULL,
        produtoEmbalagemId TEXT NOT NULL,
        FOREIGN KEY (produtoId) REFERENCES produtos(id),
        FOREIGN KEY (produtoEmbalagemId) REFERENCES produtos(id)
      )
    ''');
  }

  Future<void> _addDadosEmbalagemColumnInProdutosTable(Database db) async {
    await db.execute('''
      ALTER TABLE produtos
      ADD COLUMN isEmbalagem INTEGER NOT NULL DEFAULT 0
    ''');

    await db.execute('''
      ALTER TABLE produtos
      ADD COLUMN custoEmbalagem REAL NOT NULL DEFAULT 0
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCustosOperacionaisTable(db);
    }

    if (oldVersion < 3) {
      await _createFichaTecnicaEmbalagem(db);
    }

    if (oldVersion < 4) {
      await _addDadosEmbalagemColumnInProdutosTable(db);
    }

    if (oldVersion < 5) {
      await _tornarUnidadeConsumoObrigatoria(db);
    }

    if (oldVersion < 6) {
      await _addPrecoVendaNoProduto(db);
    }

    if (oldVersion < 7) {
      await db.execute(
        'ALTER TABLE movimentos_estoque ADD COLUMN operacaoId TEXT',
      );
    }
  }

  /// v5: `produtos.unidadeConsumoId` passa a ser NOT NULL.
  ///
  /// O SQLite não altera a nulidade de uma coluna existente, então a tabela é
  /// recriada. Produtos sem unidade de consumo (antes "usar estoque") passam a
  /// usar a própria unidade de estoque.
  Future<void> _tornarUnidadeConsumoObrigatoria(Database db) async {
    const tabelaTemporaria = 'produtos_v5';
    await db.execute('DROP TABLE IF EXISTS $tabelaTemporaria');
    await _createProdutosTable(db, nome: tabelaTemporaria);

    await db.execute('''
      INSERT INTO $tabelaTemporaria (
        id, nome, ativo, custoMedio, saldoEstoque, podeSerVendido,
        podeSerComprado, possuiFichaTecnica, tempoPreparoMinutos,
        rendimentoReceita, custoOperacional, unidadeEstoqueId,
        unidadeConsumoId, isEmbalagem, custoEmbalagem
      )
      SELECT
        id, nome, ativo, custoMedio, saldoEstoque, podeSerVendido,
        podeSerComprado, possuiFichaTecnica, tempoPreparoMinutos,
        rendimentoReceita, custoOperacional, unidadeEstoqueId,
        COALESCE(NULLIF(unidadeConsumoId, ''), unidadeEstoqueId),
        isEmbalagem, custoEmbalagem
      FROM produtos
    ''');

    await db.execute('DROP TABLE produtos');
    await db.execute('ALTER TABLE $tabelaTemporaria RENAME TO produtos');
  }

  Future<void> _addPrecoVendaNoProduto(Database db) async {
    await db.execute('''
      ALTER TABLE produtos
      ADD COLUMN precoVenda REAL NOT NULL DEFAULT 0
    ''');
  }

  Future<void> close() async {
    await _database?.close();
  }
}
