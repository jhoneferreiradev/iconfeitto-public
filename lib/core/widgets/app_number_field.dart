import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:material_ui/material_ui.dart';

import '../utils/formatters.dart';
import 'app_input_decoration.dart';

class _PtBrNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final textoSemMilhares = newValue.text.replaceAll('.', '');
    if (!RegExp(r'^\d*(,\d*)?$').hasMatch(textoSemMilhares)) {
      return oldValue;
    }
    if (newValue.text.contains('.') && !oldValue.text.contains('.')) {
      return oldValue;
    }

    final textoFormatado = _formatar(textoSemMilhares);
    final inicio = _posicaoFormatada(
      newValue.text,
      newValue.selection.start,
      textoFormatado,
    );
    final fim = _posicaoFormatada(
      newValue.text,
      newValue.selection.end,
      textoFormatado,
    );

    return newValue.copyWith(
      text: textoFormatado,
      selection: TextSelection(baseOffset: inicio, extentOffset: fim),
    );
  }

  String _formatar(String texto) {
    final partes = texto.split(',');
    final inteiro = partes.first;
    if (inteiro.isEmpty) return texto;

    final grupos = <String>[];
    for (var fim = inteiro.length; fim > 0; fim -= 3) {
      final inicio = (fim - 3).clamp(0, fim);
      grupos.insert(0, inteiro.substring(inicio, fim));
    }
    return grupos.join('.') + (partes.length > 1 ? ',${partes[1]}' : '');
  }

  int _posicaoFormatada(
    String textoOriginal,
    int posicao,
    String textoFormatado,
  ) {
    final caracteresRelevantes = textoOriginal
        .substring(0, posicao)
        .replaceAll('.', '')
        .length;
    if (caracteresRelevantes == 0) return 0;

    var contagem = 0;
    for (var i = 0; i < textoFormatado.length; i++) {
      if (textoFormatado[i] != '.') contagem++;
      if (contagem == caracteresRelevantes) return i + 1;
    }
    return textoFormatado.length;
  }
}

/// Campo numérico padronizado: teclado numérico, máscara de dígitos/decimais,
/// validação obrigatória + numérica + valor mínimo, e conversão para double.
class AppNumberField extends StatelessWidget {
  final String name;
  final String label;
  final IconData? icon;
  final String? suffixText;
  final bool required;
  final double? min;
  final bool readOnly;
  final Function(String?)? onChanged;

  const AppNumberField({
    super.key,
    required this.name,
    required this.label,
    this.icon,
    this.suffixText,
    this.required = true,
    this.min,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: name,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_PtBrNumberInputFormatter()],
      decoration: AppInputDecoration.of(
        label,
        icon: icon,
        suffixText: suffixText,
      ),
      valueTransformer: (text) {
        if (text == null || text.isEmpty) return null;
        return text.toDouble();
      },
      validator: FormBuilderValidators.compose([
        if (required)
          FormBuilderValidators.required(errorText: 'Campo obrigatório'),
        (value) {
          if (value == null || value.isEmpty) return null;
          final numero = value.toDouble();
          if (numero == null) return 'Informe um número válido';
          if (min != null && numero < min!) return 'Valor mínimo: $min';
          return null;
        },
      ]),
      readOnly: readOnly,
      onChanged: onChanged,
    );
  }
}
