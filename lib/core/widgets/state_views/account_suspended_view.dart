import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';

/// Reusable suspended-account state view conforming to FSD §3.2 and §5 (Phase 1).
///
/// Blocks restricted contexts and directs suspended accounts to support channels.
class AccountSuspendedView extends StatelessWidget {
  final String title;
  final String message;
  final String? supportContact;
  final VoidCallback? onContactSupport;

  const AccountSuspendedView({
    super.key,
    this.title = 'Account Suspended',
    this.message =
        'Your account access has been suspended due to policy or administrative action.',
    this.supportContact,
    this.onContactSupport,
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
              Icons.block_flipped,
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
            if (supportContact != null && supportContact!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Text(
                  'Contact: $supportContact',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (onContactSupport != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton.primary(
                label: 'Reach Support',
                icon: const Icon(Icons.mail_outline, size: AppSpacing.iconSm),
                onPressed: onContactSupport!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
