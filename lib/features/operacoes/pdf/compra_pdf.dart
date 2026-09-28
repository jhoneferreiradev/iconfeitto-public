import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/pdf/pdf_header_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/operacao.dart';

/// Gera e imprime o PDF de uma compra.
class CompraPdf {
  static Future<void> imprimir(Compra compra) async {
    final repo = AppRepository.instance;
    final fornecedor =
        repo.fornecedorPorId(compra.fornecedorId)?.nome ??
        'Fornecedor removido';

    var totalCompra = 0.0;

    final linhas = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _celula('Produto', bold: true),
          _celula('Qtd', bold: true),
          _celula('Unid.', bold: true),
          _celula('Vl. unit.', bold: true),
          _celula('Subtotal', bold: true),
        ],
      ),
    ];

    for (final item in compra.itens) {
      final produto = repo.produtoPorId(item.produtoId);
      final unidade = repo.unidadePorId(item.unidadeId);
      final subtotal = item.quantidade * item.valorUnitario;
      totalCompra += subtotal;

      linhas.add(
        pw.TableRow(
          children: [
            _celula(produto?.nome ?? 'Produto removido'),
            _celula(formatarNumero(item.quantidade)),
            _celula(unidade.sigla),
            _celula(item.valorUnitario.toCurrency()),
            _celula(subtotal.toCurrency()),
          ],
        ),
      );
    }

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          PdfHeaderHelper.buildCompanyHeader(repo.empresa),
          pw.Text(
            'Compra',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Fornecedor: $fornecedor'),
          pw.Text('Data: ${_formatarData(compra.data)}'),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: linhas,
          ),
          pw.SizedBox(height: 12),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total compra: ${totalCompra.toCurrency()}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  static pw.Widget _celula(String texto, {bool bold = false}) => pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      texto,
      style: pw.TextStyle(
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        fontSize: 10,
      ),
    ),
  );

  static String _formatarData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
}
