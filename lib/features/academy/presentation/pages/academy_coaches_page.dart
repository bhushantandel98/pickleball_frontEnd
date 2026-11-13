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

/// Academy Coach Staff Directory & Affiliations page (Phase 3 — Feature 3.5).
class AcademyCoachesPage extends StatelessWidget {
  final AcademyCubit? cubit;
  final String academyId;

  const AcademyCoachesPage({
    super.key,
    this.cubit,
    this.academyId = 'acad_001',
  });

  @override
  Widget build(BuildContext context) {
    return AcademyPageScaffold(
      cubit: cubit,
      academyId: academyId,
      title: 'Coach Staff Directory',
      subtitle:
          'Manage academy coach invitations, branch assignments, and official schedule permissions. Personal coaching records remain private to each coach.',
      headerActionBuilder: (context, state) => FilledButton.icon(
        onPressed: state.data.branches.isEmpty
            ? null
            : () => _showInviteCoachDialog(context, state),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Invite Coach'),
      ),
      bodyBuilder: (context, state) {
        final cubit = context.read<AcademyCubit>();
        final theme = Theme.of(context);
        final affiliations = state.scopedAffiliations;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AcademyBranchFilterBar(
              branches: state.data.branches,
              selectedBranchId: state.selectedBranchId,
              onBranchSelected: cubit.selectBranch,
            ),
            const SizedBox(height: AppSpacing.md),
            if (affiliations.isEmpty)
              EmptyStateView(
                icon: const Icon(Icons.sports_outlined),
                title: 'No Affiliated Coaches',
                message:
                    'Invite a coach and assign branches. Coaches must accept invitations before becoming active.',
                actionLabel:
                    state.data.branches.isEmpty ? null : 'Invite Coach',
                onAction: state.data.branches.isEmpty
                    ? null
                    : () => _showInviteCoachDialog(context, state),
              )
            else
              ...affiliations.map((aff) {
                final statusColor = switch (aff.status) {
                  CoachAffiliationStatus.accepted => AppColors.success,
                  CoachAffiliationStatus.pendingAcceptance => AppColors.warning,
                  CoachAffiliationStatus.declined => AppColors.error,
                  CoachAffiliationStatus.revoked =>
                    theme.colorScheme.onSurfaceVariant,
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
                                aff.status.label,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(
                                aff.canModifyOfficialSchedule
                                    ? 'Schedule Edit Permitted'
                                    : 'Read-only Official Schedule',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          aff.coachName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${aff.specialization} • ${aff.coachContact}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Assigned Branches: ${aff.assignedBranchNames.join(', ')}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (aff.status == CoachAffiliationStatus.accepted ||
                            aff.status ==
                                CoachAffiliationStatus.pendingAcceptance) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _showAssignmentDialog(
                                  context,
                                  state,
                                  aff,
                                ),
                                icon: const Icon(Icons.tune, size: 16),
                                label: const Text('Assign Branches'),
                              ),
                              TextButton.icon(
                                onPressed: () =>
                                    cubit.revokeCoachAffiliation(aff.id),
                                icon: Icon(
                                  Icons.link_off,
                                  size: 16,
                                  color: theme.colorScheme.error,
                                ),
                                label: Text(
                                  'Revoke',
                                  style:
                                      TextStyle(color: theme.colorScheme.error),
                                ),
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

  Future<void> _showInviteCoachDialog(
    BuildContext context,
    AcademyLoaded state,
  ) async {
    final cubit = context.read<AcademyCubit>();
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final specController = TextEditingController();
    final selectedBranches = <String>{state.data.branches.first.id};
    bool canModifySchedule = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Invite Coach'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Coach Name'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: contactController,
                    decoration:
                        const InputDecoration(labelText: 'Contact / Phone'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: specController,
                    decoration:
                        const InputDecoration(labelText: 'Specialization'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Assign Branches'),
                  ...state.data.branches.map(
                    (b) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(b.name),
                      value: selectedBranches.contains(b.id),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selectedBranches.add(b.id);
                          } else {
                            selectedBranches.remove(b.id);
                          }
                        });
                      },
                    ),
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Permit Official Schedule Edits'),
                    value: canModifySchedule,
                    onChanged: (val) =>
                        setState(() => canModifySchedule = val),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: AppSpacing.xs),
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
                if (nameController.text.trim().isEmpty ||
                    selectedBranches.isEmpty) {
                  setState(
                    () => errorText =
                        'Coach name and at least one branch are required.',
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                await cubit.inviteCoach(
                  coachName: nameController.text.trim(),
                  coachContact: contactController.text.trim(),
                  specialization: specController.text.trim(),
                  branchIds: selectedBranches.toList(),
                  canModifyOfficialSchedule: canModifySchedule,
                );
              },
              child: const Text('Send Invitation'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignmentDialog(
    BuildContext context,
    AcademyLoaded state,
    AcademyCoachAffiliation aff,
  ) async {
    final cubit = context.read<AcademyCubit>();
    final selectedBranches = Set<String>.from(aff.assignedBranchIds);
    bool canModifySchedule = aff.canModifyOfficialSchedule;
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Assignments — ${aff.coachName}'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...state.data.branches.map(
                    (b) => CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(b.name),
                      value: selectedBranches.contains(b.id),
                      onChanged: (checked) {
                        setState(() {
                          if (checked == true) {
                            selectedBranches.add(b.id);
                          } else {
                            selectedBranches.remove(b.id);
                          }
                        });
                      },
                    ),
                  ),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Permit Official Schedule Edits'),
                    value: canModifySchedule,
                    onChanged: (val) =>
                        setState(() => canModifySchedule = val),
                  ),
                  if (errorText != null)
                    Text(
                      errorText!,
                      style: TextStyle(
                        color: Theme.of(ctx).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
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
                if (selectedBranches.isEmpty) {
                  setState(
                    () => errorText = 'Select at least one assigned branch.',
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                await cubit.updateCoachAssignment(
                  affiliationId: aff.id,
                  branchIds: selectedBranches.toList(),
                  canModifyOfficialSchedule: canModifySchedule,
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
