import 'package:iconfeitto/core/theme/app_spacing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/produto.dart';
import '../../../shared/models/tipo_item.dart';

class ItemListPdf {
  static Future<void> imprimir(
    List<Produto> itens, {
    required String titulo,
    required bool listaDeEstoque,
  }) async {
    final repo = AppRepository.instance;
    final documento = pw.Document(title: titulo);
    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text(
            titulo,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: listaDeEstoque
                ? ['Item', 'Tipo', 'Custo médio', 'Saldo em estoque']
                : ['Item', 'Tipo', 'Custo por rendimento', 'Valor de venda'],
            data: [
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
                        item.tipo.label + ' ',
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
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF8B3A62),
            ),
            cellPadding: pw.EdgeInsets.all(AppSpacing.xs),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            headerAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
            },
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => documento.save());
  }
}
