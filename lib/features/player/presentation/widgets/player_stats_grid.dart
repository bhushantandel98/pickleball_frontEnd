import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/player/domain/entities/player_dashboard_data.dart';

/// Performance and activity statistics grid for the Player Dashboard.
class PlayerStatsGrid extends StatelessWidget {
  final PlayerStats stats;

  const PlayerStatsGrid({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final statItems = [
      _StatData(
        label: 'Skill Rating',
        value: stats.skillRating.toStringAsFixed(2),
        subtext: 'DUPR verified',
        icon: Icons.military_tech_outlined,
      ),
      _StatData(
        label: 'Matches Played',
        value: stats.matchesPlayed.toString(),
        subtext: 'Official matches',
        icon: Icons.sports_tennis_outlined,
      ),
      _StatData(
        label: 'Win Rate',
        value: '${stats.winRatePercentage.toStringAsFixed(0)}%',
        subtext: 'Match victory %',
        icon: Icons.trending_up_outlined,
      ),
      _StatData(
        label: 'Upcoming Bookings',
        value: stats.upcomingBookingsCount.toString(),
        subtext: 'Confirmed slots',
        icon: Icons.calendar_today_outlined,
      ),
      _StatData(
        label: 'Tournaments',
        value: stats.tournamentsEnteredCount.toString(),
        subtext: 'Active / Registered',
        icon: Icons.emoji_events_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Text(
            'Activity & Stats',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 700
                ? 5
                : constraints.maxWidth > 420
                    ? 3
                    : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: statItems.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                mainAxisExtent: 88,
              ),
              itemBuilder: (context, index) {
                final item = statItems[index];
                return AppCard(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const Spacer(),
                          Text(
                            item.value,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.subtext,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final String subtext;
  final IconData icon;

  const _StatData({
    required this.label,
    required this.value,
    required this.subtext,
    required this.icon,
  });
}
