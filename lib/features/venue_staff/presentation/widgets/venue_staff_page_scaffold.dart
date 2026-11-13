import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/venue_staff/data/repositories/mock_venue_staff_repository.dart';
import 'package:pickleball_platform/features/venue_staff/presentation/cubit/venue_staff_cubit.dart';
import 'package:pickleball_platform/features/venue_staff/presentation/cubit/venue_staff_state.dart';

/// Shared wrapper for Venue Staff pages providing DI-aware [VenueStaffCubit],
/// authenticated session context resolution via [SessionCubit], snackbar
/// feedback, pull-to-refresh, and loading/error states.
class VenueStaffPageScaffold extends StatelessWidget {
  final VenueStaffCubit? cubit;
  final String? partnerId;
  final String? staffId;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, VenueStaffLoaded state)?
      headerActionBuilder;
  final Widget Function(BuildContext context, VenueStaffLoaded state)
      bodyBuilder;

  const VenueStaffPageScaffold({
    super.key,
    this.cubit,
    this.partnerId,
    this.staffId,
    required this.title,
    required this.subtitle,
    this.headerActionBuilder,
    required this.bodyBuilder,
  });

  (String, String) _resolveAuthContext(BuildContext context) {
    String? sessionPartnerId;
    String? sessionStaffId;
    try {
      final session = context.read<SessionCubit>().state;
      if (session.isAuthenticated) {
        sessionPartnerId = session.activeOrganizationId;
        sessionStaffId = session.userId;
      }
    } catch (_) {
      // SessionCubit may not be mounted in isolated widget tests.
    }

    return (
      partnerId ?? sessionPartnerId ?? 'org_venue_001',
      staffId ?? sessionStaffId ?? 'user_venue_staff_001',
    );
  }

  @override
  Widget build(BuildContext context) {
    final (resolvedPartnerId, resolvedStaffId) = _resolveAuthContext(context);

    if (cubit != null) {
      return BlocProvider<VenueStaffCubit>.value(
        value: cubit!,
        child: _VenueStaffScaffoldBody(
          partnerId: resolvedPartnerId,
          staffId: resolvedStaffId,
          title: title,
          subtitle: subtitle,
          headerActionBuilder: headerActionBuilder,
          bodyBuilder: bodyBuilder,
        ),
      );
    }

    try {
      final existing = context.read<VenueStaffCubit>();
      return BlocProvider<VenueStaffCubit>.value(
        value: existing,
        child: _VenueStaffScaffoldBody(
          partnerId: resolvedPartnerId,
          staffId: resolvedStaffId,
          title: title,
          subtitle: subtitle,
          headerActionBuilder: headerActionBuilder,
          bodyBuilder: bodyBuilder,
        ),
      );
    } catch (_) {
      return BlocProvider<VenueStaffCubit>(
        create: (_) => sl.isRegistered<VenueStaffCubit>()
            ? sl<VenueStaffCubit>()
            : VenueStaffCubit(repository: MockVenueStaffRepository()),
        child: _VenueStaffScaffoldBody(
          partnerId: resolvedPartnerId,
          staffId: resolvedStaffId,
          title: title,
          subtitle: subtitle,
          headerActionBuilder: headerActionBuilder,
          bodyBuilder: bodyBuilder,
        ),
      );
    }
  }
}

class _VenueStaffScaffoldBody extends StatefulWidget {
  final String partnerId;
  final String staffId;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, VenueStaffLoaded state)?
      headerActionBuilder;
  final Widget Function(BuildContext context, VenueStaffLoaded state)
      bodyBuilder;

  const _VenueStaffScaffoldBody({
    required this.partnerId,
    required this.staffId,
    required this.title,
    required this.subtitle,
    this.headerActionBuilder,
    required this.bodyBuilder,
  });

  @override
  State<_VenueStaffScaffoldBody> createState() =>
      _VenueStaffScaffoldBodyState();
}

class _VenueStaffScaffoldBodyState extends State<_VenueStaffScaffoldBody> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<VenueStaffCubit>();
    if (cubit.state is VenueStaffInitial) {
      cubit.loadWorkspace(
        partnerId: widget.partnerId,
        staffId: widget.staffId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VenueStaffCubit, VenueStaffState>(
      listener: (context, state) {
        if (state is VenueStaffLoaded && state.feedbackMessage != null) {
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
          context.read<VenueStaffCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        switch (state) {
          case VenueStaffInitial():
          case VenueStaffLoading():
            return const Scaffold(
              body: LoadingView(message: 'Loading Venue Staff workspace...'),
            );

          case VenueStaffFailure(:final failure):
            return Scaffold(
              body: ErrorStateView(
                title: 'Unable to load Venue Staff workspace',
                message: failure.message,
                onRetry: () => context.read<VenueStaffCubit>().loadWorkspace(
                      partnerId: widget.partnerId,
                      staffId: widget.staffId,
                    ),
              ),
            );

          case VenueStaffLoaded():
            final theme = Theme.of(context);
            final cubit = context.read<VenueStaffCubit>();
            return Scaffold(
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () => cubit.refreshWorkspace(
                    partnerId: widget.partnerId,
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
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.subtitle,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              if (widget.headerActionBuilder != null)
                                widget.headerActionBuilder!(context, state),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          widget.bodyBuilder(context, state),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
        }
      },
    );
  }
}
