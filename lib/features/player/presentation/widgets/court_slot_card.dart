import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_item.dart';

/// Card widget representing an individual bookable time-slot on a court.
class CourtSlotCard extends StatelessWidget {
  final CourtSlot slot;
  final bool isSelected;
  final ValueChanged<CourtSlot> onSlotTapped;

  const CourtSlotCard({
    super.key,
    required this.slot,
    required this.isSelected,
    required this.onSlotTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = slot.isAvailable;
    final isBooked = slot.isBooked;

    Color backgroundColor;
    Color borderColor;
    Color textColor;
    Color priceColor;

    if (isSelected) {
      backgroundColor = theme.colorScheme.primary;
      borderColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
      priceColor = theme.colorScheme.onPrimary;
    } else if (isAvailable) {
      backgroundColor = theme.colorScheme.surface;
      borderColor = theme.colorScheme.outlineVariant;
      textColor = theme.colorScheme.onSurface;
      priceColor = theme.colorScheme.primary;
    } else {
      // Booked or unavailable
      backgroundColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      borderColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.3);
      textColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
      priceColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4);
    }

    return Semantics(
      button: isAvailable,
      selected: isSelected,
      enabled: isAvailable,
      label: '${slot.formattedTime}, ₹${slot.price.toStringAsFixed(0)}, ${slot.status.displayName}',
      child: InkWell(
        key: Key('court_slot_${slot.id}'),
        onTap: isAvailable ? () => onSlotTapped(slot) : null,
        borderRadius: AppSpacing.borderRadiusSm,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: AppSpacing.borderRadiusSm,
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected) ...[
                    Icon(Icons.check_circle, size: 13, color: textColor),
                    const SizedBox(width: 3),
                  ] else if (isBooked) ...[
                    Icon(Icons.lock_outline, size: 12, color: textColor),
                    const SizedBox(width: 3),
                  ],
                  Flexible(
                    child: Text(
                      slot.formattedTime,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              if (isAvailable || isSelected)
                Text(
                  '₹${slot.price.toStringAsFixed(0)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: priceColor,
                  ),
                )
              else
                Text(
                  slot.status.displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
