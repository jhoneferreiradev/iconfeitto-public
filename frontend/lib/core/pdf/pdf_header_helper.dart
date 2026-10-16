import 'dart:io';

import 'package:pdf/widgets.dart' as pw;

import '../../shared/models/empresa.dart';

/// Helper class for building consistent PDF headers with company information.
class PdfHeaderHelper {
  /// Build a company header widget for PDF documents.
  /// Only shows non-null fields as per requirement.
  static pw.Widget buildCompanyHeader(
    Empresa empresa, {
    double fontSize = 10,
    double logoWidth = 60,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo
            if (empresa.logoPath != null && empresa.logoPath!.isNotEmpty)
              pw.SizedBox(
                width: logoWidth,
                height: logoWidth,
                child: pw.Image(
                  pw.MemoryImage(File(empresa.logoPath!).readAsBytesSync()),
                  fit: pw.BoxFit.cover,
                ),
              )
            else
              pw.SizedBox(width: logoWidth),

            // Company info
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (empresa.nome != null && empresa.nome!.isNotEmpty)
                    pw.Text(
                      empresa.nome!,
                      style: pw.TextStyle(
                        fontSize: fontSize + 2,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  // if (empresa.cnpjCpf != null && empresa.cnpjCpf!.isNotEmpty)
                  //   pw.Text(
                  //     'CNPJ/CPF: ${empresa.cnpjCpf}',
                  //     style: pw.TextStyle(fontSize: fontSize),
                  //   ),
                  if (empresa.telefone != null && empresa.telefone!.isNotEmpty)
                    pw.Text(
                      'Tel: ${empresa.telefone}',
                      style: pw.TextStyle(fontSize: fontSize),
                    ),
                  if (empresa.endereco != null && empresa.endereco!.isNotEmpty)
                    pw.Text(
                      'End: ${empresa.endereco}',
                      style: pw.TextStyle(fontSize: fontSize),
                    ),
                  if (empresa.instagram != null &&
                      empresa.instagram!.isNotEmpty)
                    pw.Text(
                      'Instagram: ${empresa.instagram}',
                      style: pw.TextStyle(fontSize: fontSize),
                    ),
                  if (empresa.facebook != null && empresa.facebook!.isNotEmpty)
                    pw.Text(
                      'Facebook: ${empresa.facebook}',
                      style: pw.TextStyle(fontSize: fontSize),
                    ),
                ],
              ),
            ),
          ],
        ),
        pw.Divider(),
      ],
    );
  }

  /// Build a simple header with just the company name.
  static pw.Widget buildSimpleHeader(Empresa empresa, {double fontSize = 14}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (empresa.nome != null && empresa.nome!.isNotEmpty)
          pw.Text(
            empresa.nome!,
            style: pw.TextStyle(
              fontSize: fontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        pw.SizedBox(height: 4),
        pw.Divider(),
      ],
    );
  }
}
