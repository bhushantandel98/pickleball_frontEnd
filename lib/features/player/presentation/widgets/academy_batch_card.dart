import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';

/// Card displaying details of an individual training batch and providing enrollment / waitlist actions.
class AcademyBatchCard extends StatelessWidget {
  final AcademyBatch batch;
  final VoidCallback onEnroll;

  const AcademyBatchCard({
    super.key,
    required this.batch,
    required this.onEnroll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Batch Name & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  batch.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (batch.canEnrollDirectly)
                AppChip.success(label: '${batch.availableSpots} spots left')
              else if (batch.canJoinWaitlist)
                AppChip.warning(label: 'Waitlist (${batch.waitlistCount})')
              else
                AppChip.error(label: 'Batch Closed'),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Schedule / Timings
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  batch.schedule,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Instructor
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'Instructor: ${batch.instructorName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Capacity Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: batch.maxCapacity > 0
                  ? (batch.enrolledCount / batch.maxCapacity).clamp(0.0, 1.0)
                  : 0.0,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: batch.isFull ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enrolled: ${batch.enrolledCount} / ${batch.maxCapacity} players',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Action Button based on enrollment / waitlist availability
          SizedBox(
            width: double.infinity,
            child: batch.canEnrollDirectly
                ? AppButton.primary(
                    label: 'Request Enrollment',
                    onPressed: onEnroll,
                    icon: const Icon(Icons.app_registration),
                  )
                : batch.canJoinWaitlist
                    ? AppButton.secondary(
                        label: 'Join Waitlist',
                        onPressed: onEnroll,
                        icon: const Icon(Icons.hourglass_top_outlined),
                      )
                    : const AppButton.secondary(
                        label: 'Batch Full (Waitlist Closed)',
                        onPressed: null,
                      ),
          ),
        ],
      ),
    );
  }
}
