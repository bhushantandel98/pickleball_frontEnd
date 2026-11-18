import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/application_admin/presentation/bloc/application_admin_cubit.dart';
import 'package:pickleball_platform/features/application_admin/presentation/widgets/application_admin_scaffold.dart';
import 'package:pickleball_platform/features/application_staff/domain/entities/application_staff_entities.dart';

/// Feature 7.2 — Application Staff Management & Capability Scopes.
class ApplicationAdminStaffPage extends StatelessWidget {
  final ApplicationAdminCubit? cubit;
  final String? adminUserId;

  const ApplicationAdminStaffPage({
    super.key,
    this.cubit,
    this.adminUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ApplicationAdminScaffold(
      cubit: cubit,
      adminUserId: adminUserId,
      title: 'Staff Management & Scopes',
      subtitle:
          'Delegate Application Staff permissions and authorized organization scopes.',
      actionsBuilder: (context, _) => [
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.applicationAdminDashboard),
          icon: const Icon(Icons.dashboard_outlined),
          label: const Text('Dashboard'),
        ),
      ],
      bodyBuilder: (context, state) {
        final theme = Theme.of(context);
        final adminCubit = context.read<ApplicationAdminCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.info),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Single Application Admin Policy (ADR-007): Additional Application Admin accounts cannot be created. Use this screen only to manage Application Staff permissions, organization scopes, and active status.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.staffProfiles.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final staff = state.staffProfiles[index];
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${staff.staffName} (${staff.roleTitle})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Chip(
                            label: Text(staff.isActive ? 'Active' : 'Inactive'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Staff ID: ${staff.staffId} • Email: ${staff.staffEmail}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Authorized Organizations (${staff.authorizedOrganizationIds.length}): ${staff.authorizedOrganizationIds.isEmpty ? 'None' : staff.authorizedOrganizationIds.join(', ')}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: staff.permissions
                            .map((p) => Chip(label: Text(p.label)))
                            .toList(),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton.icon(
                        onPressed: state.isMutating
                            ? null
                            : () => _showEditStaffDialog(
                                  context,
                                  adminCubit,
                                  staff,
                                ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit Permissions & Scope'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditStaffDialog(
    BuildContext context,
    ApplicationAdminCubit cubit,
    ApplicationStaffProfile staff,
  ) async {
    var selectedPerms = Set<ApplicationStaffPermission>.from(staff.permissions);
    var isActive = staff.isActive;
    final orgsCtrl = TextEditingController(
      text: staff.authorizedOrganizationIds.join(', '),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Staff Access — ${staff.staffName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active Staff Assignment'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text('Delegated Permissions:'),
                ...ApplicationStaffPermission.values.map((perm) {
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(perm.label),
                    value: selectedPerms.contains(perm),
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          selectedPerms.add(perm);
                        } else {
                          selectedPerms.remove(perm);
                        }
                      });
                    },
                  );
                }),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: orgsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Authorized Organization IDs (comma-separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save Access'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final orgIds = orgsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toSet();
      await cubit.updateStaffAccess(
        staffId: staff.staffId,
        permissions: selectedPerms,
        authorizedOrganizationIds: orgIds,
        isActive: isActive,
      );
    }
    orgsCtrl.dispose();
  }
}
