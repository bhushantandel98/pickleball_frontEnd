import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';

/// Reusable permission-denied state view conforming to FSD §3.2.
///
/// Explains insufficient access without exposing hidden record details or sensitive data.
class PermissionDeniedView extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PermissionDeniedView({
    super.key,
    this.title = 'Access Restricted',
    this.message = 'You do not have permission to view this section or perform this action.',
    this.actionLabel = 'Return to Dashboard',
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
            Icon(
              Icons.lock_person_outlined,
              size: AppSpacing.iconXl * 1.5,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),

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
              AppButton.outline(
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
