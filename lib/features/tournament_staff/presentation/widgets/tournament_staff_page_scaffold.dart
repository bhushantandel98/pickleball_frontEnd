import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/tournament_staff/data/repositories/mock_tournament_staff_repository.dart';
import 'package:pickleball_platform/features/tournament_staff/presentation/cubit/tournament_staff_cubit.dart';
import 'package:pickleball_platform/features/tournament_staff/presentation/cubit/tournament_staff_state.dart';

/// Shared wrapper for Tournament Staff pages providing DI-aware
/// [TournamentStaffCubit], strict session validation via [SessionCubit],
/// snackbar feedback, pull-to-refresh, and loading/error states.
class TournamentStaffPageScaffold extends StatelessWidget {
  final TournamentStaffCubit? cubit;
  final String? tournamentId;
  final String? staffId;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, TournamentStaffLoaded state)
      bodyBuilder;

  const TournamentStaffPageScaffold({
    super.key,
    this.cubit,
    this.tournamentId,
    this.staffId,
    required this.title,
    required this.subtitle,
    required this.bodyBuilder,
  });

  (String, String)? _resolveAuthContext(BuildContext context) {
    try {
      final session = context.read<SessionCubit>().state;
      if (!session.isAuthenticated ||
          session.isSuspended ||
          session.activeRole != UserRole.tournamentStaff) {
        return null;
      }

      final sessionTournamentId = session.activeTournamentId?.trim();
      final sessionStaffId = session.userId?.trim();
      if (sessionTournamentId == null ||
          sessionTournamentId.isEmpty ||
          sessionStaffId == null ||
          sessionStaffId.isEmpty) {
        return null;
      }

      if (tournamentId != null &&
          tournamentId!.trim().isNotEmpty &&
          tournamentId!.trim() != sessionTournamentId) {
        return null;
      }
      if (staffId != null &&
          staffId!.trim().isNotEmpty &&
          staffId!.trim() != sessionStaffId) {
        return null;
      }

      return (sessionTournamentId, sessionStaffId);
    } catch (_) {
      // SessionCubit is not mounted in context; deny access.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = _resolveAuthContext(context);
    if (auth == null) {
      return const Scaffold(
        body: ErrorStateView(
          title: 'Tournament Staff Access Required',
          message:
              'A valid authenticated Tournament Staff session with an assigned tournament context is required.',
        ),
      );
    }

    final (resolvedTournamentId, resolvedStaffId) = auth;

    if (cubit != null) {
      return BlocProvider<TournamentStaffCubit>.value(
        value: cubit!,
        child: _TournamentStaffScaffoldBody(
          tournamentId: resolvedTournamentId,
          staffId: resolvedStaffId,
          title: title,
          subtitle: subtitle,
          bodyBuilder: bodyBuilder,
        ),
      );
    }

    try {
      final existing = context.read<TournamentStaffCubit>();
      return BlocProvider<TournamentStaffCubit>.value(
        value: existing,
        child: _TournamentStaffScaffoldBody(
          tournamentId: resolvedTournamentId,
          staffId: resolvedStaffId,
          title: title,
          subtitle: subtitle,
          bodyBuilder: bodyBuilder,
        ),
      );
    } catch (_) {
      return BlocProvider<TournamentStaffCubit>(
        create: (_) => sl.isRegistered<TournamentStaffCubit>()
            ? sl<TournamentStaffCubit>()
            : TournamentStaffCubit(
                repository: MockTournamentStaffRepository(),
              ),
        child: _TournamentStaffScaffoldBody(
          tournamentId: resolvedTournamentId,
          staffId: resolvedStaffId,
          title: title,
          subtitle: subtitle,
          bodyBuilder: bodyBuilder,
        ),
      );
    }
  }
}

class _TournamentStaffScaffoldBody extends StatefulWidget {
  final String tournamentId;
  final String staffId;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, TournamentStaffLoaded state)
      bodyBuilder;

  const _TournamentStaffScaffoldBody({
    required this.tournamentId,
    required this.staffId,
    required this.title,
    required this.subtitle,
    required this.bodyBuilder,
  });

  @override
  State<_TournamentStaffScaffoldBody> createState() =>
      _TournamentStaffScaffoldBodyState();
}

class _TournamentStaffScaffoldBodyState
    extends State<_TournamentStaffScaffoldBody> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<TournamentStaffCubit>();
    if (cubit.state is TournamentStaffInitial) {
      cubit.loadWorkspace(
        tournamentId: widget.tournamentId,
        staffId: widget.staffId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<TournamentStaffCubit, TournamentStaffState>(
      listenWhen: (prev, curr) {
        if (curr is! TournamentStaffLoaded) return false;
        if (prev is! TournamentStaffLoaded) {
          return curr.feedbackMessage != null;
        }
        return curr.feedbackMessage != null &&
            curr.feedbackMessage != prev.feedbackMessage;
      },
      listener: (context, state) {
        if (state is TournamentStaffLoaded && state.feedbackMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.feedbackMessage!),
              backgroundColor: state.isErrorFeedback
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          );
          context.read<TournamentStaffCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        return switch (state) {
          TournamentStaffInitial() ||
          TournamentStaffLoading() =>
            const Scaffold(
              body: LoadingView(
                message: 'Loading tournament staff workspace...',
              ),
            ),
          TournamentStaffFailure(:final failure) => Scaffold(
              body: ErrorStateView(
                title: 'Unable to Load Workspace',
                message: failure.message,
                onRetry: () => context
                    .read<TournamentStaffCubit>()
                    .loadWorkspace(
                      tournamentId: widget.tournamentId,
                      staffId: widget.staffId,
                    ),
              ),
            ),
          TournamentStaffLoaded() => Scaffold(
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () => context
                      .read<TournamentStaffCubit>()
                      .refreshWorkspace(
                        tournamentId: widget.tournamentId,
                        staffId: widget.staffId,
                      ),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ResponsiveContainer(
                      maxWidth: 1180,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          widget.bodyBuilder(context, state),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        };
      },
    );
  }
}
