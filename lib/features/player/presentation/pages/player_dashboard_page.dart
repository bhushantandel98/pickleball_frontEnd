import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/player/domain/entities/player_dashboard_data.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/player_dashboard_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/player_dashboard_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/player_header_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/player_quick_actions.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/player_stats_grid.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/recent_activity_section.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/upcoming_activities_section.dart';

/// Primary dashboard page for the Player role (Role 1), conforming to Player PRD v1.6 and FSD §5.
class PlayerDashboardPage extends StatelessWidget {
  final PlayerDashboardCubit? cubit;
  final String? userId;

  const PlayerDashboardPage({
    super.key,
    this.cubit,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<PlayerDashboardCubit>.value(
        value: cubit!,
        child: _PlayerDashboardView(userId: userId),
      );
    }

    try {
      final existing = context.read<PlayerDashboardCubit>();
      return BlocProvider<PlayerDashboardCubit>.value(
        value: existing,
        child: _PlayerDashboardView(userId: userId),
      );
    } catch (_) {
      return BlocProvider<PlayerDashboardCubit>(
        create: (_) => sl<PlayerDashboardCubit>(),
        child: _PlayerDashboardView(userId: userId),
      );
    }
  }
}

class _PlayerDashboardView extends StatefulWidget {
  final String? userId;

  const _PlayerDashboardView({this.userId});

  @override
  State<_PlayerDashboardView> createState() => _PlayerDashboardViewState();
}

class _PlayerDashboardViewState extends State<_PlayerDashboardView> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<PlayerDashboardCubit>();
    if (cubit.state is PlayerDashboardInitial) {
      cubit.loadDashboard(userId: widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerDashboardCubit, PlayerDashboardState>(
      builder: (context, state) {
        switch (state) {
          case PlayerDashboardInitial():
          case PlayerDashboardLoading():
            return const Scaffold(
              body: LoadingView(message: 'Loading player dashboard...'),
            );

          case PlayerDashboardFailure(:final failure):
            return Scaffold(
              body: ErrorStateView(
                title: 'Failed to Load Dashboard',
                message: failure.message,
                onRetry: () => context
                    .read<PlayerDashboardCubit>()
                    .loadDashboard(userId: widget.userId),
              ),
            );

          case PlayerDashboardEmpty(:final message):
            return Scaffold(
              body: EmptyStateView(
                title: 'No Player Profile Found',
                message: message,
              ),
            );

          case PlayerDashboardLoaded(:final data):
            return Scaffold(
              body: RefreshIndicator(
                onRefresh: () => context
                    .read<PlayerDashboardCubit>()
                    .refreshDashboard(userId: widget.userId),
                child: ResponsiveContainer(
                  maxWidth: AppSpacing.maxContentWidth,
                  padding: EdgeInsets.zero,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    child: ResponsiveLayout(
                      mobile: (_) => _buildMobileLayout(context, data),
                      tablet: (_) => _buildWideLayout(context, data),
                      desktop: (_) => _buildWideLayout(context, data),
                    ),
                  ),
                ),
              ),
            );
        }
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, PlayerDashboardData data) {
    final todayMatch = data.todayMatch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlayerHeaderCard(
          profile: data.profile,
          unreadNotificationsCount: data.unreadNotificationsCount,
        ),
        const SizedBox(height: AppSpacing.md),
        if (todayMatch != null) ...[
          _MatchDayHighlightCard(match: todayMatch),
          const SizedBox(height: AppSpacing.md),
        ],
        PlayerQuickActions(
          enrolledAcademyBranchId: data.enrolledAcademyBranchId,
        ),
        const SizedBox(height: AppSpacing.md),
        UpcomingActivitiesSection(
          activities: data.upcomingActivities,
        ),
        const SizedBox(height: AppSpacing.md),
        PlayerStatsGrid(
          stats: data.stats,
          showSkillRating: data.showSkillRating,
        ),
        const SizedBox(height: AppSpacing.md),
        RecentActivitySection(activities: data.recentActivities),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context, PlayerDashboardData data) {
    final todayMatch = data.todayMatch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlayerHeaderCard(
          profile: data.profile,
          unreadNotificationsCount: data.unreadNotificationsCount,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Match Day (if today), Quick Actions & Upcoming Schedule
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (todayMatch != null) ...[
                    _MatchDayHighlightCard(match: todayMatch),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  PlayerQuickActions(
                    enrolledAcademyBranchId: data.enrolledAcademyBranchId,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  UpcomingActivitiesSection(
                    activities: data.upcomingActivities,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // Right Column: Stats & Recent Activity
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PlayerStatsGrid(
                    stats: data.stats,
                    showSkillRating: data.showSkillRating,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  RecentActivitySection(
                    activities: data.recentActivities,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class _MatchDayHighlightCard extends StatelessWidget {
  final UpcomingActivity match;

  const _MatchDayHighlightCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push(match.actionRoute ?? AppRoutes.playerMatchDay),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppSpacing.borderRadiusMd,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.14),
              colorScheme.primaryContainer.withValues(alpha: 0.35),
            ],
          ),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.35),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(
                Icons.sports_score,
                color: colorScheme.onPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppChip.info(label: 'Match Day • Today'),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          match.timeSlot,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    match.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (match.opponentOrCoach != null) match.opponentOrCoach!,
                      '${match.venueOrLocation} (${match.courtName})',
                    ].join(' • '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
