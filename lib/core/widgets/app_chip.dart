import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';

enum AppChipType {
  neutral,
  success,
  warning,
  error,
  info,
}

/// Reusable status chip and indicator tag.
class AppChip extends StatelessWidget {
  final String label;
  final AppChipType type;
  final Widget? icon;
  final VoidCallback? onTap;

  const AppChip({
    super.key,
    required this.label,
    this.type = AppChipType.neutral,
    this.icon,
    this.onTap,
  });

  const AppChip.neutral({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  }) : type = AppChipType.neutral;

  const AppChip.success({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  }) : type = AppChipType.success;

  const AppChip.warning({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  }) : type = AppChipType.warning;

  const AppChip.error({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  }) : type = AppChipType.error;

  const AppChip.info({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
  }) : type = AppChipType.info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (backgroundColor, textColor) = resolveColors(theme, type);

    return Material(
      color: backgroundColor,
      borderRadius: AppSpacing.borderRadiusSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxxs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    size: AppSpacing.iconXs,
                    color: textColor,
                  ),
                  child: icon!,
                ),
                const SizedBox(width: AppSpacing.xxs),
              ],
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Resolves the background and text color pair for a chip type under the given theme.
  static (Color backgroundColor, Color textColor) resolveColors(
    ThemeData theme,
    AppChipType type,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    switch (type) {
      case AppChipType.neutral:
        return (
          isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
          isDark ? AppColors.onSurfaceDark : AppColors.onSurfaceLight,
        );
      case AppChipType.success:
        return (
          isDark ? AppColors.surfaceVariantDark : AppColors.successContainer,
          isDark ? AppColors.successDark : AppColors.onSuccessContainer,
        );
      case AppChipType.warning:
        return (
          isDark ? AppColors.surfaceVariantDark : AppColors.warningContainer,
          isDark ? AppColors.warningDark : AppColors.onWarningContainer,
        );
      case AppChipType.error:
        return (
          isDark ? AppColors.surfaceVariantDark : AppColors.errorContainer,
          isDark ? AppColors.errorDark : AppColors.onErrorContainer,
        );
      case AppChipType.info:
        return (
          isDark ? AppColors.surfaceVariantDark : AppColors.infoContainer,
          isDark ? AppColors.infoDark : AppColors.onInfoContainer,
        );
    }
  }
}
