import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/responsive.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/produto.dart';
import '../../../shared/models/tipo_item.dart';
import '../pdf/ficha_tecnica_pdf.dart';
import '../pdf/item_list_pdf.dart';

class ProdutoListScreen extends StatefulWidget {
  final String title;
  final List<TipoItem> tipos;

  const ProdutoListScreen({
    super.key,
    this.title = 'Produtos e preparos',
    this.tipos = const [TipoItem.produto, TipoItem.preparo],
  });

  @override
  State<ProdutoListScreen> createState() => _ProdutoListScreenState();
}

class _ProdutoListScreenState extends State<ProdutoListScreen> {
  String _busca = '';
  TipoItem? _tipoFiltro;

  bool get _listaDeEstoque => widget.tipos.contains(TipoItem.insumo);

  @override
  Widget build(BuildContext context) {
    final repo = AppRepository.instance;
    return AnimatedBuilder(
      animation: repo,
      builder: (context, _) {
        final itens = repo.produtos.where((item) {
          final nomeCorresponde = item.nome.toLowerCase().contains(
            _busca.trim().toLowerCase(),
          );
          return widget.tipos.contains(item.tipo) &&
              (_tipoFiltro == null || item.tipo == _tipoFiltro) &&
              nomeCorresponde;
        }).toList()..sort((a, b) => a.nome.compareTo(b.nome));
        return AppScaffold(
          title: widget.title,
          actions: [
            IconButton(
              tooltip: 'Imprimir lista',
              icon: const Icon(Icons.print_outlined),
              onPressed: itens.isEmpty
                  ? null
                  : () => ItemListPdf.imprimir(
                      itens,
                      titulo: widget.title,
                      listaDeEstoque: _listaDeEstoque,
                    ),
            ),
          ],
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push(
              '/produtos/novo?tipo=${(_listaDeEstoque ? TipoItem.insumo : TipoItem.produto).name}&grupo=${_listaDeEstoque ? 'estoque' : 'produto'}',
            ),
            icon: const Icon(Icons.add),
            label: const Text('Novo item'),
          ),
          body: Column(
            children: [
              ContentWidth(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final busca = TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar por nome',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) => setState(() => _busca = value),
                    );
                    final tipo = DropdownButtonFormField<TipoItem?>(
                      initialValue: _tipoFiltro,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                      items: [
                        const DropdownMenuItem<TipoItem?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        for (final tipo in widget.tipos)
                          DropdownMenuItem<TipoItem?>(
                            value: tipo,
                            child: Text(tipo.label),
                          ),
                      ],
                      onChanged: (value) => setState(() => _tipoFiltro = value),
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
                            ? 'Nenhum item cadastrado.'
                            : 'Nenhum item encontrado.',
                        icon: _listaDeEstoque
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

  Widget _buildCard(BuildContext context, AppRepository repo, Produto item) {
    final custo = _listaDeEstoque
        ? item.custoMedio
        : CalculadoraCustoProduto(
            rendimentoReceita: item.rendimentoReceita,
            custoFichaTecnica: repo.custoTotalFicha(item),
            custoOperacional: item.custoOperacional,
            custoUnitarioEmbalagem: repo.custoEmbalagem(item),
          ).custoRendimentoUnitario;

    final bool isProduto = TipoItem.produto == item.tipo;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Row(
          children: [
            Expanded(child: Text(item.nome)),
            if (isProduto)
              IconButton(
                icon: const Icon(Icons.print_outlined),
                tooltip: 'Imprimir ficha técnica',
                onPressed: () => FichaTecnicaPdf.imprimir(item),
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir item',
              onPressed: () async {
                final confirmar = await confirmarExclusao(
                  context,
                  titulo: 'Excluir item',
                  mensagem:
                      'Deseja excluir "${item.nome}"? Essa ação não pode ser desfeita.',
                );
                if (confirmar) await repo.excluirProduto(item.id);
              },
            ),
          ],
        ),
        subtitle: _listaDeEstoque
            ? Text(
                'Custo médio: ${custo.toCurrency()}  •  '
                'Saldo: ${formatarNumero(item.saldoEstoque)} '
                '${repo.unidadePorId(item.unidadeEstoqueId).sigla}',
              )
            : Text(
                isProduto
                    ? 'Custo: ${custo.toCurrency()}  •  Venda: ${item.precoVenda.toCurrency()}'
                    : 'Custo para 1 rendimento: ${custo.toCurrency()}',
              ),
        onTap: () => context.push(
          '/produtos/${item.id}/editar?grupo=${_listaDeEstoque ? 'estoque' : 'produto'}',
        ),
      ),
    );
  }
}
