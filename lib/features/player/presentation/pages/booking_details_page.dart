import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/widgets/app_dialog.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_booking.dart';
import 'package:pickleball_platform/features/player/domain/repositories/booking_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/booking_details_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/booking_details_state.dart';

/// Screen displaying comprehensive reservation details for an individual court booking.
class BookingDetailsPage extends StatelessWidget {
  final String bookingId;
  final CourtBooking? initialBooking;
  final BookingDetailsCubit? cubit;

  const BookingDetailsPage({
    super.key,
    required this.bookingId,
    this.initialBooking,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<BookingDetailsCubit>.value(
        value: cubit!..loadBooking(bookingId, initialBooking: initialBooking),
        child: const _BookingDetailsView(),
      );
    }

    return BlocProvider<BookingDetailsCubit>(
      create: (_) => BookingDetailsCubit(
        repository: sl<BookingRepository>(),
      )..loadBooking(bookingId, initialBooking: initialBooking),
      child: const _BookingDetailsView(),
    );
  }
}

class _BookingDetailsView extends StatelessWidget {
  const _BookingDetailsView();

  Future<void> _handleCancelBooking(BuildContext context, CourtBooking booking) async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Cancel Booking',
      message: 'Are you sure you want to cancel booking ${booking.bookingReference}? This action cannot be undone.',
      confirmLabel: 'Cancel Booking',
      cancelLabel: 'Keep Booking',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await context.read<BookingDetailsCubit>().cancelBooking(booking.id);
    }
  }

  void _copyReference(BuildContext context, String reference) {
    Clipboard.setData(ClipboardData(text: reference));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied "$reference" to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return AppChip.success(label: status.displayName);
      case BookingStatus.paymentPending:
        return AppChip.warning(label: status.displayName);
      case BookingStatus.completed:
        return AppChip.info(label: status.displayName);
      case BookingStatus.cancelled:
        return AppChip.error(label: status.displayName);
    }
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required String label,
    required String value,
    bool isBold = false,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isBold ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? (isBold ? theme.colorScheme.primary : theme.colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Booking Details',
        leading: IconButton(
          key: const Key('booking_details_back_button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.playerBookings);
            }
          },
        ),
      ),
      body: BlocConsumer<BookingDetailsCubit, BookingDetailsState>(
        listener: (context, state) {
          if (state is BookingDetailsLoaded && state.feedbackMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.feedbackMessage!),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<BookingDetailsCubit>().clearFeedback();
          }
        },
        builder: (context, state) {
          if (state is BookingDetailsLoading || state is BookingDetailsInitial) {
            return const LoadingView(message: 'Loading booking details...');
          }

          if (state is BookingDetailsFailure) {
            return ErrorStateView(
              title: 'Booking Not Found',
              message: state.message,
              onRetry: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.playerBookings);
                }
              },
            );
          }

          final loadedState = state as BookingDetailsLoaded;
          final booking = loadedState.booking;
          final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(booking.date);

          // Card 1: Reference, Status & Quick Action
          final referenceCard = AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Booking Reference',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    _buildStatusChip(booking.status),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        booking.bookingReference,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('copy_reference_button'),
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      tooltip: 'Copy Reference',
                      onPressed: () => _copyReference(context, booking.bookingReference),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Booked for: ${booking.playerName}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );

          // Card 2: Venue & Court
          final venueCard = AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: AppSpacing.borderRadiusSm,
                      ),
                      child: Icon(
                        Icons.store_outlined,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.venueName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${booking.venueAddress}, ${booking.venueCity}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Court',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.courtName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Surface',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.surfaceType,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );

          // Card 3: Schedule
          final scheduleCard = AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Schedule & Duration',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formattedDate,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Slot & Duration',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${booking.slotTime} (${booking.durationMinutes} min)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          // Card 4: Price & Payment
          final paymentCard = AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Payment & Pricing Breakdown',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSummaryRow(
                  context,
                  label: 'Court Fee (${booking.durationMinutes} mins)',
                  value: '₹${booking.courtFee.toStringAsFixed(0)}',
                ),
                _buildSummaryRow(
                  context,
                  label: 'Convenience / Platform Fee',
                  value: booking.platformFee > 0 ? '₹${booking.platformFee.toStringAsFixed(0)}' : 'Free',
                  valueColor: booking.platformFee > 0 ? null : theme.colorScheme.primary,
                ),
                _buildSummaryRow(
                  context,
                  label: 'Taxes & GST',
                  value: booking.taxes > 0 ? '₹${booking.taxes.toStringAsFixed(0)}' : '₹0',
                ),
                const Divider(height: 16),
                _buildSummaryRow(
                  context,
                  label: 'Total Payable Amount',
                  value: '₹${booking.totalAmount.toStringAsFixed(0)}',
                  isBold: true,
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: AppSpacing.borderRadiusSm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment Method:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        booking.paymentMethod,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );

          // Card 5: Check-in instructions
          final checkInCard = AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      booking.isCancelled ? Icons.info_outline : Icons.room_service_outlined,
                      color: booking.isCancelled
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      booking.isCancelled ? 'Cancellation Note' : 'Venue Check-in Advisory',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: booking.isCancelled ? theme.colorScheme.error : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  booking.isCancelled
                      ? 'This booking was cancelled. No payment was collected and the court slot was released.'
                      : 'Please arrive 10-15 minutes prior to slot start time (${booking.startTime}). Show this booking reference at the reception counter to complete offline payment and access the court.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );

          return ResponsiveContainer(
            maxWidth: AppSpacing.maxContentWidth,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  referenceCard,
                  const SizedBox(height: AppSpacing.md),
                  venueCard,
                  const SizedBox(height: AppSpacing.md),
                  scheduleCard,
                  const SizedBox(height: AppSpacing.md),
                  paymentCard,
                  const SizedBox(height: AppSpacing.md),
                  checkInCard,
                  const SizedBox(height: AppSpacing.xl),

                  // Action Buttons
                  if (booking.canCancel) ...[
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.outline(
                        key: const Key('details_cancel_booking_button'),
                        label: 'Cancel Booking',
                        icon: const Icon(Icons.close, size: 18),
                        isLoading: loadedState.isCancelling,
                        onPressed: loadedState.isCancelling
                            ? null
                            : () => _handleCancelBooking(context, booking),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (booking.isPast || booking.isCancelled) ...[
                    SizedBox(
                      width: double.infinity,
                      child: AppButton.primary(
                        key: const Key('details_book_again_button'),
                        label: 'Book Again',
                        icon: const Icon(Icons.sports_tennis),
                        onPressed: () => context.push(
                          AppRoutes.playerCourtAvailabilityPath(booking.venueId),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.outline(
                      key: const Key('details_back_to_bookings_button'),
                      label: 'Back to My Bookings',
                      icon: const Icon(Icons.list_alt_rounded),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.playerBookings);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
