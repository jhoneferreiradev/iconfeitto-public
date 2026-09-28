import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/pdf/pdf_header_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/produto.dart';

/// Gera e imprime a ficha técnica de um produto, expandindo recursivamente
/// os ingredientes que também possuem ficha técnica própria.
class FichaTecnicaPdf {
  static Future<void> imprimir(Produto produto) async {
    final repo = AppRepository.instance;
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          PdfHeaderHelper.buildCompanyHeader(repo.empresa),
          pw.Text(
            'Ficha técnica: ${produto.nome}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          ..._buildItens(repo, produto, 0),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Custo total: ${repo.custoTotalFicha(produto).toCurrency()}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  static List<pw.Widget> _buildItens(
    AppRepository repo,
    Produto produto,
    int nivel,
  ) {
    final widgets = <pw.Widget>[];
    for (final item in produto.fichaTecnica) {
      final ingrediente = repo.produtoPorId(item.produtoIngredienteId);
      final unidade = repo.unidadePorId(item.unidadeId);
      final custo = repo.custoItemFicha(item);
      widgets.add(
        pw.Padding(
          padding: pw.EdgeInsets.only(left: (nivel * 16).toDouble(), bottom: 4),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${ingrediente?.nome ?? 'Ingrediente removido'} — '
                  '${formatarNumero(item.quantidade)} ${unidade.sigla}',
                ),
              ),
              pw.Text(custo.toCurrency()),
            ],
          ),
        ),
      );
      if (ingrediente != null &&
          ingrediente.possuiFichaTecnica &&
          ingrediente.fichaTecnica.isNotEmpty) {
        widgets.addAll(_buildItens(repo, ingrediente, nivel + 1));
      }
    }
    return widgets;
  }
}
