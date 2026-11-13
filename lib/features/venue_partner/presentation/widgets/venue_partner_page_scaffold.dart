import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/venue_partner/data/repositories/mock_venue_partner_repository.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/bloc/venue_partner_cubit.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/bloc/venue_partner_state.dart';

/// Shared wrapper for Venue Partner pages providing DI-aware [VenuePartnerCubit],
/// snackbar feedback, pull-to-refresh, and loading/error states.
class VenuePartnerPageScaffold extends StatelessWidget {
  final VenuePartnerCubit? cubit;
  final String partnerId;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, VenuePartnerLoaded state)?
      headerActionBuilder;
  final Widget Function(BuildContext context, VenuePartnerLoaded state)
      bodyBuilder;

  const VenuePartnerPageScaffold({
    super.key,
    this.cubit,
    this.partnerId = 'org_venue_001',
    required this.title,
    required this.subtitle,
    this.headerActionBuilder,
    required this.bodyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<VenuePartnerCubit>.value(
        value: cubit!,
        child: _VenuePartnerScaffoldBody(
          partnerId: partnerId,
          title: title,
          subtitle: subtitle,
          headerActionBuilder: headerActionBuilder,
          bodyBuilder: bodyBuilder,
        ),
      );
    }

    try {
      final existing = context.read<VenuePartnerCubit>();
      return BlocProvider<VenuePartnerCubit>.value(
        value: existing,
        child: _VenuePartnerScaffoldBody(
          partnerId: partnerId,
          title: title,
          subtitle: subtitle,
          headerActionBuilder: headerActionBuilder,
          bodyBuilder: bodyBuilder,
        ),
      );
    } catch (_) {
      return BlocProvider<VenuePartnerCubit>(
        create: (_) => sl.isRegistered<VenuePartnerCubit>()
            ? sl<VenuePartnerCubit>()
            : VenuePartnerCubit(repository: MockVenuePartnerRepository()),
        child: _VenuePartnerScaffoldBody(
          partnerId: partnerId,
          title: title,
          subtitle: subtitle,
          headerActionBuilder: headerActionBuilder,
          bodyBuilder: bodyBuilder,
        ),
      );
    }
  }
}

class _VenuePartnerScaffoldBody extends StatefulWidget {
  final String partnerId;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, VenuePartnerLoaded state)?
      headerActionBuilder;
  final Widget Function(BuildContext context, VenuePartnerLoaded state)
      bodyBuilder;

  const _VenuePartnerScaffoldBody({
    required this.partnerId,
    required this.title,
    required this.subtitle,
    this.headerActionBuilder,
    required this.bodyBuilder,
  });

  @override
  State<_VenuePartnerScaffoldBody> createState() =>
      _VenuePartnerScaffoldBodyState();
}

class _VenuePartnerScaffoldBodyState extends State<_VenuePartnerScaffoldBody> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<VenuePartnerCubit>();
    if (cubit.state is VenuePartnerInitial) {
      cubit.loadWorkspace(partnerId: widget.partnerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VenuePartnerCubit, VenuePartnerState>(
      listener: (context, state) {
        if (state is VenuePartnerLoaded && state.feedbackMessage != null) {
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
          context.read<VenuePartnerCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        switch (state) {
          case VenuePartnerInitial():
          case VenuePartnerLoading():
            return const Scaffold(
              body: LoadingView(message: 'Loading venue partner workspace...'),
            );

          case VenuePartnerFailure(:final failure):
            return Scaffold(
              body: ErrorStateView(
                title: 'Unable to load venue partner workspace',
                message: failure.message,
                onRetry: () => context
                    .read<VenuePartnerCubit>()
                    .loadWorkspace(partnerId: widget.partnerId),
              ),
            );

          case VenuePartnerLoaded():
            final theme = Theme.of(context);
            final cubit = context.read<VenuePartnerCubit>();
            return Scaffold(
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () =>
                      cubit.refreshWorkspace(partnerId: widget.partnerId),
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
