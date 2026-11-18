import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_cubit.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_branch_filter_bar.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_page_scaffold.dart';

enum _EnrollmentTab {
  pending('Pending Requests'),
  approved('Approved'),
  rejected('Rejected'),
  history('History');

  final String label;
  const _EnrollmentTab(this.label);
}

/// Shared Academy Enrollment management page (Pending, Approved, Rejected & History).
class AcademyEnrollmentsPage extends StatefulWidget {
  final AcademyCubit? cubit;
  final String academyId;

  const AcademyEnrollmentsPage({
    super.key,
    this.cubit,
    this.academyId = 'acad_001',
  });

  @override
  State<AcademyEnrollmentsPage> createState() => _AcademyEnrollmentsPageState();
}

class _AcademyEnrollmentsPageState extends State<AcademyEnrollmentsPage> {
  _EnrollmentTab _activeTab = _EnrollmentTab.pending;

  @override
  Widget build(BuildContext context) {
    return AcademyPageScaffold(
      cubit: widget.cubit,
      academyId: widget.academyId,
      title: 'Enrollment Management',
      subtitle:
          'Review pending requests, manage approved & rejected enrollments, and track enrollment history.',
      bodyBuilder: (context, state) {
        final cubit = context.read<AcademyCubit>();
        final theme = Theme.of(context);
        final df = DateFormat('dd MMM yyyy');

        final branchScoped = state.data.enrollments.where((e) {
          if (!state.canAccessBranch(e.branchId)) return false;
          if (state.selectedBranchId != null &&
              e.branchId != state.selectedBranchId) {
            return false;
          }
          return true;
        }).toList();

        final filtered = switch (_activeTab) {
          _EnrollmentTab.pending => branchScoped
              .where((e) =>
                  e.status == EnrollmentRequestStatus.pending ||
                  e.status == EnrollmentRequestStatus.waitlisted)
              .toList(),
          _EnrollmentTab.approved => branchScoped
              .where((e) => e.status == EnrollmentRequestStatus.approved)
              .toList(),
          _EnrollmentTab.rejected => branchScoped
              .where((e) => e.status == EnrollmentRequestStatus.declined)
              .toList(),
          _EnrollmentTab.history => [...branchScoped]
            ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt)),
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AcademyBranchFilterBar(
              branches: state.scopedBranches,
              selectedBranchId: state.selectedBranchId,
              onBranchSelected: cubit.selectBranch,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: _EnrollmentTab.values.map((tab) {
                return ChoiceChip(
                  label: Text(tab.label),
                  selected: _activeTab == tab,
                  onSelected: (_) => setState(() => _activeTab = tab),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.md),
            if (filtered.isEmpty)
              EmptyStateView(
                icon: const Icon(Icons.badge_outlined),
                title: 'No ${_activeTab.label}',
                message:
                    'No enrollment records found for this section and branch filter.',
              )
            else
              ...filtered.map((enr) {
                final statusColor = switch (enr.status) {
                  EnrollmentRequestStatus.approved => AppColors.success,
                  EnrollmentRequestStatus.pending => AppColors.warning,
                  EnrollmentRequestStatus.waitlisted => AppColors.info,
                  EnrollmentRequestStatus.declined => AppColors.error,
                };

                final statusLabel =
                    enr.status == EnrollmentRequestStatus.declined
                        ? 'Rejected'
                        : enr.status.label;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
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
                                    enr.studentName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${enr.studentContact}${enr.guardianName != null ? ' • Guardian: ${enr.guardianName}' : ''}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.14),
                                borderRadius: AppSpacing.borderRadiusSm,
                              ),
                              child: Text(
                                statusLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${enr.branchName} • ${enr.batchName}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            AppChip.neutral(
                              label: 'Fee: ${enr.feeStatus.label}',
                            ),
                            Text(
                              '₹${enr.tuitionAmountInr.toStringAsFixed(0)}/mo',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Requested: ${df.format(enr.requestedAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (state.canManageEnrollments ||
                            state.canRecordTuition) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              if (state.canManageEnrollments &&
                                  (enr.status ==
                                          EnrollmentRequestStatus.pending ||
                                      enr.status ==
                                          EnrollmentRequestStatus.waitlisted)) ...[
                                FilledButton(
                                  onPressed: () => cubit.updateEnrollmentStatus(
                                    enrollmentId: enr.id,
                                    newStatus: EnrollmentRequestStatus.approved,
                                  ),
                                  child: const Text('Approve'),
                                ),
                                OutlinedButton(
                                  onPressed: () => cubit.updateEnrollmentStatus(
                                    enrollmentId: enr.id,
                                    newStatus: EnrollmentRequestStatus.declined,
                                  ),
                                  child: const Text('Reject'),
                                ),
                              ],
                              if (state.canRecordTuition &&
                                  enr.status ==
                                      EnrollmentRequestStatus.approved &&
                                  enr.feeStatus != TuitionFeeStatus.paid)
                                OutlinedButton.icon(
                                  onPressed: () => cubit.recordTuitionPayment(
                                    enrollmentId: enr.id,
                                    feeStatus: TuitionFeeStatus.paid,
                                  ),
                                  icon: const Icon(
                                    Icons.payments_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Mark Fee Paid'),
                                ),
                            ],
                          ),
                        ],
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
