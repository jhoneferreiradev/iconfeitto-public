import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'versions/app_database_version.dart';
import 'versions/mixin_app_database_version.dart';

class AppDatabase with MixinAppDatabaseVersion {
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

    final versao = versions.last.versao;

    return openDatabase(
      path,
      version: versao,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(
    Database db,
    int version, {
    bool seedUnidades = true,
  }) async {
    await AppDatabaseVersion_000_0001().aplicarMigracao(db, 0, 0);
  }

  // Future<void> _createFichaTecnicaEmbalagem(Database db) async {
  //   // Embalagem
  //   await db.execute('''
  //     CREATE TABLE itens_ficha_tecnica_embalagem (
  //       id INTEGER PRIMARY KEY AUTOINCREMENT,
  //       produtoId TEXT NOT NULL,
  //       produtoEmbalagemId TEXT NOT NULL,
  //       quantidade REAL NOT NULL,
  //       unidadeId TEXT NOT NULL,
  //       FOREIGN KEY (produtoId) REFERENCES produtos(id),
  //       FOREIGN KEY (produtoEmbalagemId) REFERENCES produtos(id),
  //       FOREIGN KEY (unidadeId) REFERENCES unidades_medida(id)
  //     )
  //   ''');
  // }

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

  /// Financeiro (v16): cartões de crédito, lançamentos e quitações.
  Future<void> _createFinanceiroTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cartoes_credito (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        diaVencimento INTEGER NOT NULL DEFAULT 10,
        diasFechamento INTEGER NOT NULL DEFAULT 7
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS bandeiras_cartao (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        taxa REAL NOT NULL DEFAULT 0,
        diasCompensacao INTEGER NOT NULL DEFAULT 1,
        tipoTaxa TEXT NOT NULL DEFAULT 'percentual'
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS lancamentos_financeiros (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pessoaId INTEGER NOT NULL,
        pessoaTipo TEXT NOT NULL,
        pessoaNome TEXT NOT NULL,
        tipoLancamento TEXT NOT NULL,
        lancamentoPaiId INTEGER,
        statusLancamento TEXT NOT NULL,
        tipoOperacaoOrigem TEXT NOT NULL,
        operacaoOrigemId TEXT NOT NULL,
        formaPagamento TEXT,
        dataCriacao TEXT NOT NULL,
        dataVencimento TEXT NOT NULL,
        descricao TEXT NOT NULL,
        observacao TEXT,
        valorLancamento REAL NOT NULL,
        valorDesconto REAL NOT NULL DEFAULT 0,
        valorAcrescimo REAL NOT NULL DEFAULT 0,
        valorTaxasImpostos REAL NOT NULL DEFAULT 0,
        dataCompensacao TEXT,
        FOREIGN KEY (lancamentoPaiId) REFERENCES lancamentos_financeiros(id)
      )
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_lancamentos_origem
      ON lancamentos_financeiros (tipoOperacaoOrigem, operacaoOrigemId)
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS quitacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lancamentoId INTEGER NOT NULL,
        dataQuitacao TEXT NOT NULL,
        valorQuitado REAL NOT NULL,
        formaPagamento TEXT NOT NULL,
        FOREIGN KEY (lancamentoId) REFERENCES lancamentos_financeiros(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (final version in versions) {
      await version.aplicarMigracao(db, oldVersion, newVersion);
    }
  }

  Future<void> close() async {
    await _database?.close();
  }
}
