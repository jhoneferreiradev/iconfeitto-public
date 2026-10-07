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
      version: 20,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(
    Database db,
    int version, {
    bool seedUnidades = true,
  }) async {
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
    await _createProdutosTable(db);

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

    await _createCustosOperacionaisTable(db);
    await _createFinanceiroTables(db);
    // await _createFichaTecnicaEmbalagem(db);
    if (seedUnidades) await _seedUnidades(db);
  }

  /// Schema atual da tabela de produtos (v5+). [nome] permite criar uma
  /// tabela temporária durante a migração.
  Future<void> _createProdutosTable(
    Database db, {
    String nome = 'produtos',
    bool legacyTextId = false,
  }) {
    final idColumn = legacyTextId
        ? 'TEXT PRIMARY KEY'
        : 'INTEGER PRIMARY KEY AUTOINCREMENT';
    final unidadeIdType = legacyTextId ? 'TEXT' : 'INTEGER';
    return db.execute('''
      CREATE TABLE $nome (
        id $idColumn,
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
        unidadeEstoqueId $unidadeIdType NOT NULL,
        unidadeConsumoId $unidadeIdType NOT NULL,
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
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        empresaId INTEGER NOT NULL,
        nome TEXT NOT NULL,
        valor REAL NOT NULL,
        FOREIGN KEY (empresaId) REFERENCES empresa(id)
      )
    ''');
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

  Future<void> _adicionarColunaSeNecessario(
    Database db,
    String tabela,
    String coluna,
    String definicao,
  ) async {
    final colunas = await db.rawQuery('PRAGMA table_info($tabela)');
    if (colunas.any((c) => c['name'] == coluna)) return;
    await db.execute('ALTER TABLE $tabela ADD COLUMN $coluna $definicao');
  }

  /// v17: dados do cartão (vencimento/fechamento), bandeiras com taxa,
  /// taxas e dia de depósito no lançamento.
  Future<void> _migrarFinanceiroV17(Database db) async {
    await _createFinanceiroTables(db);
    await _adicionarColunaSeNecessario(
      db,
      'cartoes_credito',
      'diaVencimento',
      'INTEGER NOT NULL DEFAULT 10',
    );
    await _adicionarColunaSeNecessario(
      db,
      'cartoes_credito',
      'diasFechamento',
      'INTEGER NOT NULL DEFAULT 7',
    );
    await _adicionarColunaSeNecessario(
      db,
      'lancamentos_financeiros',
      'valorTaxasImpostos',
      'REAL NOT NULL DEFAULT 0',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createCustosOperacionaisTable(db);
    }

    if (oldVersion < 3) {
      // await _createFichaTecnicaEmbalagem(db);
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

    if (oldVersion < 8) {
      final colunas = await db.rawQuery('PRAGMA table_info(produtos)');
      if (!colunas.any((coluna) => coluna['name'] == 'tipo')) {
        await db.execute(
          "ALTER TABLE produtos ADD COLUMN tipo TEXT NOT NULL DEFAULT 'produto'",
        );
      }
      await db.execute('''
        UPDATE produtos
        SET tipo = CASE
          WHEN isEmbalagem = 1 THEN 'embalagem'
          WHEN podeSerVendido = 1 THEN 'produto'
          WHEN possuiFichaTecnica = 1 THEN 'preparo'
          WHEN podeSerComprado = 1 THEN 'insumo'
          ELSE 'produto'
        END
      ''');
    }

    if (oldVersion < 9) {
      await db.execute('''
        UPDATE produtos
        SET unidadeEstoqueId = 'un', unidadeConsumoId = 'un'
        WHERE tipo = 'embalagem' OR isEmbalagem = 1
      ''');
    }

    if (oldVersion < 10) {
      await db.execute('''
      INSERT INTO unidades_medida (id, nome, sigla, grupo, fatorParaBase) VALUES
        ('m', 'Metro', 'm', 'GrupoUnidade.comprimento', 1),
        ('cm', 'Centímetro', 'cm', 'GrupoUnidade.comprimento', 0.01);
    ''');
    }

    if (oldVersion < 11) {
      await db.execute('''
        UPDATE unidades_medida
        SET sigla = 'und'
        WHERE sigla = 'un'
      ''');

      await db.execute('''
        ALTER TABLE itens_ficha_tecnica_embalagem ADD COLUMN quantidade REAL NOT NULL DEFAULT 0
      ''');

      await db.execute('''
        ALTER TABLE itens_ficha_tecnica_embalagem ADD COLUMN unidadeId TEXT NULL REFERENCES unidades_medida(id)
      ''');

      await db.execute('''
        UPDATE itens_ficha_tecnica_embalagem
        SET unidadeId = (SELECT id FROM unidades_medida WHERE sigla = 'und' LIMIT 1)
        WHERE unidadeId IS NULL
      ''');

      await db.execute('''
        ALTER TABLE itens_ficha_tecnica_embalagem
        ALTER COLUMN unidadeId SET NOT NULL
      ''');
    }

    if (oldVersion < 12) {
      await _ajustarEmbalagensDaFichaTecnica(db);
    }

    if (oldVersion < 13) {
      await db.execute('DROP TABLE IF EXISTS itens_ficha_tecnica_embalagem');
    }

    if (oldVersion < 14) {
      await _migrarChavesPrimariasParaInteiro(db);
    }

    if (oldVersion < 15) {
      // A migração para v14 já cria a coluna nas tabelas recriadas.
      final colunas = await db.rawQuery('PRAGMA table_info(fabricacoes)');
      final existe = colunas.any((c) => c['name'] == 'fabricacaoPaiId');
      if (!existe) {
        await db.execute(
          'ALTER TABLE fabricacoes ADD COLUMN fabricacaoPaiId INTEGER '
          'REFERENCES fabricacoes(id)',
        );
      }
    }

    if (oldVersion < 16) {
      await _createFinanceiroTables(db);
    }

    if (oldVersion < 17) {
      await _migrarFinanceiroV17(db);
    }

    if (oldVersion < 18) {
      // O pagamento é sempre um lançamento com quitação: sem tabela de caixa.
      await db.execute('DROP TABLE IF EXISTS movimentacoes_caixa');
    }

    if (oldVersion < 19) {
      // v19: dias para compensação na bandeira e data de compensação no
      // lançamento a receber.
      await _adicionarColunaSeNecessario(
        db,
        'bandeiras_cartao',
        'diasCompensacao',
        'INTEGER NOT NULL DEFAULT 1',
      );
      await _adicionarColunaSeNecessario(
        db,
        'lancamentos_financeiros',
        'dataCompensacao',
        'TEXT',
      );
    }
    
    if (oldVersion < 20) {
      // v20: taxa da bandeira em percentual ou valor fixo.
      await _adicionarColunaSeNecessario(
        db,
        'bandeiras_cartao',
        'tipoTaxa',
        "TEXT NOT NULL DEFAULT 'percentual'",
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
    await _createProdutosTable(db, nome: tabelaTemporaria, legacyTextId: true);

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

  Future<void> _ajustarEmbalagensDaFichaTecnica(Database db) async {
    await db.execute('''

      INSERT INTO itens_ficha_tecnica(
        produtoId, produtoIngredienteId, quantidade, unidadeId
      )
      SELECT
        produtoId, produtoEmbalagemId, quantidade, unidadeId
      FROM itens_ficha_tecnica_embalagem

    ''');
  }

  Future<void> _migrarChavesPrimariasParaInteiro(Database db) async {
    const tabelas = [
      'unidades_medida',
      'produtos',
      'fornecedores',
      'clientes',
      'compras',
      'vendas',
      'fabricacoes',
      'movimentos_estoque',
      'empresa',
      'custos_operacionais',
      'itens_ficha_tecnica',
      'itens_compra',
      'itens_venda',
      'itens_fabricacao_registro',
    ];

    for (final tabela in tabelas) {
      await db.execute(
        'CREATE TEMP TABLE migracao_$tabela AS SELECT * FROM $tabela',
      );
    }

    const idsUnidades = {
      'g': 1,
      'kg': 2,
      'mg': 3,
      'ml': 4,
      'l': 5,
      'xicara': 6,
      'colher-sopa': 7,
      'colher-cha': 8,
      'un': 9,
      'dz': 10,
      'm': 11,
      'cm': 12,
    };
    await _criarMapaIds(db, 'unidades_medida', idsUnidades);
    for (final tabela in [
      'produtos',
      'fornecedores',
      'clientes',
      'compras',
      'vendas',
      'fabricacoes',
      'movimentos_estoque',
      'custos_operacionais',
    ]) {
      await _criarMapaIds(db, tabela);
    }
    await _criarMapaIds(db, 'empresa', const {'empresa': 1});

    for (final tabela in [
      'itens_ficha_tecnica',
      'itens_compra',
      'itens_venda',
      'itens_fabricacao_registro',
      'custos_operacionais',
      'movimentos_estoque',
      'fabricacoes',
      'vendas',
      'compras',
      'produtos',
      'fornecedores',
      'clientes',
      'empresa',
      'unidades_medida',
    ]) {
      await db.execute('DROP TABLE $tabela');
    }
    await _onCreate(db, 14, seedUnidades: false);

    await db.execute('''
      INSERT INTO unidades_medida (id, nome, sigla, grupo, fatorParaBase)
      SELECT ids.newId, old.nome, old.sigla,
        REPLACE(old.grupo, 'GrupoUnidade.', ''), old.fatorParaBase
      FROM migracao_unidades_medida old
      JOIN migracao_ids_unidades_medida ids ON ids.oldId = old.id
    ''');
    await db.execute('''
      INSERT INTO empresa (
        id, nome, cnpjCpf, telefone, endereco, instagram, facebook,
        logoPath, despesasGlobais
      )
      SELECT ids.newId, old.nome, old.cnpjCpf, old.telefone, old.endereco,
        old.instagram, old.facebook, old.logoPath, old.despesasGlobais
      FROM migracao_empresa old
      JOIN migracao_ids_empresa ids ON ids.oldId = old.id
    ''');
    await db.execute('''
      INSERT INTO fornecedores (id, nome, ativo)
      SELECT ids.newId, old.nome, old.ativo
      FROM migracao_fornecedores old
      JOIN migracao_ids_fornecedores ids ON ids.oldId = old.id
    ''');
    await db.execute('''
      INSERT INTO clientes (id, nome, ativo)
      SELECT ids.newId, old.nome, old.ativo
      FROM migracao_clientes old
      JOIN migracao_ids_clientes ids ON ids.oldId = old.id
    ''');
    await db.execute('''
      INSERT INTO produtos (
        id, nome, ativo, custoMedio, saldoEstoque, podeSerVendido,
        podeSerComprado, tipo, possuiFichaTecnica, tempoPreparoMinutos,
        rendimentoReceita, custoOperacional, unidadeEstoqueId,
        unidadeConsumoId, isEmbalagem, custoEmbalagem, precoVenda
      )
      SELECT ids.newId, old.nome, old.ativo, old.custoMedio, old.saldoEstoque,
        old.podeSerVendido, old.podeSerComprado,
        REPLACE(old.tipo, 'TipoItem.', ''), old.possuiFichaTecnica,
        old.tempoPreparoMinutos, old.rendimentoReceita, old.custoOperacional,
        estoque.newId, consumo.newId, old.isEmbalagem, old.custoEmbalagem,
        old.precoVenda
      FROM migracao_produtos old
      JOIN migracao_ids_produtos ids ON ids.oldId = old.id
      JOIN migracao_ids_unidades_medida estoque
        ON estoque.oldId = old.unidadeEstoqueId
      JOIN migracao_ids_unidades_medida consumo
        ON consumo.oldId = old.unidadeConsumoId
    ''');
    await db.execute('''
      INSERT INTO compras (id, data, fornecedorId)
      SELECT ids.newId, old.data, fornecedor.newId
      FROM migracao_compras old
      JOIN migracao_ids_compras ids ON ids.oldId = old.id
      JOIN migracao_ids_fornecedores fornecedor
        ON fornecedor.oldId = old.fornecedorId
    ''');
    await db.execute('''
      INSERT INTO vendas (id, data, clienteId)
      SELECT ids.newId, old.data, cliente.newId
      FROM migracao_vendas old
      JOIN migracao_ids_vendas ids ON ids.oldId = old.id
      JOIN migracao_ids_clientes cliente ON cliente.oldId = old.clienteId
    ''');
    await db.execute('''
      INSERT INTO fabricacoes (id, data, produtoId, quantidade)
      SELECT ids.newId, old.data, produto.newId, old.quantidade
      FROM migracao_fabricacoes old
      JOIN migracao_ids_fabricacoes ids ON ids.oldId = old.id
      JOIN migracao_ids_produtos produto ON produto.oldId = old.produtoId
    ''');
    await db.execute('''
      INSERT INTO itens_ficha_tecnica (
        produtoId, produtoIngredienteId, quantidade, unidadeId
      )
      SELECT produto.newId, ingrediente.newId, old.quantidade, unidade.newId
      FROM migracao_itens_ficha_tecnica old
      JOIN migracao_ids_produtos produto ON produto.oldId = old.produtoId
      JOIN migracao_ids_produtos ingrediente
        ON ingrediente.oldId = old.produtoIngredienteId
      JOIN migracao_ids_unidades_medida unidade ON unidade.oldId = old.unidadeId
    ''');
    await db.execute('''
      INSERT INTO itens_compra (
        compraId, produtoId, quantidade, valorUnitario, unidadeId
      )
      SELECT compra.newId, produto.newId, old.quantidade, old.valorUnitario,
        unidade.newId
      FROM migracao_itens_compra old
      JOIN migracao_ids_compras compra ON compra.oldId = old.compraId
      JOIN migracao_ids_produtos produto ON produto.oldId = old.produtoId
      JOIN migracao_ids_unidades_medida unidade ON unidade.oldId = old.unidadeId
    ''');
    await db.execute('''
      INSERT INTO itens_venda (
        vendaId, produtoId, quantidade, valorUnitario, unidadeId
      )
      SELECT venda.newId, produto.newId, old.quantidade, old.valorUnitario,
        unidade.newId
      FROM migracao_itens_venda old
      JOIN migracao_ids_vendas venda ON venda.oldId = old.vendaId
      JOIN migracao_ids_produtos produto ON produto.oldId = old.produtoId
      JOIN migracao_ids_unidades_medida unidade ON unidade.oldId = old.unidadeId
    ''');
    await db.execute('''
      INSERT INTO itens_fabricacao_registro (
        fabricacaoId, produtoIngredienteId, quantidade, unidadeId
      )
      SELECT fabricacao.newId, ingrediente.newId, old.quantidade, unidade.newId
      FROM migracao_itens_fabricacao_registro old
      JOIN migracao_ids_fabricacoes fabricacao
        ON fabricacao.oldId = old.fabricacaoId
      JOIN migracao_ids_produtos ingrediente
        ON ingrediente.oldId = old.produtoIngredienteId
      JOIN migracao_ids_unidades_medida unidade ON unidade.oldId = old.unidadeId
    ''');
    await db.execute('''
      INSERT INTO movimentos_estoque (
        id, operacaoId, data, produtoId, tipo, quantidade, valorUnitario,
        unidadeId
      )
      SELECT ids.newId,
        CASE
          WHEN old.operacaoId IS NULL THEN NULL
          WHEN old.tipo LIKE '%compra%' THEN compra.newId
          WHEN old.tipo LIKE '%venda%' THEN venda.newId
          WHEN old.tipo LIKE '%Fabricacao%'
            OR old.tipo LIKE '%producao%'
            OR old.tipo LIKE '%consumoFabricacao%'
            THEN fabricacao.newId
          ELSE NULL
        END,
        old.data, produto.newId,
        REPLACE(old.tipo, 'TipoMovimentoEstoque.', ''), old.quantidade,
        old.valorUnitario, unidade.newId
      FROM migracao_movimentos_estoque old
      JOIN migracao_ids_movimentos_estoque ids ON ids.oldId = old.id
      JOIN migracao_ids_produtos produto ON produto.oldId = old.produtoId
      JOIN migracao_ids_unidades_medida unidade ON unidade.oldId = old.unidadeId
      LEFT JOIN migracao_ids_compras compra ON compra.oldId = old.operacaoId
      LEFT JOIN migracao_ids_vendas venda ON venda.oldId = old.operacaoId
      LEFT JOIN migracao_ids_fabricacoes fabricacao
        ON fabricacao.oldId = old.operacaoId
    ''');
    await db.execute('''
      INSERT INTO custos_operacionais (id, empresaId, nome, valor)
      SELECT ids.newId, empresa.newId, old.nome, old.valor
      FROM migracao_custos_operacionais old
      JOIN migracao_ids_custos_operacionais ids ON ids.oldId = old.id
      JOIN migracao_ids_empresa empresa ON empresa.oldId = old.empresaId
    ''');

    final totalUnidades = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM unidades_medida'),
    );
    if (totalUnidades == 0) await _seedUnidades(db);

    for (final tabela in tabelas) {
      final antigos = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM migracao_$tabela'),
      );
      final migrados = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $tabela'),
      );
      if (antigos != migrados) {
        throw StateError(
          'Migração de $tabela incompleta: $migrados de $antigos registros.',
        );
      }
    }
  }

  Future<void> _criarMapaIds(
    Database db,
    String tabela, [
    Map<String, int> idsFixos = const {},
  ]) async {
    final nomeTabela = 'migracao_ids_$tabela';
    await db.execute(
      'CREATE TEMP TABLE $nomeTabela (oldId TEXT PRIMARY KEY, newId INTEGER NOT NULL)',
    );
    final linhas = await db.query('migracao_$tabela', columns: ['id']);
    var proximoId = idsFixos.values.fold<int>(
      0,
      (maior, id) => id > maior ? id : maior,
    );
    final idsExistentes = <String>{};
    for (final linha in linhas) {
      final idAntigo = linha['id'].toString();
      idsExistentes.add(idAntigo);
      await db.insert(nomeTabela, {
        'oldId': idAntigo,
        'newId': idsFixos[idAntigo] ?? ++proximoId,
      });
    }
    for (final entrada in idsFixos.entries) {
      if (!idsExistentes.contains(entrada.key)) {
        await db.insert(nomeTabela, {
          'oldId': entrada.key,
          'newId': entrada.value,
        });
      }
    }
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

  Future<void> close() async {
    await _database?.close();
  }
}
