import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/operacao.dart';
import '../pdf/venda_pdf.dart';
import '../widgets/venda_status_chip.dart';

Future<bool> confirmarExclusaoVenda(BuildContext context, Venda venda) async {
  final confirmou = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Excluir venda?'),
      content: const Text(
        'A venda e seus lançamentos financeiros serão removidos e o estoque e o custo médio serão recalculados.',
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
    await AppRepository.instance.excluirVenda(venda.id);
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

class VendaListScreen extends StatefulWidget {
  const VendaListScreen({super.key});

  @override
  State<VendaListScreen> createState() => _VendaListScreenState();
}

class _VendaListScreenState extends State<VendaListScreen> {
  String _busca = '';
  DateTime? _dataFiltro;
  StatusVenda? _statusFiltro;

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final vendas = repo.vendas.where(_vendaFiltrada).toList()
          ..sort((a, b) => b.data.compareTo(a.data));
        return AppScaffold(
          title: 'Vendas',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/vendas/nova'),
            icon: const Icon(Icons.add),
            label: const Text('Nova venda'),
          ),
          body: Column(
            children: [
              _buildFiltros(context),
              Expanded(
                child: vendas.isEmpty
                    ? const EmptyState(
                        mensagem: 'Nenhum resultado encontrado.',
                        icon: Icons.point_of_sale_outlined,
                      )
                    : ResponsiveCardList(
                        itemCount: vendas.length,
                        itemBuilder: (context, index) {
                          final venda = vendas[index];
                          final cliente =
                              repo.clientePorId(venda.clienteId)?.nome ??
                              'Cliente removido';
                          return Card(
                            margin: EdgeInsets.zero,
                            child: ListTile(
                              title: Text(cliente),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    VendaStatusChip(status: venda.status),
                                    Text(
                                      '${venda.tipo.label} · pedido em '
                                      '${_formatarData(venda.data)}'
                                      '${venda.dataEntrega == null ? '' : ' · entrega em ${_formatarData(venda.dataEntrega!)}'}',
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () =>
                                  context.push('/vendas/${venda.id}/editar'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    venda.total.toCurrency(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.print_outlined),
                                    tooltip: 'Prévia de impressão',
                                    onPressed: () => VendaPdf.visualizar(context, venda),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: 'Ações da venda',
                                    onSelected: (acao) {
                                      if (acao == 'editar') {
                                        context.push(
                                          '/vendas/${venda.id}/editar',
                                        );
                                      } else {
                                        _confirmarExclusao(venda);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'editar',
                                        child: Text('Editar'),
                                      ),
                                      PopupMenuItem(
                                        value: 'excluir',
                                        child: Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFiltros(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar produto ou cliente',
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
          PopupMenuButton<String>(
            tooltip: 'Filtrar por andamento',
            icon: Icon(
              _statusFiltro == null
                  ? Icons.filter_list
                  : Icons.filter_list_alt,
            ),
            onSelected: (valor) => setState(
              () => _statusFiltro = StatusVenda.values
                  .where((status) => status.name == valor)
                  .firstOrNull,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'todos',
                child: Text('Todos os andamentos'),
              ),
              for (final status in StatusVenda.values)
                PopupMenuItem(value: status.name, child: Text(status.label)),
            ],
          ),
        ],
      ),
    );
  }

  bool _vendaFiltrada(Venda venda) {
    if (_statusFiltro != null && venda.status != _statusFiltro) return false;
    if (_dataFiltro != null &&
        (venda.data.year != _dataFiltro!.year ||
            venda.data.month != _dataFiltro!.month ||
            venda.data.day != _dataFiltro!.day)) {
      return false;
    }
    final busca = _busca.trim().toLowerCase();
    if (busca.isEmpty) return true;
    final repo = AppRepository.instance;
    final cliente =
        repo.clientePorId(venda.clienteId)?.nome.toLowerCase() ?? '';
    return cliente.contains(busca) ||
        venda.itens.any((item) {
          final nome =
              repo.produtoPorId(item.produtoId)?.nome.toLowerCase() ?? '';
          return nome.contains(busca);
        });
  }

  Future<void> _confirmarExclusao(Venda venda) async {
    final excluida = await confirmarExclusaoVenda(context, venda);
    if (excluida && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Venda excluída.')));
    }
  }
}

String _formatarData(DateTime data) =>
    '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
