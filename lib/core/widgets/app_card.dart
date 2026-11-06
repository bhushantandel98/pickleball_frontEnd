import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';

/// Reusable card surface with standardized Material 3 border radius,
/// padding, elevation, and optional tap callback.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderSide? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardShape = theme.cardTheme.shape;
    final fallbackSide = cardShape is RoundedRectangleBorder
        ? cardShape.side
        : BorderSide(color: theme.colorScheme.outline);

    final effectiveShape = RoundedRectangleBorder(
      borderRadius: AppSpacing.borderRadiusMd,
      side: border ?? fallbackSide,
    );

    return Card(
      color: color ?? theme.cardTheme.color,
      elevation: AppSpacing.elevationNone,
      shape: effectiveShape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMd,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
