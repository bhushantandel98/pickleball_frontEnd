import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';

/// Reusable confirmation dialog for destructive or high-impact actions.
///
/// Follows FSD §3.3: displays consequences clearly and prevents accidental execution.
class AppConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const AppConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    required this.onConfirm,
    this.onCancel,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AppConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
        onCancel: () => Navigator.of(dialogContext).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSpacing.maxModalWidth),
      child: AlertDialog(
        title: Text(title, style: theme.textTheme.titleLarge),
        content: Text(message, style: theme.textTheme.bodyMedium),
        actionsPadding: const EdgeInsets.only(
          right: AppSpacing.md,
          bottom: AppSpacing.md,
          left: AppSpacing.md,
        ),
        actions: [
          AppButton.text(
            label: cancelLabel,
            onPressed: () {
              if (onCancel != null) {
                onCancel!();
              } else {
                Navigator.of(context).pop(false);
              }
            },
          ),
          isDestructive
              ? AppButton.destructive(
                  label: confirmLabel,
                  onPressed: onConfirm,
                )
              : AppButton.primary(
                  label: confirmLabel,
                  onPressed: onConfirm,
                ),
        ],
      ),
    );
  }
}
