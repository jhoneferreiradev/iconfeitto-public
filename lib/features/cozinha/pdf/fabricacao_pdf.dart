import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/pdf/pdf_header_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/operacao.dart';

/// Gera e imprime o PDF de um registro de fabricação.
class FabricacaoPdf {
  static Future<void> imprimir(Fabricacao fabricacao) async {
    final repo = AppRepository.instance;
    final produto = repo.produtoPorId(fabricacao.produtoId);
    final unidadeProduto = produto == null
        ? null
        : repo.unidadePorId(produto.unidadeEstoqueId);

    final linhas = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _celula('Ingrediente', bold: true),
          _celula('Qtd', bold: true),
          _celula('Unid.', bold: true),
        ],
      ),
    ];

    for (final item in fabricacao.fichaTecnica) {
      final ingrediente = repo.produtoPorId(item.produtoIngredienteId);
      final unidade = repo.unidadePorId(item.unidadeId);
      linhas.add(
        pw.TableRow(
          children: [
            _celula(ingrediente?.nome ?? 'Ingrediente removido'),
            _celula(formatarNumero(item.quantidade)),
            _celula(unidade.sigla),
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
            'Fabricação',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Produto: ${produto?.nome ?? 'Produto removido'}'),
          pw.Text(
            'Quantidade fabricada: ${formatarNumero(fabricacao.quantidade)}'
            '${unidadeProduto != null ? ' ${unidadeProduto.sigla}' : ''}',
          ),
          pw.Text('Data: ${_formatarData(fabricacao.data)}'),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: linhas,
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
