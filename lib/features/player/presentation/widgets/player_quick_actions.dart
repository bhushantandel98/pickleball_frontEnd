import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';

/// Item configuration model for player quick action shortcuts.
class _QuickActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  const _QuickActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}

/// Quick action hub providing direct navigation into player feature areas.
class PlayerQuickActions extends StatelessWidget {
  const PlayerQuickActions({super.key});

  static const List<_QuickActionItem> _actions = [
    _QuickActionItem(
      title: 'Book a Court',
      subtitle: 'Reserve court slots',
      icon: Icons.sports_tennis,
      route: AppRoutes.playerVenues,
    ),
    _QuickActionItem(
      title: 'Find Coaches',
      subtitle: 'Academies & batches',
      icon: Icons.school_outlined,
      route: AppRoutes.playerAcademies,
    ),
    _QuickActionItem(
      title: 'Tournaments',
      subtitle: 'Browse & enter draws',
      icon: Icons.emoji_events_outlined,
      route: AppRoutes.playerTournaments,
    ),
    _QuickActionItem(
      title: 'Match Day',
      subtitle: 'Live schedules & scores',
      icon: Icons.schedule_outlined,
      route: AppRoutes.playerMatchDay,
    ),
    _QuickActionItem(
      title: 'Shop Gear',
      subtitle: 'Paddles, balls & nets',
      icon: Icons.shopping_bag_outlined,
      route: AppRoutes.playerMarketplace,
    ),
    _QuickActionItem(
      title: 'My Bookings',
      subtitle: 'Manage reservations',
      icon: Icons.calendar_month_outlined,
      route: AppRoutes.playerBookings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Text(
            'Quick Actions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            // Determine column count based on available width
            final crossAxisCount = constraints.maxWidth > 800
                ? 6
                : constraints.maxWidth > 500
                    ? 3
                    : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _actions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                mainAxisExtent: 96,
              ),
              itemBuilder: (context, index) {
                final item = _actions[index];
                return AppCard(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  onTap: () => context.push(item.route),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(
                            item.icon,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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
