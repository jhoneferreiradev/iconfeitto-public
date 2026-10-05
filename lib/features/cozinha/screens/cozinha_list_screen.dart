import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/operacao.dart';
import '../pdf/fabricacao_pdf.dart';

/// Lista as fabricações registradas, mais recentes primeiro.
class CozinhaListScreen extends StatelessWidget {
  const CozinhaListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        // Vinculadas aparecem dentro da fabricação principal.
        final idsExistentes = {for (final f in repo.fabricacoes) f.id};
        final fabricacoes =
            repo.fabricacoes
                .where((f) => !idsExistentes.contains(f.fabricacaoPaiId))
                .toList()
              ..sort((a, b) => b.data.compareTo(a.data));
        return AppScaffold(
          title: 'Fabricação',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/cozinha/nova'),
            icon: const Icon(Icons.add),
            label: const Text('Registrar fabricação'),
          ),
          body: fabricacoes.isEmpty
              ? const EmptyState(
                  mensagem: 'Nenhuma fabricação registrada ainda.',
                  icon: Icons.factory_outlined,
                )
              : ResponsiveCardList(
                  itemCount: fabricacoes.length,
                  itemBuilder: (context, index) {
                    final fabricacao = fabricacoes[index];
                    final produto = repo.produtoPorId(fabricacao.produtoId);
                    final unidade = produto == null
                        ? null
                        : repo.unidadePorId(produto.unidadeEstoqueId);
                    final vinculadas = repo.fabricacoesVinculadas(
                      fabricacao.id,
                    );
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: const Icon(Icons.factory_outlined),
                        title: Text(produto?.nome ?? 'Produto removido'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_formatarData(fabricacao.data)}  •  '
                              '${formatarNumero(fabricacao.quantidade)}'
                              '${unidade != null ? ' ${unidade.sigla}' : ''}',
                            ),
                            if (vinculadas.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Chip(
                                  avatar: const Icon(Icons.link, size: 16),
                                  label: Text(
                                    vinculadas.length == 1
                                        ? '1 preparo vinculado'
                                        : '${vinculadas.length} preparos vinculados',
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                          ],
                        ),
                        onTap: () => context.push('/cozinha/${fabricacao.id}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.print_outlined),
                              tooltip: 'Imprimir',
                              onPressed: () =>
                                  FabricacaoPdf.imprimir(fabricacao),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: 'Excluir',
                              onPressed: () => confirmarExclusaoFabricacao(
                                context,
                                fabricacao,
                              ),
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

  String _formatarData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
}

/// Pede confirmação e exclui a fabricação, avisando se faltar saldo.
Future<bool> confirmarExclusaoFabricacao(
  BuildContext context,
  Fabricacao fabricacao,
) async {
  final vinculadas = AppRepository.instance.fabricacoesVinculadas(
    fabricacao.id,
  );
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Excluir fabricação?'),
      content: Text(
        vinculadas.isEmpty
            ? 'A fabricação será removida e o estoque e o custo médio serão recalculados.'
            : 'A fabricação será removida junto com ${vinculadas.length == 1 ? 'o preparo vinculado' : 'os ${vinculadas.length} preparos vinculados'}: ${vinculadas.map((v) => AppRepository.instance.produtoPorId(v.produtoId)?.nome ?? 'Produto removido').join(', ')}. '
                  'O estoque e o custo médio serão recalculados.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  if (confirmou != true || !context.mounted) return false;
  try {
    await AppRepository.instance.excluirFabricacao(fabricacao.id);
    return true;
  } on SaldoEstoqueInsuficienteException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  } on StateError catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
  return false;
}
