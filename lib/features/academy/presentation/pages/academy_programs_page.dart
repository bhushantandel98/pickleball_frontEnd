import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_cubit.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_state.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_branch_filter_bar.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_page_scaffold.dart';

/// Academy Coaching Programs & Batches management page (Phase 3 — Feature 3.5).
class AcademyProgramsPage extends StatelessWidget {
  final AcademyCubit? cubit;
  final String academyId;

  const AcademyProgramsPage({
    super.key,
    this.cubit,
    this.academyId = 'acad_001',
  });

  @override
  Widget build(BuildContext context) {
    return AcademyPageScaffold(
      cubit: cubit,
      academyId: academyId,
      title: 'Coaching Programs & Batches',
      subtitle:
          'Manage academy-owned curricula, monthly tuition, and scheduled batches per branch.',
      headerActionBuilder: (context, state) => FilledButton.icon(
        onPressed: state.data.branches.isEmpty
            ? null
            : () => _showCreateProgramDialog(context, state),
        icon: const Icon(Icons.add),
        label: const Text('Add Program'),
      ),
      bodyBuilder: (context, state) {
        final cubit = context.read<AcademyCubit>();
        final theme = Theme.of(context);
        final programs = state.scopedPrograms;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AcademyBranchFilterBar(
              branches: state.data.branches,
              selectedBranchId: state.selectedBranchId,
              onBranchSelected: cubit.selectBranch,
            ),
            const SizedBox(height: AppSpacing.md),
            if (programs.isEmpty)
              EmptyStateView(
                icon: const Icon(Icons.menu_book_outlined),
                title: 'No Programs Found',
                message: state.data.branches.isEmpty
                    ? 'Create a branch first before adding coaching programs.'
                    : 'Create an academy coaching program for this branch.',
                actionLabel:
                    state.data.branches.isEmpty ? null : 'Add Program',
                onAction: state.data.branches.isEmpty
                    ? null
                    : () => _showCreateProgramDialog(context, state),
              )
            else
              ...programs.map((program) {
                final programBatches = state.scopedBatches
                    .where((b) => b.programId == program.id)
                    .toList();

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    program.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${program.branchName} • ${program.skillLevel} • ${program.ageGroup}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: program.isActive,
                              onChanged: (val) =>
                                  cubit.toggleProgramStatus(program.id, val),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(program.description,
                            style: theme.textTheme.bodySmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Monthly Tuition: INR ${program.monthlyTuitionInr.toStringAsFixed(0)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Divider(height: AppSpacing.lg),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Batches (${programBatches.length})',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () => _showCreateBatchDialog(
                                context,
                                state,
                                program,
                              ),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Batch'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (programBatches.isEmpty)
                          Text(
                            'No batches scheduled under this program yet.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        else
                          ...programBatches.map(
                            (batch) => Container(
                              margin: const EdgeInsets.only(top: AppSpacing.xs),
                              padding: const EdgeInsets.all(AppSpacing.sm),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          batch.name,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '${batch.scheduleLabel} • Coach: ${batch.assignedCoachName ?? 'Unassigned'}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${batch.enrolledCount}/${batch.capacity}',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: batch.isFull
                                          ? AppColors.warning
                                          : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

  Future<void> _showCreateProgramDialog(
    BuildContext context,
    AcademyLoaded state,
  ) async {
    final cubit = context.read<AcademyCubit>();
    String selectedBranchId =
        state.selectedBranchId ?? state.data.branches.first.id;
    final titleController = TextEditingController();
    final skillController = TextEditingController(text: 'Beginner (1.5–2.5)');
    final ageController = TextEditingController(text: 'All Ages');
    final descController = TextEditingController();
    final feeController = TextEditingController(text: '4000');
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Coaching Program'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedBranchId,
                    decoration: const InputDecoration(labelText: 'Branch'),
                    items: state.data.branches
                        .map(
                          (b) => DropdownMenuItem(
                            value: b.id,
                            child: Text(b.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedBranchId = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: titleController,
                    decoration:
                        const InputDecoration(labelText: 'Program Title'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: skillController,
                    decoration: const InputDecoration(labelText: 'Skill Level'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: ageController,
                    decoration: const InputDecoration(labelText: 'Age Group'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: feeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monthly Tuition (INR)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      errorText!,
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final fee = double.tryParse(feeController.text.trim());
                if (titleController.text.trim().isEmpty ||
                    fee == null ||
                    fee < 0) {
                  setState(
                    () => errorText =
                        'Program title and valid non-negative tuition are required.',
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                await cubit.createProgram(
                  branchId: selectedBranchId,
                  title: titleController.text.trim(),
                  skillLevel: skillController.text.trim(),
                  ageGroup: ageController.text.trim(),
                  description: descController.text.trim(),
                  monthlyTuitionInr: fee,
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateBatchDialog(
    BuildContext context,
    AcademyLoaded state,
    AcademyProgram program,
  ) async {
    final cubit = context.read<AcademyCubit>();
    final nameController = TextEditingController();
    final scheduleController =
        TextEditingController(text: 'Tue / Thu • 18:00 – 19:30');
    final capacityController = TextEditingController(text: '8');
    final acceptedCoaches = state.data.coachAffiliations
        .where((c) =>
            c.status == CoachAffiliationStatus.accepted &&
            c.assignedBranchIds.contains(program.branchId))
        .toList();
    String? selectedCoachId;
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Add Batch — ${program.title}'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Batch Name'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: scheduleController,
                    decoration:
                        const InputDecoration(labelText: 'Schedule Label'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: capacityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacity'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedCoachId,
                    decoration: const InputDecoration(
                      labelText: 'Assign Accepted Coach (optional)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ...acceptedCoaches.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c.coachId,
                          child: Text(c.coachName),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => selectedCoachId = val),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      errorText!,
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final cap = int.tryParse(capacityController.text.trim());
                if (nameController.text.trim().isEmpty ||
                    scheduleController.text.trim().isEmpty ||
                    cap == null ||
                    cap <= 0) {
                  setState(
                    () => errorText =
                        'Batch name, schedule, and valid capacity (> 0) are required.',
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                await cubit.createBatch(
                  programId: program.id,
                  name: nameController.text.trim(),
                  scheduleLabel: scheduleController.text.trim(),
                  capacity: cap,
                  assignedCoachId: selectedCoachId,
                );
              },
              child: const Text('Create Batch'),
            ),
          ],
        ),
      ),
    );
  }
}
