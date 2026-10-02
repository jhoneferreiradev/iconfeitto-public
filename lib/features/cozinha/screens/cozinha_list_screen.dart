import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_scaffold.dart';
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
        final fabricacoes = repo.fabricacoes.toList()
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
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: fabricacoes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final fabricacao = fabricacoes[index];
                    final produto = repo.produtoPorId(fabricacao.produtoId);
                    final unidade = produto == null
                        ? null
                        : repo.unidadePorId(produto.unidadeEstoqueId);
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.factory_outlined),
                        title: Text(produto?.nome ?? 'Produto removido'),
                        subtitle: Text(
                          '${_formatarData(fabricacao.data)}  •  '
                          '${formatarNumero(fabricacao.quantidade)}'
                          '${unidade != null ? ' ${unidade.sigla}' : ''}',
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
                              onPressed: () =>
                                  confirmarExclusaoFabricacao(context, fabricacao),
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
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Excluir fabricação?'),
      content: const Text(
        'A fabricação será removida e o estoque e o custo médio serão recalculados.',
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  } on StateError catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
  return false;
}