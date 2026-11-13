import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/venue_partner/domain/entities/venue_partner_entities.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/bloc/venue_partner_cubit.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/widgets/venue_location_filter_bar.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/widgets/venue_partner_page_scaffold.dart';

/// Primary Venue Partner Dashboard (Phase 3 — Feature 3.7).
class VenuePartnerDashboardPage extends StatelessWidget {
  final VenuePartnerCubit? cubit;
  final String partnerId;

  const VenuePartnerDashboardPage({
    super.key,
    this.cubit,
    this.partnerId = 'org_venue_001',
  });

  @override
  Widget build(BuildContext context) {
    return VenuePartnerPageScaffold(
      cubit: cubit,
      partnerId: partnerId,
      title: 'Venue Partner Dashboard',
      subtitle:
          'Multi-location courts, booking rules, availability blocks, offline payments, staff & expenses.',
      bodyBuilder: (context, state) {
        final cubit = context.read<VenuePartnerCubit>();
        final theme = Theme.of(context);
        final profile = state.data.profile;

        final pendingBookings = state.data.bookings
            .where((b) =>
                (state.selectedLocationId == null ||
                    b.locationId == state.selectedLocationId) &&
                b.status == PartnerBookingStatus.pending)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
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
                    'Owner: ${profile.ownerName} • ${profile.contactEmail} • ${profile.contactPhone}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  VenueLocationFilterBar(
                    locations: state.data.locations,
                    selectedLocationId: state.selectedLocationId,
                    onLocationSelected: cubit.selectLocation,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 4
                    : (constraints.maxWidth >= 560 ? 2 : 1);
                final cardWidth =
                    (constraints.maxWidth - (AppSpacing.sm * (columns - 1))) /
                        columns;

                final metrics = [
                  _PartnerMetric(
                    label: 'Active Locations / Courts',
                    value:
                        '${state.activeLocationCount} / ${state.activeCourtCount}',
                    icon: Icons.place_outlined,
                    color: theme.colorScheme.primary,
                    route: AppRoutes.venuePartnerLocations,
                  ),
                  _PartnerMetric(
                    label: 'Pending Approvals',
                    value: '${state.pendingBookingCount}',
                    icon: Icons.pending_actions_outlined,
                    color: AppColors.warning,
                    route: AppRoutes.venuePartnerBookings,
                  ),
                  _PartnerMetric(
                    label: 'Collected (Offline)',
                    value:
                        '₹${state.collectedOfflineRevenueInr.toStringAsFixed(0)}',
                    icon: Icons.payments_outlined,
                    color: AppColors.success,
                    route: AppRoutes.venuePartnerBookings,
                  ),
                  _PartnerMetric(
                    label: 'Expenses Logged',
                    value: '₹${state.totalExpensesInr.toStringAsFixed(0)}',
                    icon: Icons.receipt_long_outlined,
                    color: theme.colorScheme.secondary,
                    route: AppRoutes.venuePartnerLocations,
                  ),
                ];

                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: metrics.map((m) {
                    return SizedBox(
                      width: cardWidth,
                      child: AppCard(
                        onTap: () => context.go(m.route),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(m.icon, color: m.color),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              m.value,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              m.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pending Booking Requests',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            context.go(AppRoutes.venuePartnerBookings),
                        child: const Text('View All Bookings'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (pendingBookings.isEmpty)
                    const EmptyStateView(
                      icon: Icon(Icons.check_circle_outline),
                      title: 'No Pending Requests',
                      message:
                          'All court booking requests for this location filter have been reviewed.',
                    )
                  else
                    ...pendingBookings.map(
                      (bkg) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${bkg.playerName} • ${bkg.courtName}',
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${bkg.locationName} • ₹${bkg.amountInr.toStringAsFixed(0)}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Wrap(
                                spacing: AppSpacing.xs,
                                children: [
                                  FilledButton.tonal(
                                    onPressed: () => cubit.updateBookingStatus(
                                      bookingId: bkg.id,
                                      newStatus: PartnerBookingStatus.confirmed,
                                    ),
                                    child: const Text('Confirm'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => cubit.updateBookingStatus(
                                      bookingId: bkg.id,
                                      newStatus: PartnerBookingStatus.declined,
                                    ),
                                    child: const Text('Decline'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business & Operational Summary (V1 Offline Accounting)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Collected at Venue: ₹${state.collectedOfflineRevenueInr.toStringAsFixed(0)} • '
                    'Pending Verification/Unpaid: ₹${state.pendingOfflineRevenueInr.toStringAsFixed(0)} • '
                    'Expenses: ₹${state.totalExpensesInr.toStringAsFixed(0)} • '
                    'Active Staff: ${state.scopedStaff.where((s) => s.isActive).length}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PartnerMetric {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String route;

  const _PartnerMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.route,
  });
}
