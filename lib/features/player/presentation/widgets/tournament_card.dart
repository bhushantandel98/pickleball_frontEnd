import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';

/// Card component rendering tournament discovery information, status, schedule, and fees.
class TournamentCard extends StatelessWidget {
  final TournamentItem tournament;
  final VoidCallback onTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    required this.onTap,
  });

  Widget _buildStatusChip(BuildContext context) {
    switch (tournament.status) {
      case TournamentStatus.registrationOpen:
        return const AppChip.success(label: 'Registration Open');
      case TournamentStatus.upcoming:
        return const AppChip.info(label: 'Upcoming');
      case TournamentStatus.inProgress:
        return const AppChip.error(label: 'In Progress');
      case TournamentStatus.completed:
        return const AppChip.neutral(label: 'Completed');
      case TournamentStatus.cancelled:
        return const AppChip.error(label: 'Cancelled');
    }
  }

  Widget _buildImage(BuildContext context) {
    final theme = Theme.of(context);

    if (tournament.imageUrl != null) {
      return Image.asset(
        tournament.imageUrl!,
        height: 110,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallbackImage(theme),
      );
    }
    return _buildFallbackImage(theme);
  }

  Widget _buildFallbackImage(ThemeData theme) {
    return Container(
      height: 110,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.emoji_events_outlined,
          size: 48,
          color: theme.colorScheme.primary.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image with Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMd),
                ),
                child: _buildImage(context),
              ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: _buildStatusChip(context),
              ),
              if (tournament.isRegistered)
                const Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: AppChip.info(
                    label: 'My Entry',
                    icon: Icon(Icons.how_to_reg, size: 12),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tournament Title & Organizer
                Text(
                  tournament.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Organized by ${tournament.organizerName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppSpacing.sm),

                // Date & Venue Details
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tournament.formattedDateRange,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${tournament.venueName}, ${tournament.city}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.sm),

                // Key Metrics: Entry Fee & Prize Pool
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entry From',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          tournament.formattedFeeFrom,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Prize Pool',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          tournament.prizePool,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Categories Strip
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: tournament.categories.take(3).map((cat) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cat.name,
                        style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                      ),
                    );
                  }).toList()
                    ..addAll(
                      tournament.categories.length > 3
                          ? [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+${tournament.categories.length - 3} more',
                                  style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                                ),
                              ),
                            ]
                          : [],
                    ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
