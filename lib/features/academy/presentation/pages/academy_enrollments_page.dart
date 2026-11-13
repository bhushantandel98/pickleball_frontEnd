import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_cubit.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_branch_filter_bar.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_page_scaffold.dart';

/// Academy Student Enrollments & Tuition Fee tracking page (Phase 3 — Feature 3.5).
class AcademyEnrollmentsPage extends StatelessWidget {
  final AcademyCubit? cubit;
  final String academyId;

  const AcademyEnrollmentsPage({
    super.key,
    this.cubit,
    this.academyId = 'acad_001',
  });

  @override
  Widget build(BuildContext context) {
    return AcademyPageScaffold(
      cubit: cubit,
      academyId: academyId,
      title: 'Student Enrollments & Tuition',
      subtitle:
          'Review enrollment requests, manage waitlists, and track academy tuition fee status.',
      bodyBuilder: (context, state) {
        final cubit = context.read<AcademyCubit>();
        final theme = Theme.of(context);
        final enrollments = state.scopedEnrollments;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AcademyBranchFilterBar(
              branches: state.data.branches,
              selectedBranchId: state.selectedBranchId,
              onBranchSelected: cubit.selectBranch,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                ChoiceChip(
                  label: const Text('All Statuses'),
                  selected: state.enrollmentFilter == null,
                  onSelected: (_) => cubit.setEnrollmentFilter(null),
                ),
                ...EnrollmentRequestStatus.values.map(
                  (status) => ChoiceChip(
                    label: Text(status.label),
                    selected: state.enrollmentFilter == status,
                    onSelected: (_) => cubit.setEnrollmentFilter(status),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (enrollments.isEmpty)
              EmptyStateView(
                icon: const Icon(Icons.badge_outlined),
                title: 'No Enrollment Records',
                message:
                    'No student enrollments match the selected branch or status filter.',
                actionLabel:
                    state.enrollmentFilter != null ||
                            state.selectedBranchId != null
                        ? 'Clear Filters'
                        : null,
                onAction:
                    state.enrollmentFilter != null ||
                            state.selectedBranchId != null
                        ? () {
                            cubit.selectBranch(null);
                            cubit.setEnrollmentFilter(null);
                          }
                        : null,
              )
            else
              ...enrollments.map((enr) {
                final statusColor = switch (enr.status) {
                  EnrollmentRequestStatus.approved => AppColors.success,
                  EnrollmentRequestStatus.pending => AppColors.warning,
                  EnrollmentRequestStatus.waitlisted =>
                    theme.colorScheme.secondary,
                  EnrollmentRequestStatus.declined => AppColors.error,
                };
                final feeColor = switch (enr.feeStatus) {
                  TuitionFeeStatus.paid => AppColors.success,
                  TuitionFeeStatus.pending => AppColors.warning,
                  TuitionFeeStatus.overdue => AppColors.error,
                };

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                enr.waitlistPosition != null
                                    ? '${enr.status.label} (#${enr.waitlistPosition})'
                                    : enr.status.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: feeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Tuition: ${enr.feeStatus.label} (INR ${enr.tuitionAmountInr.toStringAsFixed(0)})',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: feeColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          enr.studentName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          enr.guardianName != null
                              ? '${enr.studentContact} • Guardian: ${enr.guardianName}'
                              : enr.studentContact,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${enr.programTitle} • ${enr.batchName} • ${enr.branchName}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (enr.status == EnrollmentRequestStatus.pending ||
                                enr.status ==
                                    EnrollmentRequestStatus.waitlisted) ...[
                              FilledButton.tonalIcon(
                                onPressed: () => cubit.updateEnrollmentStatus(
                                  enrollmentId: enr.id,
                                  newStatus: EnrollmentRequestStatus.approved,
                                ),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Approve'),
                              ),
                              if (enr.status !=
                                  EnrollmentRequestStatus.waitlisted)
                                OutlinedButton(
                                  onPressed: () => cubit.updateEnrollmentStatus(
                                    enrollmentId: enr.id,
                                    newStatus:
                                        EnrollmentRequestStatus.waitlisted,
                                  ),
                                  child: const Text('Waitlist'),
                                ),
                              TextButton(
                                onPressed: () => cubit.updateEnrollmentStatus(
                                  enrollmentId: enr.id,
                                  newStatus: EnrollmentRequestStatus.declined,
                                ),
                                child: Text(
                                  'Decline',
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                            if (enr.status ==
                                    EnrollmentRequestStatus.approved &&
                                enr.feeStatus != TuitionFeeStatus.paid)
                              FilledButton.icon(
                                onPressed: () => cubit.recordTuitionPayment(
                                  enrollmentId: enr.id,
                                  feeStatus: TuitionFeeStatus.paid,
                                ),
                                icon: const Icon(Icons.payments_outlined,
                                    size: 16),
                                label: const Text('Mark Tuition Paid'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
