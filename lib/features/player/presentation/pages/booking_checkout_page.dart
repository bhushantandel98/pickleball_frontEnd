import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/booking_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/booking_checkout_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/booking_checkout_state.dart';

/// Screen allowing players to review booking details, inspect pricing, and confirm court reservation.
class BookingCheckoutPage extends StatelessWidget {
  final BookingSelectionPayload? payload;
  final BookingCheckoutCubit? cubit;

  const BookingCheckoutPage({
    super.key,
    this.payload,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<BookingCheckoutCubit>.value(
        value: cubit!..init(payload),
        child: _BookingCheckoutView(payload: payload),
      );
    }

    return BlocProvider<BookingCheckoutCubit>(
      create: (_) => BookingCheckoutCubit(
        repository: sl<BookingRepository>(),
      )..init(payload),
      child: _BookingCheckoutView(payload: payload),
    );
  }
}

class _BookingCheckoutView extends StatelessWidget {
  final BookingSelectionPayload? payload;

  const _BookingCheckoutView({this.payload});

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else if (payload != null && payload!.venueId.isNotEmpty) {
      context.go(AppRoutes.playerCourtAvailabilityPath(payload!.venueId));
    } else {
      context.go(AppRoutes.playerVenues);
    }
  }

  void _handleConfirm(BuildContext context) {
    String? playerId;
    String? playerName;

    try {
      final session = context.read<SessionCubit>().state;
      if (session.isAuthenticated) {
        playerId = session.userId;
        playerName = session.displayName;
      }
    } catch (_) {
      // Graceful fallback when SessionCubit is not in context (e.g. in targeted tests)
    }

    context.read<BookingCheckoutCubit>().confirmBooking(
          playerId: playerId,
          playerName: playerName,
        );
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

    return BlocConsumer<BookingCheckoutCubit, BookingCheckoutState>(
      listener: (context, state) {
        if (state is BookingCheckoutSuccess) {
          context.pushReplacement(
            AppRoutes.playerBookingConfirmation,
            extra: state.booking,
          );
        }
      },
      builder: (context, state) {
        if (state is BookingCheckoutInvalid) {
          return Scaffold(
            appBar: CommonAppBar(
              title: 'Booking Checkout',
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _handleBack(context),
              ),
            ),
            body: ErrorStateView(
              title: 'Invalid Booking Details',
              message: state.errorMessage,
              onRetry: () => _handleBack(context),
            ),
          );
        }

        final BookingSelectionPayload currentPayload;
        final double courtFee;
        final double platformFee;
        final double taxes;
        final double totalAmount;
        final bool isSubmitting = state is BookingCheckoutSubmitting;

        if (state is BookingCheckoutReady) {
          currentPayload = state.payload;
          courtFee = state.courtFee;
          platformFee = state.platformFee;
          taxes = state.taxes;
          totalAmount = state.totalAmount;
        } else if (state is BookingCheckoutSubmitting) {
          currentPayload = state.payload;
          courtFee = currentPayload.price;
          platformFee = 0.0;
          taxes = 0.0;
          totalAmount = currentPayload.price;
        } else if (state is BookingCheckoutFailure) {
          currentPayload = state.payload;
          courtFee = currentPayload.price;
          platformFee = 0.0;
          taxes = 0.0;
          totalAmount = currentPayload.price;
        } else {
          currentPayload = payload ??
              BookingSelectionPayload(
                venueId: '',
                venueName: '',
                courtId: '',
                courtName: '',
                surfaceType: '',
                date: DateTime.now(),
                slotId: '',
                slotTime: '',
                price: 0,
              );
          courtFee = currentPayload.price;
          platformFee = 0.0;
          taxes = 0.0;
          totalAmount = currentPayload.price;
        }

        final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(currentPayload.date);

        final venueCard = AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentPayload.venueName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (currentPayload.venueAddress != null &&
                            currentPayload.venueAddress!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${currentPayload.venueAddress!}${currentPayload.venueCity != null ? ", ${currentPayload.venueCity!}" : ""}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              // Court & Surface details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Court',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentPayload.courtName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      AppChip.neutral(label: currentPayload.surfaceType),
                      AppChip.info(label: '${currentPayload.durationMinutes} min slot'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );

        final scheduleCard = AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event_available_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Schedule & Time Slot',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              Row(
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
                          'Time Slot',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentPayload.slotTime,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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

        final paymentInfoCard = AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Payment Mode',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const AppChip.warning(label: 'Pay at Venue'),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Offline Venue Payment (V1)',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Payment is settled in person upon arrival at the venue counter (UPI, Cash, or Card). Your slot will be held for 30 minutes while payment is pending.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        final priceSummaryCard = AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Price Breakdown',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              _buildSummaryRow(
                context,
                label: 'Court Fee (${currentPayload.slotTime})',
                value: '₹${courtFee.toStringAsFixed(0)}',
              ),
              _buildSummaryRow(
                context,
                label: 'Convenience Fee',
                value: platformFee == 0 ? 'FREE' : '₹${platformFee.toStringAsFixed(0)}',
                valueColor: platformFee == 0 ? Colors.green : null,
              ),
              _buildSummaryRow(
                context,
                label: 'Taxes & GST',
                value: taxes == 0 ? '₹0' : '₹${taxes.toStringAsFixed(0)}',
              ),
              const SizedBox(height: AppSpacing.xs),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),
              _buildSummaryRow(
                context,
                label: 'Total Amount',
                value: '₹${totalAmount.toStringAsFixed(0)}',
                isBold: true,
              ),
            ],
          ),
        );

        return Scaffold(
          appBar: CommonAppBar(
            title: 'Review Booking',
            subtitle: currentPayload.venueName,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _handleBack(context),
            ),
          ),
          bottomNavigationBar: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) return const SizedBox.shrink();

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
                              '₹${totalAmount.toStringAsFixed(0)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Text(
                              'Pay at Venue',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      AppButton.primary(
                        key: const Key('booking_checkout_confirm_button'),
                        label: 'Confirm Booking',
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        isLoading: isSubmitting,
                        onPressed: isSubmitting ? null : () => _handleConfirm(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          body: ResponsiveContainer(
            maxWidth: AppSpacing.maxContentWidth,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SingleChildScrollView(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 800;

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column: Venue, Schedule, Payment mode
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              venueCard,
                              const SizedBox(height: AppSpacing.md),
                              scheduleCard,
                              const SizedBox(height: AppSpacing.md),
                              paymentInfoCard,
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        // Right column: Price breakdown & confirmation CTAs
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              priceSummaryCard,
                              const SizedBox(height: AppSpacing.md),
                              SizedBox(
                                width: double.infinity,
                                child: AppButton.primary(
                                  key: const Key('booking_checkout_desktop_confirm_button'),
                                  label: 'Confirm Booking',
                                  icon: const Icon(Icons.check_circle_outline_rounded),
                                  isLoading: isSubmitting,
                                  onPressed: isSubmitting ? null : () => _handleConfirm(context),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: double.infinity,
                                child: AppButton.outline(
                                  key: const Key('booking_checkout_back_button'),
                                  label: 'Back / Edit Selection',
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () => _handleBack(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      venueCard,
                      const SizedBox(height: AppSpacing.md),
                      scheduleCard,
                      const SizedBox(height: AppSpacing.md),
                      paymentInfoCard,
                      const SizedBox(height: AppSpacing.md),
                      priceSummaryCard,
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton.outline(
                          key: const Key('booking_checkout_mobile_back_button'),
                          label: 'Back / Edit Selection',
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => _handleBack(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
