import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_cubit.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_state.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_branch_filter_bar.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_page_scaffold.dart';

/// Shared graphical Academy Dashboard for Academy Admin & Academy Staff.
class AcademyDashboardPage extends StatelessWidget {
  final AcademyCubit? cubit;
  final String academyId;

  const AcademyDashboardPage({
    super.key,
    this.cubit,
    this.academyId = 'acad_001',
  });

  @override
  Widget build(BuildContext context) {
    return AcademyPageScaffold(
      cubit: cubit,
      academyId: academyId,
      title: 'Academy Dashboard',
      subtitle:
          'Student growth, branch distribution, batch capacity, attendance trends & fee collection.',
      headerActionBuilder: (context, state) {
        if (!state.canManageStaff) {
          return AppChip.info(label: 'Staff Scope');
        }
        return OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.academyStaffManagement),
          icon: const Icon(Icons.manage_accounts_outlined, size: 18),
          label: const Text('Staff Management'),
        );
      },
      bodyBuilder: (context, state) {
        final cubit = context.read<AcademyCubit>();
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        final totalStudents = state.scopedStudents.length;
        final activeEnrollments = state.activeStudentCount;
        final pendingEnrollments = state.pendingEnrollmentCount;
        final collected = state.collectedTuitionInr;
        final pendingFee = state.pendingTuitionInr;
        final totalExpectedFee = collected + pendingFee;
        final feeRatio = totalExpectedFee > 0
            ? (collected / totalExpectedFee).clamp(0.0, 1.0)
            : 0.0;

        final totalCapacity = state.scopedBatches
            .fold<int>(0, (sum, b) => sum + b.capacity);
        final totalBatchEnrolled = state.scopedBatches
            .fold<int>(0, (sum, b) => sum + b.enrolledCount);
        final capacityRatio = totalCapacity > 0
            ? (totalBatchEnrolled / totalCapacity).clamp(0.0, 1.0)
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Organization & Branch Filter Header
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.data.profile.academyName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${state.data.profile.primaryCity} • ${state.isAdmin ? 'Admin View' : 'Assigned Branch Staff View'}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (state.canManageStaff)
                        IconButton(
                          tooltip: 'Staff Management',
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () =>
                              context.push(AppRoutes.academyStaffManagement),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AcademyBranchFilterBar(
                    branches: state.scopedBranches,
                    selectedBranchId: state.selectedBranchId,
                    onBranchSelected: cubit.selectBranch,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 1. Concise KPI Summary Row
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 4
                    : (constraints.maxWidth >= 520 ? 2 : 1);
                final cardWidth =
                    (constraints.maxWidth - (AppSpacing.sm * (columns - 1))) /
                        columns;

                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _KpiCard(
                      width: cardWidth,
                      title: 'Students & Enrollments',
                      value: '$totalStudents / $activeEnrollments',
                      subtitle: 'Total students • Active enrolled',
                      icon: Icons.people_outline,
                      accent: AppColors.primary,
                      onTap: () => context.go(
                        state.isAdmin
                            ? AppRoutes.academyStudents
                            : AppRoutes.academyStaffStudents,
                      ),
                    ),
                    _KpiCard(
                      width: cardWidth,
                      title: 'Pending Enrollments',
                      value: '$pendingEnrollments',
                      subtitle: 'Awaiting review',
                      icon: Icons.pending_actions_outlined,
                      accent: AppColors.warning,
                      onTap: () => context.go(
                        state.isAdmin
                            ? AppRoutes.academyEnrollments
                            : AppRoutes.academyStaffEnrollments,
                      ),
                    ),
                    _KpiCard(
                      width: cardWidth,
                      title: 'Batch Utilisation',
                      value: '${(capacityRatio * 100).round()}%',
                      subtitle: '$totalBatchEnrolled / $totalCapacity seats filled',
                      icon: Icons.donut_large_outlined,
                      accent: AppColors.info,
                      onTap: () => context.go(
                        state.isAdmin
                            ? AppRoutes.academyBranches
                            : AppRoutes.academyStaffBranches,
                      ),
                    ),
                    _KpiCard(
                      width: cardWidth,
                      title: 'Monthly Fee Collection',
                      value: '₹${collected.toStringAsFixed(0)}',
                      subtitle: pendingFee > 0
                          ? '₹${pendingFee.toStringAsFixed(0)} pending'
                          : 'All dues collected',
                      icon: Icons.payments_outlined,
                      accent: AppColors.success,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. Graphical Analytics Grid: Branch Distribution + Attendance Trend
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 820;
                final branchCard = _BranchDistributionCard(state: state);
                final attendanceCard =
                    _AttendanceTrendCard(trends: state.data.attendanceTrends);

                if (!isWide) {
                  return Column(
                    children: [
                      branchCard,
                      const SizedBox(height: AppSpacing.md),
                      attendanceCard,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: branchCard),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: attendanceCard),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // 3. Batch Capacity Utilisation + Monthly Fee Progress + Coach Activity
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 820;
                final capacityCard =
                    _BatchCapacityCard(batches: state.scopedBatches);
                final coachAndFeeCard = Column(
                  children: [
                    _FeeCollectionCard(
                      collected: collected,
                      pending: pendingFee,
                      ratio: feeRatio,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _CoachActivityCard(state: state),
                  ],
                );

                if (!isWide) {
                  return Column(
                    children: [
                      capacityCard,
                      const SizedBox(height: AppSpacing.md),
                      coachAndFeeCard,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: capacityCard),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: coachAndFeeCard),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final double width;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.width,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchDistributionCard extends StatelessWidget {
  final AcademyLoaded state;

  const _BranchDistributionCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final branches = state.scopedBranches;
    final counts = <String, int>{};
    var maxCount = 1;

    for (final b in branches) {
      final c = state.data.batches
          .where((batch) => batch.branchId == b.id)
          .fold<int>(0, (sum, batch) => sum + batch.enrolledCount);
      counts[b.id] = c;
      if (c > maxCount) maxCount = c;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Branch-Wise Student Distribution',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (branches.isEmpty)
            const Text('No branch data available.')
          else
            ...branches.map((branch) {
              final count = counts[branch.id] ?? 0;
              final ratio = (count / maxCount).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            branch.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$count students',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: AppSpacing.borderRadiusSm,
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _AttendanceTrendCard extends StatelessWidget {
  final List<AttendanceTrendPoint> trends;

  const _AttendanceTrendCard({required this.trends});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Attendance Trends (Weekly %)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (trends.isEmpty)
            const Text('No attendance trend data.')
          else
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trends.map((point) {
                  final barHeight = (point.attendanceRate / 100 * 78)
                      .clamp(8.0, 78.0);
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${point.attendanceRate.round()}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 18,
                          height: barHeight,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          point.label,
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _BatchCapacityCard extends StatelessWidget {
  final List<AcademyBatch> batches;

  const _BatchCapacityCard({required this.batches});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Batch Capacity Utilisation',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (batches.isEmpty)
            const Text('No batches available.')
          else
            ...batches.map((batch) {
              final ratio = batch.capacity > 0
                  ? (batch.enrolledCount / batch.capacity).clamp(0.0, 1.0)
                  : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${batch.name} (${batch.skillLevel.label})',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${batch.enrolledCount}/${batch.capacity}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: batch.isFull
                                ? AppColors.error
                                : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: AppSpacing.borderRadiusSm,
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        color: batch.isFull
                            ? AppColors.warning
                            : AppColors.success,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _FeeCollectionCard extends StatelessWidget {
  final double collected;
  final double pending;
  final double ratio;

  const _FeeCollectionCard({
    required this.collected,
    required this.pending,
    required this.ratio,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Fee Collection',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Collected: ₹${collected.toStringAsFixed(0)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Pending: ₹${pending.toStringAsFixed(0)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: AppSpacing.borderRadiusSm,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              color: AppColors.success,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachActivityCard extends StatelessWidget {
  final AcademyLoaded state;

  const _CoachActivityCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final approvedCoaches = state.scopedAffiliations
        .where((c) => c.status == CoachAffiliationStatus.accepted)
        .toList();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coach Activity & Performance',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (approvedCoaches.isEmpty)
            const Text('No active coaches in scope.')
          else
            ...approvedCoaches.map((coach) {
              final batchesLed = state.scopedBatches
                  .where((b) => b.assignedCoachId == coach.coachId)
                  .length;
              final assessmentsCount = state.scopedStudents
                  .expand((s) => s.coachAssessments)
                  .where((a) => a.coachId == coach.coachId)
                  .length;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      child: Text(
                        coach.coachName[0],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        coach.coachName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '$batchesLed batches • $assessmentsCount reviews',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
