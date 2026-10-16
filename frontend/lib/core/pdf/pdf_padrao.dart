import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../shared/models/empresa.dart';

/// Cores do padrão de impressão do app.
class PdfCores {
  static final primaria = PdfColor.fromInt(0xFF8B3A62);
  static final primariaSuave = PdfColor.fromInt(0xFFF7ECF1);
  static final texto = PdfColor.fromInt(0xFF2B2630);
  static final apagado = PdfColor.fromInt(0xFF7A727C);
  static final linha = PdfColor.fromInt(0xFFE8DFE4);
  static final zebra = PdfColor.fromInt(0xFFFBF8FA);
  static final positivo = PdfColor.fromInt(0xFF2E7D4F);
  static final negativo = PdfColor.fromInt(0xFFB3261E);
}

/// Linha de detalhe de uma caixa de totais.
class PdfDetalheTotal {
  final String rotulo;
  final String valor;
  final PdfColor? cor;

  const PdfDetalheTotal(this.rotulo, this.valor, {this.cor});
}

/// Componentes e estrutura comuns a todos os PDFs do app: faixa de cor no
/// topo, cabeçalho da empresa, bloco de título, tabelas, totais e rodapé.
///
/// Cada documento só monta o seu conteúdo; o padrão visual fica aqui.
class PdfPadrao {
  PdfPadrao._();

  static const _margem = pw.EdgeInsets.fromLTRB(36, 40, 36, 32);

  // ---------------------------------------------------------------------------
  // Documento
  // ---------------------------------------------------------------------------

  /// Monta o documento no padrão do app. O cabeçalho da empresa e o título
  /// são adicionados automaticamente antes de [conteudo].
  ///
  /// [referencia] aparece no rodapé (ex.: nome do cliente ou do produto).
  static Future<Uint8List> gerar({
    required Empresa empresa,
    required String tituloDocumento,
    required String referencia,
    required pw.Widget titulo,
    required List<pw.Widget> Function(pw.Context context) conteudo,
  }) {
    final documento = pw.Document(title: tituloDocumento);
    documento.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: _margem,
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
                child: pw.Container(color: PdfCores.primaria),
              ),
            ),
          ),
        ),
        footer: (context) => rodape(context, empresa, referencia),
        build: (context) => [
          cabecalhoEmpresa(empresa),
          pw.SizedBox(height: 18),
          titulo,
          pw.SizedBox(height: 22),
          ...conteudo(context),
        ],
      ),
    );
    return documento.save();
  }

  // ---------------------------------------------------------------------------
  // Texto e utilidades
  // ---------------------------------------------------------------------------

  static pw.TextStyle estilo(
    double tamanho, {
    bool negrito = false,
    PdfColor? cor,
    double? espacamento,
  }) => pw.TextStyle(
    fontSize: tamanho,
    fontWeight: negrito ? pw.FontWeight.bold : pw.FontWeight.normal,
    color: cor ?? PdfCores.texto,
    letterSpacing: espacamento,
  );

  static pw.Widget espaco(double altura) => pw.SizedBox(height: altura);

  static bool preenchido(String? texto) =>
      texto != null && texto.trim().isNotEmpty;

  static pw.MemoryImage? carregarLogo(String? caminho) {
    if (!preenchido(caminho)) return null;
    try {
      final arquivo = File(caminho!);
      if (!arquivo.existsSync()) return null;
      return pw.MemoryImage(arquivo.readAsBytesSync());
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Cabeçalho, título e rodapé
  // ---------------------------------------------------------------------------

  static pw.Widget cabecalhoEmpresa(Empresa empresa) {
    final logo = carregarLogo(empresa.logoPath);
    final contatos = [
      if (preenchido(empresa.telefone)) 'Tel: ${empresa.telefone}',
      if (preenchido(empresa.instagram)) 'Instagram: ${empresa.instagram}',
      if (preenchido(empresa.facebook)) 'Facebook: ${empresa.facebook}',
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
              if (preenchido(empresa.nome))
                pw.Text(empresa.nome!, style: estilo(17, negrito: true)),
              if (contatos.isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  contatos.join('   ·   '),
                  style: estilo(9, cor: PdfCores.apagado),
                ),
              ],
              if (preenchido(empresa.endereco)) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  empresa.endereco!,
                  style: estilo(9, cor: PdfCores.apagado),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Bloco de título: sobretítulo em caixa alta, título grande e destaques
  /// (rótulo + valor) logo abaixo.
  static pw.Widget titulo({
    required String sobretitulo,
    required String titulo,
    List<({String rotulo, String valor})> destaques = const [],
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: pw.BoxDecoration(
        color: PdfCores.primariaSuave,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            sobretitulo.toUpperCase(),
            style: estilo(
              8.5,
              negrito: true,
              cor: PdfCores.primaria,
              espacamento: 1.4,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(titulo, style: estilo(23, negrito: true)),
          if (destaques.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final destaque in destaques)
                  _destaque(destaque.rotulo, destaque.valor),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _destaque(String rotulo, String valor) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(14),
      border: pw.Border.all(color: PdfCores.linha, width: 0.8),
    ),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$rotulo  ',
            style: estilo(9, cor: PdfCores.apagado),
          ),
          pw.TextSpan(text: valor, style: estilo(9.5, negrito: true)),
        ],
      ),
    ),
  );

  static pw.Widget rodape(
    pw.Context context,
    Empresa empresa,
    String referencia,
  ) {
    final geradoEm = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    final origem = preenchido(empresa.nome) ? '${empresa.nome}  ·  ' : '';
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 14),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfCores.linha, width: 0.8)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              '$origem$referencia  ·  gerado em $geradoEm',
              style: estilo(8, cor: PdfCores.apagado),
            ),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: estilo(8, cor: PdfCores.apagado),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Seções, tabelas e totais
  // ---------------------------------------------------------------------------

  static pw.Widget secao(String titulo, {String? apoio}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6, bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            titulo.toUpperCase(),
            style: estilo(
              9,
              negrito: true,
              cor: PdfCores.primaria,
              espacamento: 1.1,
            ),
          ),
          if (preenchido(apoio)) ...[
            pw.SizedBox(width: 8),
            pw.Text(apoio!, style: estilo(8.5, cor: PdfCores.apagado)),
          ],
        ],
      ),
    );
  }

  /// Tabela no padrão do app. [larguras] são proporções (flex) por coluna;
  /// colunas em [alinhadasADireita] (índices) alinham números.
  static pw.Widget tabela({
    required List<String> colunas,
    required List<double> larguras,
    required List<List<String>> linhas,
    Set<int> alinhadasADireita = const {},
  }) {
    pw.Alignment alinhamento(int coluna) => alinhadasADireita.contains(coluna)
        ? pw.Alignment.centerRight
        : pw.Alignment.centerLeft;
    return pw.Table(
      columnWidths: {
        for (var i = 0; i < larguras.length; i++)
          i: pw.FlexColumnWidth(larguras[i]),
      },
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          repeat: true,
          decoration: pw.BoxDecoration(color: PdfCores.primaria),
          children: [
            for (var i = 0; i < colunas.length; i++)
              pw.Container(
                alignment: alinhamento(i),
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: pw.Text(
                  colunas[i].toUpperCase(),
                  style: estilo(
                    8,
                    negrito: true,
                    cor: PdfColors.white,
                    espacamento: 0.6,
                  ),
                ),
              ),
          ],
        ),
        for (var indice = 0; indice < linhas.length; indice++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: indice.isOdd ? PdfCores.zebra : null,
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfCores.linha, width: 0.5),
              ),
            ),
            children: [
              for (var i = 0; i < linhas[indice].length; i++)
                pw.Container(
                  alignment: alinhamento(i),
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: pw.Text(linhas[indice][i], style: estilo(9.5)),
                ),
            ],
          ),
      ],
    );
  }

  /// Caixa de total: linha principal em destaque e, opcionalmente, detalhes
  /// (ex.: custo e lucro) logo abaixo.
  static pw.Widget caixaTotal({
    required String rotulo,
    required String valor,
    List<PdfDetalheTotal> detalhes = const [],
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: pw.BoxDecoration(
        color: PdfCores.primariaSuave,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(rotulo.toUpperCase(), style: estilo(10, negrito: true)),
              pw.Text(
                valor,
                style: estilo(13, negrito: true, cor: PdfCores.primaria),
              ),
            ],
          ),
          if (detalhes.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Divider(color: PdfCores.linha, thickness: 0.8, height: 1),
            pw.SizedBox(height: 8),
            for (var i = 0; i < detalhes.length; i++) ...[
              if (i > 0) pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    detalhes[i].rotulo.toUpperCase(),
                    style: estilo(9, negrito: true),
                  ),
                  pw.Text(
                    detalhes[i].valor,
                    style: estilo(10, negrito: true, cor: detalhes[i].cor),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
