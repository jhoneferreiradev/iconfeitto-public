import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Um documento PDF que sabe se gerar. A tela de prévia usa [gerar] para
/// exibir, imprimir, salvar e compartilhar sem precisar gerar um arquivo antes.
class PdfRelatorio {
  /// Nome usado no título da prévia e no arquivo salvo/compartilhado.
  final String titulo;
  final Future<Uint8List> Function(PdfPageFormat formato) gerar;

  const PdfRelatorio({required this.titulo, required this.gerar});

  /// Abre a prévia do documento dentro do app.
  Future<void> visualizar(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => PdfPreviaScreen(this)));
}

/// Prévia de impressão: mostra o PDF na tela e oferece imprimir, salvar e
/// compartilhar.
class PdfPreviaScreen extends StatelessWidget {
  final PdfRelatorio relatorio;

  const PdfPreviaScreen(this.relatorio, {super.key});

  String get _nomeArquivo {
    final limpo = relatorio.titulo.replaceAll(RegExp(r'[\\/:*?"<>|]'), '-');
    return '$limpo.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Prévia - ${relatorio.titulo}')),
      body: PdfPreview(
        build: relatorio.gerar,
        pdfFileName: _nomeArquivo,
        initialPageFormat: PdfPageFormat.a4,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        onError: (context, error) =>
            Center(child: Text('Não foi possível gerar o PDF: $error')),
      ),
    );
  }
}
