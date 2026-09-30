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

    buildLinhaCabecalho(String titulo, String valor, {pw.TextStyle? style}) {
      return pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              titulo,
              style:
                  style ??
                  pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal),
            ),
          ),
          pw.Text(valor, style: style),
        ],
      );
    }

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          PdfHeaderHelper.buildCompanyHeader(repo.empresa),
          pw.Text(
            'Ficha técnica: ${produto.nome}',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Divider(endIndent: 200),

          buildLinhaCabecalho(
            'Tempo de preparo',
            "${produto.tempoPreparoMinutos} minutos",
          ),
          buildLinhaCabecalho(
            'Rendimento',
            "${produto.rendimentoReceita} ${produto.unidadeConsumoId ?? produto.unidadeEstoqueId}",
          ),
          buildLinhaCabecalho(
            'Custo total dos itens',
            repo.custoTotalFicha(produto).toCurrency(),
          ),
          buildLinhaCabecalho(
            'Custo operacional',
            produto.custoOperacional.toCurrency(),
          ),
          buildLinhaCabecalho(
            'Custo total da receita',
            produto.custoTotalReceita.toCurrency(),
          ),
          pw.Divider(endIndent: 200),
          buildLinhaCabecalho(
            'Custo para produzir 1 ${produto.unidadeConsumoId ?? produto.unidadeEstoqueId}',
            produto.custoRendimentoUnitario.toCurrency(),
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Divider(endIndent: 200),
          pw.SizedBox(height: 24),
          pw.Text(
            'Produtos e ingredientes',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          _buildTabelaItens(repo, produto),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => doc.save());
  }

  static pw.Widget _buildTabelaItens(AppRepository repo, Produto produto) {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(4),
        2: pw.FlexColumnWidth(2),
      },
      border: pw.TableBorder(horizontalInside: const pw.BorderSide(width: 0.5)),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 1)),
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                'Quantidade',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                'Ingrediente',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 4),
              child: pw.Text(
                'Custo',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        ..._buildLinhasItens(repo, produto, 0),
      ],
    );
  }

  static List<pw.TableRow> _buildLinhasItens(
    AppRepository repo,
    Produto produto,
    int nivel,
  ) {
    final rows = <pw.TableRow>[];

    for (final item in produto.fichaTecnica) {
      final ingrediente = repo.produtoPorId(item.produtoIngredienteId);
      final unidade = repo.unidadePorId(item.unidadeId);
      final custo = repo.custoItemFicha(item);
      rows.add(
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Text(
                '${formatarNumero(item.quantidade)} ${unidade.sigla}',
              ),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.only(
                left: (nivel * 16).toDouble(),
                top: 3,
                bottom: 3,
              ),
              child: pw.Text(ingrediente?.nome ?? 'Ingrediente removido'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Text(custo.toCurrency(), textAlign: pw.TextAlign.right),
            ),
          ],
        ),
      );
      if (ingrediente != null &&
          ingrediente.possuiFichaTecnica &&
          ingrediente.fichaTecnica.isNotEmpty) {
        rows.addAll(_buildLinhasItens(repo, ingrediente, nivel + 1));
      }
    }
    return rows;
  }
}
