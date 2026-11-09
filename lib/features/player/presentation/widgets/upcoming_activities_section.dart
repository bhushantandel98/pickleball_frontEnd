import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/features/player/domain/entities/player_dashboard_data.dart';

/// Section rendering the player's upcoming scheduled commitments or an empty state.
class UpcomingActivitiesSection extends StatelessWidget {
  final List<UpcomingActivity> activities;

  const UpcomingActivitiesSection({
    super.key,
    required this.activities,
  });

  IconData _iconForType(UpcomingActivityType type) {
    switch (type) {
      case UpcomingActivityType.courtBooking:
        return Icons.sports_tennis;
      case UpcomingActivityType.tournamentMatch:
        return Icons.emoji_events_outlined;
      case UpcomingActivityType.coachingSession:
        return Icons.school_outlined;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_available_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No upcoming activities scheduled',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Reserve a court, register for a tournament, or join a coaching batch to get started.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                AppButton.primary(
                  label: 'Book a Court',
                  icon: const Icon(Icons.sports_tennis),
                  onPressed: () => context.push(AppRoutes.playerVenues),
                ),
                AppButton.outline(
                  label: 'Find Tournaments',
                  icon: const Icon(Icons.emoji_events_outlined),
                  onPressed: () => context.push(AppRoutes.playerTournaments),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortedActivities = List<UpcomingActivity>.from(activities)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Upcoming Schedule',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (sortedActivities.isNotEmpty)
              TextButton(
                onPressed: () => context.push(AppRoutes.playerBookings),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('View All Bookings'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (sortedActivities.isEmpty)
          _buildEmptyState(context)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedActivities.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = sortedActivities[index];
              return AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                onTap: item.actionRoute != null
                    ? () => context.push(item.actionRoute!)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          child: Icon(
                            _iconForType(item.type),
                            size: 18,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.timeSlot,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        if (item.status == ActivityStatus.confirmed)
                          AppChip.success(label: item.statusLabel)
                        else if (item.status == ActivityStatus.scheduled)
                          AppChip.info(label: item.statusLabel)
                        else
                          AppChip.warning(label: item.statusLabel),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.courtName != null
                                ? '${item.venueOrLocation} • ${item.courtName}'
                                : item.venueOrLocation,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.opponentOrCoach != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            item.opponentOrCoach!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
