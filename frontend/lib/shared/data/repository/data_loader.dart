import '../../models/cartao_credito.dart';
import '../../models/cliente.dart';
import '../../models/custo_operacional.dart';
import '../../models/empresa.dart';
import '../../models/forma_pagamento.dart';
import '../../models/fornecedor.dart';
import '../../models/item_ficha_tecnica.dart';
import '../../models/item_ficha_tecnica_embalagem.dart';
import '../../models/lancamento_financeiro.dart';
import '../../models/operacao.dart';
import '../../models/produto.dart';
import '../../models/tipo_item.dart';
import 'estoque_service.dart';
import 'repository_component.dart';
import 'row_mappers.dart';

/// Carga inicial: lê o banco e monta os caches em memória e as pessoas
/// financeiras.
class DataLoader extends RepositoryComponent {
  final EstoqueService estoqueService;

  DataLoader(super.context, {required this.estoqueService});

  /// Lê todo o banco e monta os caches em memória.
  Future<void> carregarTudo() async {
    _limparCaches();
    await _carregarUnidades();
    await _carregarFornecedores();
    await _carregarClientes();
    await _carregarProdutos();
    await _carregarCompras();
    await _carregarVendas();
    await _carregarFabricacoes();
    await _carregarMovimentosEstoque();
    await _carregarEmpresa();

    estoqueService.recalcular();

    await _carregarCartoesCredito();
    await _carregarBandeirasCartao();
    _montarPessoasFinanceiras();
    await _carregarLancamentosFinanceiros();
  }

  void _limparCaches() {
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
  }

  Future<void> _carregarUnidades() async {
    final unidadesData = await db.query('unidades_medida');
    for (final row in unidadesData) {
      unidades.add(unidadeDeLinha(row));
    }
  }

  Future<void> _carregarFornecedores() async {
    final fornecedoresData = await db.query('fornecedores');
    for (final row in fornecedoresData) {
      fornecedores.add(
        Fornecedor(
          id: idString(row['id']),
          nome: row['nome'] as String,
          ativo: (row['ativo'] as int) == 1,
        ),
      );
    }
  }

  Future<void> _carregarClientes() async {
    final clientesData = await db.query('clientes');
    for (final row in clientesData) {
      clientes.add(
        Cliente(
          id: idString(row['id']),
          nome: row['nome'] as String,
          ativo: (row['ativo'] as int) == 1,
        ),
      );
    }
  }

  Future<void> _carregarProdutos() async {
    final produtosData = await db.query('produtos');
    for (final row in produtosData) {
      final produtoId = idString(row['id']);
      final fichaTecnicaRows = await db.rawQuery(
        '''
        SELECT ift.*
        FROM itens_ficha_tecnica ift
        JOIN produtos ingrediente ON ift.produtoIngredienteId = ingrediente.id
        WHERE ift.produtoId = ?
        AND ingrediente.tipo <> ?
        ''',
        [produtoId, 'embalagem'],
      );

      final fichaTecnicaEmbalagemRows = await db.rawQuery(
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
            produtoIngredienteId: idString(fichaRow['produtoIngredienteId']),
            quantidade: fichaRow['quantidade'] as double,
            unidadeId: idString(fichaRow['unidadeId']),
          ),
      ];

      final fichaTecnicaEmbalagem = [
        for (final fichaRow in fichaTecnicaEmbalagemRows)
          ItemFichaTecnicaEmbalagem(
            produtoEmbalagemId: idString(fichaRow['produtoIngredienteId']),
            quantidade: fichaRow['quantidade'] as double,
            unidadeId: idString(fichaRow['unidadeId']),
          ),
      ];

      produtos.add(
        Produto(
          id: produtoId,
          nome: row['nome'] as String,
          ativo: (row['ativo'] as int) == 1,
          custoMedio: row['custoMedio'] as double,
          saldoEstoque: row['saldoEstoque'] as double,
          tipo: TipoItem.fromString((row['tipo'] as String)),
          possuiFichaTecnica: (row['possuiFichaTecnica'] as int) == 1,
          tempoPreparoMinutos: row['tempoPreparoMinutos'] as int,
          rendimentoReceita: row['rendimentoReceita'] as int,
          unidadeEstoqueId: idString(row['unidadeEstoqueId']),
          unidadeConsumoId: idString(row['unidadeConsumoId']),
          fichaTecnica: fichaTecnica,
          fichaTecnicaEmbalagem: fichaTecnicaEmbalagem,
          custoOperacional: row['custoOperacional'] as double,
          precoVenda: row['precoVenda'] as double,
          quantidadeMinimaEstoque: row['quantidadeMinimaEstoque'] as double,
        ),
      );
    }
  }

  Future<void> _carregarCompras() async {
    final comprasData = await db.query('compras');
    for (final row in comprasData) {
      final compraId = idString(row['id']);
      final itensData = await db.query(
        'itens_compra',
        where: 'compraId = ?',
        whereArgs: [compraId],
        orderBy: 'id',
      );
      final itens = [
        for (final itemRow in itensData)
          ItemOperacao(
            produtoId: idString(itemRow['produtoId']),
            quantidade: itemRow['quantidade'] as double,
            valorUnitario: itemRow['valorUnitario'] as double,
            unidadeId: idString(itemRow['unidadeId']),
          ),
      ];

      compras.add(
        Compra(
          id: compraId,
          data: DateTime.parse(row['data'] as String),
          fornecedorId: idString(row['fornecedorId']),
          itens: itens,
        ),
      );
    }
  }

  Future<void> _carregarVendas() async {
    final vendasData = await db.query('vendas');
    for (final row in vendasData) {
      final vendaId = idString(row['id']);
      final itensData = await db.query(
        'itens_venda',
        where: 'vendaId = ?',
        whereArgs: [vendaId],
      );
      final itens = [
        for (final itemRow in itensData)
          ItemOperacao(
            produtoId: idString(itemRow['produtoId']),
            quantidade: itemRow['quantidade'] as double,
            valorUnitario: itemRow['valorUnitario'] as double,
            unidadeId: idString(itemRow['unidadeId']),
          ),
      ];

      vendas.add(
        Venda(
          id: vendaId,
          data: DateTime.parse(row['data'] as String),
          clienteId: idString(row['clienteId']),
          itens: itens,
          tipo: enumPorNome(
            TipoVenda.values,
            row['tipo'],
            TipoVenda.prontaEntrega,
          ),
          status: enumPorNome(
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
  }

  Future<void> _carregarFabricacoes() async {
    final fabricacoesData = await db.query('fabricacoes');
    for (final row in fabricacoesData) {
      final fabricacaoId = idString(row['id']);
      final itensData = await db.query(
        'itens_fabricacao_registro',
        where: 'fabricacaoId = ?',
        whereArgs: [fabricacaoId],
      );
      final fichaTecnica = [
        for (final itemRow in itensData)
          ItemFichaTecnica(
            produtoIngredienteId: idString(itemRow['produtoIngredienteId']),
            quantidade: itemRow['quantidade'] as double,
            unidadeId: idString(itemRow['unidadeId']),
          ),
      ];

      fabricacoes.add(
        Fabricacao(
          id: fabricacaoId,
          data: DateTime.parse(row['data'] as String),
          produtoId: idString(row['produtoId']),
          quantidade: row['quantidade'] as double,
          fichaTecnica: fichaTecnica,
          fabricacaoPaiId: row['fabricacaoPaiId']?.toString(),
          vendaId: row['vendaId']?.toString(),
        ),
      );
    }
  }

  Future<void> _carregarMovimentosEstoque() async {
    final movimentosData = await db.query('movimentos_estoque');
    for (final row in movimentosData) {
      movimentacoes.add(
        MovimentoEstoque(
          id: idString(row['id']),
          operacaoId: row['operacaoId']?.toString(),
          data: DateTime.parse(row['data'] as String),
          produtoId: idString(row['produtoId']),
          tipo: tipoMovimentoDeTexto(row['tipo'] as String),
          quantidade: row['quantidade'] as double,
          valorUnitario: row['valorUnitario'] as double,
          unidadeId: idString(row['unidadeId']),
        ),
      );
    }
  }

  Future<void> _carregarEmpresa() async {
    final empresaData = await db.query('empresa');
    if (empresaData.isNotEmpty) {
      empresa = Empresa.fromMap(empresaData.first);
      final custosData = await db.query(
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
  }

  void _montarPessoasFinanceiras() {
    pessoasFinanceiro.add(
      PessoaFinanceiro(
        id: empresa.id,
        nome: empresa.nome ?? "Esta empresa",
        tipoPessoaFinanceiro: TipoPessoaFinanceiro.empresaCorrente,
      ),
    );
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

  Future<void> _carregarCartoesCredito() async {
    final linhas = await db.query('cartoes_credito');
    for (final linha in linhas) {
      cartoesCredito.add(
        CartaoCredito(
          id: idString(linha['id']),
          nome: linha['nome'] as String,
          diaVencimento: (linha['diaVencimento'] as num?)?.toInt() ?? 10,
          diasFechamento: (linha['diasFechamento'] as num?)?.toInt() ?? 7,
        ),
      );
    }
  }

  Future<void> _carregarBandeirasCartao() async {
    final linhas = await db.query('bandeiras_cartao');
    for (final linha in linhas) {
      bandeirasCartaoCredito.add(
        BandeiraCartaoCredito(
          id: idString(linha['id']),
          nome: linha['nome'] as String,
          taxa: (linha['taxa'] as num).toDouble(),
          tipoTaxa: enumPorNome(
            TipoTaxaBandeira.values,
            linha['tipoTaxa'],
            TipoTaxaBandeira.percentual,
          ),
          diasCompensacao: (linha['diasCompensacao'] as num?)?.toInt() ?? 1,
        ),
      );
    }
  }

  Future<void> _carregarLancamentosFinanceiros() async {
    final quitacoesPorLancamento = <String, List<Quitacao>>{};
    for (final linha in await db.query('quitacoes')) {
      final lancamentoId = idString(linha['lancamentoId']);
      quitacoesPorLancamento
          .putIfAbsent(lancamentoId, () => [])
          .add(
            Quitacao(
              id: idString(linha['id']),
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
    for (final linha in await db.query('lancamentos_financeiros')) {
      final id = idString(linha['id']);
      final pessoaId = idString(linha['pessoaId']);
      final pessoaTipo = enumPorNome(
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
          tipoLancamento: enumPorNome(
            TipoLancamentoFinanceiro.values,
            linha['tipoLancamento'],
            TipoLancamentoFinanceiro.despesa,
          ),
          statusLancamento: enumPorNome(
            StatusLancamentoFinanceiro.values,
            linha['statusLancamento'],
            StatusLancamentoFinanceiro.pendente,
          ),
          tipoOperacaoOriem: enumPorNome(
            TipoOperacaoOrigem.values,
            linha['tipoOperacaoOrigem'],
            TipoOperacaoOrigem.avulso,
          ),
          operacaoOrigemId: idString(linha['operacaoOrigemId']),
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
      if (paiId != null) paiPorLancamento[id] = idString(paiId);
    }

    for (final lancamento in lancamentosFinanceiros) {
      final paiId = paiPorLancamento[lancamento.id];
      if (paiId != null) lancamento.lancamentoPai = lancamentoFinanceiroPorId(paiId);
    }
  }
}
