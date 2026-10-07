import 'package:go_router/go_router.dart';
import 'package:iconfeitto/shared/models/lancamento_financeiro.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../../../shared/data/app_repository.dart';

class LancamentoFinanceiroListScreen extends StatefulWidget {
  final String title;
  final List<TipoLancamentoFinanceiro> tipos;

  const LancamentoFinanceiroListScreen({
    super.key,
    this.title = 'Lançamentos financeiros',
    this.tipos = const [
      TipoLancamentoFinanceiro.receita,
      TipoLancamentoFinanceiro.despesa,
    ],
  });

  @override
  State<LancamentoFinanceiroListScreen> createState() =>
      _LancamentoFinanceiroListScreenState();
}

class _LancamentoFinanceiroListScreenState
    extends State<LancamentoFinanceiroListScreen> {
  String _busca = '';
  TipoLancamentoFinanceiro _tipoFiltro = TipoLancamentoFinanceiro.receita;

  bool get _lancamentos => widget.tipos.contains(_tipoFiltro);

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final itens = repo.lancamentosFinanceiros.where((item) {
          return widget.tipos.contains(item.tipoLancamento) &&
              (item.tipoLancamento == _tipoFiltro) &&
              item.descricao.toLowerCase().contains(
                _busca.trim().toLowerCase(),
              );
        }).toList()..sort((a, b) => a.descricao.compareTo(b.descricao));
        return AppScaffold(
          title: widget.title,
          actions: [
            // IconButton(
            //   tooltip: 'Imprimir lista',
            //   icon: const Icon(Icons.print_outlined),
            //   onPressed: itens.isEmpty
            //       ? null
            //       : () => Lan.imprimir(
            //           itens,
            //           titulo: widget.title,
            //           listaDeLancamentos: _lancamentos,
            //         ),
            // ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/financeiro/lancamentos/novo'),
            icon: const Icon(Icons.add),
            label: const Text('Novo lançamento'),
          ),
          body: Column(
            children: [
              ContentWidth(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final busca = TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar por descrição',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() => _busca = value),
                    );
                    final tipo =
                        DropdownButtonFormField<TipoLancamentoFinanceiro?>(
                          initialValue: _tipoFiltro,
                          decoration: const InputDecoration(labelText: 'Tipo'),
                          items: [
                            for (final tipo in widget.tipos)
                              DropdownMenuItem<TipoLancamentoFinanceiro?>(
                                value: tipo,
                                child: Text(tipo.label),
                              ),
                          ],
                          onChanged: (value) => setState(
                            () => _tipoFiltro =
                                value ?? TipoLancamentoFinanceiro.receita,
                          ),
                        );
                    if (constraints.maxWidth < 560) {
                      return Column(
                        children: [busca, const SizedBox(height: 8), tipo],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(flex: 2, child: busca),
                        const SizedBox(width: 12),
                        Expanded(child: tipo),
                      ],
                    );
                  },
                ),
              ),
              Expanded(
                child: itens.isEmpty
                    ? EmptyState(
                        mensagem: _busca.isEmpty
                            ? 'Nenhum lançamento cadastrado.'
                            : 'Nenhum lançamento encontrado.',
                        icon: _lancamentos
                            ? Icons.inventory_2_outlined
                            : Icons.cake_outlined,
                      )
                    : SingleChildScrollView(
                        child: ContentWidth(
                          child: ResponsiveCardGrid(
                            children: [
                              for (final item in itens)
                                _buildCard(context, repo, item),
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

  Widget _buildCard(
    BuildContext context,
    AppRepository repo,
    LancamentoFinanceiro item,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Row(
          children: [
            Expanded(child: Text(item.descricao)),
            // if (isProduto)
            //   IconButton(
            //     icon: const Icon(Icons.print_outlined),
            //     tooltip: 'Imprimir ficha técnica',
            //     onPressed: () => FichaTecnicaPdf.imprimir(item),
            //   ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: item.tipoOperacaoOriem == TipoOperacaoOrigem.avulso
                  ? 'Excluir item'
                  : 'Vinculado a uma operação: exclua pela operação de origem',
              onPressed: item.tipoOperacaoOriem != TipoOperacaoOrigem.avulso
                  ? null
                  : () async {
                final confirmar = await confirmarExclusao(
                  context,
                  titulo: 'Excluir lançamento',
                  mensagem: 'Deseja excluir o lançamento? Essa ação não pode ser desfeita.',
                );
                if (confirmar) await repo.excluirLancamentoFinanceiro(item);
              },
            ),
          ],
        ),
        subtitle: Text(
          'Valor: ${item.valorTotal.toCurrency()}  •  '
          'Vencimento: ${item.dataVencimento.toFormattedDate()}',
        ),
        onTap: () => context.push('/financeiro/lancamentos/${item.id}/editar'),
      ),
    );
  }
}
