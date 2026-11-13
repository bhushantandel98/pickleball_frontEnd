import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_branch_filter_bar.dart';
import 'package:pickleball_platform/features/academy_staff/domain/entities/academy_staff_entities.dart';
import 'package:pickleball_platform/features/academy_staff/presentation/cubit/academy_staff_cubit.dart';
import 'package:pickleball_platform/features/academy_staff/presentation/widgets/academy_staff_page_scaffold.dart';

/// Primary Academy Staff Operations Dashboard (Phase 3 — Feature 3.6).
class AcademyStaffDashboardPage extends StatelessWidget {
  final AcademyStaffCubit? cubit;
  final String academyId;
  final String staffId;

  const AcademyStaffDashboardPage({
    super.key,
    this.cubit,
    this.academyId = 'acad_001',
    this.staffId = 'user_acad_staff_001',
  });

  @override
  Widget build(BuildContext context) {
    return AcademyStaffPageScaffold(
      cubit: cubit,
      academyId: academyId,
      staffId: staffId,
      title: 'Academy Staff Operations',
      subtitle:
          'Branch-scoped daily operations, attendance, batch schedules, and delegated student support.',
      bodyBuilder: (context, state) {
        final cubit = context.read<AcademyStaffCubit>();
        final theme = Theme.of(context);
        final profile = state.staffProfile;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                              profile.academyName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${profile.staffName} • ${profile.roleTitle} • ${profile.staffEmail}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.verified_user_outlined, size: 16),
                        label: Text(
                          '${profile.assignedBranchIds.length} Branch Scope',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Delegated Permissions (Assigned by Academy Admin — Read-Only)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: profile.permissions
                        .map(
                          (perm) => Chip(
                            label: Text(perm.label),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AcademyBranchFilterBar(
                    branches: state.data.assignedBranches,
                    selectedBranchId: state.selectedBranchId,
                    onBranchSelected: cubit.selectBranch,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 4
                    : (constraints.maxWidth >= 560 ? 2 : 1);
                final cardWidth =
                    (constraints.maxWidth - (AppSpacing.sm * (columns - 1))) /
                        columns;

                final metrics = [
                  _StaffMetricItem(
                    label: 'Assigned Branches',
                    value: '${state.data.assignedBranches.length}',
                    icon: Icons.store_outlined,
                    color: theme.colorScheme.primary,
                    route: AppRoutes.academyStaffOperations,
                  ),
                  _StaffMetricItem(
                    label: 'Today\'s Sessions',
                    value: '${state.scopedTodaySessions.length}',
                    icon: Icons.schedule_outlined,
                    color: theme.colorScheme.secondary,
                    route: AppRoutes.academyStaffOperations,
                  ),
                  _StaffMetricItem(
                    label: 'Present Today',
                    value: state.hasPermission(
                            AcademyStaffPermission.manageAttendance)
                        ? '${state.presentTodayCount}/${state.scopedAttendance.length}'
                        : 'Restricted',
                    icon: Icons.fact_check_outlined,
                    color: AppColors.success,
                    route: AppRoutes.academyStaffAttendance,
                  ),
                  _StaffMetricItem(
                    label: 'Pending Enrollments',
                    value: state.hasPermission(
                                AcademyStaffPermission.manageEnrollments) ||
                            state.hasPermission(
                                AcademyStaffPermission.viewStudents)
                        ? '${state.pendingEnrollmentCount}'
                        : 'Restricted',
                    icon: Icons.badge_outlined,
                    color: AppColors.warning,
                    route: AppRoutes.academyStaffOperations,
                  ),
                ];

                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: metrics.map((m) {
                    return SizedBox(
                      width: cardWidth,
                      child: AppCard(
                        onTap: () => context.go(m.route),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(m.icon, color: m.color),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              m.value,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Assigned Branch Sessions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Wrap(
                        spacing: AppSpacing.xs,
                        children: [
                          if (state.hasPermission(
                              AcademyStaffPermission.manageAttendance))
                            TextButton.icon(
                              onPressed: () =>
                                  context.go(AppRoutes.academyStaffAttendance),
                              icon: const Icon(Icons.fact_check_outlined,
                                  size: 18),
                              label: const Text('Mark Attendance'),
                            ),
                          TextButton.icon(
                            onPressed: () =>
                                context.go(AppRoutes.academyStaffOperations),
                            icon: const Icon(Icons.tune_outlined, size: 18),
                            label: const Text('Operations'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (state.scopedTodaySessions.isEmpty)
                    const EmptyStateView(
                      icon: Icon(Icons.event_busy_outlined),
                      title: 'No Assigned Sessions',
                      message:
                          'No academy batch sessions are scheduled for your assigned branch filter.',
                    )
                  else
                    ...state.scopedTodaySessions.map(
                      (session) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${session.batchName} • ${session.programTitle}',
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${session.branchName} • ${session.scheduleLabel}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (session.assignedCoachName != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Coach: ${session.assignedCoachName}',
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Chip(
                                label: Text(
                                  '${session.enrolledCount}/${session.capacity} Seats',
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ),
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

class _StaffMetricItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String route;

  const _StaffMetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.route,
  });
}
