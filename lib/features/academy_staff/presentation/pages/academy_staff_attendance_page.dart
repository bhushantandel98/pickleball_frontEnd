import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_branch_filter_bar.dart';
import 'package:pickleball_platform/features/academy_staff/domain/entities/academy_staff_entities.dart';
import 'package:pickleball_platform/features/academy_staff/presentation/cubit/academy_staff_cubit.dart';
import 'package:pickleball_platform/features/academy_staff/presentation/widgets/academy_staff_page_scaffold.dart';

/// Academy Staff Attendance Management page (Phase 3 — Feature 3.6).
class AcademyStaffAttendancePage extends StatelessWidget {
  final AcademyStaffCubit? cubit;
  final String academyId;
  final String staffId;

  const AcademyStaffAttendancePage({
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
      title: 'Session Attendance',
      subtitle:
          'Record and update student attendance for batches in your assigned branches.',
      bodyBuilder: (context, state) {
        final cubit = context.read<AcademyStaffCubit>();
        final theme = Theme.of(context);

        if (!state.hasPermission(AcademyStaffPermission.manageAttendance)) {
          return const AppCard(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: EmptyStateView(
              icon: Icon(Icons.lock_outline),
              title: 'Attendance Access Restricted',
              message:
                  'Your Academy Admin has not delegated attendance management permission to your staff account.',
            ),
          );
        }

        final records = state.scopedAttendance;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AcademyBranchFilterBar(
              branches: state.data.assignedBranches,
              selectedBranchId: state.selectedBranchId,
              onBranchSelected: cubit.selectBranch,
            ),
            const SizedBox(height: AppSpacing.xs),
            if (state.scopedBatches.isNotEmpty)
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  ChoiceChip(
                    label: const Text('All Batches'),
                    selected: state.selectedBatchId == null,
                    onSelected: (_) => cubit.selectBatch(null),
                  ),
                  ...state.scopedBatches.map(
                    (batch) => ChoiceChip(
                      label: Text(batch.name),
                      selected: state.selectedBatchId == batch.id,
                      onSelected: (_) => cubit.selectBatch(batch.id),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            if (records.isEmpty)
              EmptyStateView(
                icon: const Icon(Icons.fact_check_outlined),
                title: 'No Attendance Records',
                message:
                    'No attendance records match the selected branch or batch filter.',
                actionLabel:
                    state.selectedBranchId != null || state.selectedBatchId != null
                        ? 'Clear Filters'
                        : null,
                onAction:
                    state.selectedBranchId != null || state.selectedBatchId != null
                        ? () {
                            cubit.selectBranch(null);
                            cubit.selectBatch(null);
                          }
                        : null,
              )
            else
              ...records.map((rec) {
                final statusColor = switch (rec.status) {
                  StaffAttendanceStatus.present => AppColors.success,
                  StaffAttendanceStatus.late => AppColors.warning,
                  StaffAttendanceStatus.excused => theme.colorScheme.secondary,
                  StaffAttendanceStatus.absent => AppColors.error,
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
                                    rec.studentName,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${rec.batchName} • ${rec.branchName}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                rec.status.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (rec.notes != null && rec.notes!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Notes: ${rec.notes}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            ...StaffAttendanceStatus.values.map(
                              (status) => ChoiceChip(
                                label: Text(status.label),
                                selected: rec.status == status,
                                onSelected: (_) => cubit.markAttendance(
                                  attendanceId: rec.id,
                                  status: status,
                                  notes: rec.notes,
                                ),
                              ),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.edit_note, size: 16),
                              label: const Text('Add/Edit Note'),
                              onPressed: () =>
                                  _showNotesDialog(context, cubit, rec),
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

  Future<void> _showNotesDialog(
    BuildContext context,
    AcademyStaffCubit cubit,
    StaffSessionAttendance record,
  ) async {
    final controller = TextEditingController(text: record.notes ?? '');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Attendance Note — ${record.studentName}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            maxLines: 3,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Session Note (optional)',
              hintText: 'e.g., Checked in on Court 2',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.markAttendance(
        attendanceId: record.id,
        status: record.status,
        notes: controller.text,
      );
    }
    controller.dispose();
  }
}
