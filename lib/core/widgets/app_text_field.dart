import 'package:material_ui/material_ui.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'app_input_decoration.dart';

/// Campo de texto padronizado (estilo + validação "obrigatório" centralizados).
class AppTextField extends StatelessWidget {
  final String name;
  final String label;
  final IconData? icon;
  final bool required;
  final int maxLines;
  final bool readOnly;

  const AppTextField({
    super.key,
    required this.name,
    required this.label,
    this.icon,
    this.required = true,
    this.maxLines = 1,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilderTextField(
      name: name,
      maxLines: maxLines,
      decoration: AppInputDecoration.of(label, icon: icon),
      readOnly: readOnly,
      validator: required ? FormBuilderValidators.required(errorText: 'Campo obrigatório') : null,
    );
  }
}
