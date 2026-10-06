import 'package:material_ui/material_ui.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'app_searchable_dropdown.dart';

/// FormBuilder wrapper for AppSearchableDropdown.
class FormBuilderSearchableDropdownField<T> extends FormBuilderField<T> {
  FormBuilderSearchableDropdownField({
    required super.name,
    required String label,
    required List<T> items,
    required ItemBuilder<T> itemBuilder,
    ItemComparator<T>? itemComparator,
    IconData? icon,
    super.validator,
    super.onChanged,
    super.initialValue,
    super.key,
    bool readOnly = false,
  }) : super(
         builder: (FormFieldState<T> field) {
           return AppSearchableDropdown<T>(
             label: label,
             value: field.value,
             items: items,
             readOnly: readOnly,
             itemBuilder: itemBuilder,
             itemComparator: itemComparator,
             icon: icon,
             onChanged: (newValue) {
               field.didChange(newValue);
             },
           );
         },
       );
}
