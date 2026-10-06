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
  String toPercentage() => this == 0 ? '0%' : '${toDecimal()}%';
}

extension StringNumberParser on String {
  double? toDouble() =>
      double.tryParse(replaceAll('.', '').replaceAll(',', '.'));

  int? toInt() => int.tryParse(this);
}

/// Texto no padrão pt-BR aceito pelos campos numéricos (até 8 decimais).
String formatarParaCampo(double valor) {
  final partes = valor.toStringAsFixed(8).split('.');
  final decimais = partes[1].replaceFirst(RegExp(r'0+$'), '');
  final inteiro = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return decimais.isEmpty ? inteiro : '$inteiro,$decimais';
}

/// Formata um número sem casas decimais desnecessárias (ex.: 12.0 -> "12").
String formatarNumero(double valor) {
  if (valor == valor.roundToDouble()) return valor.toStringAsFixed(0);
  return valor.toString();
}

extension DateTimeExtension on DateTime {

  DateFormat get _dateFormatter => DateFormat('dd/MM/yyyy');

  String toFormattedDate() => _dateFormatter.format(this);

}