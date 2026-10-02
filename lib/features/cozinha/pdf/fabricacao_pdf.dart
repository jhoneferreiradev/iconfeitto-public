import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/utils/formatters.dart';
import '../../../shared/data/app_repository.dart';
import '../../../shared/models/empresa.dart';
import '../../../shared/models/item_ficha_tecnica.dart';
import '../../../shared/models/operacao.dart';

class _FabricacaoPdfTheme {
  static final primaria = PdfColor.fromInt(0xFF8B3A62);
  static final primariaSuave = PdfColor.fromInt(0xFFF7ECF1);
  static final texto = PdfColor.fromInt(0xFF2B2630);
  static final apagado = PdfColor.fromInt(0xFF7A727C);
  static final linha = PdfColor.fromInt(0xFFE8DFE4);
  static final zebra = PdfColor.fromInt(0xFFFBF8FA);
}

/// Gera e imprime o registro de fabricação com a identidade da ficha técnica.
class FabricacaoPdf {
  static Future<void> imprimir(Fabricacao fabricacao) async {
    final repo = AppRepository.instance;
    final produto = repo.produtoPorId(fabricacao.produtoId);
    final nomeProduto = produto?.nome ?? 'Produto removido';
    final unidadeProduto = produto == null
        ? null
        : repo.unidadePorId(produto.unidadeEstoqueId);
    final quantidade =
        '${formatarNumero(fabricacao.quantidade)}'
        '${unidadeProduto != null ? ' ${unidadeProduto.sigla}' : ''}';

    final doc = pw.Document(title: 'Fabricação - $nomeProduto');
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
                child: pw.Container(color: _FabricacaoPdfTheme.primaria),
              ),
            ),
          ),
        ),
        footer: (context) => _rodape(context, repo.empresa, nomeProduto),
        build: (context) => [
          _cabecalhoEmpresa(repo.empresa),
          pw.SizedBox(height: 18),
          _titulo(fabricacao, nomeProduto, quantidade),
          pw.SizedBox(height: 22),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(5),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(1.2),
            },
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              _cabecalhoTabela(),
              for (var i = 0; i < fabricacao.fichaTecnica.length; i++)
                _linhaItem(repo, fabricacao.fichaTecnica[i], i),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'Fabricação - $nomeProduto',
      onLayout: (format) => doc.save(),
    );
  }

  static pw.Widget _titulo(
    Fabricacao fabricacao,
    String produto,
    String quantidade,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: pw.BoxDecoration(
        color: _FabricacaoPdfTheme.primariaSuave,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'REGISTRO DE FABRICAÇÃO',
            style: _estilo(
              8.5,
              negrito: true,
              cor: _FabricacaoPdfTheme.primaria,
              espacamento: 1.4,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(produto, style: _estilo(23, negrito: true)),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _destaque('Quantidade fabricada', quantidade),
              _destaque('Data', _formatarData(fabricacao.data)),
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
            style: _estilo(9, cor: _FabricacaoPdfTheme.apagado),
          ),
          pw.TextSpan(text: valor, style: _estilo(9.5, negrito: true)),
        ],
      ),
    ),
  );

  static pw.TableRow _cabecalhoTabela() => pw.TableRow(
    repeat: true,
    decoration: pw.BoxDecoration(color: _FabricacaoPdfTheme.primaria),
    children: [
      for (final titulo in ['Ingrediente', 'Qtd.', 'Unid.'])
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
    ItemFichaTecnica item,
    int indice,
  ) {
    final ingrediente = repo.produtoPorId(item.produtoIngredienteId);
    final valores = [
      ingrediente?.nome ?? 'Ingrediente removido',
      formatarNumero(item.quantidade),
      repo.unidadePorId(item.unidadeId).sigla,
    ];
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: indice.isOdd ? _FabricacaoPdfTheme.zebra : null,
        border: pw.Border(
          bottom: pw.BorderSide(color: _FabricacaoPdfTheme.linha, width: 0.5),
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
                  style: _estilo(9, cor: _FabricacaoPdfTheme.apagado),
                ),
              ],
              if (_preenchido(empresa.endereco)) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  empresa.endereco!,
                  style: _estilo(9, cor: _FabricacaoPdfTheme.apagado),
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
    String produto,
  ) {
    final geradoEm = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final origem = _preenchido(empresa.nome) ? '${empresa.nome}  ·  ' : '';
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _FabricacaoPdfTheme.linha, width: 0.8),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              '$origem$produto  ·  gerado em $geradoEm',
              style: _estilo(8, cor: _FabricacaoPdfTheme.apagado),
            ),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: _estilo(8, cor: _FabricacaoPdfTheme.apagado),
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
    color: cor ?? _FabricacaoPdfTheme.texto,
    letterSpacing: espacamento,
  );

  static String _formatarData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
}
