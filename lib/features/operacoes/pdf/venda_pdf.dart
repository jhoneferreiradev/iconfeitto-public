import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/empresa.dart';
import '../../../shared/models/operacao.dart';

class _VendaPdfTheme {
  static final primaria = PdfColor.fromInt(0xFF8B3A62);
  static final primariaSuave = PdfColor.fromInt(0xFFF7ECF1);
  static final texto = PdfColor.fromInt(0xFF2B2630);
  static final apagado = PdfColor.fromInt(0xFF7A727C);
  static final linha = PdfColor.fromInt(0xFFE8DFE4);
  static final zebra = PdfColor.fromInt(0xFFFBF8FA);
  static final positivo = PdfColor.fromInt(0xFF2E7D4F);
  static final negativo = PdfColor.fromInt(0xFFB3261E);
}

/// Gera e imprime o comprovante da venda, com custo e lucro/prejuízo, no
/// mesmo layout dos demais documentos.
class VendaPdf {
  static Future<void> imprimir(Venda venda) async {
    final repo = AppRepository.instance;
    final cliente =
        repo.clientePorId(venda.clienteId)?.nome ?? 'Cliente removido';

    var totalVenda = 0.0;
    var totalCusto = 0.0;
    final linhas = <pw.TableRow>[_cabecalhoTabela()];
    for (var indice = 0; indice < venda.itens.length; indice++) {
      final item = venda.itens[indice];
      final produto = repo.produtoPorId(item.produtoId);
      final unidade = repo.unidadePorId(item.unidadeId);
      final custoUnitario = produto == null
          ? 0.0
          : repo.custoPorUnidadeBase(produto) * unidade.fatorParaBase;
      final subtotal = item.quantidade * item.valorUnitario;
      totalVenda += subtotal;
      totalCusto += custoUnitario * item.quantidade;
      linhas.add(
        _linhaItem(item, produto?.nome, unidade.sigla, custoUnitario, indice),
      );
    }

    final doc = pw.Document(title: 'Venda - $cliente');
    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(36, 40, 36, 32),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
            italic: pw.Font.helveticaOblique(),
            boldItalic: pw.Font.helveticaBoldOblique(),
          ),
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Align(
              alignment: pw.Alignment.topCenter,
              child: pw.SizedBox(
                width: PdfPageFormat.a4.width,
                height: 10,
                child: pw.Container(color: _VendaPdfTheme.primaria),
              ),
            ),
          ),
        ),
        footer: (context) => _rodape(context, repo.empresa, cliente),
        build: (context) => [
          _cabecalhoEmpresa(repo.empresa),
          pw.SizedBox(height: 18),
          _tituloVenda(venda, cliente),
          pw.SizedBox(height: 22),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(4),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1.6),
              4: pw.FlexColumnWidth(1.6),
              5: pw.FlexColumnWidth(1.6),
            },
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: linhas,
          ),
          pw.SizedBox(height: 14),
          _totais(totalVenda, totalCusto),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'Venda - $cliente',
      onLayout: (format) => doc.save(),
    );
  }

  static pw.Widget _tituloVenda(Venda venda, String cliente) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: pw.BoxDecoration(
        color: _VendaPdfTheme.primariaSuave,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'REGISTRO DE VENDA',
            style: _estilo(
              8.5,
              negrito: true,
              cor: _VendaPdfTheme.primaria,
              espacamento: 1.4,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Venda', style: _estilo(23, negrito: true)),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _destaque('Cliente', cliente),
              _destaque('Data', _formatarData(venda.data)),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _destaque(String rotulo, String valor) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(14),
    ),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$rotulo  ',
            style: _estilo(9, cor: _VendaPdfTheme.apagado),
          ),
          pw.TextSpan(text: valor, style: _estilo(9.5, negrito: true)),
        ],
      ),
    ),
  );

  static pw.TableRow _cabecalhoTabela() => pw.TableRow(
    repeat: true,
    decoration: pw.BoxDecoration(color: _VendaPdfTheme.primaria),
    children: [
      for (final titulo in [
        'Produto',
        'Qtd.',
        'Unid.',
        'Vl. unitário',
        'Custo unit.',
        'Subtotal',
      ])
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: pw.Text(
            titulo.toUpperCase(),
            style: _estilo(
              8,
              negrito: true,
              cor: PdfColors.white,
              espacamento: 0.6,
            ),
          ),
        ),
    ],
  );

  static pw.TableRow _linhaItem(
    ItemOperacao item,
    String? nomeProduto,
    String sigla,
    double custoUnitario,
    int indice,
  ) {
    final subtotal = item.quantidade * item.valorUnitario;
    final valores = [
      nomeProduto ?? 'Produto removido',
      formatarNumero(item.quantidade),
      sigla,
      item.valorUnitario.toCurrency(),
      custoUnitario.toCurrency(),
      subtotal.toCurrency(),
    ];
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: indice.isOdd ? _VendaPdfTheme.zebra : null,
        border: pw.Border(
          bottom: pw.BorderSide(color: _VendaPdfTheme.linha, width: 0.5),
        ),
      ),
      children: [
        for (final valor in valores)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: pw.Text(valor, style: _estilo(9.5)),
          ),
      ],
    );
  }

  static pw.Widget _totais(double totalVenda, double totalCusto) {
    final lucro = totalVenda - totalCusto;
    pw.Widget linha(String rotulo, String valor, {PdfColor? cor}) => pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(rotulo, style: _estilo(9, negrito: true)),
        pw.Text(valor, style: _estilo(10, negrito: true, cor: cor)),
      ],
    );
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: pw.BoxDecoration(
        color: _VendaPdfTheme.primariaSuave,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('TOTAL DA VENDA', style: _estilo(10, negrito: true)),
              pw.Text(
                totalVenda.toCurrency(),
                style: _estilo(13, negrito: true, cor: _VendaPdfTheme.primaria),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: _VendaPdfTheme.linha, thickness: 0.8, height: 1),
          pw.SizedBox(height: 8),
          linha('TOTAL DE CUSTO', totalCusto.toCurrency()),
          pw.SizedBox(height: 4),
          linha(
            lucro >= 0 ? 'LUCRO' : 'PREJUÍZO',
            lucro.toCurrency(),
            cor: lucro >= 0 ? _VendaPdfTheme.positivo : _VendaPdfTheme.negativo,
          ),
        ],
      ),
    );
  }

  static pw.Widget _cabecalhoEmpresa(Empresa empresa) {
    final logo = _carregarLogo(empresa.logoPath);
    final contatos = [
      if (_preenchido(empresa.telefone)) 'Tel: ${empresa.telefone}',
      if (_preenchido(empresa.instagram)) 'Instagram: ${empresa.instagram}',
      if (_preenchido(empresa.facebook)) 'Facebook: ${empresa.facebook}',
    ];
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logo != null) ...[
          pw.SizedBox(
            width: 56,
            height: 56,
            child: pw.ClipRRect(
              horizontalRadius: 10,
              verticalRadius: 10,
              child: pw.Image(logo, fit: pw.BoxFit.cover),
            ),
          ),
          pw.SizedBox(width: 14),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (_preenchido(empresa.nome))
                pw.Text(empresa.nome!, style: _estilo(17, negrito: true)),
              if (contatos.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  contatos.join('   ·   '),
                  style: _estilo(9, cor: _VendaPdfTheme.apagado),
                ),
              ],
              if (_preenchido(empresa.endereco)) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  empresa.endereco!,
                  style: _estilo(9, cor: _VendaPdfTheme.apagado),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _rodape(
    pw.Context context,
    Empresa empresa,
    String cliente,
  ) {
    final geradoEm = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final origem = _preenchido(empresa.nome) ? '${empresa.nome}  ·  ' : '';
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _VendaPdfTheme.linha, width: 0.8),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              '$origem$cliente  ·  gerado em $geradoEm',
              style: _estilo(8, cor: _VendaPdfTheme.apagado),
            ),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: _estilo(8, cor: _VendaPdfTheme.apagado),
          ),
        ],
      ),
    );
  }

  static pw.MemoryImage? _carregarLogo(String? caminho) {
    if (!_preenchido(caminho)) return null;
    try {
      final arquivo = File(caminho!);
      if (!arquivo.existsSync()) return null;
      return pw.MemoryImage(arquivo.readAsBytesSync());
    } catch (_) {
      return null;
    }
  }

  static bool _preenchido(String? texto) =>
      texto != null && texto.trim().isNotEmpty;

  static pw.TextStyle _estilo(
    double tamanho, {
    bool negrito = false,
    PdfColor? cor,
    double? espacamento,
  }) => pw.TextStyle(
    fontSize: tamanho,
    fontWeight: negrito ? pw.FontWeight.bold : pw.FontWeight.normal,
    color: cor ?? _VendaPdfTheme.texto,
    letterSpacing: espacamento,
  );

  static String _formatarData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
}
