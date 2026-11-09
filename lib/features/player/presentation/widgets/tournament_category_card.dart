import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';

/// Card rendering individual tournament category details, eligibility status, capacity, and fee.
class TournamentCategoryCard extends StatelessWidget {
  final TournamentCategory category;
  final bool isEligible;
  final bool isRegistered;
  final bool isSelected;
  final VoidCallback? onSelect;
  final bool isSelectable;

  const TournamentCategoryCard({
    super.key,
    required this.category,
    this.isEligible = true,
    this.isRegistered = false,
    this.isSelected = false,
    this.onSelect,
    this.isSelectable = false,
  });

  Widget _buildEligibilityChip(BuildContext context) {
    if (isRegistered) {
      return const AppChip.info(
        label: 'Registered',
        icon: Icon(Icons.check, size: 12),
      );
    }
    if (!category.isRegistrationOpen) {
      return const AppChip.neutral(label: 'Closed');
    }
    if (!isEligible) {
      return const AppChip.error(label: 'Not Eligible');
    }
    if (category.isCapacityFull) {
      return const AppChip.warning(label: 'Waitlist Open');
    }
    return const AppChip.success(label: 'Eligible');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fillRatio =
        (category.registeredCount / category.maxParticipants).clamp(0.0, 1.0);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      border: isSelected
          ? BorderSide(color: theme.colorScheme.primary, width: 2)
          : null,
      onTap: isSelectable ? onSelect : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Name & Eligibility Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSelectable)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm, top: 2),
                  child: Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.eligibilitySummary,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildEligibilityChip(context),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Capacity Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${category.registeredCount}/${category.maxParticipants} Registered',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                category.isCapacityFull
                    ? 'Division Full'
                    : '${category.spotsRemaining} spots left',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: category.isCapacityFull
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fillRatio,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                category.isCapacityFull
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Fee Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category.isDoubles ? 'Entry Fee (Team)' : 'Entry Fee (Per Player)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                category.formattedFee,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
