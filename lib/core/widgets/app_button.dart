import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';


enum AppButtonVariant {
  primary,
  secondary,
  outline,
  text,
  destructive,
}

/// Reusable atomic button supporting primary, secondary, outline, text,
/// and destructive styling with built-in loading and accessibility states.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppSpacing.buttonHeight,
  });

  const AppButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppSpacing.buttonHeight,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppSpacing.buttonHeight,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.outline({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppSpacing.buttonHeight,
  }) : variant = AppButtonVariant.outline;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppSpacing.buttonHeight,
  }) : variant = AppButtonVariant.text;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppSpacing.buttonHeight,
  }) : variant = AppButtonVariant.destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = onPressed != null && !isLoading;

    final childContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: AppSpacing.iconSm,
            height: AppSpacing.iconSm,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getLoadingColor(theme),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ] else if (icon != null) ...[
          icon!,
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(label),
      ],
    );

    Widget button;

    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          child: childContent,
        );
      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
          ),
          child: childContent,
        );
      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isEnabled ? onPressed : null,
          child: childContent,
        );
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isEnabled ? onPressed : null,
          child: childContent,
        );
      case AppButtonVariant.destructive:
        button = ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: childContent,
        );
    }

    if (width != null) {
      return SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: height,
        minWidth: AppSpacing.minTouchTarget,
      ),
      child: button,
    );
  }

  Color _getLoadingColor(ThemeData theme) {
    switch (variant) {
      case AppButtonVariant.primary:
        return theme.colorScheme.onPrimary;
      case AppButtonVariant.secondary:
        return theme.colorScheme.onSecondaryContainer;
      case AppButtonVariant.outline:
      case AppButtonVariant.text:
        return theme.colorScheme.primary;
      case AppButtonVariant.destructive:
        return theme.colorScheme.onError;
    }
  }
}
