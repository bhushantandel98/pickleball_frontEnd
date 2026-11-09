import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';

/// Reusable preference switch row displaying an icon, title, subtitle description,
/// and accessible toggle switch supporting channel-disabled states.
class PreferenceSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final bool value;
  final bool isChannelEnabled;
  final ValueChanged<bool>? onChanged;

  const PreferenceSwitchTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    required this.value,
    this.isChannelEnabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInteractive = isChannelEnabled && onChanged != null;

    final titleColor = isChannelEnabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    final subtitleColor = isChannelEnabled
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface.withValues(alpha: 0.28);

    final iconColor = isChannelEnabled
        ? (value ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant)
        : theme.colorScheme.onSurface.withValues(alpha: 0.28);

    return InkWell(
      onTap: isInteractive ? () => onChanged!(!value) : null,
      borderRadius: AppSpacing.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 2, right: AppSpacing.sm),
                child: Icon(icon, size: 20, color: iconColor),
              ),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subtitleColor,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Switch.adaptive(
              value: value,
              onChanged: isInteractive ? onChanged : null,
              activeThumbColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
