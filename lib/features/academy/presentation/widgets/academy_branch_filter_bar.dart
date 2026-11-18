import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';

/// Compact horizontal branch-scoping filter bar used across Academy screens.
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All Branches'),
            selected: selectedBranchId == null,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onSelected: (_) => onBranchSelected(null),
          ),
          ...branches.map(
            (branch) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.xs),
              child: ChoiceChip(
                label: Text(branch.name),
                selected: selectedBranchId == branch.id,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onSelected: (_) => onBranchSelected(branch.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
