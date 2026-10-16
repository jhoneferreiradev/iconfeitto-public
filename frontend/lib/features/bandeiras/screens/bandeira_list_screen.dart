import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/cartao_credito.dart';
import '../../cartoes/widgets/cartao_dialogs.dart';

class BandeiraListScreen extends StatelessWidget {
  const BandeiraListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final bandeiras = [...repo.bandeirasCartaoCredito]
          ..sort((a, b) => a.nome.compareTo(b.nome));
        return AppScaffold(
          title: 'Bandeiras de cartão',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/bandeiras/nova'),
            icon: const Icon(Icons.add),
            label: const Text('Nova bandeira'),
          ),
          body: bandeiras.isEmpty
              ? const EmptyState(
                  mensagem:
                      'Nenhuma bandeira cadastrada ainda.\nToque em "Nova bandeira" para começar.',
                  icon: Icons.contactless_outlined,
                )
              : ResponsiveCardList(
                  itemCount: bandeiras.length,
                  itemBuilder: (context, index) {
                    final bandeira = bandeiras[index];
                    return _BandeiraTile(
                      bandeira: bandeira,
                      onEditar: () =>
                          context.push('/bandeiras/${bandeira.id}/editar'),
                      onExcluir: () => _excluir(context, repo, bandeira),
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
    BandeiraCartaoCredito bandeira,
  ) async {
    final confirmar = await confirmarExclusao(
      context,
      titulo: 'Excluir bandeira',
      mensagem: 'Deseja excluir "${bandeira.nome}"?',
    );
    if (!confirmar) return;
    try {
      await repo.excluirBandeiraCartao(bandeira.id);
    } on StateError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class _BandeiraTile extends StatelessWidget {
  final BandeiraCartaoCredito bandeira;
  final VoidCallback onEditar;
  final VoidCallback onExcluir;

  const _BandeiraTile({
    required this.bandeira,
    required this.onEditar,
    required this.onExcluir,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.contactless_outlined),
        title: Text(bandeira.nome),
        subtitle: Text(
          'Taxa: ${descricaoTaxaBandeira(bandeira)} · compensa em '
          '${bandeira.diasCompensacao} '
          '${bandeira.diasCompensacao == 1 ? 'dia' : 'dias'}',
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
