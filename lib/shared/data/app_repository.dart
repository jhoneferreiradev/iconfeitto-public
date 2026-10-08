import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/cartao_credito.dart';
import '../models/cliente.dart';
import '../models/custo_operacional.dart';
import '../models/empresa.dart';
import '../models/forma_pagamento.dart';
import '../models/fornecedor.dart';
import '../models/grupo_unidade.dart';
import '../models/item_ficha_tecnica.dart';
import '../models/item_ficha_tecnica_embalagem.dart';
import '../models/lancamento_financeiro.dart';
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
  final List<LancamentoFinanceiro> lancamentosFinanceiros = [];
  final List<PessoaFinanceiro> pessoasFinanceiro = [];
  final List<CartaoCredito> cartoesCredito = [];
  final List<BandeiraCartaoCredito> bandeirasCartaoCredito = [];
  Empresa empresa = const Empresa();

  late final Database _db;
  bool _initialized = false;
  int _ultimoIdGerado = 0;

  bool get isInitialized => _initialized;

  String novoId() {
    final agora = DateTime.now().microsecondsSinceEpoch;
    _ultimoIdGerado = agora > _ultimoIdGerado ? agora : _ultimoIdGerado + 1;
    return _ultimoIdGerado.toString();
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
    lancamentosFinanceiros.clear();
    pessoasFinanceiro.clear();
    cartoesCredito.clear();
    bandeirasCartaoCredito.clear();

    // Load unidades
    final unidadesData = await _db.query('unidades_medida');
    for (final row in unidadesData) {
      unidades.add(_unidadeFromRow(row));
    }

    // Load fornecedores
    final fornecedoresData = await _db.query('fornecedores');
    for (final row in fornecedoresData) {
      fornecedores.add(
        Fornecedor(
          id: _idString(row['id']),
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
          id: _idString(row['id']),
          nome: row['nome'] as String,
          ativo: (row['ativo'] as int) == 1,
        ),
      );
    }

    // Load produtos (including ficha técnica)
    final produtosData = await _db.query('produtos');
    for (final row in produtosData) {
      final produtoId = _idString(row['id']);
      final fichaTecnicaRows = await _db.rawQuery(
        '''
        SELECT ift.*
        FROM itens_ficha_tecnica ift
        JOIN produtos ingrediente ON ift.produtoIngredienteId = ingrediente.id
        WHERE ift.produtoId = ?
        AND ingrediente.tipo <> ?
        ''',
        [produtoId, 'embalagem'],
      );

      final fichaTecnicaEmbalagemRows = await _db.rawQuery(
        '''
        SELECT ift.*
        FROM itens_ficha_tecnica ift
        JOIN produtos embalagem ON ift.produtoIngredienteId = embalagem.id
        WHERE ift.produtoId = ?
        AND embalagem.tipo = 'embalagem'
        ''',
        [produtoId],
      );

      final fichaTecnica = [
        for (final fichaRow in fichaTecnicaRows)
          ItemFichaTecnica(
            produtoIngredienteId: _idString(fichaRow['produtoIngredienteId']),
            quantidade: fichaRow['quantidade'] as double,
            unidadeId: _idString(fichaRow['unidadeId']),
          ),
      ];

      final fichaTecnicaEmbalagem = [
        for (final fichaRow in fichaTecnicaEmbalagemRows)
          ItemFichaTecnicaEmbalagem(
            produtoEmbalagemId: _idString(fichaRow['produtoIngredienteId']),
            quantidade: fichaRow['quantidade'] as double,
            unidadeId: _idString(fichaRow['unidadeId']),
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
          unidadeEstoqueId: _idString(row['unidadeEstoqueId']),
          unidadeConsumoId: _idString(row['unidadeConsumoId']),
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
      final compraId = _idString(row['id']);
      final itensData = await _db.query(
        'itens_compra',
        where: 'compraId = ?',
        whereArgs: [compraId],
        orderBy: 'id',
      );
      final itens = [
        for (final itemRow in itensData)
          ItemOperacao(
            produtoId: _idString(itemRow['produtoId']),
            quantidade: itemRow['quantidade'] as double,
            valorUnitario: itemRow['valorUnitario'] as double,
            unidadeId: _idString(itemRow['unidadeId']),
          ),
      ];

      compras.add(
        Compra(
          id: compraId,
          data: DateTime.parse(row['data'] as String),
          fornecedorId: _idString(row['fornecedorId']),
          itens: itens,
        ),
      );
    }

    // Load vendas (including items)
    final vendasData = await _db.query('vendas');
    for (final row in vendasData) {
      final vendaId = _idString(row['id']);
      final itensData = await _db.query(
        'itens_venda',
        where: 'vendaId = ?',
        whereArgs: [vendaId],
      );
      final itens = [
        for (final itemRow in itensData)
          ItemOperacao(
            produtoId: _idString(itemRow['produtoId']),
            quantidade: itemRow['quantidade'] as double,
            valorUnitario: itemRow['valorUnitario'] as double,
            unidadeId: _idString(itemRow['unidadeId']),
          ),
      ];

      vendas.add(
        Venda(
          id: vendaId,
          data: DateTime.parse(row['data'] as String),
          clienteId: _idString(row['clienteId']),
          itens: itens,
          tipo: _enumPorNome(
            TipoVenda.values,
            row['tipo'],
            TipoVenda.prontaEntrega,
          ),
          status: _enumPorNome(
            StatusVenda.values,
            row['status'],
            StatusVenda.entregue,
          ),
          dataEntrega: row['dataEntrega'] == null
              ? null
              : DateTime.parse(row['dataEntrega'] as String),
          // Vendas antigas não guardavam a entrega: a saída foi na data.
          dataEntregue: row['dataEntregue'] == null
              ? null
              : DateTime.parse(row['dataEntregue'] as String),
        ),
      );
    }

    // Load fabricacoes (including items)
    final fabricacoesData = await _db.query('fabricacoes');
    for (final row in fabricacoesData) {
      final fabricacaoId = _idString(row['id']);
      final itensData = await _db.query(
        'itens_fabricacao_registro',
        where: 'fabricacaoId = ?',
        whereArgs: [fabricacaoId],
      );
      final fichaTecnica = [
        for (final itemRow in itensData)
          ItemFichaTecnica(
            produtoIngredienteId: _idString(itemRow['produtoIngredienteId']),
            quantidade: itemRow['quantidade'] as double,
            unidadeId: _idString(itemRow['unidadeId']),
          ),
      ];

      fabricacoes.add(
        Fabricacao(
          id: fabricacaoId,
          data: DateTime.parse(row['data'] as String),
          produtoId: _idString(row['produtoId']),
          quantidade: row['quantidade'] as double,
          fichaTecnica: fichaTecnica,
          fabricacaoPaiId: row['fabricacaoPaiId']?.toString(),
          vendaId: row['vendaId']?.toString(),
        ),
      );
    }

    // Load movimentos estoque
    final movimentosData = await _db.query('movimentos_estoque');
    for (final row in movimentosData) {
      movimentacoes.add(
        MovimentoEstoque(
          id: _idString(row['id']),
          operacaoId: row['operacaoId']?.toString(),
          data: DateTime.parse(row['data'] as String),
          produtoId: _idString(row['produtoId']),
          tipo: _tipoMovimentoFromString(row['tipo'] as String),
          quantidade: row['quantidade'] as double,
          valorUnitario: row['valorUnitario'] as double,
          unidadeId: _idString(row['unidadeId']),
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

    await _loadCartoesCredito();
    await _loadBandeirasCartao();
    _loadPessoasFinanceiras();
    await _loadLancamentosFinanceiros();
  }

  void _loadPessoasFinanceiras() {
    pessoasFinanceiro.addAll(
      clientes.map(
        (e) => PessoaFinanceiro(
          id: e.id,
          nome: e.nome,
          tipoPessoaFinanceiro: TipoPessoaFinanceiro.cliente,
        ),
      ),
    );
    pessoasFinanceiro.addAll(
      fornecedores.map(
        (e) => PessoaFinanceiro(
          id: e.id,
          nome: e.nome,
          tipoPessoaFinanceiro: TipoPessoaFinanceiro.fornecedor,
        ),
      ),
    );
    pessoasFinanceiro.addAll(
      cartoesCredito.map(
        (e) => PessoaFinanceiro(
          id: e.id,
          nome: e.nome,
          tipoPessoaFinanceiro: TipoPessoaFinanceiro.cartaoCredito,
        ),
      ),
    );
    pessoasFinanceiro.addAll(
      bandeirasCartaoCredito.map(
        (e) => PessoaFinanceiro(
          id: e.id,
          nome: e.nome,
          tipoPessoaFinanceiro: TipoPessoaFinanceiro.bandeiraCartaoCredito,
        ),
      ),
    );
  }

  UnidadeMedida unidadePorId(String id) =>
      unidades.firstWhere((u) => u.id == id);

  Produto? produtoPorId(String id) {
    for (final p in produtos) {
      if (p.id == id) return p;
    }
    return null;
  }

  LancamentoFinanceiro? lancamentoFinanceiroPorId(String id) {
    for (final l in lancamentosFinanceiros) {
      if (l.id == id) return l;
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
      await _db.insert('itens_ficha_tecnica', {
        'produtoId': produto.id,
        'produtoIngredienteId': item.produtoEmbalagemId,
        'quantidade': item.quantidade,
        'unidadeId': item.unidadeId,
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
    // await _db.delete(
    //   'itens_ficha_tecnica_embalagem',
    //   where: 'produtoId = ?',
    //   whereArgs: [id],
    // );
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
          'grupo': unidade.grupo.name,
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
        'grupo': unidade.grupo.name,
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
    await _db.transaction((transaction) async {
      await _inserirCompra(transaction, compra, movimentosNovos);
      for (final lancamento in compra.lancamentosFinanceiros) {
        await _gravarLancamento(transaction, lancamento);
      }
    });
    compras.add(compra);
    movimentacoes.addAll(movimentosNovos);
    recalcularEstoque(
      produtosSemMovimentacoes: movimentosNovos
          .map((movimento) => movimento.produtoId)
          .toSet(),
      saldosIniciais: saldosIniciais,
    );
    await _persistirProdutos();

    _registrarLancamentosDaCompra(compra);

    notifyListeners();
  }

  Future<void> atualizarCompra(
    Compra compra, {
    bool atualizarFinanceiro = false,
  }) async {
    final indice = compras.indexWhere((existente) => existente.id == compra.id);
    if (indice < 0) {
      throw StateError('A compra que você tentou editar não foi encontrada.');
    }
    if (lancamentosDaCompra(compra.id).any((l) => l.hasQuitacoes)) {
      throw StateError(
        'Esta compra possui lançamentos financeiros com pagamentos '
        '(quitações) e não pode ser editada. Remova as quitações antes.',
      );
    }

    // recupere a data da compra original, do banco
    final compraDoBancoRaw = await _db.query(
      'compras',
      where: 'id = ?',
      whereArgs: [compra.id],
    );
    final compraDoBanco = compraDoBancoRaw.isNotEmpty
        ? compraDoBancoRaw.first
        : null;
    final dataCompraOriginal = compraDoBanco != null
        ? DateTime.parse(compraDoBanco['data'] as String)
        : null;

    final dataCompraAlterada =
        dataCompraOriginal != null && dataCompraOriginal != compra.data;

    final movimentosAntigos = _movimentosDaCompra(compras[indice]);
    final movimentosNovos = _criarMovimentosCompra(compra);

    bool deveRemover(MovimentoEstoque mov) {
      final idx = compra.itens.indexWhere(
        (item) =>
            item.produtoId == mov.produtoId &&
            item.quantidade == mov.quantidade &&
            item.unidadeId == mov.unidadeId &&
            mov.valorUnitario == item.valorUnitario,
      );
      return idx >= 0;
    }

    if (!dataCompraAlterada) {
      movimentosAntigos.removeWhere(deveRemover);
      movimentosNovos.removeWhere(deveRemover);
    }

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
      if (atualizarFinanceiro) {
        await _excluirLancamentosDaCompraDoBanco(transaction, compra.id);
        for (final lancamento in compra.lancamentosFinanceiros) {
          await _gravarLancamento(transaction, lancamento);
        }
      }
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

    if (atualizarFinanceiro) {
      _removerLancamentosDaCompra(compra.id);
      _registrarLancamentosDaCompra(compra);
    }

    notifyListeners();
  }

  Future<void> excluirCompra(String compraId) async {
    final indice = compras.indexWhere((compra) => compra.id == compraId);
    if (indice < 0) return;

    final compra = compras[indice];
    if (lancamentosDaCompra(compraId).any((l) => l.hasQuitacoes)) {
      throw StateError(
        'Esta compra possui lançamentos financeiros com pagamentos '
        'registrados. Exclua as quitações antes de excluir a compra.',
      );
    }
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
      await _excluirLancamentosDaCompraDoBanco(transaction, compraId);
    });

    movimentacoes.removeWhere(
      (movimento) => idsRemovidos.contains(movimento.id),
    );
    compras.removeAt(indice);
    _removerLancamentosDaCompra(compraId);
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
    final movimentosNovos = _criarMovimentosVenda(venda);
    final saldosIniciais = _capturarSaldosIniciais(
      movimentosNovos.map((movimento) => movimento.produtoId),
    );
    _validarSaldoEstoque(movimentosNovos);
    await _db.transaction((transaction) async {
      await _inserirVenda(transaction, venda, movimentosNovos);
      for (final lancamento in venda.lancamentosFinanceiros) {
        await _gravarLancamento(transaction, lancamento);
      }
    });
    vendas.add(venda);
    _registrarLancamentos(venda.lancamentosFinanceiros);
    movimentacoes.addAll(movimentosNovos);
    recalcularEstoque(saldosIniciais: saldosIniciais);
    await _persistirProdutos();
    notifyListeners();
  }

  Future<void> atualizarVenda(
    Venda venda, {
    bool atualizarFinanceiro = false,
  }) async {
    final indice = vendas.indexWhere((existente) => existente.id == venda.id);
    if (indice < 0) {
      throw StateError('A venda que você tentou editar não foi encontrada.');
    }
    if (lancamentosDaVenda(venda.id).any((l) => l.hasQuitacoes)) {
      throw StateError(
        'Esta venda possui lançamentos financeiros com pagamentos '
        '(quitações) e não pode ser editada. Remova as quitações antes.',
      );
    }

    if (!vendas[indice].itensEditaveis) {
      throw StateError(
        'Só é possível editar os itens de uma venda com o pedido recebido. '
        'Reabra a venda para alterá-la.',
      );
    }
    final movimentosAntigos = _movimentosDaVenda(vendas[indice]);
    final movimentosNovos = _criarMovimentosVenda(venda);
    final idsAntigos = movimentosAntigos
        .map((movimento) => movimento.id)
        .toSet();
    final produtosAfetados = {
      ...movimentosAntigos.map((movimento) => movimento.produtoId),
      ...movimentosNovos.map((movimento) => movimento.produtoId),
    };
    final saldosIniciais = _capturarSaldosIniciais(produtosAfetados);
    _validarSaldoEstoque(movimentosNovos, removerIds: idsAntigos);
    await _db.transaction((transaction) async {
      await _removerVendaDoBanco(transaction, venda.id, movimentosAntigos);
      await _inserirVenda(transaction, venda, movimentosNovos);
      if (atualizarFinanceiro) {
        await _excluirLancamentosDaOperacaoDoBanco(
          transaction,
          TipoOperacaoOrigem.venda,
          venda.id,
        );
        for (final lancamento in venda.lancamentosFinanceiros) {
          await _gravarLancamento(transaction, lancamento);
        }
      }
    });

    movimentacoes.removeWhere((movimento) => idsAntigos.contains(movimento.id));
    movimentacoes.addAll(movimentosNovos);
    vendas[indice] = venda;
    if (atualizarFinanceiro) {
      _removerLancamentosDaOperacao(TipoOperacaoOrigem.venda, venda.id);
      _registrarLancamentos(venda.lancamentosFinanceiros);
    }
    recalcularEstoque(
      produtosSemMovimentacoes: produtosAfetados,
      saldosIniciais: saldosIniciais,
    );
    await _persistirProdutos();
    notifyListeners();
  }

  Future<void> excluirVenda(String vendaId) async {
    final indice = vendas.indexWhere((venda) => venda.id == vendaId);
    if (indice < 0) return;

    if (lancamentosDaVenda(vendaId).any((l) => l.hasQuitacoes)) {
      throw StateError(
        'Esta venda possui lançamentos financeiros com pagamentos '
        'registrados. Exclua as quitações antes de excluir a venda.',
      );
    }
    if (const [
      StatusVenda.emProducao,
      StatusVenda.aguardandoRetirada,
      StatusVenda.emEntrega,
    ].contains(vendas[indice].status)) {
      throw StateError(
        'Esta venda está em andamento. Cancele a venda antes de excluí-la.',
      );
    }
    final movimentosDaVenda = _movimentosDaVenda(vendas[indice]);
    final idsRemovidos = movimentosDaVenda
        .map((movimento) => movimento.id)
        .toSet();
    final produtosAfetados = movimentosDaVenda
        .map((movimento) => movimento.produtoId)
        .toSet();
    final saldosIniciais = _capturarSaldosIniciais(produtosAfetados);
    _validarSaldoEstoque(const [], removerIds: idsRemovidos);
    await _db.transaction((transaction) async {
      await _removerVendaDoBanco(transaction, vendaId, movimentosDaVenda);
      await _excluirLancamentosDaOperacaoDoBanco(
        transaction,
        TipoOperacaoOrigem.venda,
        vendaId,
      );
    });

    movimentacoes.removeWhere(
      (movimento) => idsRemovidos.contains(movimento.id),
    );
    vendas.removeAt(indice);
    _removerLancamentosDaOperacao(TipoOperacaoOrigem.venda, vendaId);
    recalcularEstoque(
      produtosSemMovimentacoes: produtosAfetados,
      saldosIniciais: saldosIniciais,
    );
    await _persistirProdutos();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Andamento da venda
  // ---------------------------------------------------------------------------

  int _indiceDaVenda(String vendaId) {
    final indice = vendas.indexWhere((venda) => venda.id == vendaId);
    if (indice < 0) throw StateError('A venda não foi encontrada.');
    return indice;
  }

  Future<void> _gravarStatusDaVenda(DatabaseExecutor database, Venda venda) =>
      database.update(
        'vendas',
        {
          'status': venda.status.name,
          'dataEntregue': venda.dataEntregue?.toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [venda.id],
      );

  bool _temFichaDeFabricacao(Produto? produto) =>
      produto != null &&
      TipoItem.tiposFabricacao.contains(produto.tipo) &&
      produto.possuiFichaTecnica &&
      produto.fichaTecnica.isNotEmpty;

  /// Mudança de status que não mexe no estoque (aguardando retirada, em
  /// percurso, cancelada). Produção e entrega têm métodos próprios.
  Future<void> alterarStatusVenda(String vendaId, StatusVenda novo) async {
    if (novo == StatusVenda.emProducao || novo == StatusVenda.entregue) {
      throw StateError('Use a ação específica para produzir ou entregar.');
    }
    final indice = _indiceDaVenda(vendaId);
    final venda = vendas[indice];
    if (!venda.proximosStatus.contains(novo)) {
      throw StateError(
        'Não é possível passar de "${venda.status.label}" para '
        '"${novo.label}".',
      );
    }
    final atualizada = venda.copyWith(status: novo);
    await _db.transaction(
      (transaction) => _gravarStatusDaVenda(transaction, atualizada),
    );
    vendas[indice] = atualizada;
    notifyListeners();
  }

  /// Preparos necessários para fabricar [quantidade] (na unidade de estoque)
  /// de [produto], em todos os níveis da ficha técnica. A lista vem na ordem
  /// de fabricação: um preparo só aparece depois dos preparos que ele usa, e
  /// cada preparo aparece uma única vez, com a quantidade somada.
  List<({String produtoId, double quantidade})> _planejarPreparos(
    Produto produto,
    double quantidade,
  ) {
    final totais = <String, double>{};

    void acumular(Produto atual, double quantidadeAtual, List<String> caminho) {
      for (final itemFicha in atual.fichaTecnica) {
        final ingrediente = produtoPorId(itemFicha.produtoIngredienteId);
        if (!_temFichaDeFabricacao(ingrediente)) continue;
        if (caminho.contains(ingrediente!.id)) {
          throw StateError(
            'A ficha técnica de "${ingrediente.nome}" usa ele mesmo '
            '(direta ou indiretamente).',
          );
        }
        final necessaria =
            itemFicha.quantidade *
            quantidadeAtual *
            unidadePorId(itemFicha.unidadeId).fatorParaBase /
            unidadePorId(ingrediente.unidadeEstoqueId).fatorParaBase;
        totais.update(
          ingrediente.id,
          (total) => total + necessaria,
          ifAbsent: () => necessaria,
        );
        acumular(ingrediente, necessaria, [...caminho, ingrediente.id]);
      }
    }

    acumular(produto, quantidade, [produto.id]);

    final ordem = <String>[];
    final visitados = <String>{};
    void visitar(Produto atual) {
      for (final itemFicha in atual.fichaTecnica) {
        final ingrediente = produtoPorId(itemFicha.produtoIngredienteId);
        if (!_temFichaDeFabricacao(ingrediente)) continue;
        if (visitados.add(ingrediente!.id)) {
          visitar(ingrediente);
          ordem.add(ingrediente.id);
        }
      }
    }

    visitar(produto);
    return [
      for (final id in ordem)
        if ((totais[id] ?? 0) > 0) (produtoId: id, quantidade: totais[id]!),
    ];
  }

  /// Inicia a produção de uma venda programada: fabrica os produtos (e seus
  /// preparos) do pedido, consumindo os insumos do estoque.
  Future<void> iniciarProducaoVenda(String vendaId) async {
    final indice = _indiceDaVenda(vendaId);
    final venda = vendas[indice];
    if (venda.tipo != TipoVenda.programada ||
        venda.status != StatusVenda.pedido) {
      throw StateError(
        'A produção só pode ser iniciada em uma venda programada com o '
        'pedido recebido.',
      );
    }
    final data = DateTime.now();
    final fabricacoesDaVenda = <Fabricacao>[];
    for (final item in venda.itens) {
      final produto = produtoPorId(item.produtoId);
      if (!_temFichaDeFabricacao(produto)) continue;
      final quantidade =
          item.quantidade *
          unidadePorId(item.unidadeId).fatorParaBase /
          unidadePorId(produto!.unidadeEstoqueId).fatorParaBase;

      // Preparos da ficha técnica (inclusive preparos dentro de preparos),
      // fabricados antes do produto final e todos vinculados a ele.
      final principalId = novoId();
      for (final preparo in _planejarPreparos(produto, quantidade)) {
        fabricacoesDaVenda.add(
          Fabricacao(
            id: novoId(),
            data: data,
            produtoId: preparo.produtoId,
            quantidade: preparo.quantidade,
            fabricacaoPaiId: principalId,
            vendaId: venda.id,
            fichaTecnica: produtoPorId(preparo.produtoId)!.fichaTecnica
                .map((itemFicha) => itemFicha.copy())
                .toList(),
          ),
        );
      }
      fabricacoesDaVenda.add(
        Fabricacao(
          id: principalId,
          data: data,
          produtoId: produto.id,
          quantidade: quantidade,
          vendaId: venda.id,
          fichaTecnica: produto.fichaTecnica
              .map((itemFicha) => itemFicha.copy())
              .toList(),
        ),
      );
    }

    // Valida o saldo dos insumos antes de alterar qualquer coisa.
    if (fabricacoesDaVenda.isNotEmpty) {
      await salvarFabricacoes(fabricacoesDaVenda);
    }
    final atualizada = venda.copyWith(status: StatusVenda.emProducao);
    await _db.transaction(
      (transaction) => _gravarStatusDaVenda(transaction, atualizada),
    );
    vendas[indice] = atualizada;
    notifyListeners();
  }

  /// Registra a entrega: a venda passa a "entregue" e o produto final sai do
  /// estoque na data da entrega.
  Future<void> entregarVenda(String vendaId, DateTime dataEntregue) async {
    final indice = _indiceDaVenda(vendaId);
    final venda = vendas[indice];
    if (!venda.proximosStatus.contains(StatusVenda.entregue)) {
      throw StateError(
        'Uma venda "${venda.status.label}" não pode ser marcada como '
        'entregue.',
      );
    }
    final entregue = venda.copyWith(
      status: StatusVenda.entregue,
      dataEntregue: dataEntregue,
    );
    final movimentosNovos = _criarMovimentosVenda(entregue);
    final saldosIniciais = _capturarSaldosIniciais(
      movimentosNovos.map((movimento) => movimento.produtoId),
    );
    _validarSaldoEstoque(movimentosNovos);
    await _db.transaction((transaction) async {
      await _gravarStatusDaVenda(transaction, entregue);
      for (final movimento in movimentosNovos) {
        await transaction.insert(
          'movimentos_estoque',
          _movimentoToRow(movimento),
        );
      }
    });
    vendas[indice] = entregue;
    movimentacoes.addAll(movimentosNovos);
    recalcularEstoque(saldosIniciais: saldosIniciais);
    await _persistirProdutos();
    notifyListeners();
  }

  /// Desfaz a entrega (devolvendo o produto ao estoque) ou reabre uma venda
  /// cancelada.
  Future<void> reabrirVenda(String vendaId) async {
    final indice = _indiceDaVenda(vendaId);
    final venda = vendas[indice];
    if (venda.status != StatusVenda.entregue &&
        venda.status != StatusVenda.cancelada) {
      throw StateError('Esta venda não está entregue nem cancelada.');
    }
    final temProducao = fabricacoes.any((f) => f.vendaId == venda.id);
    final destino = venda.tipo == TipoVenda.programada && temProducao
        ? (venda.entregue
              ? StatusVenda.aguardandoRetirada
              : StatusVenda.emProducao)
        : StatusVenda.pedido;
    final reaberta = venda.copyWith(status: destino, limparDataEntregue: true);

    final movimentosAntigos = _movimentosDaVenda(venda);
    final idsAntigos = movimentosAntigos.map((m) => m.id).toSet();
    final produtosAfetados = movimentosAntigos.map((m) => m.produtoId).toSet();
    final saldosIniciais = _capturarSaldosIniciais(produtosAfetados);
    _validarSaldoEstoque(const [], removerIds: idsAntigos);
    await _db.transaction((transaction) async {
      for (final movimento in movimentosAntigos) {
        await transaction.delete(
          'movimentos_estoque',
          where: 'id = ?',
          whereArgs: [movimento.id],
        );
      }
      await _gravarStatusDaVenda(transaction, reaberta);
    });
    movimentacoes.removeWhere((movimento) => idsAntigos.contains(movimento.id));
    vendas[indice] = reaberta;
    recalcularEstoque(
      produtosSemMovimentacoes: produtosAfetados,
      saldosIniciais: saldosIniciais,
    );
    await _persistirProdutos();
    notifyListeners();
  }

  /// Troca só os lançamentos financeiros da venda (usado quando a venda já
  /// andou e seus itens não podem mais ser editados).
  Future<void> atualizarFinanceiroDaVenda(
    String vendaId,
    List<LancamentoFinanceiro> lancamentos,
  ) async {
    _indiceDaVenda(vendaId);
    if (lancamentosDaVenda(vendaId).any((l) => l.hasQuitacoes)) {
      throw StateError(
        'Esta venda possui lançamentos com pagamentos (quitações) e não pode '
        'ter o financeiro alterado.',
      );
    }
    await _db.transaction((transaction) async {
      await _excluirLancamentosDaOperacaoDoBanco(
        transaction,
        TipoOperacaoOrigem.venda,
        vendaId,
      );
      for (final lancamento in lancamentos) {
        await _gravarLancamento(transaction, lancamento);
      }
    });
    _removerLancamentosDaOperacao(TipoOperacaoOrigem.venda, vendaId);
    _registrarLancamentos(lancamentos);
    notifyListeners();
  }

  Future<void> _removerVendaDoBanco(
    DatabaseExecutor database,
    String vendaId,
    List<MovimentoEstoque> movimentos,
  ) async {
    for (final movimento in movimentos) {
      await database.delete(
        'movimentos_estoque',
        where: 'id = ?',
        whereArgs: [movimento.id],
      );
    }
    await database.delete(
      'itens_venda',
      where: 'vendaId = ?',
      whereArgs: [vendaId],
    );
    await database.delete('vendas', where: 'id = ?', whereArgs: [vendaId]);
  }

  Future<void> _inserirVenda(
    DatabaseExecutor database,
    Venda venda,
    List<MovimentoEstoque> movimentos,
  ) async {
    await database.insert('vendas', {
      'id': venda.id,
      'data': venda.data.toIso8601String(),
      'clienteId': venda.clienteId,
      'tipo': venda.tipo.name,
      'status': venda.status.name,
      'dataEntrega': venda.dataEntrega?.toIso8601String(),
      'dataEntregue': venda.dataEntregue?.toIso8601String(),
    });
    for (final item in venda.itens) {
      await database.insert('itens_venda', {
        'vendaId': venda.id,
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

  /// O produto final só sai do estoque quando a venda é entregue, na data da
  /// entrega. Antes disso (pedido, produção, retirada, percurso) não há saída.
  List<MovimentoEstoque> _criarMovimentosVenda(Venda venda) => [
    if (venda.entregue)
      for (final item in venda.itens)
        MovimentoEstoque(
          id: novoId(),
          operacaoId: venda.id,
          data: venda.dataReferencia,
          produtoId: item.produtoId,
          tipo: TipoMovimentoEstoque.venda,
          quantidade: item.quantidade,
          valorUnitario: item.valorUnitario,
          unidadeId: item.unidadeId,
        ),
  ];

  List<MovimentoEstoque> _movimentosDaVenda(Venda venda) {
    if (!venda.entregue) return const [];
    final vinculados = movimentacoes
        .where(
          (movimento) =>
              movimento.operacaoId == venda.id &&
              movimento.tipo == TipoMovimentoEstoque.venda,
        )
        .toList();
    if (vinculados.isNotEmpty) {
      if (vinculados.length != venda.itens.length) {
        throw StateError(
          'Não foi possível localizar todas as movimentações da venda.',
        );
      }
      return vinculados;
    }

    // Registros antigos, sem vínculo com a operação.
    final candidatos = movimentacoes
        .where(
          (movimento) =>
              movimento.operacaoId == null &&
              movimento.tipo == TipoMovimentoEstoque.venda,
        )
        .toList();
    final correspondentes = <MovimentoEstoque>[];
    for (final item in venda.itens) {
      final indice = candidatos.indexWhere(
        (movimento) =>
            movimento.produtoId == item.produtoId &&
            movimento.data == venda.dataReferencia &&
            movimento.quantidade == item.quantidade &&
            movimento.valorUnitario == item.valorUnitario &&
            movimento.unidadeId == item.unidadeId,
      );
      if (indice >= 0) correspondentes.add(candidatos.removeAt(indice));
    }
    if (correspondentes.length != venda.itens.length) {
      throw StateError(
        'Não foi possível localizar todas as movimentações da venda.',
      );
    }
    return correspondentes;
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
          'fabricacaoPaiId': fabricacao.fabricacaoPaiId,
          'vendaId': fabricacao.vendaId,
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

  /// Fabricações geradas a partir de [fabricacaoId] (preparos da ficha
  /// técnica), incluindo os níveis seguintes.
  List<Fabricacao> fabricacoesVinculadas(String fabricacaoId) {
    final vinculadas = <Fabricacao>[];
    final pendentes = [fabricacaoId];
    while (pendentes.isNotEmpty) {
      final paiId = pendentes.removeLast();
      for (final fabricacao in fabricacoes) {
        if (fabricacao.fabricacaoPaiId == paiId &&
            !vinculadas.any((v) => v.id == fabricacao.id)) {
          vinculadas.add(fabricacao);
          pendentes.add(fabricacao.id);
        }
      }
    }
    return vinculadas;
  }

  /// Exclui a fabricação e todas as vinculadas a ela.
  Future<void> excluirFabricacao(String fabricacaoId) async {
    final indice = fabricacoes.indexWhere((f) => f.id == fabricacaoId);
    if (indice < 0) return;

    final fabricacao = fabricacoes[indice];
    final paiId = fabricacao.fabricacaoPaiId;
    if (paiId != null && fabricacoes.any((f) => f.id == paiId)) {
      throw StateError(
        'Esta fabricação foi gerada por outra. '
        'Exclua a fabricação principal para removê-la.',
      );
    }

    final removidas = [fabricacao, ...fabricacoesVinculadas(fabricacaoId)];
    final idsDasFabricacoes = removidas.map((f) => f.id).toSet();
    final movimentosRemovidos = [
      for (final f in removidas) ..._movimentosDaFabricacao(f),
    ];
    final idsRemovidos = movimentosRemovidos.map((m) => m.id).toSet();
    final produtosAfetados = movimentosRemovidos
        .map((movimento) => movimento.produtoId)
        .toSet();
    final saldosIniciais = _capturarSaldosIniciais(produtosAfetados);
    _validarSaldoEstoque(const [], removerIds: idsRemovidos);
    await _db.transaction((transaction) async {
      for (final movimento in movimentosRemovidos) {
        await transaction.delete(
          'movimentos_estoque',
          where: 'id = ?',
          whereArgs: [movimento.id],
        );
      }
      for (final id in idsDasFabricacoes) {
        await transaction.delete(
          'itens_fabricacao_registro',
          where: 'fabricacaoId = ?',
          whereArgs: [id],
        );
        await transaction.delete(
          'fabricacoes',
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });

    movimentacoes.removeWhere(
      (movimento) => idsRemovidos.contains(movimento.id),
    );
    fabricacoes.removeWhere((f) => idsDasFabricacoes.contains(f.id));
    recalcularEstoque(
      produtosSemMovimentacoes: produtosAfetados,
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

  /// Ordem das movimentações: pela data completa (dia, hora, minuto, segundo
  /// e milissegundo) e, em caso de empate, pelo id numérico, que indica a
  /// ordem de registro.
  int _compararMovimentos(MovimentoEstoque a, MovimentoEstoque b) {
    final dataComparacao = a.data.compareTo(b.data);
    return dataComparacao != 0 ? dataComparacao : _compararIds(a.id, b.id);
  }

  /// Compara ids numericamente. Comparar como texto errava quando os ids têm
  /// tamanhos diferentes (ex.: "9" depois de "10", ou ids sequenciais antigos
  /// misturados com ids gerados por `novoId`).
  int _compararIds(String a, String b) {
    final numeroA = int.tryParse(a);
    final numeroB = int.tryParse(b);
    if (numeroA != null && numeroB != null) return numeroA.compareTo(numeroB);
    return a.compareTo(b);
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

  /// Get the last 10 movements for a product.
  List<MovimentoEstoque> ultimas10Movimentacoes(String produtoId) {
    final movimentos = movimentacoes
        .where((m) => m.produtoId == produtoId)
        .toList();
    movimentos.sort((a, b) => _compararMovimentos(b, a));
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
    'tipo': movimento.tipo.name,
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
    'precoVenda': produto.precoVenda,
  };

  UnidadeMedida _unidadeFromRow(Map<String, dynamic> row) => UnidadeMedida(
    id: _idString(row['id']),
    nome: row['nome'] as String,
    sigla: row['sigla'] as String,
    grupo: _grupoUnidadeFromString(row['grupo'] as String),
    fatorParaBase: row['fatorParaBase'] as double,
  );

  GrupoUnidade _grupoUnidadeFromString(String s) {
    return GrupoUnidade.values.firstWhere(
      (grupo) => grupo.name == s || s.endsWith('.${grupo.name}'),
      orElse: () => GrupoUnidade.unidade,
    );
  }

  TipoMovimentoEstoque _tipoMovimentoFromString(String s) {
    return TipoMovimentoEstoque.values.firstWhere(
      (tipo) => tipo.name == s || s.endsWith('.${tipo.name}'),
      orElse: () => TipoMovimentoEstoque.ajuste,
    );
  }

  Future<void> salvarLancamentoFinanceiro(
    LancamentoFinanceiro lancamento,
  ) async {
    for (final quitacao in lancamento.quitacoes) {
      quitacao.lancamentoId = lancamento.id;
    }
    await _db.transaction(
      (transaction) => _gravarLancamento(transaction, lancamento),
    );
    _guardarLancamentoEmMemoria(lancamento);
    notifyListeners();
  }

  /// Lançamentos vinculados a uma operação (ex.: compra) só são excluídos
  /// junto com ela, para manter a ligação com os dados da origem.
  Future<void> excluirLancamentoFinanceiro(
    LancamentoFinanceiro lancamento,
  ) async {
    if (lancamento.tipoOperacaoOriem != TipoOperacaoOrigem.avulso) {
      throw StateError(
        'Este lançamento está vinculado a uma operação e só pode ser '
        'excluído por ela.',
      );
    }
    await _db.transaction((transaction) async {
      await transaction.delete(
        'quitacoes',
        where: 'lancamentoId = ?',
        whereArgs: [lancamento.id],
      );
      await transaction.delete(
        'lancamentos_financeiros',
        where: 'id = ?',
        whereArgs: [lancamento.id],
      );
    });
    lancamentosFinanceiros.removeWhere((l) => l.id == lancamento.id);
    notifyListeners();
  }

  Future<void> _gravarLancamento(
    DatabaseExecutor database,
    LancamentoFinanceiro lancamento,
  ) async {
    await database.insert('lancamentos_financeiros', {
      'id': lancamento.id,
      'pessoaId': lancamento.pessoaFinanceiro.id,
      'pessoaTipo': lancamento.pessoaFinanceiro.tipoPessoaFinanceiro.name,
      'pessoaNome': lancamento.pessoaFinanceiro.nome,
      'tipoLancamento': lancamento.tipoLancamento.name,
      'lancamentoPaiId': lancamento.lancamentoPai?.id,
      'statusLancamento': lancamento.statusLancamento.name,
      'tipoOperacaoOrigem': lancamento.tipoOperacaoOriem.name,
      'operacaoOrigemId': lancamento.operacaoOrigemId,
      'formaPagamento': lancamento.formaPagamento?.name,
      'dataCriacao': lancamento.dataCriacao.toIso8601String(),
      'dataVencimento': lancamento.dataVencimento.toIso8601String(),
      'descricao': lancamento.descricao,
      'observacao': lancamento.observacao,
      'valorLancamento': lancamento.valorLancamento,
      'valorDesconto': lancamento.valorDesconto,
      'valorAcrescimo': lancamento.valorAcrescimo,
      'valorTaxasImpostos': lancamento.valorTaxasImpostos,
      'dataCompensacao': lancamento.dataCompensacao?.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await database.delete(
      'quitacoes',
      where: 'lancamentoId = ?',
      whereArgs: [lancamento.id],
    );
    for (final quitacao in lancamento.quitacoes) {
      await database.insert('quitacoes', {
        'id': quitacao.id,
        'lancamentoId': lancamento.id,
        'dataQuitacao': quitacao.dataQuitacao.toIso8601String(),
        'valorQuitado': quitacao.valorQuitado,
        'formaPagamento': quitacao.formaPagamento.name,
      });
    }
  }

  Future<void> _excluirLancamentosDaOperacaoDoBanco(
    DatabaseExecutor database,
    TipoOperacaoOrigem origem,
    String operacaoId,
  ) async {
    for (final lancamento in lancamentosDaOperacao(origem, operacaoId)) {
      await database.delete(
        'quitacoes',
        where: 'lancamentoId = ?',
        whereArgs: [lancamento.id],
      );
      await database.delete(
        'lancamentos_financeiros',
        where: 'id = ?',
        whereArgs: [lancamento.id],
      );
    }
  }

  Future<void> _excluirLancamentosDaCompraDoBanco(
    DatabaseExecutor database,
    String compraId,
  ) => _excluirLancamentosDaOperacaoDoBanco(
    database,
    TipoOperacaoOrigem.compra,
    compraId,
  );

  void _guardarLancamentoEmMemoria(LancamentoFinanceiro lancamento) {
    final indice = lancamentosFinanceiros.indexWhere(
      (l) => l.id == lancamento.id,
    );
    if (indice >= 0) {
      lancamentosFinanceiros[indice] = lancamento;
    } else {
      lancamentosFinanceiros.add(lancamento);
    }
    // Parcelas que apontavam para a versão anterior do lançamento pai.
    for (final outro in lancamentosFinanceiros) {
      if (outro.lancamentoPai?.id == lancamento.id) {
        outro.lancamentoPai = lancamento;
      }
    }
  }

  void _registrarLancamentosDaCompra(Compra compra) =>
      _registrarLancamentos(compra.lancamentosFinanceiros);

  void _registrarLancamentos(List<LancamentoFinanceiro> lancamentos) {
    for (final lancamento in lancamentos) {
      for (final quitacao in lancamento.quitacoes) {
        quitacao.lancamentoId = lancamento.id;
      }
      _guardarLancamentoEmMemoria(lancamento);
    }
  }

  Future<void> _loadCartoesCredito() async {
    final linhas = await _db.query('cartoes_credito');
    for (final linha in linhas) {
      cartoesCredito.add(
        CartaoCredito(
          id: _idString(linha['id']),
          nome: linha['nome'] as String,
          diaVencimento: (linha['diaVencimento'] as num?)?.toInt() ?? 10,
          diasFechamento: (linha['diasFechamento'] as num?)?.toInt() ?? 7,
        ),
      );
    }
  }

  Future<void> _loadBandeirasCartao() async {
    final linhas = await _db.query('bandeiras_cartao');
    for (final linha in linhas) {
      bandeirasCartaoCredito.add(
        BandeiraCartaoCredito(
          id: _idString(linha['id']),
          nome: linha['nome'] as String,
          taxa: (linha['taxa'] as num).toDouble(),
          tipoTaxa: _enumPorNome(
            TipoTaxaBandeira.values,
            linha['tipoTaxa'],
            TipoTaxaBandeira.percentual,
          ),
          diasCompensacao: (linha['diasCompensacao'] as num?)?.toInt() ?? 1,
        ),
      );
    }
  }

  Future<void> _loadLancamentosFinanceiros() async {
    final quitacoesPorLancamento = <String, List<Quitacao>>{};
    for (final linha in await _db.query('quitacoes')) {
      final lancamentoId = _idString(linha['lancamentoId']);
      quitacoesPorLancamento
          .putIfAbsent(lancamentoId, () => [])
          .add(
            Quitacao(
              id: _idString(linha['id']),
              lancamentoId: lancamentoId,
              dataQuitacao: DateTime.parse(linha['dataQuitacao'] as String),
              valorQuitado: (linha['valorQuitado'] as num).toDouble(),
              formaPagamento: FormaPagamento.fromString(
                linha['formaPagamento'] as String?,
              ),
            ),
          );
    }

    final paiPorLancamento = <String, String>{};
    for (final linha in await _db.query('lancamentos_financeiros')) {
      final id = _idString(linha['id']);
      final pessoaId = _idString(linha['pessoaId']);
      final pessoaTipo = _enumPorNome(
        TipoPessoaFinanceiro.values,
        linha['pessoaTipo'],
        TipoPessoaFinanceiro.fornecedor,
      );
      final pessoa = pessoasFinanceiro.firstWhere(
        (p) => p.id == pessoaId && p.tipoPessoaFinanceiro == pessoaTipo,
        orElse: () => PessoaFinanceiro(
          id: pessoaId,
          nome: linha['pessoaNome'] as String,
          tipoPessoaFinanceiro: pessoaTipo,
        ),
      );
      final formaPagamento = linha['formaPagamento'] as String?;

      lancamentosFinanceiros.add(
        LancamentoFinanceiro(
          id: id,
          pessoaFinanceiro: pessoa,
          tipoLancamento: _enumPorNome(
            TipoLancamentoFinanceiro.values,
            linha['tipoLancamento'],
            TipoLancamentoFinanceiro.despesa,
          ),
          statusLancamento: _enumPorNome(
            StatusLancamentoFinanceiro.values,
            linha['statusLancamento'],
            StatusLancamentoFinanceiro.pendente,
          ),
          tipoOperacaoOriem: _enumPorNome(
            TipoOperacaoOrigem.values,
            linha['tipoOperacaoOrigem'],
            TipoOperacaoOrigem.avulso,
          ),
          operacaoOrigemId: _idString(linha['operacaoOrigemId']),
          formaPagamento: formaPagamento == null
              ? null
              : FormaPagamento.fromString(formaPagamento),
          dataCriacao: DateTime.parse(linha['dataCriacao'] as String),
          dataVencimento: DateTime.parse(linha['dataVencimento'] as String),
          descricao: linha['descricao'] as String,
          observacao: linha['observacao'] as String?,
          valorLancamento: (linha['valorLancamento'] as num).toDouble(),
          valorDesconto: (linha['valorDesconto'] as num).toDouble(),
          valorAcrescimo: (linha['valorAcrescimo'] as num).toDouble(),
          valorTaxasImpostos:
              (linha['valorTaxasImpostos'] as num?)?.toDouble() ?? 0,
          dataCompensacao: linha['dataCompensacao'] == null
              ? null
              : DateTime.parse(linha['dataCompensacao'] as String),
          quitacoes: quitacoesPorLancamento[id] ?? <Quitacao>[],
        ),
      );
      final paiId = linha['lancamentoPaiId'];
      if (paiId != null) paiPorLancamento[id] = _idString(paiId);
    }

    for (final lancamento in lancamentosFinanceiros) {
      final paiId = paiPorLancamento[lancamento.id];
      if (paiId != null)
        lancamento.lancamentoPai = lancamentoFinanceiroPorId(paiId);
    }
  }

  T _enumPorNome<T extends Enum>(List<T> valores, Object? nome, T padrao) {
    for (final valor in valores) {
      if (valor.name == nome) return valor;
    }
    return padrao;
  }

  String _idString(Object? value) => value.toString();

  /// Lançamentos financeiros gerados por uma operação (compra ou venda):
  /// pai primeiro, depois as demais parcelas por vencimento.
  List<LancamentoFinanceiro> lancamentosDaOperacao(
    TipoOperacaoOrigem origem,
    String operacaoId,
  ) {
    final lista = lancamentosFinanceiros
        .where(
          (l) =>
              l.tipoOperacaoOriem == origem && l.operacaoOrigemId == operacaoId,
        )
        .toList();
    lista.sort((a, b) {
      if (a.lancamentoPai == null && b.lancamentoPai != null) return -1;
      if (a.lancamentoPai != null && b.lancamentoPai == null) return 1;
      return a.dataVencimento.compareTo(b.dataVencimento);
    });
    return lista;
  }

  List<LancamentoFinanceiro> lancamentosDaCompra(String compraId) =>
      lancamentosDaOperacao(TipoOperacaoOrigem.compra, compraId);

  List<LancamentoFinanceiro> lancamentosDaVenda(String vendaId) =>
      lancamentosDaOperacao(TipoOperacaoOrigem.venda, vendaId);

  void _removerLancamentosDaOperacao(
    TipoOperacaoOrigem origem,
    String operacaoId,
  ) {
    final ids = lancamentosDaOperacao(
      origem,
      operacaoId,
    ).map((l) => l.id).toSet();
    lancamentosFinanceiros.removeWhere((l) => ids.contains(l.id));
  }

  void _removerLancamentosDaCompra(String compraId) =>
      _removerLancamentosDaOperacao(TipoOperacaoOrigem.compra, compraId);

  /// Pessoa financeira do fornecedor (cria e registra se ainda não existir,
  /// pois fornecedores cadastrados depois do carregamento não estão na lista).
  PessoaFinanceiro pessoaFinanceiraDoFornecedor(Fornecedor fornecedor) {
    for (final pessoa in pessoasFinanceiro) {
      if (pessoa.id == fornecedor.id &&
          pessoa.tipoPessoaFinanceiro == TipoPessoaFinanceiro.fornecedor) {
        return pessoa;
      }
    }
    final pessoa = PessoaFinanceiro(
      id: fornecedor.id,
      nome: fornecedor.nome,
      tipoPessoaFinanceiro: TipoPessoaFinanceiro.fornecedor,
    );
    pessoasFinanceiro.add(pessoa);
    return pessoa;
  }

  /// Pessoa financeira do cliente (cria e registra se ainda não existir).
  PessoaFinanceiro pessoaFinanceiraDoCliente(Cliente cliente) {
    for (final pessoa in pessoasFinanceiro) {
      if (pessoa.id == cliente.id &&
          pessoa.tipoPessoaFinanceiro == TipoPessoaFinanceiro.cliente) {
        return pessoa;
      }
    }
    final pessoa = PessoaFinanceiro(
      id: cliente.id,
      nome: cliente.nome,
      tipoPessoaFinanceiro: TipoPessoaFinanceiro.cliente,
    );
    pessoasFinanceiro.add(pessoa);
    return pessoa;
  }

  List<PessoaFinanceiro> get pessoasCartaoCredito => pessoasFinanceiro
      .where(
        (p) => p.tipoPessoaFinanceiro == TipoPessoaFinanceiro.cartaoCredito,
      )
      .toList();

  List<PessoaFinanceiro> get pessoasBandeiraCartao => pessoasFinanceiro
      .where(
        (p) =>
            p.tipoPessoaFinanceiro ==
            TipoPessoaFinanceiro.bandeiraCartaoCredito,
      )
      .toList();

  CartaoCredito? cartaoPorId(String id) {
    for (final cartao in cartoesCredito) {
      if (cartao.id == id) return cartao;
    }
    return null;
  }

  BandeiraCartaoCredito? bandeiraPorId(String id) {
    for (final bandeira in bandeirasCartaoCredito) {
      if (bandeira.id == id) return bandeira;
    }
    return null;
  }

  /// Cria ou atualiza um cartão de crédito e devolve a pessoa financeira dele.
  Future<PessoaFinanceiro> salvarCartaoCredito(CartaoCredito cartao) async {
    final indice = cartoesCredito.indexWhere((c) => c.id == cartao.id);
    final linha = {
      'id': cartao.id,
      'nome': cartao.nome,
      'diaVencimento': cartao.diaVencimento,
      'diasFechamento': cartao.diasFechamento,
    };
    if (indice >= 0) {
      await _db.update(
        'cartoes_credito',
        linha,
        where: 'id = ?',
        whereArgs: [cartao.id],
      );
      cartoesCredito[indice] = cartao;
    } else {
      await _db.insert('cartoes_credito', linha);
      cartoesCredito.add(cartao);
    }
    final pessoa = await _sincronizarPessoa(
      cartao.id,
      cartao.nome,
      TipoPessoaFinanceiro.cartaoCredito,
    );
    notifyListeners();
    return pessoa;
  }

  Future<void> excluirCartaoCredito(String id) async {
    _validarPessoaSemLancamentos(
      id,
      TipoPessoaFinanceiro.cartaoCredito,
      'cartão',
    );
    await _db.delete('cartoes_credito', where: 'id = ?', whereArgs: [id]);
    cartoesCredito.removeWhere((c) => c.id == id);
    pessoasFinanceiro.removeWhere(
      (p) =>
          p.id == id &&
          p.tipoPessoaFinanceiro == TipoPessoaFinanceiro.cartaoCredito,
    );
    notifyListeners();
  }

  /// Cria ou atualiza uma bandeira e devolve a pessoa financeira dela.
  Future<PessoaFinanceiro> salvarBandeiraCartao(
    BandeiraCartaoCredito bandeira,
  ) async {
    final indice = bandeirasCartaoCredito.indexWhere(
      (b) => b.id == bandeira.id,
    );
    final linha = {
      'id': bandeira.id,
      'nome': bandeira.nome,
      'taxa': bandeira.taxa,
      'tipoTaxa': bandeira.tipoTaxa.name,
      'diasCompensacao': bandeira.diasCompensacao,
    };
    if (indice >= 0) {
      await _db.update(
        'bandeiras_cartao',
        linha,
        where: 'id = ?',
        whereArgs: [bandeira.id],
      );
      bandeirasCartaoCredito[indice] = bandeira;
    } else {
      await _db.insert('bandeiras_cartao', linha);
      bandeirasCartaoCredito.add(bandeira);
    }
    final pessoa = await _sincronizarPessoa(
      bandeira.id,
      bandeira.nome,
      TipoPessoaFinanceiro.bandeiraCartaoCredito,
    );
    notifyListeners();
    return pessoa;
  }

  Future<void> excluirBandeiraCartao(String id) async {
    _validarPessoaSemLancamentos(
      id,
      TipoPessoaFinanceiro.bandeiraCartaoCredito,
      'bandeira',
    );
    await _db.delete('bandeiras_cartao', where: 'id = ?', whereArgs: [id]);
    bandeirasCartaoCredito.removeWhere((b) => b.id == id);
    pessoasFinanceiro.removeWhere(
      (p) =>
          p.id == id &&
          p.tipoPessoaFinanceiro == TipoPessoaFinanceiro.bandeiraCartaoCredito,
    );
    notifyListeners();
  }

  void _validarPessoaSemLancamentos(
    String id,
    TipoPessoaFinanceiro tipo,
    String descricao,
  ) {
    final emUso = lancamentosFinanceiros.any(
      (l) =>
          l.pessoaFinanceiro.id == id &&
          l.pessoaFinanceiro.tipoPessoaFinanceiro == tipo,
    );
    if (emUso) {
      throw StateError(
        'Este $descricao possui lançamentos financeiros e não pode ser '
        'excluído.',
      );
    }
  }

  /// Mantém a lista de pessoas financeiras (e os lançamentos já gravados com
  /// o nome antigo) em dia depois de criar/renomear um cartão ou bandeira.
  Future<PessoaFinanceiro> _sincronizarPessoa(
    String id,
    String nome,
    TipoPessoaFinanceiro tipo,
  ) async {
    final pessoa = PessoaFinanceiro(
      id: id,
      nome: nome,
      tipoPessoaFinanceiro: tipo,
    );
    final indice = pessoasFinanceiro.indexWhere(
      (p) => p.id == id && p.tipoPessoaFinanceiro == tipo,
    );
    if (indice >= 0) {
      pessoasFinanceiro[indice] = pessoa;
    } else {
      pessoasFinanceiro.add(pessoa);
    }
    for (final lancamento in lancamentosFinanceiros) {
      final atual = lancamento.pessoaFinanceiro;
      if (atual.id == id && atual.tipoPessoaFinanceiro == tipo) {
        lancamento.pessoaFinanceiro = pessoa;
      }
    }
    await _db.update(
      'lancamentos_financeiros',
      {'pessoaNome': nome},
      where: 'pessoaId = ? AND pessoaTipo = ?',
      whereArgs: [id, tipo.name],
    );
    return pessoa;
  }
}
