import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/coach/data/repositories/mock_coach_dashboard_repository.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_dashboard_cubit.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_dashboard_state.dart';
import 'package:pickleball_platform/features/coach/presentation/widgets/coach_context_filter_bar.dart';
import 'package:pickleball_platform/features/coach/presentation/widgets/coach_finance_summary_section.dart';
import 'package:pickleball_platform/features/coach/presentation/widgets/coach_pending_tasks_section.dart';
import 'package:pickleball_platform/features/coach/presentation/widgets/coach_player_summary_section.dart';
import 'package:pickleball_platform/features/coach/presentation/widgets/coach_upcoming_sessions_section.dart';

/// Primary Coach Dashboard page (Phase 3 — Feature 3.1).
class CoachDashboardPage extends StatelessWidget {
  final CoachDashboardCubit? cubit;
  final String? coachId;

  const CoachDashboardPage({
    super.key,
    this.cubit,
    this.coachId,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<CoachDashboardCubit>.value(
        value: cubit!,
        child: _CoachDashboardView(coachId: coachId),
      );
    }

    try {
      final existing = context.read<CoachDashboardCubit>();
      return BlocProvider<CoachDashboardCubit>.value(
        value: existing,
        child: _CoachDashboardView(coachId: coachId),
      );
    } catch (_) {
      return BlocProvider<CoachDashboardCubit>(
        create: (_) => sl.isRegistered<CoachDashboardCubit>()
            ? sl<CoachDashboardCubit>()
            : CoachDashboardCubit(
                repository: const MockCoachDashboardRepository(),
              ),
        child: _CoachDashboardView(coachId: coachId),
      );
    }
  }
}

class _CoachDashboardView extends StatefulWidget {
  final String? coachId;

  const _CoachDashboardView({this.coachId});

  @override
  State<_CoachDashboardView> createState() => _CoachDashboardViewState();
}

class _CoachDashboardViewState extends State<_CoachDashboardView> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<CoachDashboardCubit>();
    if (cubit.state is CoachDashboardInitial) {
      cubit.loadDashboard(coachId: widget.coachId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CoachDashboardCubit, CoachDashboardState>(
      builder: (context, state) {
        switch (state) {
          case CoachDashboardInitial():
          case CoachDashboardLoading():
            return const Scaffold(
              body: LoadingView(message: 'Loading coach dashboard...'),
            );

          case CoachDashboardFailure(:final failure):
            return Scaffold(
              body: ErrorStateView(
                title: 'Failed to Load Coach Dashboard',
                message: failure.message,
                onRetry: () => context
                    .read<CoachDashboardCubit>()
                    .loadDashboard(coachId: widget.coachId),
              ),
            );

          case CoachDashboardEmpty(:final message):
            return Scaffold(
              body: EmptyStateView(
                title: 'No Coach Activity Yet',
                message: message,
              ),
            );

          case CoachDashboardLoaded():
            return Scaffold(
              body: RefreshIndicator(
                onRefresh: () => context
                    .read<CoachDashboardCubit>()
                    .refreshDashboard(coachId: widget.coachId),
                child: ResponsiveContainer(
                  maxWidth: AppSpacing.maxContentWidth,
                  padding: EdgeInsets.zero,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ResponsiveLayout(
                      mobile: (_) => _buildMobileLayout(context, state),
                      tablet: (_) => _buildWideLayout(context, state),
                      desktop: (_) => _buildWideLayout(context, state),
                    ),
                  ),
                ),
              ),
            );
        }
      },
    );
  }

  Widget _buildHeader(BuildContext context, CoachDashboardLoaded state) {
    final theme = Theme.of(context);
    final data = state.data;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.sports_tennis_rounded,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coach Dashboard',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  data.coachName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    Text(
                      data.certificationLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '• ${data.acceptedAffiliations.length} accepted ${data.acceptedAffiliations.length == 1 ? 'academy' : 'academies'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, CoachDashboardLoaded state) {
    final cubit = context.read<CoachDashboardCubit>();
    return CoachContextFilterBar(
      filter: state.filter,
      acceptedAffiliations: state.data.acceptedAffiliations,
      availableBranches: state.availableBranches,
      onContextChanged: cubit.selectContextType,
      onAcademySelected: cubit.selectAcademy,
      onBranchSelected: cubit.selectBranch,
    );
  }

  Widget _buildMobileLayout(BuildContext context, CoachDashboardLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, state),
        const SizedBox(height: AppSpacing.md),
        _buildFilterBar(context, state),
        const SizedBox(height: AppSpacing.lg),
        CoachUpcomingSessionsSection(sessions: state.filteredSessions),
        const SizedBox(height: AppSpacing.lg),
        CoachPendingTasksSection(tasks: state.filteredPendingTasks),
        const SizedBox(height: AppSpacing.lg),
        CoachPlayerSummarySection(
          showPersonalContext: state.showPersonalContext,
          showAcademyContext: state.showAcademyContext,
          personalSummary: state.data.personalPlayerSummary,
          academySummaries: state.filteredAcademyPlayerSummaries,
        ),
        const SizedBox(height: AppSpacing.lg),
        CoachFinanceSummarySection(
          showPersonalContext: state.showPersonalContext,
          showAcademyContext: state.showAcademyContext,
          personalFinance: state.data.personalFinanceSummary,
          academyFinances: state.filteredAcademyFinanceSummaries,
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context, CoachDashboardLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, state),
        const SizedBox(height: AppSpacing.md),
        _buildFilterBar(context, state),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoachUpcomingSessionsSection(
                    sessions: state.filteredSessions,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CoachPlayerSummarySection(
                    showPersonalContext: state.showPersonalContext,
                    showAcademyContext: state.showAcademyContext,
                    personalSummary: state.data.personalPlayerSummary,
                    academySummaries: state.filteredAcademyPlayerSummaries,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CoachPendingTasksSection(tasks: state.filteredPendingTasks),
                  const SizedBox(height: AppSpacing.lg),
                  CoachFinanceSummarySection(
                    showPersonalContext: state.showPersonalContext,
                    showAcademyContext: state.showAcademyContext,
                    personalFinance: state.data.personalFinanceSummary,
                    academyFinances: state.filteredAcademyFinanceSummaries,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
