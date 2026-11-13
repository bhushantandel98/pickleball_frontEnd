import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/academy/data/repositories/mock_academy_repository.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_cubit.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_state.dart';

/// Shared wrapper for Academy module pages providing DI-aware [AcademyCubit],
/// snackbar feedback, pull-to-refresh, and loading/error states.
class AcademyPageScaffold extends StatelessWidget {
  final AcademyCubit? cubit;
  final String academyId;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, AcademyLoaded state)?
      headerActionBuilder;
  final Widget Function(BuildContext context, AcademyLoaded state) bodyBuilder;

  const AcademyPageScaffold({
    super.key,
    this.cubit,
    this.academyId = 'acad_001',
    required this.title,
    required this.subtitle,
    this.headerActionBuilder,
    required this.bodyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<AcademyCubit>.value(
        value: cubit!,
        child: _AcademyScaffoldBody(
          academyId: academyId,
          title: title,
          subtitle: subtitle,
          headerActionBuilder: headerActionBuilder,
          bodyBuilder: bodyBuilder,
        ),
      );
    }

    try {
      final existing = context.read<AcademyCubit>();
      return BlocProvider<AcademyCubit>.value(
        value: existing,
        child: _AcademyScaffoldBody(
          academyId: academyId,
          title: title,
          subtitle: subtitle,
          headerActionBuilder: headerActionBuilder,
          bodyBuilder: bodyBuilder,
        ),
      );
    } catch (_) {
      return BlocProvider<AcademyCubit>(
        create: (_) => sl.isRegistered<AcademyCubit>()
            ? sl<AcademyCubit>()
            : AcademyCubit(repository: MockAcademyRepository()),
        child: _AcademyScaffoldBody(
          academyId: academyId,
          title: title,
          subtitle: subtitle,
          headerActionBuilder: headerActionBuilder,
          bodyBuilder: bodyBuilder,
        ),
      );
    }
  }
}

class _AcademyScaffoldBody extends StatefulWidget {
  final String academyId;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, AcademyLoaded state)?
      headerActionBuilder;
  final Widget Function(BuildContext context, AcademyLoaded state) bodyBuilder;

  const _AcademyScaffoldBody({
    required this.academyId,
    required this.title,
    required this.subtitle,
    this.headerActionBuilder,
    required this.bodyBuilder,
  });

  @override
  State<_AcademyScaffoldBody> createState() => _AcademyScaffoldBodyState();
}

class _AcademyScaffoldBodyState extends State<_AcademyScaffoldBody> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<AcademyCubit>();
    if (cubit.state is AcademyInitial) {
      cubit.loadWorkspace(academyId: widget.academyId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AcademyCubit, AcademyState>(
      listener: (context, state) {
        if (state is AcademyLoaded && state.feedbackMessage != null) {
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
          context.read<AcademyCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        switch (state) {
          case AcademyInitial():
          case AcademyLoading():
            return const Scaffold(
              body: LoadingView(message: 'Loading academy workspace...'),
            );

          case AcademyFailure(:final failure):
            return Scaffold(
              body: ErrorStateView(
                title: 'Unable to load academy workspace',
                message: failure.message,
                onRetry: () => context
                    .read<AcademyCubit>()
                    .loadWorkspace(academyId: widget.academyId),
              ),
            );

          case AcademyLoaded():
            final theme = Theme.of(context);
            final cubit = context.read<AcademyCubit>();
            return Scaffold(
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () =>
                      cubit.refreshWorkspace(academyId: widget.academyId),
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
