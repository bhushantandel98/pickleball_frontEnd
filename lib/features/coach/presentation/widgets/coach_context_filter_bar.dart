import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_dashboard_data.dart';

/// Context, accepted academy, and assigned branch filter bar for Coach Dashboard.
class CoachContextFilterBar extends StatelessWidget {
  final CoachDashboardFilter filter;
  final List<AcademyAffiliationSummary> acceptedAffiliations;
  final List<AssignedBranchSummary> availableBranches;
  final ValueChanged<CoachContextType> onContextChanged;
  final ValueChanged<String?> onAcademySelected;
  final ValueChanged<String?> onBranchSelected;

  const CoachContextFilterBar({
    super.key,
    required this.filter,
    required this.acceptedAffiliations,
    required this.availableBranches,
    required this.onContextChanged,
    required this.onAcademySelected,
    required this.onBranchSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Coaching Context',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              ChoiceChip(
                key: const Key('coach_filter_all'),
                label: const Text('All Contexts'),
                selected: filter.contextType == CoachContextType.all,
                onSelected: (_) => onContextChanged(CoachContextType.all),
              ),
              ChoiceChip(
                key: const Key('coach_filter_personal'),
                label: const Text('Personal Coaching'),
                selected: filter.contextType == CoachContextType.personal,
                onSelected: (_) => onContextChanged(CoachContextType.personal),
              ),
              ChoiceChip(
                key: const Key('coach_filter_academy'),
                label: const Text('Academy'),
                selected: filter.contextType == CoachContextType.academy,
                onSelected: (_) => onContextChanged(CoachContextType.academy),
              ),
            ],
          ),
          if (filter.contextType == CoachContextType.academy) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Accepted Academies',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (acceptedAffiliations.isEmpty)
              Text(
                'No accepted academy affiliations.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  ChoiceChip(
                    key: const Key('coach_filter_academy_all'),
                    label: const Text('All Academies'),
                    selected: filter.selectedAcademyId == null,
                    onSelected: (_) => onAcademySelected(null),
                  ),
                  for (final academy in acceptedAffiliations)
                    ChoiceChip(
                      key: Key('coach_filter_academy_${academy.academyId}'),
                      label: Text(academy.academyName),
                      selected: filter.selectedAcademyId == academy.academyId,
                      onSelected: (_) => onAcademySelected(academy.academyId),
                    ),
                ],
              ),
          ],
          if (filter.contextType == CoachContextType.academy &&
              filter.selectedAcademyId != null &&
              availableBranches.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Assigned Branches',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                ChoiceChip(
                  key: const Key('coach_filter_branch_all'),
                  label: const Text('All Assigned Branches'),
                  selected: filter.selectedBranchId == null,
                  onSelected: (_) => onBranchSelected(null),
                ),
                for (final branch in availableBranches)
                  ChoiceChip(
                    key: Key('coach_filter_branch_${branch.branchId}'),
                    label: Text(branch.branchName),
                    selected: filter.selectedBranchId == branch.branchId,
                    onSelected: (_) => onBranchSelected(branch.branchId),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
