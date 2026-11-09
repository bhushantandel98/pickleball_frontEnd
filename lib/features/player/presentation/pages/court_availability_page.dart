import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_item.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/venue_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/court_availability_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/court_availability_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/booking_summary_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/court_date_picker_strip.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/court_selector_tabs.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/court_slot_card.dart';

/// Screen allowing players to select a date, browse courts, choose a time-slot, and continue to checkout.
class CourtAvailabilityPage extends StatelessWidget {
  final String venueId;
  final CourtAvailabilityCubit? cubit;

  const CourtAvailabilityPage({
    super.key,
    required this.venueId,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<CourtAvailabilityCubit>.value(
        value: cubit!,
        child: _CourtAvailabilityView(venueId: venueId),
      );
    }

    try {
      final existing = context.read<CourtAvailabilityCubit>();
      return BlocProvider<CourtAvailabilityCubit>.value(
        value: existing,
        child: _CourtAvailabilityView(venueId: venueId),
      );
    } catch (_) {
      return BlocProvider<CourtAvailabilityCubit>(
        create: (_) => CourtAvailabilityCubit(repository: sl<VenueRepository>())
          ..loadAvailability(venueId),
        child: _CourtAvailabilityView(venueId: venueId),
      );
    }
  }
}

class _CourtAvailabilityView extends StatefulWidget {
  final String venueId;

  const _CourtAvailabilityView({required this.venueId});

  @override
  State<_CourtAvailabilityView> createState() => _CourtAvailabilityViewState();
}

class _CourtAvailabilityViewState extends State<_CourtAvailabilityView> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<CourtAvailabilityCubit>();
    if (cubit.state is CourtAvailabilityInitial) {
      cubit.loadAvailability(widget.venueId);
    }
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.playerVenueDetailsPath(widget.venueId));
    }
  }

  void _handleContinue(
    BuildContext context, {
    required VenueItem venue,
    required CourtItem court,
    required DateTime date,
    required CourtSlot slot,
  }) {
    final payload = BookingSelectionPayload(
      venueId: venue.id,
      venueName: venue.name,
      venueAddress: venue.address,
      venueCity: venue.city,
      courtId: court.id,
      courtName: court.name,
      surfaceType: court.surfaceType,
      date: date,
      slotId: slot.id,
      slotTime: slot.formattedTime,
      price: slot.price,
      durationMinutes: 60,
    );

    context.push(
      AppRoutes.playerBookingCheckout,
      extra: payload,
    );
  }

  Widget _buildStatusLegend(BuildContext context) {
    final theme = Theme.of(context);

    Widget item({required Color color, required String label, bool isSelected = false, bool isBooked = false}) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isSelected ? theme.colorScheme.primary : color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 10, color: Colors.white)
                : (isBooked ? Icon(Icons.lock, size: 9, color: theme.colorScheme.onSurfaceVariant) : null),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        item(color: theme.colorScheme.surface, label: 'Available'),
        const SizedBox(width: AppSpacing.md),
        item(color: theme.colorScheme.primary, label: 'Selected', isSelected: true),
        const SizedBox(width: AppSpacing.md),
        item(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          label: 'Booked',
          isBooked: true,
        ),
      ],
    );
  }

  Widget _buildTimeSlotsGroup(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<CourtSlot> slots,
    required CourtSlot? selectedSlot,
    required ValueChanged<CourtSlot> onSlotTapped,
  }) {
    final theme = Theme.of(context);
    if (slots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '(${slots.where((s) => s.isAvailable).length} available)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LayoutBuilder(
          builder: (context, constraints) {
            // Adaptive column count based on available width
            int crossAxisCount = 3;
            if (constraints.maxWidth > 850) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth < 460) {
              crossAxisCount = 2;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: AppSpacing.xs,
                mainAxisSpacing: AppSpacing.xs,
                mainAxisExtent: 68,
              ),
              itemCount: slots.length,
              itemBuilder: (context, index) {
                final slot = slots[index];
                return CourtSlotCard(
                  slot: slot,
                  isSelected: selectedSlot?.id == slot.id,
                  onSlotTapped: onSlotTapped,
                );
              },
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _buildMobileBottomBar(
    BuildContext context, {
    required VenueItem venue,
    required CourtItem? court,
    required DateTime date,
    required CourtSlot? slot,
  }) {
    final theme = Theme.of(context);
    final hasSelection = slot != null && court != null;
    final dateStr = DateFormat('d MMM').format(date);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasSelection
                        ? '₹${slot.price.toStringAsFixed(0)}'
                        : (court == null ? 'No courts' : 'No slot chosen'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasSelection ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    hasSelection
                        ? '${court.name} • $dateStr • ${slot.formattedTime}'
                        : (court == null ? 'No courts available for this date' : 'Choose an available slot'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            AppButton.primary(
              key: const Key('court_availability_mobile_continue_button'),
              label: 'Continue',
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              onPressed: hasSelection
                  ? () => _handleContinue(
                        context,
                        venue: venue,
                        court: court,
                        date: date,
                        slot: slot,
                      )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CourtAvailabilityCubit, CourtAvailabilityState>(
      builder: (context, state) {
        return switch (state) {
          CourtAvailabilityInitial() || CourtAvailabilityLoading() => Scaffold(
              appBar: CommonAppBar(
                title: 'Court Availability',
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _handleBack(context),
                ),
              ),
              body: const LoadingView(message: 'Loading court availability & slots...'),
            ),
          CourtAvailabilityFailure(:final failure) => Scaffold(
              appBar: CommonAppBar(
                title: 'Court Availability',
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _handleBack(context),
                ),
              ),
              body: ErrorStateView(
                title: 'Unable to Load Courts',
                message: failure.message,
                onRetry: () => context.read<CourtAvailabilityCubit>().retry(widget.venueId),
              ),
            ),
          CourtAvailabilityLoaded(
            :final venue,
            :final availableDates,
            :final selectedDate,
            :final courts,
            :final selectedCourt,
            :final slots,
            :final selectedSlot,
            :final isRefreshingSlots,
          ) =>
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                final cubit = context.read<CourtAvailabilityCubit>();

                // Split slots into time groups
                final morningSlots = slots.where((s) {
                  final startHour = int.tryParse(s.startTime.split(':').first) ?? 0;
                  return startHour < 12;
                }).toList();

                final afternoonSlots = slots.where((s) {
                  final startHour = int.tryParse(s.startTime.split(':').first) ?? 0;
                  return startHour >= 12 && startHour < 17;
                }).toList();

                final eveningSlots = slots.where((s) {
                  final startHour = int.tryParse(s.startTime.split(':').first) ?? 0;
                  return startHour >= 17;
                }).toList();

                final mainContent = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Selection Strip
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: CourtDatePickerStrip(
                        dates: availableDates,
                        selectedDate: selectedDate,
                        onDateSelected: (date) => cubit.selectDate(date),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Court Selector
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: CourtSelectorTabs(
                        courts: courts,
                        selectedCourt: selectedCourt,
                        onCourtSelected: (court) => cubit.selectCourt(court),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Time-slots Header & Status Legend
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Time Slots',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const Spacer(),
                              _buildStatusLegend(context),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Divider(height: 1),
                          const SizedBox(height: AppSpacing.md),
                          if (isRefreshingSlots)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else if (slots.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                              child: Center(
                                child: Text(
                                  courts.isEmpty
                                      ? 'No courts available for the selected date.'
                                      : 'No bookable slots found for this date and court.',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            )
                          else ...[
                            // Morning Slots
                            _buildTimeSlotsGroup(
                              context,
                              title: 'Morning (06:00 - 12:00)',
                              icon: Icons.wb_twilight_outlined,
                              slots: morningSlots,
                              selectedSlot: selectedSlot,
                              onSlotTapped: (slot) => cubit.selectSlot(slot),
                            ),
                            // Afternoon Slots
                            _buildTimeSlotsGroup(
                              context,
                              title: 'Afternoon (12:00 - 17:00)',
                              icon: Icons.wb_sunny_outlined,
                              slots: afternoonSlots,
                              selectedSlot: selectedSlot,
                              onSlotTapped: (slot) => cubit.selectSlot(slot),
                            ),
                            // Evening Slots
                            _buildTimeSlotsGroup(
                              context,
                              title: 'Evening & Night (17:00 - 22:00)',
                              icon: Icons.nights_stay_outlined,
                              slots: eveningSlots,
                              selectedSlot: selectedSlot,
                              onSlotTapped: (slot) => cubit.selectSlot(slot),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                );

                return Scaffold(
                  appBar: CommonAppBar(
                    title: 'Court Availability',
                    subtitle: venue.name,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => _handleBack(context),
                    ),
                  ),
                  bottomNavigationBar: isDesktop
                      ? null
                      : _buildMobileBottomBar(
                          context,
                          venue: venue,
                          court: selectedCourt,
                          date: selectedDate,
                          slot: selectedSlot,
                        ),
                  body: ResponsiveContainer(
                    maxWidth: AppSpacing.maxContentWidth,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column: Date, Court, Slots
                                Expanded(
                                  flex: 3,
                                  child: mainContent,
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                // Right Column: Booking Summary
                                Expanded(
                                  flex: 2,
                                  child: BookingSummaryCard(
                                    venue: venue,
                                    court: selectedCourt,
                                    date: selectedDate,
                                    slot: selectedSlot,
                                    onContinue: selectedSlot != null && selectedCourt != null
                                        ? () => _handleContinue(
                                              context,
                                              venue: venue,
                                              court: selectedCourt,
                                              date: selectedDate,
                                              slot: selectedSlot,
                                            )
                                        : null,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                mainContent,
                                BookingSummaryCard(
                                  venue: venue,
                                  court: selectedCourt,
                                  date: selectedDate,
                                  slot: selectedSlot,
                                  onContinue: selectedSlot != null && selectedCourt != null
                                      ? () => _handleContinue(
                                            context,
                                            venue: venue,
                                            court: selectedCourt,
                                            date: selectedDate,
                                            slot: selectedSlot,
                                          )
                                      : null,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
        };
      },
    );
  }
}
