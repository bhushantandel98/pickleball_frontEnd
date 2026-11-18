import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/application_admin/data/repositories/mock_application_admin_repository.dart';
import 'package:pickleball_platform/features/application_admin/presentation/bloc/application_admin_cubit.dart';
import 'package:pickleball_platform/features/application_admin/presentation/bloc/application_admin_state.dart';

/// Shared DI-aware & [SessionCubit]-scoped wrapper for Feature 7.2
/// Application Admin screens.
class ApplicationAdminScaffold extends StatelessWidget {
  final ApplicationAdminCubit? cubit;
  final String? adminUserId;
  final String title;
  final String subtitle;
  final List<Widget> Function(
    BuildContext context,
    ApplicationAdminLoaded state,
  )? actionsBuilder;
  final Widget Function(BuildContext context, ApplicationAdminLoaded state)
      bodyBuilder;

  const ApplicationAdminScaffold({
    super.key,
    this.cubit,
    this.adminUserId,
    required this.title,
    required this.subtitle,
    this.actionsBuilder,
    required this.bodyBuilder,
  });

  String? _resolveAdminUserId(BuildContext context) {
    try {
      final session = context.read<SessionCubit>().state;
      if (!session.isAuthenticated || session.isSuspended) return null;
      if (session.activeRole != UserRole.applicationAdmin) return null;

      final sessionUserId = session.userId?.trim();
      if (sessionUserId == null || sessionUserId.isEmpty) return null;

      if (adminUserId != null &&
          adminUserId!.trim().isNotEmpty &&
          adminUserId!.trim() != sessionUserId) {
        return null;
      }
      return sessionUserId;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolvedAdminId = _resolveAdminUserId(context);
    if (resolvedAdminId == null) {
      return const Scaffold(
        body: ErrorStateView(
          title: 'Application Admin Access Required',
          message:
              'Only the single Application Admin account can access platform governance screens.',
        ),
      );
    }

    if (cubit != null) {
      return BlocProvider<ApplicationAdminCubit>.value(
        value: cubit!,
        child: _ApplicationAdminView(
          adminUserId: resolvedAdminId,
          title: title,
          subtitle: subtitle,
          actionsBuilder: actionsBuilder,
          bodyBuilder: bodyBuilder,
        ),
      );
    }

    return BlocProvider<ApplicationAdminCubit>(
      create: (_) {
        if (sl.isRegistered<ApplicationAdminCubit>()) {
          return sl<ApplicationAdminCubit>()..load(adminUserId: resolvedAdminId);
        }
        return ApplicationAdminCubit(
          repository: MockApplicationAdminRepository(),
        )..load(adminUserId: resolvedAdminId);
      },
      child: _ApplicationAdminView(
        adminUserId: resolvedAdminId,
        title: title,
        subtitle: subtitle,
        actionsBuilder: actionsBuilder,
        bodyBuilder: bodyBuilder,
      ),
    );
  }
}

class _ApplicationAdminView extends StatelessWidget {
  final String adminUserId;
  final String title;
  final String subtitle;
  final List<Widget> Function(
    BuildContext context,
    ApplicationAdminLoaded state,
  )? actionsBuilder;
  final Widget Function(BuildContext context, ApplicationAdminLoaded state)
      bodyBuilder;

  const _ApplicationAdminView({
    required this.adminUserId,
    required this.title,
    required this.subtitle,
    required this.actionsBuilder,
    required this.bodyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<ApplicationAdminCubit, ApplicationAdminState>(
      listener: (context, state) {
        if (state is ApplicationAdminLoaded) {
          if (state.feedbackMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.feedbackMessage!)),
            );
            context.read<ApplicationAdminCubit>().clearFeedback();
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
            context.read<ApplicationAdminCubit>().clearFeedback();
          }
        }
      },
      builder: (context, state) {
        if (state is ApplicationAdminInitial ||
            state is ApplicationAdminLoading) {
          return const Scaffold(
            body: LoadingView(message: 'Loading Application Admin governance...'),
          );
        }
        if (state is ApplicationAdminFailure) {
          return Scaffold(
            body: ErrorStateView(
              title: 'Governance Access Denied',
              message: state.message,
              onRetry: () => context
                  .read<ApplicationAdminCubit>()
                  .load(adminUserId: adminUserId),
            ),
          );
        }

        final loaded = state as ApplicationAdminLoaded;
        final isDesktop = ResponsiveLayout.isDesktop(context);
        final horizontalPadding = isDesktop ? AppSpacing.xl : AppSpacing.md;

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => context
                .read<ApplicationAdminCubit>()
                .load(adminUserId: adminUserId),
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
