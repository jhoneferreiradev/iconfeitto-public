import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/produto.dart';
import '../pdf/movimentos_pdf.dart';

class EstoqueScreen extends StatelessWidget {
  const EstoqueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        return AppScaffold(
          title: 'Estoque',
          body: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: repo.produtos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final produto = repo.produtos[index];
              final unidade = repo.unidadePorId(produto.unidadeEstoqueId);
              return Card(
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
    if (confirmado != true) return;
    final saldo = saldoController.text.toDouble();
    final custo = custoController.text.toDouble();
    if (saldo == null || custo == null || saldo < 0 || custo < 0) return;
    await repo.ajustarEstoque(produto.id, saldo, custo);
  }
}
