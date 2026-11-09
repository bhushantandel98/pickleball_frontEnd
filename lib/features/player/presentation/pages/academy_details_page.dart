import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/features/player/domain/repositories/coaching_academy_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_details_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_details_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/academy_batch_card.dart';

/// Detail page displaying permitted public academy branch information, programs, and available batches.
class AcademyDetailsPage extends StatefulWidget {
  final String branchId;
  final AcademyDetailsCubit? cubit;

  const AcademyDetailsPage({
    super.key,
    required this.branchId,
    this.cubit,
  });

  @override
  State<AcademyDetailsPage> createState() => _AcademyDetailsPageState();
}

class _AcademyDetailsPageState extends State<AcademyDetailsPage> {
  late final AcademyDetailsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ??
        AcademyDetailsCubit(
          sl<CoachingAcademyRepository>(),
          branchId: widget.branchId,
        );
    _cubit.loadBranchDetails();
  }

  @override
  void dispose() {
    if (widget.cubit == null) _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: const CommonAppBar(title: 'Academy Details'),
        body: BlocBuilder<AcademyDetailsCubit, AcademyDetailsState>(
          builder: (context, state) {
            if (state is AcademyDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AcademyDetailsError) {
              return Center(
                child: ErrorStateView(
                  message: state.message,
                  onRetry: () => _cubit.loadBranchDetails(),
                ),
              );
            }

            if (state is AcademyDetailsLoaded) {
              final branch = state.branch;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      branch.academyName,
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      branch.branchName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AppChip.info(label: branch.city),
                            ],
                          ),
                          const Divider(height: 24),

                          // Location & Address
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  branch.address,
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Operating Timings
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_outlined,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  branch.operatingHours,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Facilities / Meta
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: 4,
                            children: [
                              if (branch.courtCount > 0)
                                AppChip(label: '${branch.courtCount} Courts'),
                              if (branch.headCoachName.isNotEmpty)
                                AppChip(label: 'Lead: ${branch.headCoachName}'),
                              if (branch.contactPhone.isNotEmpty)
                                AppChip(label: branch.contactPhone),
                            ],
                          ),

                          if (branch.overview.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Overview',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              branch.overview,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Programs & Batches Section
                    Text(
                      'Training Programs & Batches',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Browse curriculum and submit enrollment requests for scheduled batches.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (branch.programs.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32.0),
                          child: Text(
                            'No active training programs listed for this branch currently.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      )
                    else
                      ...branch.programs.map((program) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                          child: AppCard(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        program.title,
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    AppChip.info(label: program.skillLevel),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Age Group: ${program.ageGroup}',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  program.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Divider(height: 24),
                                Text(
                                  'Available Batches (${program.batches.length})',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                ...program.batches.map((batch) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm,
                                    ),
                                    child: AcademyBatchCard(
                                      batch: batch,
                                      onEnroll: () {
                                        context.push(
                                          '/player/discovery/academies/${branch.id}/enroll/${batch.id}?programId=${program.id}',
                                        );
                                      },
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
