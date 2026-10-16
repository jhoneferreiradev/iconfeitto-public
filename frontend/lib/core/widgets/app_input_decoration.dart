import 'package:material_ui/material_ui.dart';

class AppInputDecoration {
  static InputDecoration of(
    String label, {
    IconData? icon,
    String? suffixText,
  }) {
    return InputDecoration(labelText: label);
  }
}
