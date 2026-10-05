import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/responsive.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/produto.dart';
import '../data/dashboard_metrics.dart';
import '../widgets/dashboard_activity.dart';
import '../widgets/dashboard_cards.dart';
import '../widgets/dashboard_charts.dart';
import '../widgets/dashboard_common.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static double _custoUnitario(AppRepository repo, Produto produto) =>
      CalculadoraCustoProduto(
        rendimentoReceita: produto.rendimentoReceita,
        custoFichaTecnica: repo.custoTotalFicha(produto),
        custoOperacional: produto.custoOperacional,
        custoUnitarioEmbalagem: repo.custoEmbalagem(produto),
      ).custoRendimentoUnitario;

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final metrics = DashboardMetrics(
          agora: DateTime.now(),
          vendas: repo.vendas,
          compras: repo.compras,
          fabricacoes: repo.fabricacoes,
          produtos: repo.produtos,
          custoUnitario: (p) => _custoUnitario(repo, p),
        );
        final atividades = metrics.atividadesRecentes(
          nomeCliente: (id) =>
              repo.clientePorId(id)?.nome ?? 'cliente removido',
          nomeFornecedor: (id) =>
              repo.fornecedorPorId(id)?.nome ?? 'fornecedor removido',
          nomeProduto: (id) =>
              repo.produtoPorId(id)?.nome ?? 'produto removido',
        );

        final blocos = <Widget>[
          DashboardHero(nomeEmpresa: repo.empresa.nome, metrics: metrics),
          _kpis(metrics),
          _acoesRapidas(),
          LinhaResponsiva(
            esquerda: VendasComprasChart(serie: metrics.serieMensal()),
            direita: TopProdutosChart(produtos: metrics.topProdutos()),
          ),
          LinhaResponsiva(
            esquerda: FaturamentoDiarioChart(metrics: metrics),
            direita: MargensCard(margens: metrics.margens()),
          ),
          LinhaResponsiva(
            esquerda: AtividadesCard(atividades: atividades),
            direita: EstoqueCard(
              valorEmEstoque: metrics.valorEmEstoque,
              totalItens: metrics.totalItensEstoque,
              semSaldo: metrics.itensSemSaldo,
            ),
          ),
        ];

        return AppScaffold(
          title: 'Visão geral',
          body: SingleChildScrollView(
            child: ContentWidth(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < blocos.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    blocos[i].entranceAnimation(i),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _kpis(DashboardMetrics m) {
    return ResponsiveCardGrid(
      minItemWidth: 150,
      children: [
        KpiCard(
          titulo: 'Faturamento do mês',
          icon: Icons.payments_outlined,
          cor: const Color(0xFFE85D75),
          valor: m.faturamentoMes,
          variacao: DashboardMetrics.variacao(
            m.faturamentoMes,
            m.faturamentoMesAnterior,
          ),
          dica: 'Soma de todas as vendas registradas neste mês.',
        ),
        KpiCard(
          titulo: 'Lucro estimado',
          icon: Icons.trending_up,
          cor: const Color(0xFF2E9E5B),
          valor: m.lucroMes,
          variacao: DashboardMetrics.variacao(m.lucroMes, m.lucroMesAnterior),
          dica:
              'Vendas do mês menos o custo atual dos produtos vendidos '
              '(ficha técnica).',
        ),
        KpiCard(
          titulo: 'Compras do mês',
          icon: Icons.shopping_cart_outlined,
          cor: const Color(0xFF7C6BD6),
          valor: m.comprasMes,
          altaEhRuim: true,
          variacao: DashboardMetrics.variacao(
            m.comprasMes,
            m.comprasMesAnterior,
          ),
          dica: 'Quanto foi gasto com compras de insumos neste mês.',
        ),
        KpiCard(
          titulo: 'Ticket médio',
          icon: Icons.receipt_long_outlined,
          cor: const Color(0xFFFF9F5A),
          valor: m.ticketMedioMes,
          formatar: formatarMoeda,
          variacao: DashboardMetrics.variacao(
            m.ticketMedioMes,
            m.ticketMedioMesAnterior,
          ),
          dica: 'Valor médio de cada venda do mês.',
        ),
      ],
    );
  }

  Widget _acoesRapidas() {
    return ResponsiveCardGrid(
      minItemWidth: 150,
      children: const [
        AcaoRapida(
          titulo: 'Nova venda',
          descricao: 'Registre e baixe o estoque',
          icon: Icons.point_of_sale,
          rota: '/vendas/nova',
        ),
        AcaoRapida(
          titulo: 'Nova compra',
          descricao: 'Dê entrada nos insumos',
          icon: Icons.shopping_cart,
          rota: '/compras/nova',
        ),
        AcaoRapida(
          titulo: 'Fabricação',
          descricao: 'Produza e baixe insumos',
          icon: Icons.soup_kitchen,
          rota: '/cozinha/nova',
        ),
        AcaoRapida(
          titulo: 'Novo produto',
          descricao: 'Ficha técnica e preço',
          icon: Icons.cake,
          rota: '/produtos/novo?tipo=produto&grupo=produto',
        ),
      ],
    );
  }
}
