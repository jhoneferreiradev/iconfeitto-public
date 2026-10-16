import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/responsive.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/produto.dart';
import '../pdf/movimentos_pdf.dart';
import '../widgets/movimento_estoque_dialogs.dart';

class EstoqueScreen extends StatefulWidget {
  const EstoqueScreen({super.key});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;

    final produtosFiltrados = repo.produtos
        .where((p) => p.nome.toLowerCase().contains(_busca.toLowerCase()))
        .toList();

    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        return AppScaffold(
          title: 'Estoque',
          body: Column(
            children: [
              _buildFiltros(context),
              Expanded(
                child: ResponsiveCardList(
                  itemCount: produtosFiltrados.length,
                  itemBuilder: (context, index) {
                    final produto = produtosFiltrados[index];
                    final unidade = repo.unidadePorId(produto.unidadeEstoqueId);
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text(produto.nome),
                        subtitle: Text(
                          'Saldo: ${produto.saldoEstoque.toDecimal()} ${unidade.sigla}  •  Custo: ${produto.custoMedio.toCurrency()}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.print_outlined),
                              tooltip: 'Prévia das últimas movimentações',
                              onPressed: () => MovimentosPdf.visualizar(context, produto),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.tune),
                              tooltip: 'Operações de estoque',
                              onSelected: (operacao) {
                                if (operacao == 'ajuste') {
                                  mostrarAjusteEstoque(context, produto);
                                } else {
                                  mostrarSaidaConsumo(context, produto);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'ajuste',
                                  child: Text('Ajustar saldo e custo'),
                                ),
                                PopupMenuItem(
                                  value: 'consumo',
                                  child: Text('Saída para consumo'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFiltros(BuildContext context) {
    return ContentWidth(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar por nome',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busca.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _busca = ''),
                      ),
              ),
              onChanged: (value) => setState(() => _busca = value),
            ),
          ),
        ],
      ),
    );
  }
}
