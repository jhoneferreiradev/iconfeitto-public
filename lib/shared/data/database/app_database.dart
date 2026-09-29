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
    final path = join(dbPath, 'confeitaria.db');

    return openDatabase(
      path,
      version: 2,
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
    await db.execute('''
      CREATE TABLE produtos (
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
        unidadeConsumoId TEXT,
        FOREIGN KEY (unidadeEstoqueId) REFERENCES unidades_medida(id),
        FOREIGN KEY (unidadeConsumoId) REFERENCES unidades_medida(id)
      )
    ''');

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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCustosOperacionaisTable(db);
    }
  }

  Future<void> close() async {
    await _database?.close();
  }
}
