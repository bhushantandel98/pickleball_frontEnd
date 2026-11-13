import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_cubit.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_page_scaffold.dart';

/// Academy Branch Facilities management page (Phase 3 — Feature 3.5).
class AcademyBranchesPage extends StatelessWidget {
  final AcademyCubit? cubit;
  final String academyId;

  const AcademyBranchesPage({
    super.key,
    this.cubit,
    this.academyId = 'acad_001',
  });

  @override
  Widget build(BuildContext context) {
    return AcademyPageScaffold(
      cubit: cubit,
      academyId: academyId,
      title: 'Branch Facilities',
      subtitle: 'Manage academy-owned branches, court counts, and operating hours.',
      headerActionBuilder: (context, _) => FilledButton.icon(
        onPressed: () => _showBranchDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Branch'),
      ),
      bodyBuilder: (context, state) {
        final cubit = context.read<AcademyCubit>();
        final branches = state.data.branches;
        final theme = Theme.of(context);

        if (branches.isEmpty) {
          return EmptyStateView(
            icon: const Icon(Icons.store_outlined),
            title: 'No Branches Configured',
            message: 'Add your first academy branch to set up programs and batches.',
            actionLabel: 'Add Branch',
            onAction: () => _showBranchDialog(context),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: branches.map((branch) {
            final batchCount = state.data.batches
                .where((b) => b.branchId == branch.id)
                .length;
            final coachCount = state.data.coachAffiliations
                .where((c) =>
                    c.status == CoachAffiliationStatus.accepted &&
                    c.assignedBranchIds.contains(branch.id))
                .length;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                                branch.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${branch.city} • ${branch.address}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: branch.isActive,
                          onChanged: (val) =>
                              cubit.toggleBranchStatus(branch.id, val),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Chip(
                          label: Text(
                            branch.isActive ? 'Active' : 'Paused',
                            style: TextStyle(
                              color: branch.isActive
                                  ? AppColors.success
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Chip(label: Text('${branch.courtCount} Courts')),
                        Chip(label: Text('$batchCount Batches')),
                        Chip(label: Text('$coachCount Coaches')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Hours: ${branch.operatingHours} • Phone: ${branch.contactPhone}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showBranchDialog(context, existing: branch),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Branch'),
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

  Future<void> _showBranchDialog(
    BuildContext context, {
    AcademyBranch? existing,
  }) async {
    final cubit = context.read<AcademyCubit>();
    final nameController = TextEditingController(text: existing?.name ?? '');
    final cityController = TextEditingController(text: existing?.city ?? '');
    final addressController =
        TextEditingController(text: existing?.address ?? '');
    final hoursController = TextEditingController(
      text: existing?.operatingHours ?? '06:00 AM – 10:00 PM',
    );
    final courtsController = TextEditingController(
      text: existing != null ? '${existing.courtCount}' : '4',
    );
    final phoneController =
        TextEditingController(text: existing?.contactPhone ?? '');
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(existing == null ? 'Add Branch' : 'Edit Branch'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Branch Name'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: cityController,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: hoursController,
                    decoration:
                        const InputDecoration(labelText: 'Operating Hours'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: courtsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Court Count'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: phoneController,
                    decoration:
                        const InputDecoration(labelText: 'Contact Phone'),
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
                final courts = int.tryParse(courtsController.text.trim());
                if (nameController.text.trim().isEmpty ||
                    cityController.text.trim().isEmpty ||
                    addressController.text.trim().isEmpty ||
                    courts == null ||
                    courts <= 0) {
                  setState(
                    () => errorText =
                        'Enter branch name, city, address, and a valid court count.',
                  );
                  return;
                }
                Navigator.of(dialogContext).pop();
                if (existing == null) {
                  await cubit.createBranch(
                    name: nameController.text.trim(),
                    city: cityController.text.trim(),
                    address: addressController.text.trim(),
                    operatingHours: hoursController.text.trim(),
                    courtCount: courts,
                    contactPhone: phoneController.text.trim(),
                  );
                } else {
                  await cubit.updateBranch(
                    branchId: existing.id,
                    name: nameController.text.trim(),
                    city: cityController.text.trim(),
                    address: addressController.text.trim(),
                    operatingHours: hoursController.text.trim(),
                    courtCount: courts,
                    contactPhone: phoneController.text.trim(),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
