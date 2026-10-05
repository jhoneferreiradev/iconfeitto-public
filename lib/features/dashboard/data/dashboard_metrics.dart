import '../../../shared/models/operacao.dart';
import '../../../shared/models/produto.dart';
import '../../../shared/models/tipo_item.dart';

class ResumoMensal {
  final DateTime mes;
  final double vendas;
  final double compras;

  const ResumoMensal({
    required this.mes,
    required this.vendas,
    required this.compras,
  });
}

class ProdutoVendido {
  final String nome;
  final double valor;
  final double quantidade;

  const ProdutoVendido({
    required this.nome,
    required this.valor,
    required this.quantidade,
  });
}

class MargemProduto {
  final String nome;
  final double custo;
  final double preco;

  const MargemProduto({
    required this.nome,
    required this.custo,
    required this.preco,
  });

  double get lucro => preco - custo;

  /// Mesmo critério da ficha técnica: lucro sobre o custo.
  double get percentual => custo <= 0 ? 0 : lucro / custo * 100;
}

enum TipoAtividade { venda, compra, fabricacao }

class Atividade {
  final TipoAtividade tipo;
  final String titulo;
  final DateTime data;
  final double? valor;
  final String? rota;

  const Atividade({
    required this.tipo,
    required this.titulo,
    required this.data,
    this.valor,
    this.rota,
  });
}

/// Indicadores do dashboard, calculados a partir dos dados do repositório.
class DashboardMetrics {
  final DateTime agora;
  final List<Venda> vendas;
  final List<Compra> compras;
  final List<Fabricacao> fabricacoes;
  final List<Produto> produtos;
  final double Function(Produto produto) custoUnitario;

  DashboardMetrics({
    required DateTime agora,
    required this.vendas,
    required this.compras,
    required this.fabricacoes,
    required this.produtos,
    required this.custoUnitario,
  }) : agora = DateTime(agora.year, agora.month, agora.day);

  DateTime get _inicioMes => DateTime(agora.year, agora.month);
  DateTime get _inicioMesAnterior => DateTime(agora.year, agora.month - 1);

  static DateTime _dia(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  bool _noMes(DateTime data, DateTime inicio) =>
      data.year == inicio.year && data.month == inicio.month;

  Iterable<Venda> _vendasDoMes(DateTime inicio) =>
      vendas.where((v) => _noMes(v.data, inicio));

  Iterable<Compra> _comprasDoMes(DateTime inicio) =>
      compras.where((c) => _noMes(c.data, inicio));

  double _lucro(Iterable<Venda> lista) {
    final porId = {for (final p in produtos) p.id: p};
    var lucro = 0.0;
    for (final venda in lista) {
      for (final item in venda.itens) {
        final produto = porId[item.produtoId];
        final custo = produto == null ? 0 : custoUnitario(produto);
        lucro += item.quantidade * (item.valorUnitario - custo);
      }
    }
    return lucro;
  }

  double get faturamentoMes =>
      _vendasDoMes(_inicioMes).fold(0, (s, v) => s + v.total);

  double get faturamentoMesAnterior =>
      _vendasDoMes(_inicioMesAnterior).fold(0, (s, v) => s + v.total);

  double get comprasMes =>
      _comprasDoMes(_inicioMes).fold(0, (s, c) => s + c.total);

  double get comprasMesAnterior =>
      _comprasDoMes(_inicioMesAnterior).fold(0, (s, c) => s + c.total);

  double get lucroMes => _lucro(_vendasDoMes(_inicioMes));

  double get lucroMesAnterior => _lucro(_vendasDoMes(_inicioMesAnterior));

  int get quantidadeVendasMes => _vendasDoMes(_inicioMes).length;

  int get quantidadeVendasMesAnterior =>
      _vendasDoMes(_inicioMesAnterior).length;

  double get ticketMedioMes =>
      quantidadeVendasMes == 0 ? 0 : faturamentoMes / quantidadeVendasMes;

  double get ticketMedioMesAnterior => quantidadeVendasMesAnterior == 0
      ? 0
      : faturamentoMesAnterior / quantidadeVendasMesAnterior;

  int get fabricacoesMes =>
      fabricacoes.where((f) => _noMes(f.data, _inicioMes)).length;

  /// Variação percentual; `null` quando não há base de comparação.
  static double? variacao(double atual, double anterior) {
    if (anterior == 0) return null;
    return (atual - anterior) / anterior.abs() * 100;
  }

  bool get semMovimento => vendas.isEmpty && compras.isEmpty;

  /// Vendas e compras dos últimos [meses] meses, do mais antigo ao atual.
  List<ResumoMensal> serieMensal([int meses = 6]) {
    return [
      for (var i = meses - 1; i >= 0; i--)
        () {
          final mes = DateTime(agora.year, agora.month - i);
          return ResumoMensal(
            mes: mes,
            vendas: _vendasDoMes(mes).fold(0.0, (s, v) => s + v.total),
            compras: _comprasDoMes(mes).fold(0.0, (s, c) => s + c.total),
          );
        }(),
    ];
  }

  /// Faturamento por dia nos últimos [dias] dias (o último é hoje).
  List<({DateTime dia, double valor})> serieDiaria(int dias) {
    final inicio = DateTime(agora.year, agora.month, agora.day - (dias - 1));
    final porDia = <DateTime, double>{};
    for (final venda in vendas) {
      final dia = _dia(venda.data);
      if (dia.isBefore(inicio) || dia.isAfter(agora)) continue;
      porDia[dia] = (porDia[dia] ?? 0) + venda.total;
    }
    return [
      for (var i = 0; i < dias; i++)
        (
          dia: DateTime(inicio.year, inicio.month, inicio.day + i),
          valor:
              porDia[DateTime(inicio.year, inicio.month, inicio.day + i)] ?? 0,
        ),
    ];
  }

  /// Produtos que mais geraram receita nos últimos [dias] dias.
  List<ProdutoVendido> topProdutos({int dias = 30, int limite = 5}) {
    final inicio = DateTime(agora.year, agora.month, agora.day - (dias - 1));
    final nomes = {for (final p in produtos) p.id: p.nome};
    final valores = <String, double>{};
    final quantidades = <String, double>{};
    for (final venda in vendas) {
      final dia = _dia(venda.data);
      if (dia.isBefore(inicio) || dia.isAfter(agora)) continue;
      for (final item in venda.itens) {
        valores[item.produtoId] =
            (valores[item.produtoId] ?? 0) +
            item.quantidade * item.valorUnitario;
        quantidades[item.produtoId] =
            (quantidades[item.produtoId] ?? 0) + item.quantidade;
      }
    }
    final lista = [
      for (final entrada in valores.entries)
        if (entrada.value > 0)
          ProdutoVendido(
            nome: nomes[entrada.key] ?? 'Produto removido',
            valor: entrada.value,
            quantidade: quantidades[entrada.key] ?? 0,
          ),
    ]..sort((a, b) => b.valor.compareTo(a.valor));
    return lista.take(limite).toList();
  }

  /// Produtos ativos com preço de venda, da menor para a maior margem.
  List<MargemProduto> margens({int limite = 6}) {
    final lista = [
      for (final p in produtos)
        if (p.ativo && p.tipo == TipoItem.produto && p.precoVenda > 0)
          MargemProduto(
            nome: p.nome,
            custo: custoUnitario(p),
            preco: p.precoVenda,
          ),
    ]..sort((a, b) => a.percentual.compareTo(b.percentual));
    return lista.take(limite).toList();
  }

  Iterable<Produto> get _itensDeEstoque =>
      produtos.where((p) => p.ativo && TipoItem.tiposCompra.contains(p.tipo));

  double get valorEmEstoque => _itensDeEstoque.fold(
    0,
    (s, p) => s + (p.saldoEstoque > 0 ? p.saldoEstoque * p.custoMedio : 0),
  );

  int get totalItensEstoque => _itensDeEstoque.length;

  List<Produto> get itensSemSaldo =>
      _itensDeEstoque.where((p) => p.saldoEstoque <= 0).toList()
        ..sort((a, b) => a.nome.compareTo(b.nome));

  List<Atividade> atividadesRecentes({
    int limite = 6,
    required String Function(String clienteId) nomeCliente,
    required String Function(String fornecedorId) nomeFornecedor,
    required String Function(String produtoId) nomeProduto,
  }) {
    final lista = <Atividade>[
      for (final v in vendas)
        Atividade(
          tipo: TipoAtividade.venda,
          titulo: 'Venda para ${nomeCliente(v.clienteId)}',
          data: v.data,
          valor: v.total,
          rota: '/vendas',
        ),
      for (final c in compras)
        Atividade(
          tipo: TipoAtividade.compra,
          titulo: 'Compra de ${nomeFornecedor(c.fornecedorId)}',
          data: c.data,
          valor: c.total,
          rota: '/compras/${c.id}/editar',
        ),
      for (final f in fabricacoes)
        Atividade(
          tipo: TipoAtividade.fabricacao,
          titulo: 'Fabricação de ${nomeProduto(f.produtoId)}',
          data: f.data,
          rota: '/cozinha/${f.id}',
        ),
    ]..sort((a, b) => b.data.compareTo(a.data));
    return lista.take(limite).toList();
  }
}
