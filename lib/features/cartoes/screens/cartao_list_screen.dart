import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/cartao_credito.dart';

class CartaoListScreen extends StatelessWidget {
  const CartaoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final cartoes = [...repo.cartoesCredito]
          ..sort((a, b) => a.nome.compareTo(b.nome));
        return AppScaffold(
          title: 'Cartões de crédito',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/cartoes/novo'),
            icon: const Icon(Icons.add),
            label: const Text('Novo cartão'),
          ),
          body: cartoes.isEmpty
              ? const EmptyState(
                  mensagem:
                      'Nenhum cartão cadastrado ainda.\nToque em "Novo cartão" para começar.',
                  icon: Icons.credit_card_outlined,
                )
              : ResponsiveCardList(
                  itemCount: cartoes.length,
                  itemBuilder: (context, index) {
                    final cartao = cartoes[index];
                    return _CartaoTile(
                      cartao: cartao,
                      onEditar: () => context.push('/cartoes/${cartao.id}/editar'),
                      onExcluir: () => _excluir(context, repo, cartao),
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
    CartaoCredito cartao,
  ) async {
    final confirmar = await confirmarExclusao(
      context,
      titulo: 'Excluir cartão',
      mensagem: 'Deseja excluir "${cartao.nome}"?',
    );
    if (!confirmar) return;
    try {
      await repo.excluirCartaoCredito(cartao.id);
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _CartaoTile extends StatelessWidget {
  final CartaoCredito cartao;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _CartaoTile({
    required this.cartao,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    final dias = cartao.diasFechamento;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.credit_card_outlined),
        title: Text(cartao.nome),
        subtitle: Text(
          'Vence dia ${cartao.diaVencimento} · fecha $dias '
          '${dias == 1 ? 'dia' : 'dias'} antes',
        ),
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
