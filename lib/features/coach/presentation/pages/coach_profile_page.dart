import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/coach/data/repositories/mock_coach_profile_repository.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_profile.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_profile_cubit.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_profile_state.dart';
import 'package:pickleball_platform/features/coach/presentation/widgets/coach_profile_availability_section.dart';
import 'package:pickleball_platform/features/coach/presentation/widgets/coach_profile_certifications_section.dart';
import 'package:pickleball_platform/features/coach/presentation/widgets/coach_profile_personal_section.dart';
import 'package:pickleball_platform/features/coach/presentation/widgets/coach_profile_services_fees_section.dart';
import 'package:pickleball_platform/features/coach/presentation/widgets/coach_profile_specializations_section.dart';

/// Coach Profile management page (Phase 3 — Feature 3.2).
class CoachProfilePage extends StatelessWidget {
  final CoachProfileCubit? cubit;
  final String? coachId;

  const CoachProfilePage({
    super.key,
    this.cubit,
    this.coachId,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<CoachProfileCubit>.value(
        value: cubit!,
        child: _CoachProfileView(coachId: coachId),
      );
    }

    try {
      final existing = context.read<CoachProfileCubit>();
      return BlocProvider<CoachProfileCubit>.value(
        value: existing,
        child: _CoachProfileView(coachId: coachId),
      );
    } catch (_) {
      return BlocProvider<CoachProfileCubit>(
        create: (_) => sl.isRegistered<CoachProfileCubit>()
            ? sl<CoachProfileCubit>()
            : CoachProfileCubit(
                repository: MockCoachProfileRepository(),
              ),
        child: _CoachProfileView(coachId: coachId),
      );
    }
  }
}

class _CoachProfileView extends StatefulWidget {
  final String? coachId;

  const _CoachProfileView({this.coachId});

  @override
  State<_CoachProfileView> createState() => _CoachProfileViewState();
}

class _CoachProfileViewState extends State<_CoachProfileView> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<CoachProfileCubit>();
    if (cubit.state is CoachProfileInitial) {
      cubit.loadProfile(coachId: widget.coachId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CoachProfileCubit, CoachProfileState>(
      listener: (context, state) {
        if (state is CoachProfileLoaded && state.feedbackMessage != null) {
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
          context.read<CoachProfileCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        switch (state) {
          case CoachProfileInitial():
          case CoachProfileLoading():
            return const Scaffold(
              body: LoadingView(message: 'Loading coach profile...'),
            );

          case CoachProfileFailure(:final failure):
            return Scaffold(
              body: ErrorStateView(
                title: 'Failed to Load Coach Profile',
                message: failure.message,
                onRetry: () => context
                    .read<CoachProfileCubit>()
                    .loadProfile(coachId: widget.coachId),
              ),
            );

          case CoachProfileEmpty(:final message):
            return Scaffold(
              body: EmptyStateView(
                title: 'Coach Profile Unavailable',
                message: message,
              ),
            );

          case CoachProfileLoaded(:final profile):
            return Scaffold(
              body: RefreshIndicator(
                onRefresh: () => context
                    .read<CoachProfileCubit>()
                    .refreshProfile(coachId: widget.coachId),
                child: ResponsiveContainer(
                  maxWidth: AppSpacing.maxContentWidth,
                  padding: EdgeInsets.zero,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: ResponsiveLayout(
                      mobile: (_) => _buildMobileLayout(context, profile),
                      tablet: (_) => _buildWideLayout(context, profile),
                      desktop: (_) => _buildWideLayout(context, profile),
                    ),
                  ),
                ),
              ),
            );
        }
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, CoachProfile profile) {
    final cubit = context.read<CoachProfileCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CoachProfilePersonalSection(
          profile: profile,
          onAvatarChanged: cubit.updateAvatar,
          onSavePersonalDetails: cubit.updatePersonalDetails,
          onSaveExperience: cubit.updateExperience,
        ),
        const SizedBox(height: AppSpacing.md),
        CoachProfileCertificationsSection(
          certifications: profile.certifications,
          onAdd: cubit.addCertification,
          onUpdate: cubit.updateCertification,
          onRemove: cubit.removeCertification,
        ),
        const SizedBox(height: AppSpacing.md),
        CoachProfileSpecializationsSection(
          specializations: profile.specializations,
          onAdd: cubit.addSpecialization,
          onRemove: cubit.removeSpecialization,
        ),
        const SizedBox(height: AppSpacing.md),
        CoachProfileServicesFeesSection(
          profile: profile,
          onAddService: cubit.addService,
          onUpdateService: cubit.updateService,
          onRemoveService: cubit.removeService,
          onSaveFees: cubit.updateFees,
        ),
        const SizedBox(height: AppSpacing.md),
        CoachProfileAvailabilitySection(
          isAcceptingInquiries: profile.isAcceptingPersonalInquiries,
          windows: profile.availabilityWindows,
          availabilityNote: profile.availabilityNote,
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildWideLayout(BuildContext context, CoachProfile profile) {
    final cubit = context.read<CoachProfileCubit>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoachProfilePersonalSection(
                profile: profile,
                onAvatarChanged: cubit.updateAvatar,
                onSavePersonalDetails: cubit.updatePersonalDetails,
                onSaveExperience: cubit.updateExperience,
              ),
              const SizedBox(height: AppSpacing.md),
              CoachProfileCertificationsSection(
                certifications: profile.certifications,
                onAdd: cubit.addCertification,
                onUpdate: cubit.updateCertification,
                onRemove: cubit.removeCertification,
              ),
              const SizedBox(height: AppSpacing.md),
              CoachProfileSpecializationsSection(
                specializations: profile.specializations,
                onAdd: cubit.addSpecialization,
                onRemove: cubit.removeSpecialization,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoachProfileServicesFeesSection(
                profile: profile,
                onAddService: cubit.addService,
                onUpdateService: cubit.updateService,
                onRemoveService: cubit.removeService,
                onSaveFees: cubit.updateFees,
              ),
              const SizedBox(height: AppSpacing.md),
              CoachProfileAvailabilitySection(
                isAcceptingInquiries: profile.isAcceptingPersonalInquiries,
                windows: profile.availabilityWindows,
                availabilityNote: profile.availabilityNote,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
