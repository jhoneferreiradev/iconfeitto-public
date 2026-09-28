import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/grupo_unidade.dart';
import '../../../shared/models/unidade_medida.dart';

class UnidadeListScreen extends StatelessWidget {
  const UnidadeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        return AppScaffold(
          title: 'Unidades de medida',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/unidades/nova'),
            icon: const Icon(Icons.add),
            label: const Text('Nova unidade'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              for (final grupo in GrupoUnidade.values)
                ..._buildGrupo(context, repo, grupo),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildGrupo(
    BuildContext context,
    AppRepository repo,
    GrupoUnidade grupo,
  ) {
    final unidadesDoGrupo = repo.unidadesDoGrupo(grupo);
    final base = unidadesDoGrupo.where((u) => u.fatorParaBase == 1).isNotEmpty
        ? unidadesDoGrupo.firstWhere((u) => u.fatorParaBase == 1)
        : null;
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(
          grupo.label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      ...unidadesDoGrupo.map(
        (u) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('${u.nome} (${u.sigla})'),
            subtitle: Text(
              u.fatorParaBase == 1 || base == null
                  ? 'Unidade base do grupo'
                  : '1 ${u.sigla} = ${u.fatorParaBase.toDecimal()} ${base.sigla}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar',
                  onPressed: () => context.push('/unidades/${u.id}/editar'),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Excluir',
                  onPressed: () => _excluir(context, repo, u),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Future<void> _excluir(
    BuildContext context,
    AppRepository repo,
    UnidadeMedida u,
  ) async {
    final confirmar = await confirmarExclusao(
      context,
      titulo: 'Excluir unidade',
      mensagem: 'Deseja excluir "${u.nome}"?',
    );
    if (!confirmar) return;
    try {
      repo.excluirUnidade(u.id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }
}
