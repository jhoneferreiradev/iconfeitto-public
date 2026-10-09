import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/operacao.dart';
import '../pdf/compra_pdf.dart';

String _formatarDataCompra(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

class CompraListScreen extends StatefulWidget {
  const CompraListScreen({super.key});

  @override
  State<CompraListScreen> createState() => _CompraListScreenState();
}

class _CompraListScreenState extends State<CompraListScreen> {
  String _busca = '';
  DateTime? _dataFiltro;

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final compras = repo.compras.where(_compraFiltrada).toList()
          ..sort((a, b) => b.data.compareTo(a.data));
        return AppScaffold(
          title: 'Compras',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/compras/nova'),
            icon: const Icon(Icons.add),
            label: const Text('Nova compra'),
          ),
          body: Column(
            children: [
              _buildFiltros(context),
              Expanded(
                child: compras.isEmpty
                    ? const EmptyState(
                        mensagem: 'Nenhum resultado encontrado.',
                        icon: Icons.shopping_cart_outlined,
                      )
                    : SingleChildScrollView(
                        child: ContentWidth(
                          child: ResponsiveCardGrid(
                            children: [
                              for (final compra in compras)
                                _buildCardCompra(context, repo, compra),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCardCompra(
    BuildContext context,
    AppRepository repo,
    Compra compra,
  ) {
    final fornecedor =
        repo.fornecedorPorId(compra.fornecedorId)?.nome ??
        'Fornecedor removido';
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(fornecedor),
        subtitle: Text(_formatarDataCompra(compra.data)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              compra.total.toCurrency(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Prévia de impressão',
              onPressed: () => CompraPdf.visualizar(context, compra),
            ),
            PopupMenuButton<String>(
              tooltip: 'Ações da compra',
              onSelected: (acao) {
                if (acao == 'editar') {
                  context.push('/compras/${compra.id}/editar');
                } else {
                  _confirmarExclusao(compra);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'editar', child: Text('Editar')),
                PopupMenuItem(value: 'excluir', child: Text('Excluir')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros(BuildContext context) {
    return ContentWidth(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar produto ou fornecedor',
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
          IconButton(
            icon: Icon(
              _dataFiltro == null
                  ? Icons.event_outlined
                  : Icons.event_available,
            ),
            tooltip: 'Filtrar por data',
            onPressed: () async {
              final data = await showDatePicker(
                context: context,
                initialDate: _dataFiltro ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (data != null) setState(() => _dataFiltro = data);
            },
          ),
          if (_dataFiltro != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Limpar data',
              onPressed: () => setState(() => _dataFiltro = null),
            ),
        ],
      ),
    );
  }

  bool _compraFiltrada(Compra compra) {
    if (_dataFiltro != null &&
        (compra.data.year != _dataFiltro!.year ||
            compra.data.month != _dataFiltro!.month ||
            compra.data.day != _dataFiltro!.day)) {
      return false;
    }
    final busca = _busca.trim().toLowerCase();
    if (busca.isEmpty) return true;
    final repo = AppRepository.instance;
    final fornecedor =
        repo.fornecedorPorId(compra.fornecedorId)?.nome.toLowerCase() ?? '';
    return fornecedor.contains(busca) ||
        compra.itens.any((item) {
          final nome =
              repo.produtoPorId(item.produtoId)?.nome.toLowerCase() ?? '';
          return nome.contains(busca);
        });
  }

  Future<void> _confirmarExclusao(Compra compra) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir compra?'),
        content: const Text(
          'A compra será removida e o estoque e o custo médio serão recalculados.',
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
    if (confirmou != true || !mounted) return;
    try {
      await AppRepository.instance.excluirCompra(compra.id);
    } on SaldoEstoqueInsuficienteException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}