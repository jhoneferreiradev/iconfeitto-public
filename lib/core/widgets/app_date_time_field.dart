import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

/// Campo de data / hora / data e hora padronizado, reaproveitando o
/// seletor nativo do flutter_form_builder com o mesmo estilo visual.
class AppDateTimeField extends StatelessWidget {
  final String name;
  final String label;
  final InputType inputType;
  final bool required;

  const AppDateTimeField({
    super.key,
    required this.name,
    required this.label,
    this.inputType = InputType.date,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    final DateFormat formato = switch (inputType) {
      InputType.date => DateFormat('dd/MM/yyyy'),
      InputType.time => DateFormat('HH:mm'),
      InputType.both => DateFormat('dd/MM/yyyy HH:mm'),
    };
    final IconData icone = switch (inputType) {
      InputType.date => Icons.calendar_today_outlined,
      InputType.time => Icons.access_time,
      InputType.both => Icons.event_outlined,
    };
    return FormBuilderDateTimePicker(
      name: name,
      inputType: inputType,
      format: formato,
      locale: const Locale('pt', 'BR'),
      decoration: InputDecoration(labelText: label, suffixIcon: Icon(icone)),
      validator: required
          ? FormBuilderValidators.required(errorText: 'Campo obrigatório')
          : null,
    );
  }
}
