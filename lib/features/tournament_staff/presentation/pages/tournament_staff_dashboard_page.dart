import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/tournament_staff/domain/entities/tournament_staff_entities.dart';
import 'package:pickleball_platform/features/tournament_staff/presentation/cubit/tournament_staff_cubit.dart';
import 'package:pickleball_platform/features/tournament_staff/presentation/cubit/tournament_staff_state.dart';
import 'package:pickleball_platform/features/tournament_staff/presentation/widgets/tournament_staff_page_scaffold.dart';

/// Tournament Staff Dashboard scoped to the assigned tournament and delegated
/// permissions (Phase 5 — Feature 5.2).
class TournamentStaffDashboardPage extends StatelessWidget {
  final TournamentStaffCubit? cubit;
  final String? tournamentId;
  final String? staffId;

  const TournamentStaffDashboardPage({
    super.key,
    this.cubit,
    this.tournamentId,
    this.staffId,
  });

  @override
  Widget build(BuildContext context) {
    return TournamentStaffPageScaffold(
      cubit: cubit,
      tournamentId: tournamentId,
      staffId: staffId,
      title: 'Tournament Staff Dashboard',
      subtitle:
          'Assigned tournament Match Day monitoring, participant check-in & delegated operations.',
      bodyBuilder: (context, state) {
        if (!state.hasPermission(TournamentStaffPermission.viewDashboard)) {
          return const EmptyStateView(
            title: 'Dashboard Restricted',
            message:
                'Your Tournament Organizer has not delegated dashboard access to your account.',
          );
        }

        final theme = Theme.of(context);
        final profile = state.staffProfile;
        final canOperate = state
                .hasPermission(TournamentStaffPermission.manageCheckIn) ||
            state.hasPermission(TournamentStaffPermission.manageReferees) ||
            state.hasPermission(TournamentStaffPermission.editMatchScore);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.tournamentName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${profile.venueName} • ${profile.staffName} (${profile.roleTitle})',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Delegated Permissions (Read-Only)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: profile.permissions
                        .map(
                          (perm) => Chip(
                            label: Text(perm.label),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildKpiGrid(context, state),
            const SizedBox(height: AppSpacing.md),
            if (canOperate)
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilledButton.icon(
                      onPressed: () =>
                          context.go(AppRoutes.tournamentStaffOperations),
                      icon: const Icon(Icons.assignment_turned_in_outlined),
                      label: const Text('Open Check-in & Match Operations'),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            _buildLiveMatchesSummary(context, theme, state),
          ],
        );
      },
    );
  }

  Widget _buildKpiGrid(BuildContext context, TournamentStaffLoaded state) {
    final cards = [
      _KpiTile(
        label: 'Entries',
        value: '${state.data.checkIns.length}',
        icon: Icons.groups_outlined,
        color: AppColors.primary,
      ),
      _KpiTile(
        label: 'Checked In',
        value: '${state.checkedInCount}',
        icon: Icons.how_to_reg_outlined,
        color: AppColors.success,
      ),
      _KpiTile(
        label: 'Assigned Matches',
        value: '${state.data.matches.length}',
        icon: Icons.sports_tennis,
        color: AppColors.warning,
      ),
      _KpiTile(
        label: 'Active Referees',
        value: '${state.activeRefereesCount}',
        icon: Icons.sports_outlined,
        color: AppColors.info,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : (constraints.maxWidth >= 560 ? 2 : 1);
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * AppSpacing.sm) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: cards
              .map((c) => SizedBox(width: itemWidth, child: c))
              .toList(),
        );
      },
    );
  }

  Widget _buildLiveMatchesSummary(
    BuildContext context,
    ThemeData theme,
    TournamentStaffLoaded state,
  ) {
    final matches = state.data.matches;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tournament Matches (${matches.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (matches.isEmpty)
            const EmptyStateView(
              title: 'No Scheduled Matches',
              message: 'No matches are scheduled for this tournament yet.',
            )
          else
            ...matches.map(
              (m) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${m.participantA} vs ${m.participantB}'),
                subtitle: Text(
                  '${m.categoryName} • ${m.roundLabel} • ${m.courtName ?? 'Unassigned Court'}'
                  '${m.refereeName != null ? ' • Ref: ${m.refereeName}' : ''}'
                  '${m.scoreSummary != null ? ' • Score: ${m.scoreSummary}' : ''}',
                ),
                trailing: Chip(
                  label: Text(m.status.label),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
