import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';

/// Shared branch-scoping filter chips used across Academy screens.
class AcademyBranchFilterBar extends StatelessWidget {
  final List<AcademyBranch> branches;
  final String? selectedBranchId;
  final ValueChanged<String?> onBranchSelected;

  const AcademyBranchFilterBar({
    super.key,
    required this.branches,
    required this.selectedBranchId,
    required this.onBranchSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (branches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        ChoiceChip(
          label: const Text('All Branches'),
          selected: selectedBranchId == null,
          onSelected: (_) => onBranchSelected(null),
        ),
        ...branches.map(
          (branch) => ChoiceChip(
            label: Text(branch.name),
            selected: selectedBranchId == branch.id,
            onSelected: (_) => onBranchSelected(branch.id),
          ),
        ),
      ],
    );
  }
}
