import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';

/// Chip widget rendering an individual venue amenity with a contextual icon.
class VenueAmenityChip extends StatelessWidget {
  final String amenity;

  const VenueAmenityChip({
    super.key,
    required this.amenity,
  });

  IconData _getIconForAmenity(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('parking')) return Icons.local_parking_rounded;
    if (lower.contains('light')) return Icons.light_mode_outlined;
    if (lower.contains('rental') || lower.contains('equipment')) {
      return Icons.sports_tennis_rounded;
    }
    if (lower.contains('shop')) return Icons.storefront_rounded;
    if (lower.contains('locker') || lower.contains('changing')) {
      return Icons.lock_clock_outlined;
    }
    if (lower.contains('shower')) return Icons.shower_rounded;
    if (lower.contains('cafe') || lower.contains('food') || lower.contains('refreshment')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('water') || lower.contains('drinking')) {
      return Icons.water_drop_outlined;
    }
    if (lower.contains('coaching') || lower.contains('academy')) {
      return Icons.school_outlined;
    }
    if (lower.contains('seating') || lower.contains('bench')) {
      return Icons.chair_outlined;
    }
    if (lower.contains('washroom') || lower.contains('toilet')) {
      return Icons.wc_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _getIconForAmenity(amenity);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            amenity,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
