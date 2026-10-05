import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/responsive.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/operacao.dart';
import '../../../shared/models/produto.dart';
import '../pdf/movimentos_pdf.dart';

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
                              tooltip: 'Imprimir últimas movimentações',
                              onPressed: () => MovimentosPdf.imprimir(produto),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Ajustar estoque',
                              onPressed: () => _ajustar(context, repo, produto),
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

  Future<void> _ajustar(
    BuildContext context,
    AppRepository repo,
    Produto produto,
  ) async {
    final saldoController = TextEditingController(
      text: produto.saldoEstoque.toDecimal(),
    );
    final custoController = TextEditingController(
      text: produto.custoMedio.toDecimal(),
    );
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajustar ${produto.nome}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: saldoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Saldo'),
            ),
            TextField(
              controller: custoController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Custo médio'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aplicar'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (confirmado != true) return;
    final saldo = saldoController.text.toDouble();
    final custo = custoController.text.toDouble();
    if (saldo == null || custo == null || saldo < 0 || custo < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe um saldo e custo válidos.')),
      );
      return;
    }
    try {
      await repo.ajustarEstoque(produto.id, saldo, custo);
    } on SaldoEstoqueInsuficienteException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
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
