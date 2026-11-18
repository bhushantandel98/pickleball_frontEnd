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
import 'package:pickleball_platform/features/academy_staff/domain/entities/academy_staff_entities.dart';

/// Academy Admin-only Staff Management screen (Roles, Branch Access & Permissions).
class AcademyStaffManagementPage extends StatelessWidget {
  final AcademyCubit? cubit;
  final String academyId;

  const AcademyStaffManagementPage({
    super.key,
    this.cubit,
    this.academyId = 'acad_001',
  });

  @override
  Widget build(BuildContext context) {
    return AcademyPageScaffold(
      cubit: cubit,
      academyId: academyId,
      title: 'Staff Management',
      subtitle:
          'Add academy staff, assign branch access, and delegate granular operational permissions.',
      headerActionBuilder: (context, state) {
        if (!state.canManageStaff) return const SizedBox.shrink();
        return FilledButton.icon(
          onPressed: () => showAcademyStaffDialog(context, state: state),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Add Staff'),
        );
      },
      bodyBuilder: (context, state) => AcademyStaffManagementSection(state: state),
    );
  }
}

/// Reusable Staff Management body widget (used inside Enrollment tab & standalone route).
class AcademyStaffManagementSection extends StatelessWidget {
  final AcademyLoaded state;

  const AcademyStaffManagementSection({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    if (!state.canManageStaff) {
      return const EmptyStateView(
        icon: Icon(Icons.lock_outline),
        title: 'Academy Admin Only',
        message:
            'Staff members cannot manage staff roles, branch access, or permissions.',
      );
    }

    final theme = Theme.of(context);
    final staffList = state.data.staffMembers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Academy Staff (${staffList.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            FilledButton.icon(
              onPressed: () => showAcademyStaffDialog(context, state: state),
              icon: const Icon(Icons.person_add_outlined, size: 18),
              label: const Text('Add Staff'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (staffList.isEmpty)
          EmptyStateView(
            icon: const Icon(Icons.manage_accounts_outlined),
            title: 'No Staff Members',
            message: 'Add staff members and assign branch permissions.',
            actionLabel: 'Add Staff',
            onAction: () => showAcademyStaffDialog(context, state: state),
          )
        else
          ...staffList.map((member) {
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
                                '${member.name} • ${member.roleTitle}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${member.email}${member.phone.isNotEmpty ? ' • ${member.phone}' : ''}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AppChip.neutral(
                          label: member.isActive ? 'Active' : 'Inactive',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Assigned Branches: ${member.assignedBranchNames.join(', ')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: member.permissions
                          .map((p) => AppChip.info(label: p.label))
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () => showAcademyStaffDialog(
                          context,
                          state: state,
                          existing: member,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Permissions & Branches'),
                      ),
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

Future<void> showAcademyStaffDialog(
  BuildContext context, {
  required AcademyLoaded state,
  AcademyStaffMember? existing,
}) async {
    final cubit = context.read<AcademyCubit>();
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final roleCtrl = TextEditingController(
      text: existing?.roleTitle ?? 'Branch Coordinator',
    );
    final selectedBranches = <String>{
      ...(existing?.assignedBranchIds ??
          (state.data.branches.isNotEmpty ? [state.data.branches.first.id] : [])),
    };
    final selectedPermissions = <AcademyStaffPermission>{
      ...(existing?.permissions ??
          {
            AcademyStaffPermission.viewDashboard,
            AcademyStaffPermission.viewStudents,
          }),
    };
    var isActive = existing?.isActive ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Staff Member' : 'Edit Staff'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (existing == null) ...[
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    TextFormField(
                      controller: roleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Role Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Assigned Branches',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    ...state.data.branches.map(
                      (b) => CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(b.name),
                        value: selectedBranches.contains(b.id),
                        onChanged: (v) => setDialogState(() {
                          if (v == true) {
                            selectedBranches.add(b.id);
                          } else {
                            selectedBranches.remove(b.id);
                          }
                        }),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Delegated Permissions',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    ...AcademyStaffPermission.values.map(
                      (perm) => CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(perm.label),
                        value: selectedPermissions.contains(perm),
                        onChanged: (v) => setDialogState(() {
                          if (v == true) {
                            selectedPermissions.add(perm);
                          } else {
                            selectedPermissions.remove(perm);
                          }
                        }),
                      ),
                    ),
                    if (existing != null)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Staff Account Active'),
                        activeThumbColor: AppColors.primary,
                        value: isActive,
                        onChanged: (v) => setDialogState(() => isActive = v),
                      ),
                  ],
                ),
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
                if (selectedBranches.isEmpty) return;
                final ok = existing == null
                    ? await cubit.addStaffMember(
                        name: nameCtrl.text,
                        email: emailCtrl.text,
                        phone: phoneCtrl.text,
                        roleTitle: roleCtrl.text,
                        assignedBranchIds: selectedBranches.toList(),
                        permissions: selectedPermissions,
                      )
                    : await cubit.updateStaffMember(
                        staffId: existing.staffId,
                        roleTitle: roleCtrl.text,
                        assignedBranchIds: selectedBranches.toList(),
                        permissions: selectedPermissions,
                        isActive: isActive,
                      );
                if (ok && dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: Text(existing == null ? 'Add Staff' : 'Save'),
            ),
          ],
        ),
      ),
    );
}
