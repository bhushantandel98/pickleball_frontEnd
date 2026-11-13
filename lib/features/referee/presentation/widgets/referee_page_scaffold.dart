import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/referee/data/repositories/mock_referee_repository.dart';
import 'package:pickleball_platform/features/referee/presentation/bloc/referee_cubit.dart';
import 'package:pickleball_platform/features/referee/presentation/bloc/referee_state.dart';

/// Shared wrapper for Referee pages providing DI-aware [RefereeCubit],
/// strict session validation via [SessionCubit], snackbar feedback,
/// pull-to-refresh, and loading/error states.
class RefereePageScaffold extends StatelessWidget {
  final RefereeCubit? cubit;
  final String? tournamentId;
  final String? refereeId;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, RefereeLoaded state) bodyBuilder;

  const RefereePageScaffold({
    super.key,
    this.cubit,
    this.tournamentId,
    this.refereeId,
    required this.title,
    required this.subtitle,
    required this.bodyBuilder,
  });

  (String, String)? _resolveAuthContext(BuildContext context) {
    try {
      final session = context.read<SessionCubit>().state;
      if (!session.isAuthenticated ||
          session.isSuspended ||
          session.activeRole != UserRole.referee) {
        return null;
      }

      final sessionTournamentId = session.activeTournamentId?.trim();
      final sessionRefereeId = session.userId?.trim();
      if (sessionTournamentId == null ||
          sessionTournamentId.isEmpty ||
          sessionRefereeId == null ||
          sessionRefereeId.isEmpty) {
        return null;
      }

      if (tournamentId != null &&
          tournamentId!.trim().isNotEmpty &&
          tournamentId!.trim() != sessionTournamentId) {
        return null;
      }
      if (refereeId != null &&
          refereeId!.trim().isNotEmpty &&
          refereeId!.trim() != sessionRefereeId) {
        return null;
      }

      return (sessionTournamentId, sessionRefereeId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = _resolveAuthContext(context);
    if (auth == null) {
      return const Scaffold(
        body: ErrorStateView(
          title: 'Referee Access Required',
          message:
              'A valid authenticated Referee session with an assigned tournament context is required.',
        ),
      );
    }

    final (resolvedTournamentId, resolvedRefereeId) = auth;

    if (cubit != null) {
      return BlocProvider<RefereeCubit>.value(
        value: cubit!
          ..loadWorkspace(
            tournamentId: resolvedTournamentId,
            refereeId: resolvedRefereeId,
          ),
        child: _RefereeScaffoldBody(
          title: title,
          subtitle: subtitle,
          bodyBuilder: bodyBuilder,
        ),
      );
    }

    return BlocProvider<RefereeCubit>(
      create: (_) {
        final instance = sl.isRegistered<RefereeCubit>()
            ? sl<RefereeCubit>()
            : RefereeCubit(repository: MockRefereeRepository());
        instance.loadWorkspace(
          tournamentId: resolvedTournamentId,
          refereeId: resolvedRefereeId,
        );
        return instance;
      },
      child: _RefereeScaffoldBody(
        title: title,
        subtitle: subtitle,
        bodyBuilder: bodyBuilder,
      ),
    );
  }
}

class _RefereeScaffoldBody extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, RefereeLoaded state) bodyBuilder;

  const _RefereeScaffoldBody({
    required this.title,
    required this.subtitle,
    required this.bodyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: BlocConsumer<RefereeCubit, RefereeState>(
        listener: (context, state) {
          if (state is RefereeLoaded) {
            if (state.feedbackMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(state.feedbackMessage!)),
                );
              context.read<RefereeCubit>().clearFeedback();
            } else if (state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              context.read<RefereeCubit>().clearFeedback();
            }
          }
        },
        builder: (context, state) {
          if (state is RefereeInitial || state is RefereeLoading) {
            return const LoadingView(
              message: 'Loading Referee workspace...',
            );
          }
          if (state is RefereeFailure) {
            return ErrorStateView(
              title: 'Unable to Load Referee Workspace',
              message: state.message,
              onRetry: () => context.read<RefereeCubit>().refreshWorkspace(),
            );
          }
          if (state is RefereeLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<RefereeCubit>().refreshWorkspace(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ResponsiveContainer(
                  maxWidth: 1120,
                  child: bodyBuilder(context, state),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
