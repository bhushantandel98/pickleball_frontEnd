import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlayerHeaderCard(
          profile: data.profile,
          unreadNotificationsCount: data.unreadNotificationsCount,
        ),
        const SizedBox(height: AppSpacing.md),
        const PlayerQuickActions(),
        const SizedBox(height: AppSpacing.md),
        UpcomingActivitiesSection(
          activities: data.upcomingActivities,
        ),
        const SizedBox(height: AppSpacing.md),
        PlayerStatsGrid(stats: data.stats),
        const SizedBox(height: AppSpacing.md),
        RecentActivitySection(activities: data.recentActivities),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context, PlayerDashboardData data) {
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
            // Left Column: Quick Actions & Upcoming Schedule
            Expanded(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PlayerQuickActions(),
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
                  PlayerStatsGrid(stats: data.stats),
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
