import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/pdf/pdf_header_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/operacao.dart';
import '../../../shared/models/produto.dart';

/// Gera e imprime as últimas 10 movimentações de estoque de um produto,
/// indicando entrada/saída e o saldo resultante após cada movimentação.
class MovimentosPdf {
  static Future<void> imprimir(Produto produto) async {
    final repo = AppRepository.instance;
    final movimentos = repo.ultimas10Movimentacoes(produto.id);
    final unidadeProduto = repo.unidadePorId(produto.unidadeEstoqueId);

    final linhas = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _celula('Data', bold: true),
          _celula('Tipo', bold: true),
          _celula('Sentido', bold: true),
          _celula('Qtd', bold: true),
          _celula('Unid.', bold: true),
          _celula('Vl. unit.', bold: true),
          _celula('Saldo após', bold: true),
        ],
      ),
    ];

    // Movimentos vêm ordenados do mais recente para o mais antigo; o saldo
    // após o mais recente é o saldo atual do produto, e cada saldo anterior
    // é obtido revertendo o efeito do movimento seguinte na lista.
    var saldoApos = produto.saldoEstoque;
    for (final movimento in movimentos) {
      final unidadeMovimento = repo.unidadePorId(movimento.unidadeId);
      final fatorConversao =
          unidadeMovimento.fatorParaBase / unidadeProduto.fatorParaBase;
      final delta = _deltaSaldo(movimento) * fatorConversao;
      final entrada = delta >= 0;

      linhas.add(
        pw.TableRow(
          children: [
            _celula(_formatarData(movimento.data)),
            _celula(_tipoLabel(movimento.tipo)),
            _celula(entrada ? 'Entrada' : 'Saída'),
            _celula(formatarNumero(movimento.quantidade)),
            _celula(unidadeMovimento.sigla),
            _celula(movimento.valorUnitario.toCurrency()),
            _celula('${formatarNumero(saldoApos)} ${unidadeProduto.sigla}'),
          ],
        ),
      );

      saldoApos -= delta;
    }

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          PdfHeaderHelper.buildCompanyHeader(repo.empresa),
          pw.Text(
            'Últimas movimentações — ${produto.nome}',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Saldo atual: ${formatarNumero(produto.saldoEstoque)} '
            '${unidadeProduto.sigla}',
          ),
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

  /// Efeito do movimento no saldo, em unidade do próprio movimento
  /// (positivo = entrada, negativo = saída).
  static double _deltaSaldo(MovimentoEstoque m) {
    switch (m.tipo) {
      case TipoMovimentoEstoque.compra:
      case TipoMovimentoEstoque.producao:
        return m.quantidade;
      case TipoMovimentoEstoque.venda:
      case TipoMovimentoEstoque.consumoFabricacao:
        return -m.quantidade;
      case TipoMovimentoEstoque.ajuste:
        return m.quantidade;
    }
  }

  static String _tipoLabel(TipoMovimentoEstoque tipo) => switch (tipo) {
    TipoMovimentoEstoque.compra => 'Compra',
    TipoMovimentoEstoque.venda => 'Venda',
    TipoMovimentoEstoque.consumoFabricacao => 'Consumo (fabricação)',
    TipoMovimentoEstoque.producao => 'Produção',
    TipoMovimentoEstoque.ajuste => 'Ajuste',
  };

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
