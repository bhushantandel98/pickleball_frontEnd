import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/tournament_organizer/data/repositories/mock_tournament_organizer_repository.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/bloc/tournament_organizer_cubit.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/bloc/tournament_organizer_state.dart';

/// Shared wrapper for Tournament Organizer pages providing DI-aware
/// [TournamentOrganizerCubit], authenticated session resolution via
/// [SessionCubit], snackbar feedback, pull-to-refresh, and loading/error views.
class TournamentOrganizerPageScaffold extends StatelessWidget {
  final TournamentOrganizerCubit? cubit;
  final String? organizerId;
  final String? initialTournamentId;
  final String title;
  final String subtitle;
  final Widget Function(
    BuildContext context,
    TournamentOrganizerLoaded state,
  ) bodyBuilder;

  const TournamentOrganizerPageScaffold({
    super.key,
    this.cubit,
    this.organizerId,
    this.initialTournamentId,
    required this.title,
    required this.subtitle,
    required this.bodyBuilder,
  });

  String? _resolveOrganizerId(BuildContext context) {
    if (organizerId != null && organizerId!.trim().isNotEmpty) {
      return organizerId!.trim();
    }
    try {
      final session = context.read<SessionCubit>().state;
      if (session.isAuthenticated &&
          !session.isSuspended &&
          session.activeRole == UserRole.tournamentOrganizer) {
        final orgId = session.activeOrganizationId;
        if (orgId != null && orgId.trim().isNotEmpty) {
          return orgId.trim();
        }
      }
    } catch (_) {
      // SessionCubit is not mounted in context.
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final resolvedOrganizerId = _resolveOrganizerId(context);
    if (resolvedOrganizerId == null) {
      return const Scaffold(
        body: ErrorStateView(
          title: 'Organizer Access Required',
          message:
              'A valid authenticated Tournament Organizer session with an assigned organization context is required.',
        ),
      );
    }

    if (cubit != null) {
      return BlocProvider<TournamentOrganizerCubit>.value(
        value: cubit!,
        child: _OrganizerScaffoldBody(
          organizerId: resolvedOrganizerId,
          initialTournamentId: initialTournamentId,
          title: title,
          subtitle: subtitle,
          bodyBuilder: bodyBuilder,
        ),
      );
    }

    try {
      final existing = context.read<TournamentOrganizerCubit>();
      return BlocProvider<TournamentOrganizerCubit>.value(
        value: existing,
        child: _OrganizerScaffoldBody(
          organizerId: resolvedOrganizerId,
          initialTournamentId: initialTournamentId,
          title: title,
          subtitle: subtitle,
          bodyBuilder: bodyBuilder,
        ),
      );
    } catch (_) {
      return BlocProvider<TournamentOrganizerCubit>(
        create: (_) => sl.isRegistered<TournamentOrganizerCubit>()
            ? sl<TournamentOrganizerCubit>()
            : TournamentOrganizerCubit(
                repository: MockTournamentOrganizerRepository(),
              ),
        child: _OrganizerScaffoldBody(
          organizerId: resolvedOrganizerId,
          initialTournamentId: initialTournamentId,
          title: title,
          subtitle: subtitle,
          bodyBuilder: bodyBuilder,
        ),
      );
    }
  }
}

class _OrganizerScaffoldBody extends StatefulWidget {
  final String organizerId;
  final String? initialTournamentId;
  final String title;
  final String subtitle;
  final Widget Function(
    BuildContext context,
    TournamentOrganizerLoaded state,
  ) bodyBuilder;

  const _OrganizerScaffoldBody({
    required this.organizerId,
    required this.initialTournamentId,
    required this.title,
    required this.subtitle,
    required this.bodyBuilder,
  });

  @override
  State<_OrganizerScaffoldBody> createState() => _OrganizerScaffoldBodyState();
}

class _OrganizerScaffoldBodyState extends State<_OrganizerScaffoldBody> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<TournamentOrganizerCubit>();
    if (cubit.state is TournamentOrganizerInitial) {
      cubit.loadWorkspace(
        organizerId: widget.organizerId,
        initialTournamentId: widget.initialTournamentId,
      );
    } else if (widget.initialTournamentId != null &&
        cubit.state is TournamentOrganizerLoaded) {
      cubit.selectTournament(widget.initialTournamentId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<TournamentOrganizerCubit, TournamentOrganizerState>(
      listenWhen: (prev, curr) {
        if (curr is! TournamentOrganizerLoaded) return false;
        if (prev is! TournamentOrganizerLoaded) {
          return curr.feedbackMessage != null;
        }
        return curr.feedbackMessage != null &&
            curr.feedbackMessage != prev.feedbackMessage;
      },
      listener: (context, state) {
        if (state is TournamentOrganizerLoaded &&
            state.feedbackMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.feedbackMessage!),
              backgroundColor: state.isErrorFeedback
                  ? theme.colorScheme.error
                  : theme.colorScheme.primary,
            ),
          );
          context.read<TournamentOrganizerCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        return switch (state) {
          TournamentOrganizerInitial() ||
          TournamentOrganizerLoading() =>
            const Scaffold(
              body: LoadingView(
                message: 'Loading tournament organizer workspace...',
              ),
            ),
          TournamentOrganizerFailure(:final failure) => Scaffold(
              body: ErrorStateView(
                title: 'Unable to Load Workspace',
                message: failure.message,
                onRetry: () => context
                    .read<TournamentOrganizerCubit>()
                    .loadWorkspace(organizerId: widget.organizerId),
              ),
            ),
          TournamentOrganizerLoaded() => Scaffold(
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () => context
                      .read<TournamentOrganizerCubit>()
                      .refreshWorkspace(organizerId: widget.organizerId),
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
