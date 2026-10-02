import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/empresa.dart';
import '../../../shared/models/operacao.dart';

class _CompraPdfTheme {
  static final primaria = PdfColor.fromInt(0xFF8B3A62);
  static final primariaSuave = PdfColor.fromInt(0xFFF7ECF1);
  static final texto = PdfColor.fromInt(0xFF2B2630);
  static final apagado = PdfColor.fromInt(0xFF7A727C);
  static final linha = PdfColor.fromInt(0xFFE8DFE4);
  static final zebra = PdfColor.fromInt(0xFFFBF8FA);
}

/// Gera e imprime o comprovante da compra usando a identidade da ficha técnica.
class CompraPdf {
  static Future<void> imprimir(Compra compra) async {
    final repo = AppRepository.instance;
    final fornecedor =
        repo.fornecedorPorId(compra.fornecedorId)?.nome ??
        'Fornecedor removido';
    final linhas = <pw.TableRow>[
      _cabecalhoTabela(),
      for (var index = 0; index < compra.itens.length; index++)
        _linhaItem(repo, compra.itens[index], index),
    ];

    final doc = pw.Document(title: 'Compra - $fornecedor');
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
                child: pw.Container(color: _CompraPdfTheme.primaria),
              ),
            ),
          ),
        ),
        footer: (context) => _rodape(context, repo.empresa, fornecedor),
        build: (context) => [
          _cabecalhoEmpresa(repo.empresa),
          pw.SizedBox(height: 18),
          _tituloCompra(compra, fornecedor),
          pw.SizedBox(height: 22),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(4),
              1: pw.FlexColumnWidth(1.2),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1.6),
              4: pw.FlexColumnWidth(1.6),
            },
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: linhas,
          ),
          pw.SizedBox(height: 14),
          _totalCompra(compra.total),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'Compra - $fornecedor',
      onLayout: (format) => doc.save(),
    );
  }

  static pw.Widget _tituloCompra(Compra compra, String fornecedor) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: pw.BoxDecoration(
        color: _CompraPdfTheme.primariaSuave,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'REGISTRO DE COMPRA',
            style: _estilo(
              8.5,
              negrito: true,
              cor: _CompraPdfTheme.primaria,
              espacamento: 1.4,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Compra', style: _estilo(23, negrito: true)),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _destaque('Fornecedor', fornecedor),
              _destaque('Data', _formatarData(compra.data)),
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
            style: _estilo(9, cor: _CompraPdfTheme.apagado),
          ),
          pw.TextSpan(text: valor, style: _estilo(9.5, negrito: true)),
        ],
      ),
    ),
  );

  static pw.TableRow _cabecalhoTabela() => pw.TableRow(
    repeat: true,
    decoration: pw.BoxDecoration(color: _CompraPdfTheme.primaria),
    children: [
      for (final titulo in [
        'Produto',
        'Qtd.',
        'Unid.',
        'Vl. unitário',
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
    AppRepository repo,
    ItemOperacao item,
    int indice,
  ) {
    final produto = repo.produtoPorId(item.produtoId);
    final unidade = repo.unidadePorId(item.unidadeId);
    final subtotal = item.quantidade * item.valorUnitario;
    final valores = [
      produto?.nome ?? 'Produto removido',
      formatarNumero(item.quantidade),
      unidade.sigla,
      item.valorUnitario.toCurrency(),
      subtotal.toCurrency(),
    ];
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: indice.isOdd ? _CompraPdfTheme.zebra : null,
        border: pw.Border(
          bottom: pw.BorderSide(color: _CompraPdfTheme.linha, width: 0.5),
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

  static pw.Widget _totalCompra(double total) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: pw.BoxDecoration(
      color: _CompraPdfTheme.primariaSuave,
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('TOTAL DA COMPRA', style: _estilo(10, negrito: true)),
        pw.Text(
          total.toCurrency(),
          style: _estilo(13, negrito: true, cor: _CompraPdfTheme.primaria),
        ),
      ],
    ),
  );

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
                  style: _estilo(9, cor: _CompraPdfTheme.apagado),
                ),
              ],
              if (_preenchido(empresa.endereco)) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  empresa.endereco!,
                  style: _estilo(9, cor: _CompraPdfTheme.apagado),
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
    String fornecedor,
  ) {
    final geradoEm = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final origem = _preenchido(empresa.nome) ? '${empresa.nome}  ·  ' : '';
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _CompraPdfTheme.linha, width: 0.8),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              '$origem$fornecedor  ·  gerado em $geradoEm',
              style: _estilo(8, cor: _CompraPdfTheme.apagado),
            ),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: _estilo(8, cor: _CompraPdfTheme.apagado),
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
    color: cor ?? _CompraPdfTheme.texto,
    letterSpacing: espacamento,
  );

  static String _formatarData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
}
