import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_cubit.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_state.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_page_scaffold.dart';

/// Combined Academy Branches & Batches management page (shared by Admin & Staff).
class AcademyBranchesPage extends StatefulWidget {
  final AcademyCubit? cubit;
  final String academyId;

  const AcademyBranchesPage({
    super.key,
    this.cubit,
    this.academyId = 'acad_001',
  });

  @override
  State<AcademyBranchesPage> createState() => _AcademyBranchesPageState();
}

class _AcademyBranchesPageState extends State<AcademyBranchesPage> {
  String? _activeBranchId;

  @override
  Widget build(BuildContext context) {
    return AcademyPageScaffold(
      cubit: widget.cubit,
      academyId: widget.academyId,
      title: 'Branches & Batches',
      subtitle:
          'Manage academy branches, select a branch to view batches, capacities, and coach assignments.',
      headerActionBuilder: (context, state) {
        if (!state.canManageBranches) {
          return const SizedBox.shrink();
        }
        return FilledButton.icon(
          onPressed: () => _showBranchDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Add Branch'),
        );
      },
      bodyBuilder: (context, state) {
        final branches = state.scopedBranches;
        final theme = Theme.of(context);

        if (branches.isEmpty) {
          return EmptyStateView(
            icon: const Icon(Icons.store_outlined),
            title: 'No Branches Available',
            message: state.canManageBranches
                ? 'Add your first academy branch to set up training batches.'
                : 'No branches have been assigned to your staff account yet.',
            actionLabel: state.canManageBranches ? 'Add Branch' : null,
            onAction:
                state.canManageBranches ? () => _showBranchDialog(context) : null,
          );
        }

        final selectedBranch = _activeBranchId != null
            ? branches.where((b) => b.id == _activeBranchId).firstOrNull
            : null;

        if (selectedBranch != null) {
          return _buildBranchBatchesView(context, state, selectedBranch);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...branches.map((branch) {
              final branchBatches = state.data.batches
                  .where((b) => b.branchId == branch.id)
                  .toList();
              final enrolledInBranch = branchBatches.fold<int>(
                0,
                (sum, b) => sum + b.enrolledCount,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  onTap: () => setState(() => _activeBranchId = branch.id),
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
                                  branch.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  branch.address,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppChip.neutral(
                            label: branch.isActive ? 'Active' : 'Paused',
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (branch.contactPerson.isNotEmpty)
                            Text(
                              'Contact: ${branch.contactPerson}',
                              style: theme.textTheme.bodySmall,
                            ),
                          Text(
                            '${branchBatches.length} Batches',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$enrolledInBranch Students',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _activeBranchId = branch.id),
                            icon: const Icon(Icons.layers_outlined, size: 18),
                            label: const Text('View Batches'),
                          ),
                          if (state.canManageBranches) ...[
                            const SizedBox(width: AppSpacing.xs),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _showBranchDialog(context, existing: branch),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: const Text('Edit'),
                            ),
                          ],
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

  Widget _buildBranchBatchesView(
    BuildContext context,
    AcademyLoaded state,
    AcademyBranch branch,
  ) {
    final theme = Theme.of(context);
    final batches =
        state.data.batches.where((b) => b.branchId == branch.id).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'All Branches',
                onPressed: () => setState(() => _activeBranchId = null),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      [
                        if (branch.contactPerson.isNotEmpty)
                          'Contact: ${branch.contactPerson}',
                        branch.address,
                      ].join(' • '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (state.canManageBatches)
                FilledButton.icon(
                  onPressed: () => _showBatchDialog(
                    context,
                    state: state,
                    branch: branch,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Batch'),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (batches.isEmpty)
          EmptyStateView(
            icon: const Icon(Icons.groups_outlined),
            title: 'No Batches in ${branch.name}',
            message: 'Create a training batch for this branch.',
            actionLabel: state.canManageBatches ? 'Add Batch' : null,
            onAction: state.canManageBatches
                ? () => _showBatchDialog(context, state: state, branch: branch)
                : null,
          )
        else
          ...batches.map((batch) {
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
                                batch.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                batch.scheduleLabel,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppChip.info(label: batch.skillLevel.label),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Text(
                          'Coach: ${batch.assignedCoachName ?? 'Unassigned'}',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          'Enrolled: ${batch.enrolledCount}/${batch.capacity}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Available Seats: ${batch.availableSeats}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: batch.isFull
                                ? AppColors.error
                                : AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () =>
                              _showBatchDetailsDialog(context, state, batch),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('View Batch'),
                        ),
                        if (state.canManageBatches) ...[
                          const SizedBox(width: AppSpacing.xs),
                          OutlinedButton.icon(
                            onPressed: () => _showBatchDialog(
                              context,
                              state: state,
                              branch: branch,
                              existing: batch,
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit Batch'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _showBranchDialog(
    BuildContext context, {
    AcademyBranch? existing,
  }) async {
    final cubit = context.read<AcademyCubit>();
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final contactCtrl =
        TextEditingController(text: existing?.contactPerson ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(existing == null ? 'Add Branch' : 'Edit Branch'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Branch Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: contactCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Address *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final ok = existing == null
                  ? await cubit.createBranch(
                      name: nameCtrl.text,
                      contactPerson: contactCtrl.text,
                      address: addressCtrl.text,
                    )
                  : await cubit.updateBranch(
                      branchId: existing.id,
                      name: nameCtrl.text,
                      contactPerson: contactCtrl.text,
                      address: addressCtrl.text,
                    );
              if (ok && dialogCtx.mounted) Navigator.of(dialogCtx).pop();
            },
            child: Text(existing == null ? 'Create Branch' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBatchDialog(
    BuildContext context, {
    required AcademyLoaded state,
    required AcademyBranch branch,
    AcademyBatch? existing,
  }) async {
    final cubit = context.read<AcademyCubit>();
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final startCtrl =
        TextEditingController(text: existing?.startTime ?? '06:00 PM');
    final endCtrl =
        TextEditingController(text: existing?.endTime ?? '07:30 PM');
    final capCtrl =
        TextEditingController(text: '${existing?.capacity ?? 10}');
    var selectedBranchId = existing?.branchId ?? branch.id;
    var selectedSkill = existing?.skillLevel ?? BatchSkillLevel.beginner;
    final selectedDays = <String>{
      ...(existing?.daysOfWeek ?? const ['Mon', 'Wed', 'Fri']),
    };
    var selectedCoachId = existing?.assignedCoachId;

    final approvedCoaches = state.data.coachAffiliations
        .where((c) => c.status == CoachAffiliationStatus.accepted)
        .toList();

    const allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Batch' : 'Edit Batch'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Batch Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: selectedBranchId,
                    decoration: const InputDecoration(
                      labelText: 'Branch *',
                      border: OutlineInputBorder(),
                    ),
                    items: state.scopedBranches
                        .map((b) => DropdownMenuItem(
                              value: b.id,
                              child: Text(b.name),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedBranchId = v);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<BatchSkillLevel>(
                    initialValue: selectedSkill,
                    decoration: const InputDecoration(
                      labelText: 'Skill Level *',
                      border: OutlineInputBorder(),
                    ),
                    items: BatchSkillLevel.values
                        .map((level) => DropdownMenuItem(
                              value: level,
                              child: Text(level.label),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedSkill = v);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Days of the Week *',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: allDays.map((day) {
                      final active = selectedDays.contains(day);
                      return FilterChip(
                        label: Text(day),
                        selected: active,
                        onSelected: (v) => setDialogState(() {
                          if (v) {
                            selectedDays.add(day);
                          } else if (selectedDays.length > 1) {
                            selectedDays.remove(day);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: startCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Start Time *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: endCtrl,
                          decoration: const InputDecoration(
                            labelText: 'End Time *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: capCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Maximum Player Capacity *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final parsed = int.tryParse(v ?? '');
                      return (parsed == null || parsed <= 0)
                          ? 'Enter valid capacity'
                          : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedCoachId,
                    decoration: const InputDecoration(
                      labelText: 'Assigned Coach (Approved)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ...approvedCoaches.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c.coachId,
                          child: Text(c.coachName),
                        ),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => selectedCoachId = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final days =
                    allDays.where((d) => selectedDays.contains(d)).toList();
                final capacity = int.parse(capCtrl.text.trim());
                final ok = existing == null
                    ? await cubit.createBatch(
                        branchId: selectedBranchId,
                        name: nameCtrl.text,
                        skillLevel: selectedSkill,
                        daysOfWeek: days,
                        startTime: startCtrl.text,
                        endTime: endCtrl.text,
                        capacity: capacity,
                        assignedCoachId: selectedCoachId,
                      )
                    : await cubit.updateBatch(
                        batchId: existing.id,
                        branchId: selectedBranchId,
                        name: nameCtrl.text,
                        skillLevel: selectedSkill,
                        daysOfWeek: days,
                        startTime: startCtrl.text,
                        endTime: endCtrl.text,
                        capacity: capacity,
                        assignedCoachId: selectedCoachId,
                      );
                if (ok && dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: Text(existing == null ? 'Add Batch' : 'Save Batch'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBatchDetailsDialog(
    BuildContext context,
    AcademyLoaded state,
    AcademyBatch batch,
  ) async {
    final enrolledStudents = state.data.students
        .where((s) =>
            s.batchId == batch.id &&
            s.enrollmentStatus == EnrollmentRequestStatus.approved)
        .toList();
    final enrolledRecords = state.data.enrollments
        .where((e) =>
            e.batchId == batch.id &&
            e.status == EnrollmentRequestStatus.approved)
        .toList();

    final playerNames = <String>{
      ...enrolledStudents.map((s) => s.name),
      ...enrolledRecords.map((e) => e.studentName),
    }.toList();

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(batch.name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Branch: ${batch.branchName}'),
              Text('Skill Level: ${batch.skillLevel.label}'),
              Text('Schedule: ${batch.scheduleLabel}'),
              Text('Assigned Coach: ${batch.assignedCoachName ?? 'Unassigned'}'),
              Text(
                'Capacity: ${batch.enrolledCount}/${batch.capacity} '
                '(${batch.availableSeats} seats available)',
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Enrolled Players',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (playerNames.isEmpty)
                const Text('No enrolled players yet.')
              else
                ...playerNames.map(
                  (name) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Text(name),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
