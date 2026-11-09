import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';

/// Card presenting public academy branch information.
///
/// Complies with strict PRD privacy constraints: public listings show only
/// permitted branch details (name, location, timings, courts). Fees and roster data are hidden.
class AcademyBranchCard extends StatelessWidget {
  final AcademyBranch branch;
  final VoidCallback onTap;

  const AcademyBranchCard({
    super.key,
    required this.branch,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Academy Name & City Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branch.academyName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      branch.branchName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              AppChip.info(label: branch.city),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Address
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  branch.address,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Operating Hours (Public Timing Information)
          Row(
            children: [
              Icon(
                Icons.access_time_outlined,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  branch.operatingHours,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Meta info (Courts, Head Coach, Programs count)
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: 4,
            children: [
              if (branch.courtCount > 0)
                AppChip(label: '${branch.courtCount} Courts'),
              if (branch.headCoachName.isNotEmpty)
                AppChip(label: 'Lead: ${branch.headCoachName}'),
              AppChip.info(
                label: '${branch.programs.length} Program${branch.programs.length == 1 ? '' : 's'}',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Action button
          SizedBox(
            width: double.infinity,
            child: AppButton.secondary(
              label: 'View Programs & Batches',
              onPressed: onTap,
              icon: const Icon(Icons.school_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
