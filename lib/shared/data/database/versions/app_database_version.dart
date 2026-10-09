import 'package:sqflite/sqflite.dart';

import 'app_database_version_000_0023.dart';

abstract class AppDatabaseVersion {
  int get versao;
  String get descricao;
  Future<void> aplicarMigracao(Database db, int oldVersion, int newVersion);
}

class AppDatabaseVersion_000_0001 implements AppDatabaseVersion {
  @override
  int get versao => 1;

  @override
  String get descricao => 'Versão inicial do banco de dados';

  @override
  Future<void> aplicarMigracao(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Unidades de medida (base data, not mutable typically)
    await db.execute('''
      CREATE TABLE unidades_medida (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        sigla TEXT NOT NULL,
        grupo TEXT NOT NULL,
        fatorParaBase REAL NOT NULL
      )
    ''');

    // Produtos
    await db.execute('''
      CREATE TABLE produtos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        ativo INTEGER NOT NULL,
        custoMedio REAL NOT NULL,
        saldoEstoque REAL NOT NULL,
        podeSerVendido INTEGER NOT NULL,
        podeSerComprado INTEGER NOT NULL,
        tipo TEXT NOT NULL DEFAULT 'produto',
        possuiFichaTecnica INTEGER NOT NULL,
        tempoPreparoMinutos INTEGER NOT NULL,
        rendimentoReceita INTEGER NOT NULL,
        custoOperacional REAL NOT NULL,
        unidadeEstoqueId INTEGER NOT NULL,
        unidadeConsumoId INTEGER NOT NULL,
        isEmbalagem INTEGER NOT NULL DEFAULT 0,
        custoEmbalagem REAL NOT NULL DEFAULT 0,
        precoVenda REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (unidadeEstoqueId) REFERENCES unidades_medida(id),
        FOREIGN KEY (unidadeConsumoId) REFERENCES unidades_medida(id)
      )
    ''');

    // Ficha técnica (bill of materials)
    await db.execute('''
      CREATE TABLE itens_ficha_tecnica (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        produtoId INTEGER NOT NULL,
        produtoIngredienteId INTEGER NOT NULL,
        quantidade REAL NOT NULL,
        unidadeId INTEGER NOT NULL,
        FOREIGN KEY (produtoId) REFERENCES produtos(id),
        FOREIGN KEY (produtoIngredienteId) REFERENCES produtos(id),
        FOREIGN KEY (unidadeId) REFERENCES unidades_medida(id)
      )
    ''');

    // Fornecedores (suppliers)
    await db.execute('''
      CREATE TABLE fornecedores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        ativo INTEGER NOT NULL
      )
    ''');

    // Clientes (clients)
    await db.execute('''
      CREATE TABLE clientes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        ativo INTEGER NOT NULL
      )
    ''');

    // Compras (purchases)
    await db.execute('''
      CREATE TABLE compras (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        fornecedorId INTEGER NOT NULL,
        FOREIGN KEY (fornecedorId) REFERENCES fornecedores(id)
      )
    ''');

    // Itens de compra
    await db.execute('''
      CREATE TABLE itens_compra (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        compraId INTEGER NOT NULL,
        produtoId INTEGER NOT NULL,
        quantidade REAL NOT NULL,
        valorUnitario REAL NOT NULL,
        unidadeId INTEGER NOT NULL,
        FOREIGN KEY (compraId) REFERENCES compras(id),
        FOREIGN KEY (produtoId) REFERENCES produtos(id),
        FOREIGN KEY (unidadeId) REFERENCES unidades_medida(id)
      )
    ''');

    // Vendas (sales)
    await db.execute('''
      CREATE TABLE vendas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        clienteId INTEGER NOT NULL,
        tipo TEXT NOT NULL DEFAULT 'prontaEntrega',
        status TEXT NOT NULL DEFAULT 'entregue',
        dataEntrega TEXT,
        dataEntregue TEXT,
        FOREIGN KEY (clienteId) REFERENCES clientes(id)
      )
    ''');

    // Itens de venda
    await db.execute('''
      CREATE TABLE itens_venda (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vendaId INTEGER NOT NULL,
        produtoId INTEGER NOT NULL,
        quantidade REAL NOT NULL,
        valorUnitario REAL NOT NULL,
        unidadeId INTEGER NOT NULL,
        FOREIGN KEY (vendaId) REFERENCES vendas(id),
        FOREIGN KEY (produtoId) REFERENCES produtos(id),
        FOREIGN KEY (unidadeId) REFERENCES unidades_medida(id)
      )
    ''');

    // Fabricação (manufacturing/production)
    await db.execute('''
      CREATE TABLE fabricacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT NOT NULL,
        produtoId INTEGER NOT NULL,
        quantidade REAL NOT NULL,
        fabricacaoPaiId INTEGER,
        vendaId INTEGER,
        FOREIGN KEY (produtoId) REFERENCES produtos(id),
        FOREIGN KEY (fabricacaoPaiId) REFERENCES fabricacoes(id)
      )
    ''');

    // Itens da fabricação (bill of materials for a specific production run)
    await db.execute('''
      CREATE TABLE itens_fabricacao_registro (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fabricacaoId INTEGER NOT NULL,
        produtoIngredienteId INTEGER NOT NULL,
        quantidade REAL NOT NULL,
        unidadeId INTEGER NOT NULL,
        FOREIGN KEY (fabricacaoId) REFERENCES fabricacoes(id),
        FOREIGN KEY (produtoIngredienteId) REFERENCES produtos(id),
        FOREIGN KEY (unidadeId) REFERENCES unidades_medida(id)
      )
    ''');

    // Stock movements history
    await db.execute('''
      CREATE TABLE movimentos_estoque (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operacaoId INTEGER,
        data TEXT NOT NULL,
        produtoId INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        quantidade REAL NOT NULL,
        valorUnitario REAL NOT NULL,
        unidadeId INTEGER NOT NULL,
        FOREIGN KEY (produtoId) REFERENCES produtos(id),
        FOREIGN KEY (unidadeId) REFERENCES unidades_medida(id)
      )
    ''');

    // Company info (single row)
    await db.execute('''
      CREATE TABLE empresa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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

    // Custos operacionais da empresa (add/remove only)
    await db.execute('''
      CREATE TABLE custos_operacionais (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        empresaId INTEGER NOT NULL,
        nome TEXT NOT NULL,
        valor REAL NOT NULL,
        FOREIGN KEY (empresaId) REFERENCES empresa(id)
      )
    ''');

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

    await _seedUnidades(db);
  }

  Future<void> _seedUnidades(Database db) async {
    const unidades = [
      (1, 'Grama', 'g', 'peso', 1.0),
      (2, 'Quilograma', 'kg', 'peso', 1000.0),
      (3, 'Miligrama', 'mg', 'peso', 0.001),
      (4, 'Mililitro', 'ml', 'volume', 1.0),
      (5, 'Litro', 'L', 'volume', 1000.0),
      (6, 'Xícara', 'xíc', 'volume', 240.0),
      (7, 'Colher de sopa', 'c.sopa', 'volume', 15.0),
      (8, 'Colher de chá', 'c.chá', 'volume', 5.0),
      (9, 'Unidade', 'und', 'unidade', 1.0),
      (10, 'Dúzia', 'dz', 'unidade', 12.0),
      (11, 'Metro', 'm', 'comprimento', 1.0),
      (12, 'Centímetro', 'cm', 'comprimento', 0.01),
    ];
    final batch = db.batch();
    for (final unidade in unidades) {
      batch.insert('unidades_medida', {
        'id': unidade.$1,
        'nome': unidade.$2,
        'sigla': unidade.$3,
        'grupo': unidade.$4,
        'fatorParaBase': unidade.$5,
      });
    }
    await batch.commit(noResult: true);
  }
}
