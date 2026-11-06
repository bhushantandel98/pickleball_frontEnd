import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';

/// Reusable form text input supporting text, email, phone, and secure password modes.
///
/// Features built-in obscure text toggle, validation display, and accessibility semantics.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? initialValue;
  final bool isPassword;
  final bool readOnly;
  final bool enabled;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final AutovalidateMode? autovalidateMode;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.initialValue,
    this.isPassword = false,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onEditingComplete,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.autovalidateMode,
    this.maxLines = 1,
    this.inputFormatters,
  }) : assert(
          initialValue == null || controller == null,
          'Cannot provide both a controller and an initialValue to AppTextField.',
        );

  const AppTextField.password({
    super.key,
    this.controller,
    this.label = 'Password',
    this.hint = 'Enter your password',
    this.initialValue,
    this.readOnly = false,
    this.enabled = true,
    this.textInputAction = TextInputAction.done,
    this.validator,
    this.onChanged,
    this.onEditingComplete,
    this.prefixIcon = const Icon(Icons.lock_outline),
    this.prefixText,
    this.autovalidateMode,
    this.inputFormatters,
  })  : assert(
          initialValue == null || controller == null,
          'Cannot provide both a controller and an initialValue to AppTextField.password.',
        ),
        isPassword = true,
        keyboardType = TextInputType.visiblePassword,
        maxLines = 1,
        suffixIcon = null;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    Widget? effectiveSuffixIcon = widget.suffixIcon;

    if (widget.isPassword) {
      effectiveSuffixIcon = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: AppSpacing.iconMd,
        ),
        tooltip: _obscureText ? 'Show password' : 'Hide password',
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      );
    }

    return TextFormField(
      controller: widget.controller,
      initialValue: widget.initialValue,
      obscureText: _obscureText,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      inputFormatters: widget.inputFormatters,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon,
        prefixText: widget.prefixText,
        suffixIcon: effectiveSuffixIcon,
      ),
    );
  }
}
