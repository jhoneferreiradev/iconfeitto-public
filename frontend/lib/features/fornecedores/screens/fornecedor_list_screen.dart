import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/fornecedor.dart';

class FornecedorListScreen extends StatelessWidget {
  const FornecedorListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final fornecedores = repo.fornecedores;
        return AppScaffold(
          title: 'Fornecedores',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/fornecedores/novo'),
            icon: const Icon(Icons.add),
            label: const Text('Novo fornecedor'),
          ),
          body: fornecedores.isEmpty
              ? const EmptyState(
                  mensagem: 'Nenhum fornecedor cadastrado ainda.\nToque em "Novo fornecedor" para começar.',
                  icon: Icons.business_outlined,
                )
              : ResponsiveCardList(
                  itemCount: fornecedores.length,
                  itemBuilder: (context, index) {
                    final fornecedor = fornecedores[index];
                    return _FornecedorTile(
                      fornecedor: fornecedor,
                      onEditar: () =>
                          context.push('/fornecedores/${fornecedor.id}/editar'),
                      onExcluir: () => _excluir(context, repo, fornecedor),
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _excluir(
    BuildContext context,
    AppRepository repo,
    Fornecedor fornecedor,
  ) async {
    final confirmar = await confirmarExclusao(
      context,
      titulo: 'Excluir fornecedor',
      mensagem: 'Deseja excluir "${fornecedor.nome}"?',
    );
    if (confirmar) repo.excluirFornecedor(fornecedor.id);
  }
}

class _FornecedorTile extends StatelessWidget {
  final Fornecedor fornecedor;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _FornecedorTile({
    required this.fornecedor,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final corStatus = fornecedor.ativo ? Colors.green : Colors.grey;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(Icons.business_outlined, color: corStatus),
        title: Text(fornecedor.nome),
        subtitle: Text(fornecedor.ativo ? 'Ativo' : 'Inativo'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
              onPressed: onEditar,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir',
              onPressed: onExcluir,
            ),
          ],
        ),
      ),
    );
  }
}
