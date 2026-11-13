import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/coach/data/repositories/mock_coach_calendar_repository.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_calendar_cubit.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_calendar_state.dart';
import 'package:pickleball_platform/features/coach/presentation/widgets/coach_availability_management_section.dart';
import 'package:pickleball_platform/features/coach/presentation/widgets/coach_calendar_conflict_banner.dart';
import 'package:pickleball_platform/features/coach/presentation/widgets/coach_calendar_schedule_view.dart';

/// Coach Calendar & Availability page (Phase 3 — Feature 3.3).
class CoachCalendarPage extends StatelessWidget {
  final CoachCalendarCubit? cubit;
  final String? coachId;

  const CoachCalendarPage({
    super.key,
    this.cubit,
    this.coachId,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<CoachCalendarCubit>.value(
        value: cubit!,
        child: _CoachCalendarView(coachId: coachId),
      );
    }

    try {
      final existing = context.read<CoachCalendarCubit>();
      return BlocProvider<CoachCalendarCubit>.value(
        value: existing,
        child: _CoachCalendarView(coachId: coachId),
      );
    } catch (_) {
      return BlocProvider<CoachCalendarCubit>(
        create: (_) => sl.isRegistered<CoachCalendarCubit>()
            ? sl<CoachCalendarCubit>()
            : CoachCalendarCubit(
                repository: MockCoachCalendarRepository(),
              ),
        child: _CoachCalendarView(coachId: coachId),
      );
    }
  }
}

class _CoachCalendarView extends StatefulWidget {
  final String? coachId;

  const _CoachCalendarView({this.coachId});

  @override
  State<_CoachCalendarView> createState() => _CoachCalendarViewState();
}

class _CoachCalendarViewState extends State<_CoachCalendarView> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<CoachCalendarCubit>();
    if (cubit.state is CoachCalendarInitial) {
      cubit.loadCalendar(coachId: widget.coachId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CoachCalendarCubit, CoachCalendarState>(
      listener: (context, state) {
        if (state is CoachCalendarLoaded && state.feedbackMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.feedbackMessage!),
                backgroundColor: state.isErrorFeedback
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            );
          context.read<CoachCalendarCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        switch (state) {
          case CoachCalendarInitial():
          case CoachCalendarLoading():
            return const Scaffold(
              body: LoadingView(message: 'Loading coach calendar...'),
            );

          case CoachCalendarFailure(:final failure):
            return Scaffold(
              body: ErrorStateView(
                title: 'Unable to load calendar',
                message: failure.message,
                onRetry: () => context
                    .read<CoachCalendarCubit>()
                    .loadCalendar(coachId: widget.coachId),
              ),
            );

          case CoachCalendarEmpty(:final message):
            return Scaffold(
              body: EmptyStateView(
                icon: const Icon(Icons.calendar_today_outlined),
                title: 'No Calendar Data',
                message: message,
                actionLabel: 'Reload',
                onAction: () => context
                    .read<CoachCalendarCubit>()
                    .loadCalendar(coachId: widget.coachId),
              ),
            );

          case CoachCalendarLoaded():
            return _LoadedBody(
              state: state,
              coachId: widget.coachId,
            );
        }
      },
    );
  }
}

class _LoadedBody extends StatelessWidget {
  final CoachCalendarLoaded state;
  final String? coachId;

  const _LoadedBody({
    required this.state,
    required this.coachId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<CoachCalendarCubit>();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => cubit.refreshCalendar(coachId: coachId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ResponsiveContainer(
              maxWidth: 1180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Coach Calendar & Availability',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Combined personal coaching and accepted academy schedules (${state.data.acceptedAffiliations.length} accepted academies).',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (state.conflicts.isNotEmpty) ...[
                    CoachCalendarConflictBanner(conflicts: state.conflicts),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  ResponsiveLayout(
                    mobile: (_) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CoachCalendarScheduleView(
                          state: state,
                          onViewModeChanged: cubit.setViewMode,
                          onSelectDate: cubit.selectDate,
                          onStepDate: cubit.stepDate,
                          onContextFilterChanged: cubit.setContextFilter,
                          onRemoveBlockedTime: cubit.removeBlockedTime,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CoachAvailabilityManagementSection(
                          availabilityWindows: state.data.personalAvailability,
                          blockedTimes: state.data.blockedTimes,
                          selectedDate: state.selectedDate,
                          onAddAvailability: cubit.addAvailabilityWindow,
                          onToggleAvailability: cubit.toggleAvailabilityWindow,
                          onRemoveAvailability: cubit.removeAvailabilityWindow,
                          onAddBlockedTime: cubit.addBlockedTime,
                          onRemoveBlockedTime: cubit.removeBlockedTime,
                        ),
                      ],
                    ),
                    desktop: (_) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: CoachCalendarScheduleView(
                            state: state,
                            onViewModeChanged: cubit.setViewMode,
                            onSelectDate: cubit.selectDate,
                            onStepDate: cubit.stepDate,
                            onContextFilterChanged: cubit.setContextFilter,
                            onRemoveBlockedTime: cubit.removeBlockedTime,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          flex: 5,
                          child: CoachAvailabilityManagementSection(
                            availabilityWindows:
                                state.data.personalAvailability,
                            blockedTimes: state.data.blockedTimes,
                            selectedDate: state.selectedDate,
                            onAddAvailability: cubit.addAvailabilityWindow,
                            onToggleAvailability:
                                cubit.toggleAvailabilityWindow,
                            onRemoveAvailability:
                                cubit.removeAvailabilityWindow,
                            onAddBlockedTime: cubit.addBlockedTime,
                            onRemoveBlockedTime: cubit.removeBlockedTime,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
