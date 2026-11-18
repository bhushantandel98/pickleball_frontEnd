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
  final String? enrolledAcademyBranchId;

  const PlayerQuickActions({
    super.key,
    this.enrolledAcademyBranchId,
  });

  List<_QuickActionItem> _buildActions() {
    final isEnrolled = enrolledAcademyBranchId != null &&
        enrolledAcademyBranchId!.trim().isNotEmpty;

    return [
      _QuickActionItem(
        title: isEnrolled ? 'View Academy' : 'Find Academy',
        subtitle: isEnrolled ? 'Your enrolled academy' : 'Explore academies & batches',
        icon: Icons.school_outlined,
        route: isEnrolled
            ? AppRoutes.playerAcademyDetailsPath(enrolledAcademyBranchId!)
            : AppRoutes.playerAcademies,
      ),
      const _QuickActionItem(
        title: 'Personal Coaching',
        subtitle: '1-on-1 coaches & plans',
        icon: Icons.person_search_outlined,
        route: '${AppRoutes.playerAcademies}?tab=coaches',
      ),
      const _QuickActionItem(
        title: 'Tournament',
        subtitle: 'Browse & enter draws',
        icon: Icons.emoji_events_outlined,
        route: AppRoutes.playerTournaments,
      ),
      const _QuickActionItem(
        title: 'Shop Gear',
        subtitle: 'Paddles, balls & nets',
        icon: Icons.shopping_bag_outlined,
        route: AppRoutes.playerMarketplace,
      ),
      const _QuickActionItem(
        title: 'Community',
        subtitle: 'Feed & game polls',
        icon: Icons.groups_outlined,
        route: AppRoutes.playerCommunity,
      ),
      const _QuickActionItem(
        title: 'Book a Court',
        subtitle: 'Reserve court slots',
        icon: Icons.sports_tennis,
        route: AppRoutes.playerVenues,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actions = _buildActions();

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
            final crossAxisCount = constraints.maxWidth > 800
                ? 6
                : constraints.maxWidth > 500
                    ? 3
                    : 2;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: actions.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                mainAxisExtent: 96,
              ),
              itemBuilder: (context, index) {
                final item = actions[index];
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
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
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
