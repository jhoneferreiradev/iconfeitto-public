import 'package:material_ui/material_ui.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'app_grouped_dropdown.dart';

/// FormBuilder wrapper for AppGroupedDropdown.
class FormBuilderGroupedDropdownField<T> extends FormBuilderField<T> {
  FormBuilderGroupedDropdownField({
    required super.name,
    required String label,
    required List<AppDropdownGroup<T>> groups,
    required GroupedItemBuilder<T> itemBuilder,
    GroupedItemComparator<T>? itemComparator,
    IconData? icon,
    super.validator,
    super.onChanged,
    super.initialValue,
    super.key,
  }) : super(
         builder: (FormFieldState<T> field) {
           return AppGroupedDropdown<T>(
             label: label,
             value: field.value,
             groups: groups,
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
