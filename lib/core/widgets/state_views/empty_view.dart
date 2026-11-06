import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';

/// Reusable empty state view conforming to FSD §3.2.
///
/// Explains what is empty and provides a call-to-action button for the next permitted action.
class EmptyStateView extends StatelessWidget {
  final String title;
  final String message;
  final Widget? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    this.title = 'No Items Found',
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon ??
                Icon(
                  Icons.inbox_outlined,
                  size: AppSpacing.iconXl * 1.5,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),

                ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton.primary(
                label: actionLabel!,
                onPressed: onAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
