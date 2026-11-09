import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_dialog.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_booking.dart';
import 'package:pickleball_platform/features/player/domain/repositories/booking_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/my_bookings_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/my_bookings_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/booking_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/booking_filter_tabs.dart';

/// My Bookings screen providing categorized tabs for upcoming, past, and cancelled court reservations.
class MyBookingsPage extends StatelessWidget {
  final MyBookingsCubit? cubit;

  const MyBookingsPage({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<MyBookingsCubit>.value(
        value: cubit!..loadBookings(),
        child: const _MyBookingsView(),
      );
    }

    return BlocProvider<MyBookingsCubit>(
      create: (_) => MyBookingsCubit(
        repository: sl<BookingRepository>(),
      )..loadBookings(),
      child: const _MyBookingsView(),
    );
  }
}

class _MyBookingsView extends StatelessWidget {
  const _MyBookingsView();

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
      final success = await context.read<MyBookingsCubit>().cancelBooking(booking.id);
      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking ${booking.bookingReference} has been cancelled.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState(BuildContext context, BookingFilter filter) {
    final theme = Theme.of(context);
    final String title;
    final String description;
    final IconData icon;

    switch (filter) {
      case BookingFilter.upcoming:
        title = 'No Upcoming Bookings';
        description = "You don't have any upcoming court reservations scheduled.";
        icon = Icons.event_available_outlined;
        break;
      case BookingFilter.past:
        title = 'No Past Bookings';
        description = 'Your completed court bookings will appear here once played.';
        icon = Icons.history_rounded;
        break;
      case BookingFilter.cancelled:
        title = 'No Cancelled Bookings';
        description = 'You have not cancelled any court reservations.';
        icon = Icons.event_busy_outlined;
        break;
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.primary(
              key: const Key('empty_state_action_button'),
              label: 'Book a Court',
              icon: const Icon(Icons.sports_tennis),
              onPressed: () => context.push(AppRoutes.playerVenues),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'My Bookings',
        leading: IconButton(
          key: const Key('my_bookings_back_button'),
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.playerDashboard);
            }
          },
        ),
      ),
      body: BlocConsumer<MyBookingsCubit, MyBookingsState>(
        listener: (context, state) {
          if (state is MyBookingsLoaded && state.feedbackMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.feedbackMessage!),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<MyBookingsCubit>().clearFeedback();
          }
        },
        builder: (context, state) {
          if (state is MyBookingsLoading || state is MyBookingsInitial) {
            return const LoadingView(message: 'Loading your bookings...');
          }

          if (state is MyBookingsFailure) {
            return ErrorStateView(
              title: 'Unable to Load Bookings',
              message: state.message,
              onRetry: () => context.read<MyBookingsCubit>().loadBookings(),
            );
          }

          final loadedState = state as MyBookingsLoaded;
          final bookings = loadedState.filteredBookings;

          return RefreshIndicator(
            onRefresh: () => context.read<MyBookingsCubit>().loadBookings(isRefresh: true),
            child: ResponsiveContainer(
              maxWidth: AppSpacing.maxContentWidth,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Heading
                  Text(
                    'Court Bookings & History',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Track scheduled games, review reservation details, or manage offline counter payments.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Filter Tabs
                  BookingFilterTabs(
                    activeFilter: loadedState.activeFilter,
                    upcomingCount: loadedState.upcomingCount,
                    pastCount: loadedState.pastCount,
                    cancelledCount: loadedState.cancelledCount,
                    onFilterSelected: (filter) {
                      context.read<MyBookingsCubit>().setFilter(filter);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Bookings List or Empty State
                  Expanded(
                    child: bookings.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: _buildEmptyState(context, loadedState.activeFilter),
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: bookings.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final booking = bookings[index];
                              return BookingCard(
                                key: Key('booking_card_${booking.id}'),
                                booking: booking,
                                isCancelling: loadedState.cancellingBookingId == booking.id,
                                onCancel: booking.canCancel
                                    ? () => _handleCancelBooking(context, booking)
                                    : null,
                                onTap: () {
                                  context.push(
                                    AppRoutes.playerBookingDetailsPath(booking.id),
                                    extra: booking,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
