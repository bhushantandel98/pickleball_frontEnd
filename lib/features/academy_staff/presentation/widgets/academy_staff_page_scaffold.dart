import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/academy_staff/data/repositories/mock_academy_staff_repository.dart';
import 'package:pickleball_platform/features/academy_staff/presentation/cubit/academy_staff_cubit.dart';
import 'package:pickleball_platform/features/academy_staff/presentation/cubit/academy_staff_state.dart';

/// Shared wrapper for Academy Staff pages providing DI-aware [AcademyStaffCubit],
/// snackbar feedback, pull-to-refresh, and loading/error states.
class AcademyStaffPageScaffold extends StatelessWidget {
  final AcademyStaffCubit? cubit;
  final String academyId;
  final String staffId;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, AcademyStaffLoaded state)?
      headerActionBuilder;
  final Widget Function(BuildContext context, AcademyStaffLoaded state)
      bodyBuilder;

  const AcademyStaffPageScaffold({
    super.key,
    this.cubit,
    this.academyId = 'acad_001',
    this.staffId = 'user_acad_staff_001',
    required this.title,
    required this.subtitle,
    this.headerActionBuilder,
    required this.bodyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<AcademyStaffCubit>.value(
        value: cubit!,
        child: _AcademyStaffScaffoldBody(
          academyId: academyId,
          staffId: staffId,
          title: title,
          subtitle: subtitle,
          headerActionBuilder: headerActionBuilder,
          bodyBuilder: bodyBuilder,
        ),
      );
    }

    try {
      final existing = context.read<AcademyStaffCubit>();
      return BlocProvider<AcademyStaffCubit>.value(
        value: existing,
        child: _AcademyStaffScaffoldBody(
          academyId: academyId,
          staffId: staffId,
          title: title,
          subtitle: subtitle,
          headerActionBuilder: headerActionBuilder,
          bodyBuilder: bodyBuilder,
        ),
      );
    } catch (_) {
      return BlocProvider<AcademyStaffCubit>(
        create: (_) => sl.isRegistered<AcademyStaffCubit>()
            ? sl<AcademyStaffCubit>()
            : AcademyStaffCubit(repository: MockAcademyStaffRepository()),
        child: _AcademyStaffScaffoldBody(
          academyId: academyId,
          staffId: staffId,
          title: title,
          subtitle: subtitle,
          headerActionBuilder: headerActionBuilder,
          bodyBuilder: bodyBuilder,
        ),
      );
    }
  }
}

class _AcademyStaffScaffoldBody extends StatefulWidget {
  final String academyId;
  final String staffId;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, AcademyStaffLoaded state)?
      headerActionBuilder;
  final Widget Function(BuildContext context, AcademyStaffLoaded state)
      bodyBuilder;

  const _AcademyStaffScaffoldBody({
    required this.academyId,
    required this.staffId,
    required this.title,
    required this.subtitle,
    this.headerActionBuilder,
    required this.bodyBuilder,
  });

  @override
  State<_AcademyStaffScaffoldBody> createState() =>
      _AcademyStaffScaffoldBodyState();
}

class _AcademyStaffScaffoldBodyState extends State<_AcademyStaffScaffoldBody> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<AcademyStaffCubit>();
    if (cubit.state is AcademyStaffInitial) {
      cubit.loadWorkspace(
        academyId: widget.academyId,
        staffId: widget.staffId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AcademyStaffCubit, AcademyStaffState>(
      listener: (context, state) {
        if (state is AcademyStaffLoaded && state.feedbackMessage != null) {
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
          context.read<AcademyStaffCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        switch (state) {
          case AcademyStaffInitial():
          case AcademyStaffLoading():
            return const Scaffold(
              body: LoadingView(message: 'Loading Academy Staff workspace...'),
            );

          case AcademyStaffFailure(:final failure):
            return Scaffold(
              body: ErrorStateView(
                title: 'Unable to load Academy Staff workspace',
                message: failure.message,
                onRetry: () => context.read<AcademyStaffCubit>().loadWorkspace(
                      academyId: widget.academyId,
                      staffId: widget.staffId,
                    ),
              ),
            );

          case AcademyStaffLoaded():
            final theme = Theme.of(context);
            final cubit = context.read<AcademyStaffCubit>();
            return Scaffold(
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () => cubit.refreshWorkspace(
                    academyId: widget.academyId,
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
