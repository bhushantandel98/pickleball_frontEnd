import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';

/// Reusable brand logo emblem for Pickleball platform auth screens.
///
/// Features the signature court-green brand styling and sports emblem.
class BrandLogoEmblem extends StatelessWidget {
  final double size;
  final bool showBadge;

  const BrandLogoEmblem({
    super.key,
    this.size = 72.0,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final containerColor = isDark
        ? AppColors.primaryContainer.withAlpha(50)
        : AppColors.primaryContainer;
    final iconColor = isDark ? AppColors.successDark : AppColors.primary;

    return Semantics(
      label: 'Pickleball Platform Logo',
      image: true,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: containerColor,
            shape: BoxShape.circle,
            boxShadow: isDark ? null : AppSpacing.shadowLow,
            border: Border.all(
              color: iconColor.withAlpha(60),
              width: 2.0,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.sports_tennis_rounded,
                size: size * 0.52,
                color: iconColor,
              ),
              if (showBadge)
                Positioned(
                  right: size * 0.15,
                  top: size * 0.15,
                  child: Container(
                    width: size * 0.22,
                    height: size * 0.22,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: size * 0.08,
                        height: size * 0.08,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
