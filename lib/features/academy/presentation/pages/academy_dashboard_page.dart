import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_cubit.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_branch_filter_bar.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_page_scaffold.dart';

/// Primary Academy Dashboard page (Phase 3 — Feature 3.5).
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
          'Multi-branch operations, coaching programs, coach affiliations, and student enrollments.',
      bodyBuilder: (context, state) {
        final cubit = context.read<AcademyCubit>();
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.data.profile.academyName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Owner: ${state.data.profile.ownerName} • ${state.data.profile.primaryCity} • ${state.data.profile.contactEmail}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AcademyBranchFilterBar(
                    branches: state.data.branches,
                    selectedBranchId: state.selectedBranchId,
                    onBranchSelected: cubit.selectBranch,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // KPI Summary Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 4
                    : (constraints.maxWidth >= 560 ? 2 : 1);
                final cardWidth =
                    (constraints.maxWidth - (AppSpacing.sm * (columns - 1))) /
                        columns;

                final metrics = [
                  _MetricItem(
                    label: 'Active Branches',
                    value:
                        '${state.activeBranchCount}/${state.data.branches.length}',
                    icon: Icons.store_outlined,
                    color: theme.colorScheme.primary,
                    route: AppRoutes.academyBranches,
                  ),
                  _MetricItem(
                    label: 'Programs & Batches',
                    value:
                        '${state.scopedPrograms.length} / ${state.scopedBatches.length}',
                    icon: Icons.menu_book_outlined,
                    color: theme.colorScheme.secondary,
                    route: AppRoutes.academyPrograms,
                  ),
                  _MetricItem(
                    label: 'Affiliated Coaches',
                    value: '${state.acceptedCoachCount}',
                    icon: Icons.sports_outlined,
                    color: AppColors.success,
                    route: AppRoutes.academyCoaches,
                  ),
                  _MetricItem(
                    label: 'Active Students',
                    value: '${state.activeStudentCount}',
                    icon: Icons.groups_outlined,
                    color: AppColors.warning,
                    route: AppRoutes.academyEnrollments,
                  ),
                ];

                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: metrics
                      .map(
                        (m) => SizedBox(
                          width: cardWidth,
                          child: InkWell(
                            onTap: () => context.go(m.route),
                            borderRadius: BorderRadius.circular(12),
                            child: AppCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor:
                                        m.color.withValues(alpha: 0.14),
                                    child: Icon(m.icon, color: m.color),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.value,
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        Text(
                                          m.label,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            // Tuition & Pending Operations Summary
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academy Tuition & Pending Actions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Academy tuition records are strictly separated from coach personal coaching fees.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _SummaryChip(
                        label: 'Tuition Collected',
                        value:
                            'INR ${state.collectedTuitionInr.toStringAsFixed(0)}',
                        color: AppColors.success,
                      ),
                      _SummaryChip(
                        label: 'Tuition Pending/Overdue',
                        value:
                            'INR ${state.pendingTuitionInr.toStringAsFixed(0)}',
                        color: AppColors.warning,
                      ),
                      _SummaryChip(
                        label: 'Pending Enrollments',
                        value: '${state.pendingEnrollmentCount}',
                        color: theme.colorScheme.primary,
                      ),
                      _SummaryChip(
                        label: 'Pending Coach Invites',
                        value: '${state.pendingCoachInviteCount}',
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Upcoming / Active Batches Overview
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Active Batches (${state.scopedBatches.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.academyPrograms),
                        child: const Text('Manage Programs'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (state.scopedBatches.isEmpty)
                    Text(
                      'No batches configured for the selected branch.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ...state.scopedBatches.map(
                      (batch) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${batch.name} • ${batch.programTitle}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${batch.branchName} • ${batch.scheduleLabel} • Coach: ${batch.assignedCoachName ?? 'Unassigned'}',
                        ),
                        trailing: Text(
                          '${batch.enrolledCount}/${batch.capacity}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: batch.isFull
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // Quick Pending Enrollment Requests
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Recent Enrollment Requests',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.go(AppRoutes.academyEnrollments),
                        child: const Text('Review All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (state.scopedEnrollments
                      .where((e) =>
                          e.status == EnrollmentRequestStatus.pending ||
                          e.status == EnrollmentRequestStatus.waitlisted)
                      .isEmpty)
                    Text(
                      'No pending or waitlisted enrollment requests.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ...state.scopedEnrollments
                        .where((e) =>
                            e.status == EnrollmentRequestStatus.pending ||
                            e.status == EnrollmentRequestStatus.waitlisted)
                        .map(
                          (e) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(e.studentName),
                            subtitle: Text(
                              '${e.programTitle} (${e.batchName}) • ${e.branchName}',
                            ),
                            trailing: Chip(label: Text(e.status.label)),
                          ),
                        ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MetricItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String route;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.route,
  });
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}
