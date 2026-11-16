import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/application_staff/data/repositories/mock_application_staff_repository.dart';
import 'package:pickleball_platform/features/application_staff/domain/entities/application_staff_entities.dart';
import 'package:pickleball_platform/features/application_staff/presentation/cubit/application_staff_cubit.dart';
import 'package:pickleball_platform/features/application_staff/presentation/cubit/application_staff_state.dart';

/// Shared DI-aware & [SessionCubit]-scoped wrapper for Feature 7.1
/// Application Staff screens.
class ApplicationStaffScaffold extends StatelessWidget {
  final ApplicationStaffCubit? cubit;
  final String? userId;
  final String? staffId;
  final ApplicationStaffPermission? requiredPermission;
  final String title;
  final String subtitle;
  final List<Widget> Function(
    BuildContext context,
    ApplicationStaffLoaded state,
  )? actionsBuilder;
  final Widget Function(BuildContext context, ApplicationStaffLoaded state)
      bodyBuilder;

  const ApplicationStaffScaffold({
    super.key,
    this.cubit,
    this.userId,
    this.staffId,
    this.requiredPermission,
    required this.title,
    required this.subtitle,
    this.actionsBuilder,
    required this.bodyBuilder,
  });

  String? _resolveAuthUserId(BuildContext context) {
    try {
      final session = context.read<SessionCubit>().state;
      if (!session.isAuthenticated || session.isSuspended) return null;
      if (session.activeRole != UserRole.applicationStaff) return null;

      final sessionUserId = session.userId?.trim();
      if (sessionUserId == null || sessionUserId.isEmpty) return null;

      if (userId != null &&
          userId!.trim().isNotEmpty &&
          userId!.trim() != sessionUserId) {
        return null;
      }
      return sessionUserId;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedUserId = _resolveAuthUserId(context);
    if (resolvedUserId == null) {
      return const Scaffold(
        body: ErrorStateView(
          title: 'Application Staff Access Required',
          message:
              'Sign in with an active Application Staff role to access platform operations.',
        ),
      );
    }

    if (cubit != null) {
      return BlocProvider<ApplicationStaffCubit>.value(
        value: cubit!,
        child: _ApplicationStaffView(
          userId: resolvedUserId,
          staffId: staffId,
          requiredPermission: requiredPermission,
          title: title,
          subtitle: subtitle,
          actionsBuilder: actionsBuilder,
          bodyBuilder: bodyBuilder,
        ),
      );
    }

    return BlocProvider<ApplicationStaffCubit>(
      create: (_) {
        if (sl.isRegistered<ApplicationStaffCubit>()) {
          return sl<ApplicationStaffCubit>()
            ..load(userId: resolvedUserId, staffId: staffId);
        }
        return ApplicationStaffCubit(
          repository: MockApplicationStaffRepository(),
        )..load(userId: resolvedUserId, staffId: staffId);
      },
      child: _ApplicationStaffView(
        userId: resolvedUserId,
        staffId: staffId,
        requiredPermission: requiredPermission,
        title: title,
        subtitle: subtitle,
        actionsBuilder: actionsBuilder,
        bodyBuilder: bodyBuilder,
      ),
    );
  }
}

class _ApplicationStaffView extends StatelessWidget {
  final String userId;
  final String? staffId;
  final ApplicationStaffPermission? requiredPermission;
  final String title;
  final String subtitle;
  final List<Widget> Function(
    BuildContext context,
    ApplicationStaffLoaded state,
  )? actionsBuilder;
  final Widget Function(BuildContext context, ApplicationStaffLoaded state)
      bodyBuilder;

  const _ApplicationStaffView({
    required this.userId,
    required this.staffId,
    required this.requiredPermission,
    required this.title,
    required this.subtitle,
    required this.actionsBuilder,
    required this.bodyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<ApplicationStaffCubit, ApplicationStaffState>(
      listener: (context, state) {
        if (state is ApplicationStaffLoaded) {
          if (state.feedbackMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.feedbackMessage!)),
            );
            context.read<ApplicationStaffCubit>().clearFeedback();
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
            context.read<ApplicationStaffCubit>().clearFeedback();
          }
        }
      },
      builder: (context, state) {
        if (state is ApplicationStaffInitial ||
            state is ApplicationStaffLoading) {
          return const Scaffold(
            body: LoadingView(message: 'Loading Application Staff workspace...'),
          );
        }
        if (state is ApplicationStaffFailure) {
          return Scaffold(
            body: ErrorStateView(
              title: 'Unable to Load Staff Operations',
              message: state.message,
              onRetry: () => context
                  .read<ApplicationStaffCubit>()
                  .load(userId: userId, staffId: staffId),
            ),
          );
        }

        final loaded = state as ApplicationStaffLoaded;
        if (requiredPermission != null &&
            !loaded.profile.hasPermission(requiredPermission!)) {
          return Scaffold(
            body: ErrorStateView(
              title: 'Permission Required',
              message:
                  'Your Application Staff account does not have the "${requiredPermission!.label}" permission.',
            ),
          );
        }

        final isDesktop = ResponsiveLayout.isDesktop(context);
        final horizontalPadding = isDesktop ? AppSpacing.xl : AppSpacing.md;

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => context
                .read<ApplicationStaffCubit>()
                .load(userId: userId, staffId: staffId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppSpacing.lg,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.sm,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          if (actionsBuilder != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: actionsBuilder!(context, loaded),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      bodyBuilder(context, loaded),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
