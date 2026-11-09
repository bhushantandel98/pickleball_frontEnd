import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/my_bookings_state.dart';

/// Segmented filter bar for switching between upcoming, past, and cancelled booking categories.
class BookingFilterTabs extends StatelessWidget {
  final BookingFilter activeFilter;
  final int upcomingCount;
  final int pastCount;
  final int cancelledCount;
  final ValueChanged<BookingFilter> onFilterSelected;

  const BookingFilterTabs({
    super.key,
    required this.activeFilter,
    required this.upcomingCount,
    required this.pastCount,
    required this.cancelledCount,
    required this.onFilterSelected,
  });

  int _countFor(BookingFilter filter) {
    switch (filter) {
      case BookingFilter.upcoming:
        return upcomingCount;
      case BookingFilter.past:
        return pastCount;
      case BookingFilter.cancelled:
        return cancelledCount;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: BookingFilter.values.map((filter) {
          final isSelected = filter == activeFilter;
          final count = _countFor(filter);

          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: Key('filter_tab_${filter.name}'),
                onTap: () => onFilterSelected(filter),
                borderRadius: AppSpacing.borderRadiusSm,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: AppSpacing.borderRadiusSm,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        filter.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.onPrimary.withValues(alpha: 0.25)
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
