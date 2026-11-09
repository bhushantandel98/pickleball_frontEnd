import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/player/domain/entities/match_day_data.dart';
import 'package:pickleball_platform/features/player/domain/repositories/match_day_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/match_day_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/match_day_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/court_live_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/match_score_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/tournament_bracket_view.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/tournament_standings_table.dart';

/// Central match day hub for players providing schedule, live scoring, court monitoring, standings, and brackets.
class MatchDayPage extends StatelessWidget {
  final MatchDayCubit? cubit;

  const MatchDayPage({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<MatchDayCubit>.value(
        value: cubit!..loadMatchDay(),
        child: const _MatchDayView(),
      );
    }

    return BlocProvider<MatchDayCubit>(
      create: (_) => MatchDayCubit(
        repository: sl<MatchDayRepository>(),
      )..loadMatchDay(),
      child: const _MatchDayView(),
    );
  }
}

class _MatchDayView extends StatelessWidget {
  const _MatchDayView();

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Tournament Matches Today',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                'You do not have any active tournament fixtures scheduled for today. Explore upcoming tournaments to register and compete.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              key: const Key('match_day_empty_explore_button'),
              label: 'Explore Tournaments',
              icon: const Icon(Icons.emoji_events_outlined),
              onPressed: () => context.push(AppRoutes.playerTournaments),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentHeader(BuildContext context, PlayerMatchDayData data) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(data.date);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Icon(
                  Icons.emoji_events,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.tournamentName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            data.tournamentVenue,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              AppChip.info(label: '${data.myMatches.length} Matches Today'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, MatchDayLoaded state) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: MatchDayTab.values.map((tab) {
          final isSelected = tab == state.activeTab;

          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                key: Key('match_day_tab_${tab.name}'),
                onTap: () => context.read<MatchDayCubit>().setTab(tab),
                borderRadius: AppSpacing.borderRadiusSm,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                    borderRadius: AppSpacing.borderRadiusSm,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.25),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      tab.label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Match Day Hub',
        leading: IconButton(
          key: const Key('match_day_back_button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.playerDashboard);
            }
          },
        ),
      ),
      body: BlocConsumer<MatchDayCubit, MatchDayState>(
        listener: (context, state) {
          if (state is MatchDayLoaded && state.feedbackMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.feedbackMessage!),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<MatchDayCubit>().clearFeedback();
          }
        },
        builder: (context, state) {
          if (state is MatchDayLoading || state is MatchDayInitial) {
            return const LoadingView(message: 'Loading match day schedule...');
          }

          if (state is MatchDayFailure) {
            return ErrorStateView(
              title: 'Match Day Unavailable',
              message: state.message,
              onRetry: () => context.read<MatchDayCubit>().loadMatchDay(),
            );
          }

          final loadedState = state as MatchDayLoaded;
          final data = loadedState.data;

          return RefreshIndicator(
            onRefresh: () => context.read<MatchDayCubit>().loadMatchDay(isRefresh: true),
            child: ResponsiveContainer(
              maxWidth: AppSpacing.maxContentWidth,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (loadedState.isEmpty)
                      _buildEmptyState(context)
                    else ...[
                      // Tournament Info Card
                      _buildTournamentHeader(context, data),
                      const SizedBox(height: AppSpacing.md),

                      // Segmented Navigation Tabs
                      _buildTabBar(context, loadedState),
                      const SizedBox(height: AppSpacing.md),

                      // Tab View 1: My Schedule
                      if (loadedState.activeTab == MatchDayTab.mySchedule) ...[
                        Text(
                          'My Matches Today',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track court assignments, live set scores, and report for match check-in.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        if (data.myMatches.isEmpty)
                          AppCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Center(
                              child: Text(
                                'No personal matches scheduled today.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: data.myMatches.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final match = data.myMatches[index];
                              return MatchScoreCard(
                                key: Key('match_card_${match.id}'),
                                match: match,
                                isCheckingIn: loadedState.checkingInMatchId == match.id,
                                onCheckIn: () => context.read<MatchDayCubit>().checkIn(match.id),
                              );
                            },
                          ),
                      ],

                      // Tab View 2: Live Courts
                      if (loadedState.activeTab == MatchDayTab.liveScores) ...[
                        Text(
                          'Active Courts & Live Progress',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Real-time point tracker and upcoming match queue across all tournament courts.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        if (data.courtMatches.isEmpty)
                          AppCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Center(
                              child: Text(
                                'No court score data available.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: data.courtMatches.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              return CourtLiveCard(
                                key: Key('court_card_${data.courtMatches[index].courtId}'),
                                courtMatch: data.courtMatches[index],
                              );
                            },
                          ),
                      ],

                      // Tab View 3: Bracket & Standings
                      if (loadedState.activeTab == MatchDayTab.bracketStandings) ...[
                        Text(
                          'Pool Standings & Qualifications',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track pool points, win/loss records, and elimination stage qualifiers.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        if (data.standings.isNotEmpty)
                          TournamentStandingsTable(standings: data.standings)
                        else
                          AppCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Center(
                              child: Text(
                                'No pool standings available.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Elimination Bracket',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tournament championship knockout bracket progression.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        if (data.bracket.isNotEmpty)
                          TournamentBracketView(bracket: data.bracket)
                        else
                          AppCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Center(
                              child: Text(
                                'No bracket draws released yet.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
