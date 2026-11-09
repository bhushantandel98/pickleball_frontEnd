import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/features/notifications/domain/entities/notification_item.dart';

/// Horizontally scrollable chip row enabling instant filtering by category and unread status.
class NotificationCategoryChips extends StatelessWidget {
  final NotificationFilterCategory selectedFilter;
  final int totalCount;
  final int unreadCount;
  final ValueChanged<NotificationFilterCategory> onFilterSelected;

  const NotificationCategoryChips({
    super.key,
    required this.selectedFilter,
    required this.totalCount,
    required this.unreadCount,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: NotificationFilterCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final filter = NotificationFilterCategory.values[index];
          final isSelected = filter == selectedFilter;

          String label = filter.label;
          if (filter == NotificationFilterCategory.all && totalCount > 0) {
            label = '$label ($totalCount)';
          } else if (filter == NotificationFilterCategory.unread && unreadCount > 0) {
            label = '$label ($unreadCount)';
          }

          return FilterChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onFilterSelected(filter),
            selectedColor: theme.colorScheme.primaryContainer,
            labelStyle: theme.textTheme.labelMedium?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
            ),
            avatar: filter == NotificationFilterCategory.unread && unreadCount > 0
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
