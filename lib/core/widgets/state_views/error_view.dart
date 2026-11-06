import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';

/// Reusable error state view conforming to FSD §3.2.
///
/// Displays human-readable error messages and offers safe retry capability.
class ErrorStateView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final Widget? icon;

  const ErrorStateView({
    super.key,
    this.title = 'Something Went Wrong',
    required this.message,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.icon,
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
                  Icons.error_outline_rounded,
                  size: AppSpacing.iconXl * 1.5,
                  color: theme.colorScheme.error,
                ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
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
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton.outline(
                label: retryLabel,
                icon: const Icon(Icons.refresh, size: AppSpacing.iconSm),
                onPressed: onRetry!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
