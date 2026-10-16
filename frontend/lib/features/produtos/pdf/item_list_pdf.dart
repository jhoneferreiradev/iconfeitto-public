import 'package:material_ui/material_ui.dart';

import '../../../core/pdf/pdf_padrao.dart';
import '../../../core/pdf/pdf_relatorio.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/produto.dart';
import '../../../shared/models/tipo_item.dart';

/// Lista de itens (estoque ou custos) no padrão de impressão do app.
class ItemListPdf {
  static Future<void> visualizar(
    BuildContext context,
    List<Produto> itens, {
    required String titulo,
    required bool listaDeEstoque,
  }) => relatorio(
    itens,
    titulo: titulo,
    listaDeEstoque: listaDeEstoque,
  ).visualizar(context);

  static PdfRelatorio relatorio(
    List<Produto> itens, {
    required String titulo,
    required bool listaDeEstoque,
  }) {
    final repo = AppRepository.instance;
    return PdfRelatorio(
      titulo: titulo,
      gerar: (_) => PdfPadrao.gerar(
        empresa: repo.empresa,
        tituloDocumento: titulo,
        referencia: titulo,
        titulo: PdfPadrao.titulo(
          sobretitulo: 'Relatório',
          titulo: titulo,
          destaques: [(rotulo: 'Itens', valor: '${itens.length}')],
        ),
        conteudo: (_) => [
          PdfPadrao.tabela(
            colunas: listaDeEstoque
                ? const ['Item', 'Tipo', 'Custo médio', 'Saldo em estoque']
                : const [
                    'Item',
                    'Tipo',
                    'Custo por rendimento',
                    'Valor de venda',
                  ],
            larguras: const [3, 2, 2, 2],
            alinhadasADireita: const {2, 3},
            linhas: [
              for (final item in itens)
                listaDeEstoque
                    ? [
                        item.nome,
                        item.tipo.label,
                        item.custoMedio.toCurrency(),
                        '${item.saldoEstoque.toDecimal()} ${repo.unidadePorId(item.unidadeEstoqueId).sigla}',
                      ]
                    : [
                        item.nome,
                        item.tipo.label,
                        CalculadoraCustoProduto(
                          rendimentoReceita: item.rendimentoReceita,
                          custoFichaTecnica: repo.custoTotalFicha(item),
                          custoOperacional: item.custoOperacional,
                          custoUnitarioEmbalagem: repo.custoEmbalagem(item),
                        ).custoRendimentoUnitario.toCurrency(),
                        item.tipo == TipoItem.produto
                            ? item.precoVenda.toCurrency()
                            : '',
                      ],
            ],
          ),
        ],
      ),
    );
  }
}
