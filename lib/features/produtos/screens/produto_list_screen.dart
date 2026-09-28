import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../shared/data/app_repository.dart';
import '../widgets/produto_card.dart';

class ProdutoListScreen extends StatelessWidget {
  const ProdutoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final produtos = repo.produtos;
        return AppScaffold(
          title: 'Produtos',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/produtos/novo'),
            icon: const Icon(Icons.add),
            label: const Text('Novo produto'),
          ),
          body: produtos.isEmpty
              ? const EmptyState(
                  mensagem: 'Nenhum produto cadastrado ainda.\nToque em "Novo produto" para começar.',
                  icon: Icons.cake_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: produtos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final produto = produtos[index];
                    final unidade = repo.unidadePorId(produto.unidadeEstoqueId);
                    final custoFicha = repo.custoTotalFicha(produto);
                    return ProdutoCard(
                      produto: produto,
                      unidade: unidade,
                      custoFicha: custoFicha,
                      onTap: () =>
                          context.push('/produtos/${produto.id}/editar'),
                      onDelete: () async {
                        final confirmar = await confirmarExclusao(
                          context,
                          titulo: 'Excluir produto',
                          mensagem:
                              'Deseja excluir "${produto.nome}"? Essa ação não pode ser desfeita.',
                        );
                        if (confirmar) await repo.excluirProduto(produto.id);
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}
