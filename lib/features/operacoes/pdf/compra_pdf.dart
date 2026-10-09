import 'package:material_ui/material_ui.dart';

import '../../../core/pdf/pdf_padrao.dart';
import '../../../core/pdf/pdf_relatorio.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/operacao.dart';

/// Comprovante da compra no padrão de impressão do app.
class CompraPdf {
  static Future<void> visualizar(BuildContext context, Compra compra) =>
      relatorio(compra).visualizar(context);

  static PdfRelatorio relatorio(Compra compra) {
    final repo = AppRepository.instance;
    final fornecedor =
        repo.fornecedorPorId(compra.fornecedorId)?.nome ??
        'Fornecedor removido';
    final titulo = 'Compra - $fornecedor';

    return PdfRelatorio(
      titulo: titulo,
      gerar: (_) => PdfPadrao.gerar(
        empresa: repo.empresa,
        tituloDocumento: titulo,
        referencia: fornecedor,
        titulo: PdfPadrao.titulo(
          sobretitulo: 'Registro de compra',
          titulo: 'Compra',
          destaques: [
            (rotulo: 'Fornecedor', valor: fornecedor),
            (rotulo: 'Data', valor: compra.data.toFormattedDate()),
          ],
        ),
        conteudo: (_) => [
          PdfPadrao.tabela(
            colunas: const ['Produto', 'Qtd.', 'Unid.', 'Vl. unitário', 'Subtotal'],
            larguras: const [4, 1.2, 1, 1.6, 1.6],
            alinhadasADireita: const {1, 3, 4},
            linhas: [
              for (final item in compra.itens)
                [
                  repo.produtoPorId(item.produtoId)?.nome ?? 'Produto removido',
                  formatarNumero(item.quantidade),
                  repo.unidadePorId(item.unidadeId).sigla,
                  item.valorUnitario.toCurrency(),
                  (item.quantidade * item.valorUnitario).toCurrency(),
                ],
            ],
          ),
          PdfPadrao.espaco(14),
          PdfPadrao.caixaTotal(
            rotulo: 'Total da compra',
            valor: compra.total.toCurrency(),
          ),
        ],
      ),
    );
  }
}
