import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_branch_filter_bar.dart';
import 'package:pickleball_platform/features/academy_staff/domain/entities/academy_staff_entities.dart';
import 'package:pickleball_platform/features/academy_staff/presentation/cubit/academy_staff_cubit.dart';
import 'package:pickleball_platform/features/academy_staff/presentation/cubit/academy_staff_state.dart';
import 'package:pickleball_platform/features/academy_staff/presentation/widgets/academy_staff_page_scaffold.dart';

/// Delegated Academy Staff Operations page (Phase 3 — Feature 3.6):
/// Batches & schedules, student enrollments & manual tuition, and affiliated coaches.
class AcademyStaffOperationsPage extends StatefulWidget {
  final AcademyStaffCubit? cubit;
  final String academyId;
  final String staffId;

  const AcademyStaffOperationsPage({
    super.key,
    this.cubit,
    this.academyId = 'acad_001',
    this.staffId = 'user_acad_staff_001',
  });

  @override
  State<AcademyStaffOperationsPage> createState() =>
      _AcademyStaffOperationsPageState();
}

class _AcademyStaffOperationsPageState
    extends State<AcademyStaffOperationsPage> {
  int _selectedSection = 0;

  @override
  Widget build(BuildContext context) {
    return AcademyStaffPageScaffold(
      cubit: widget.cubit,
      academyId: widget.academyId,
      staffId: widget.staffId,
      title: 'Delegated Branch Operations',
      subtitle:
          'Manage assigned branch batches, review enrollments, record manual tuition, and view affiliated coaches.',
      bodyBuilder: (context, state) {
        final cubit = context.read<AcademyStaffCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AcademyBranchFilterBar(
              branches: state.data.assignedBranches,
              selectedBranchId: state.selectedBranchId,
              onBranchSelected: cubit.selectBranch,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                ChoiceChip(
                  label: Text('Batches (${state.scopedBatches.length})'),
                  selected: _selectedSection == 0,
                  onSelected: (_) => setState(() => _selectedSection = 0),
                ),
                ChoiceChip(
                  label:
                      Text('Enrollments (${state.scopedEnrollments.length})'),
                  selected: _selectedSection == 1,
                  onSelected: (_) => setState(() => _selectedSection = 1),
                ),
                ChoiceChip(
                  label: Text('Coaches (${state.scopedCoaches.length})'),
                  selected: _selectedSection == 2,
                  onSelected: (_) => setState(() => _selectedSection = 2),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            switch (_selectedSection) {
              0 => _BatchesSection(state: state, cubit: cubit),
              1 => _EnrollmentsSection(state: state, cubit: cubit),
              _ => _CoachesSection(state: state),
            },
          ],
        );
      },
    );
  }
}

class _BatchesSection extends StatelessWidget {
  final AcademyStaffLoaded state;
  final AcademyStaffCubit cubit;

  const _BatchesSection({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canEditSchedule =
        state.hasPermission(AcademyStaffPermission.manageBatches);

    if (state.scopedBatches.isEmpty) {
      return const EmptyStateView(
        icon: Icon(Icons.groups_outlined),
        title: 'No Assigned Batches',
        message: 'No batches exist for your assigned branch filter.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: state.scopedBatches.map((batch) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${batch.name} • ${batch.programTitle}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${batch.branchName} • ${batch.scheduleLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seats: ${batch.enrolledCount}/${batch.capacity}'
                        '${batch.assignedCoachName != null ? ' • Coach: ${batch.assignedCoachName}' : ''}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (canEditSchedule)
                  OutlinedButton.icon(
                    onPressed: () =>
                        _showScheduleDialog(context, cubit, batch),
                    icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                    label: const Text('Update Timing'),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _showScheduleDialog(
    BuildContext context,
    AcademyStaffCubit cubit,
    AcademyBatch batch,
  ) async {
    final controller = TextEditingController(text: batch.scheduleLabel);
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update Timing — ${batch.name}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Schedule Timing',
              hintText: 'e.g., Tue / Thu / Sat • 06:00 PM – 07:30 PM',
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Schedule timing is required.'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.of(dialogContext).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.updateBatchSchedule(
        batchId: batch.id,
        scheduleLabel: controller.text,
      );
    }
    controller.dispose();
  }
}

class _EnrollmentsSection extends StatelessWidget {
  final AcademyStaffLoaded state;
  final AcademyStaffCubit cubit;

  const _EnrollmentsSection({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canView = state.hasPermission(AcademyStaffPermission.viewStudents) ||
        state.hasPermission(AcademyStaffPermission.manageEnrollments) ||
        state.hasPermission(AcademyStaffPermission.recordTuition);

    if (!canView) {
      return const EmptyStateView(
        icon: Icon(Icons.lock_outline),
        title: 'Student & Enrollment Access Restricted',
        message:
            'Your Academy Admin has not delegated student or enrollment permissions to your account.',
      );
    }

    final canManageEnrollments =
        state.hasPermission(AcademyStaffPermission.manageEnrollments);
    final canRecordTuition =
        state.hasPermission(AcademyStaffPermission.recordTuition);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        if (state.scopedEnrollments.isEmpty)
          const EmptyStateView(
            icon: Icon(Icons.badge_outlined),
            title: 'No Enrollment Records',
            message:
                'No student enrollments match the selected branch or status filter.',
          )
        else
          ...state.scopedEnrollments.map((enr) {
            final statusColor = switch (enr.status) {
              EnrollmentRequestStatus.approved => AppColors.success,
              EnrollmentRequestStatus.pending => AppColors.warning,
              EnrollmentRequestStatus.waitlisted => theme.colorScheme.secondary,
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
                              const SizedBox(height: 2),
                              Text(
                                '${enr.programTitle} • ${enr.batchName} • ${enr.branchName}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(
                            enr.waitlistPosition != null
                                ? '${enr.status.label} (#${enr.waitlistPosition})'
                                : enr.status.label,
                          ),
                          backgroundColor: statusColor.withValues(alpha: 0.12),
                          labelStyle: theme.textTheme.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Tuition: ₹${enr.tuitionAmountInr.toStringAsFixed(0)} • Fee Status: ${enr.feeStatus.label}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: feeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (canManageEnrollments || canRecordTuition) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (canManageEnrollments) ...[
                            if (enr.status != EnrollmentRequestStatus.approved)
                              FilledButton.tonal(
                                onPressed: () => cubit.updateEnrollmentStatus(
                                  enrollmentId: enr.id,
                                  newStatus: EnrollmentRequestStatus.approved,
                                ),
                                child: const Text('Approve'),
                              ),
                            if (enr.status !=
                                EnrollmentRequestStatus.waitlisted)
                              OutlinedButton(
                                onPressed: () => cubit.updateEnrollmentStatus(
                                  enrollmentId: enr.id,
                                  newStatus: EnrollmentRequestStatus.waitlisted,
                                ),
                                child: const Text('Waitlist'),
                              ),
                            if (enr.status != EnrollmentRequestStatus.declined)
                              OutlinedButton(
                                onPressed: () => cubit.updateEnrollmentStatus(
                                  enrollmentId: enr.id,
                                  newStatus: EnrollmentRequestStatus.declined,
                                ),
                                child: const Text('Decline'),
                              ),
                          ],
                          if (canRecordTuition &&
                              enr.feeStatus != TuitionFeeStatus.paid)
                            OutlinedButton.icon(
                              onPressed: () => cubit.recordTuitionPayment(
                                enrollmentId: enr.id,
                                feeStatus: TuitionFeeStatus.paid,
                              ),
                              icon: const Icon(Icons.payments_outlined,
                                  size: 16),
                              label: const Text('Mark Paid'),
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
  }
}

class _CoachesSection extends StatelessWidget {
  final AcademyStaffLoaded state;

  const _CoachesSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!state.hasPermission(AcademyStaffPermission.viewCoaches)) {
      return const EmptyStateView(
        icon: Icon(Icons.lock_outline),
        title: 'Coach Directory Restricted',
        message:
            'Your Academy Admin has not delegated coach directory access to your staff account.',
      );
    }

    if (state.scopedCoaches.isEmpty) {
      return const EmptyStateView(
        icon: Icon(Icons.sports_outlined),
        title: 'No Affiliated Coaches',
        message: 'No accepted coaches are assigned to your scoped branches.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            'Read-only academy roster (Coach personal coaching records remain private; only Academy Admin can invite or revoke coaches).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ...state.scopedCoaches.map((coach) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          coach.coachName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${coach.specialization} • ${coach.assignedBranchNames.join(', ')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(coach.status.label),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
