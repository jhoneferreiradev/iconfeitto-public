import 'package:intl/intl.dart';

final NumberFormat _moedaFormatter = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
);
final NumberFormat _decimalFormatter = NumberFormat.decimalPatternDigits(
  locale: 'pt_BR',
  decimalDigits: 2,
);

String formatarMoeda(double valor) => _moedaFormatter.format(valor);

String formatarDecimal(double valor) => _decimalFormatter.format(valor);

extension DoubleFormatters on double {
  String toCurrency() => _moedaFormatter.format(this);

  String toDecimal() => _decimalFormatter.format(this);
}

extension StringNumberParser on String {
  double? toDouble() =>
      double.tryParse(replaceAll('.', '').replaceAll(',', '.'));

  int? toInt() => int.tryParse(this);
}

/// Formata um número sem casas decimais desnecessárias (ex.: 12.0 -> "12").
String formatarNumero(double valor) {
  if (valor == valor.roundToDouble()) return valor.toStringAsFixed(0);
  return valor.toString();
}
