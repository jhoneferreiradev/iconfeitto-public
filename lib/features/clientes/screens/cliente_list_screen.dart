import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../shared/data/app_repository.dart';

class ClienteListScreen extends StatelessWidget {
  const ClienteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        return AppScaffold(
          title: 'Clientes',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/clientes/novo'),
            icon: const Icon(Icons.add),
            label: const Text('Novo cliente'),
          ),
          body: repo.clientes.isEmpty
              ? const EmptyState(
                  mensagem: 'Nenhum cliente cadastrado ainda.',
                  icon: Icons.person_outline,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: repo.clientes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final cliente = repo.clientes[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.person_outline,
                          color: cliente.ativo ? Colors.green : Colors.grey,
                        ),
                        title: Text(cliente.nome),
                        subtitle: Text(cliente.ativo ? 'Ativo' : 'Inativo'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Editar',
                              onPressed: () => context.push(
                                '/clientes/${cliente.id}/editar',
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Excluir',
                              onPressed: () async {
                                final confirmar = await confirmarExclusao(
                                  context,
                                  titulo: 'Excluir cliente',
                                  mensagem: 'Deseja excluir "${cliente.nome}"?',
                                );
                                if (confirmar) repo.excluirCliente(cliente.id);
                              },
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
}
