import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/widgets/venue_location_filter_bar.dart';
import 'package:pickleball_platform/features/venue_staff/domain/entities/venue_staff_entities.dart';
import 'package:pickleball_platform/features/venue_staff/presentation/cubit/venue_staff_cubit.dart';
import 'package:pickleball_platform/features/venue_staff/presentation/cubit/venue_staff_state.dart';
import 'package:pickleball_platform/features/venue_staff/presentation/widgets/venue_staff_page_scaffold.dart';

/// Primary Venue Staff Dashboard scoped strictly to assigned locations and
/// delegated permissions (Phase 3 — Feature 3.8).
class VenueStaffDashboardPage extends StatelessWidget {
  final VenueStaffCubit? cubit;
  final String? partnerId;
  final String? staffId;

  const VenueStaffDashboardPage({
    super.key,
    this.cubit,
    this.partnerId,
    this.staffId,
  });

  @override
  Widget build(BuildContext context) {
    return VenueStaffPageScaffold(
      cubit: cubit,
      partnerId: partnerId,
      staffId: staffId,
      title: 'Venue Staff Operations',
      subtitle:
          'Assigned location courts, daily check-ins, maintenance tasks & purchase receipts.',
      bodyBuilder: (context, state) {
        if (!state.hasPermission(VenueStaffPermission.viewDashboard)) {
          return const EmptyStateView(
            title: 'Dashboard Restricted',
            message:
                'Your Venue Partner has not delegated dashboard access to your account.',
          );
        }

        final cubit = context.read<VenueStaffCubit>();
        final theme = Theme.of(context);
        final profile = state.staffProfile;
        final canSeeFinancialReport =
            state.hasPermission(VenueStaffPermission.viewReports) ||
                state.hasPermission(VenueStaffPermission.recordOfflinePayments);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
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
                              profile.partnerName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${profile.staffName} • ${profile.roleTitle} • ${profile.staffEmail}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.location_on_outlined, size: 16),
                        label: Text(
                          '${profile.assignedLocationNames.length} Assigned Location(s)',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Assigned Location Scope',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: profile.assignedLocationNames
                        .map(
                          (name) => Chip(
                            label: Text(name),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
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
                  if (state.data.assignedLocations.length > 1) ...[
                    const SizedBox(height: AppSpacing.sm),
                    VenueLocationFilterBar(
                      locations: state.data.assignedLocations,
                      selectedLocationId: state.selectedLocationId,
                      onLocationSelected: cubit.selectLocation,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildKpiGrid(context, state, canSeeFinancialReport),
            const SizedBox(height: AppSpacing.md),
            _buildQuickActions(context, state),
            const SizedBox(height: AppSpacing.md),
            _buildCourtAvailabilitySummary(context, state),
          ],
        );
      },
    );
  }

  Widget _buildKpiGrid(
    BuildContext context,
    VenueStaffLoaded state,
    bool canSeeFinancialReport,
  ) {
    final cards = <Widget>[
      _KpiTile(
        label: 'Assigned Locations',
        value: '${state.data.assignedLocations.length}',
        icon: Icons.storefront_outlined,
        color: AppColors.primary,
      ),
      _KpiTile(
        label: 'Open Tasks',
        value: '${state.openTaskCount}',
        icon: Icons.build_circle_outlined,
        color: AppColors.warning,
      ),
      _KpiTile(
        label: 'Checked-in Today',
        value: '${state.checkedInCount}',
        icon: Icons.how_to_reg_outlined,
        color: AppColors.success,
      ),
      if (canSeeFinancialReport)
        _KpiTile(
          label: 'Offline Collected',
          value: '₹${state.collectedOfflineInr.toStringAsFixed(0)}',
          icon: Icons.payments_outlined,
          color: AppColors.info,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? cards.length
            : (constraints.maxWidth >= 560 ? 2 : 1);
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * AppSpacing.sm) / columns;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: cards
              .map((card) => SizedBox(width: itemWidth, child: card))
              .toList(),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, VenueStaffLoaded state) {
    final canCheckIn =
        state.hasPermission(VenueStaffPermission.manageCheckIn) ||
            state.hasPermission(VenueStaffPermission.recordOfflinePayments);
    final canTasksOrPurchases =
        state.hasPermission(VenueStaffPermission.manageMaintenance) ||
            state.hasPermission(VenueStaffPermission.submitPurchases);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          if (canCheckIn)
            FilledButton.icon(
              onPressed: () => context.go(AppRoutes.venueStaffBookings),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Daily Check-in & Bookings'),
            ),
          if (canTasksOrPurchases)
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.venueStaffTasks),
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('Maintenance & Receipts'),
            ),
        ],
      ),
    );
  }

  Widget _buildCourtAvailabilitySummary(
    BuildContext context,
    VenueStaffLoaded state,
  ) {
    final theme = Theme.of(context);
    final courts = state.scopedCourts;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assigned Courts & Active Holds',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (courts.isEmpty)
            const EmptyStateView(
              title: 'No Assigned Courts',
              message: 'No courts are available for your assigned location(s).',
            )
          else
            ...courts.map((court) {
              final courtBlocks = state.scopedBlocks
                  .where((b) => b.courtId == court.id)
                  .toList();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  court.isActive ? Icons.sports_tennis : Icons.block,
                  color: court.isActive
                      ? AppColors.success
                      : theme.colorScheme.error,
                ),
                title: Text('${court.name} (${court.locationName})'),
                subtitle: Text(
                  '${court.surfaceType} • ${court.isIndoor ? 'Indoor' : 'Outdoor'}'
                  '${court.hasLighting ? ' • Floodlights' : ''}'
                  '${courtBlocks.isNotEmpty ? ' • ${courtBlocks.length} active hold(s)' : ''}',
                ),
                trailing: Chip(
                  label: Text(court.isActive ? 'Operational' : 'Inactive'),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }),
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
