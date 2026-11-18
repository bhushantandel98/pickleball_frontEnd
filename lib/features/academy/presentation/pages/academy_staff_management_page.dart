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
          onPressed: () => _showStaffDialog(context, state: state),
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Add Staff'),
        );
      },
      bodyBuilder: (context, state) {
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

        if (staffList.isEmpty) {
          return EmptyStateView(
            icon: const Icon(Icons.manage_accounts_outlined),
            title: 'No Staff Members',
            message: 'Add staff members and assign branch permissions.',
            actionLabel: 'Add Staff',
            onAction: () => _showStaffDialog(context, state: state),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: staffList.map((member) {
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
                        onPressed: () => _showStaffDialog(
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
          }).toList(),
        );
      },
    );
  }

  Future<void> _showStaffDialog(
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
}
