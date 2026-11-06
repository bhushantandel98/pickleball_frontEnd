import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';

/// Reusable dropdown select form field following Material 3 guidelines.
class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool enabled;
  final Widget? prefixIcon;

  const AppDropdown({
    super.key,
    this.label,
    this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      icon: const Icon(Icons.arrow_drop_down, size: AppSpacing.iconMd),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
      ),
    );
  }
}
