import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/coach/data/repositories/mock_personal_coaching_repository.dart';
import 'package:pickleball_platform/features/coach/domain/entities/personal_coaching_booking.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/personal_coaching_cubit.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/personal_coaching_state.dart';
import 'package:pickleball_platform/features/coach/presentation/widgets/personal_booking_card.dart';
import 'package:pickleball_platform/features/coach/presentation/widgets/personal_booking_detail_sheet.dart';
import 'package:pickleball_platform/features/coach/presentation/widgets/personal_booking_form_dialog.dart';

/// Coach Personal Coaching Management page (Phase 3 — Feature 3.4).
class PersonalCoachingPage extends StatelessWidget {
  final PersonalCoachingCubit? cubit;
  final String coachId;

  const PersonalCoachingPage({
    super.key,
    this.cubit,
    this.coachId = 'coach_001',
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<PersonalCoachingCubit>.value(
        value: cubit!,
        child: _PersonalCoachingView(coachId: coachId),
      );
    }

    try {
      final existing = context.read<PersonalCoachingCubit>();
      return BlocProvider<PersonalCoachingCubit>.value(
        value: existing,
        child: _PersonalCoachingView(coachId: coachId),
      );
    } catch (_) {
      return BlocProvider<PersonalCoachingCubit>(
        create: (_) => sl.isRegistered<PersonalCoachingCubit>()
            ? sl<PersonalCoachingCubit>()
            : PersonalCoachingCubit(
                repository: MockPersonalCoachingRepository(),
              ),
        child: _PersonalCoachingView(coachId: coachId),
      );
    }
  }
}

class _PersonalCoachingView extends StatefulWidget {
  final String coachId;

  const _PersonalCoachingView({required this.coachId});

  @override
  State<_PersonalCoachingView> createState() => _PersonalCoachingViewState();
}

class _PersonalCoachingViewState extends State<_PersonalCoachingView> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<PersonalCoachingCubit>();
    if (cubit.state is PersonalCoachingInitial) {
      cubit.loadBookings(coachId: widget.coachId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PersonalCoachingCubit, PersonalCoachingState>(
      listener: (context, state) {
        if (state is PersonalCoachingLoaded && state.feedbackMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.feedbackMessage!),
                backgroundColor: state.isErrorFeedback
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            );
          context.read<PersonalCoachingCubit>().clearFeedback();
        }
      },
      builder: (context, state) {
        switch (state) {
          case PersonalCoachingInitial():
          case PersonalCoachingLoading():
            return const Scaffold(
              body: LoadingView(message: 'Loading personal coaching bookings...'),
            );

          case PersonalCoachingFailure(:final failure):
            return Scaffold(
              body: ErrorStateView(
                title: 'Unable to load bookings',
                message: failure.message,
                onRetry: () => context
                    .read<PersonalCoachingCubit>()
                    .loadBookings(coachId: widget.coachId),
              ),
            );

          case PersonalCoachingLoaded():
            return _LoadedBody(
              state: state,
              coachId: widget.coachId,
            );
        }
      },
    );
  }
}

class _LoadedBody extends StatelessWidget {
  final PersonalCoachingLoaded state;
  final String coachId;

  const _LoadedBody({
    required this.state,
    required this.coachId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<PersonalCoachingCubit>();
    final filtered = state.filteredBookings;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => cubit.refreshBookings(coachId: coachId),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ResponsiveContainer(
              maxWidth: 1100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Personal Coaching',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Manage your personal coaching bookings separately from academy schedules.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      FilledButton.icon(
                        onPressed: () => _handleCreate(context, cubit),
                        icon: const Icon(Icons.add),
                        label: const Text('New Booking'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search by player, session title, or venue...',
                    ),
                    onChanged: cubit.setSearchQuery,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: PersonalBookingFilter.values.map((filter) {
                      final count = state.countFor(filter);
                      return ChoiceChip(
                        label: Text('${filter.label} ($count)'),
                        selected: state.activeFilter == filter,
                        onSelected: (_) => cubit.setFilter(filter),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (filtered.isEmpty)
                    EmptyStateView(
                      icon: const Icon(Icons.event_note_outlined),
                      title: 'No Personal Bookings',
                      message: state.bookings.isEmpty
                          ? 'Create a personal coaching booking to send it for player approval.'
                          : 'No bookings match the selected status filter or search query.',
                      actionLabel: state.bookings.isEmpty
                          ? 'Create Booking'
                          : 'Show All',
                      onAction: state.bookings.isEmpty
                          ? () => _handleCreate(context, cubit)
                          : () => cubit.setFilter(PersonalBookingFilter.all),
                    )
                  else
                    ...filtered.map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: PersonalBookingCard(
                          booking: booking,
                          onViewDetails: () => PersonalBookingDetailSheet.show(
                            context,
                            booking: booking,
                          ),
                          onEdit: booking.canEdit
                              ? () => _handleEdit(context, cubit, booking)
                              : null,
                          onCancel: booking.canCancel
                              ? () => _handleCancel(context, cubit, booking)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCreate(
    BuildContext context,
    PersonalCoachingCubit cubit,
  ) async {
    final result = await PersonalBookingFormDialog.show(context);
    if (result == null) return;
    await cubit.createBooking(
      playerName: result.playerName,
      playerContact: result.playerContact,
      sessionTitle: result.sessionTitle,
      sessionType: result.sessionType,
      venueName: result.venueName,
      startTime: result.startTime,
      endTime: result.endTime,
      notes: result.notes,
    );
  }

  Future<void> _handleEdit(
    BuildContext context,
    PersonalCoachingCubit cubit,
    PersonalCoachingBooking booking,
  ) async {
    final result = await PersonalBookingFormDialog.show(
      context,
      existing: booking,
    );
    if (result == null) return;
    await cubit.editBooking(
      bookingId: booking.id,
      sessionTitle: result.sessionTitle,
      sessionType: result.sessionType,
      venueName: result.venueName,
      startTime: result.startTime,
      endTime: result.endTime,
      notes: result.notes,
    );
  }

  Future<void> _handleCancel(
    BuildContext context,
    PersonalCoachingCubit cubit,
    PersonalCoachingBooking booking,
  ) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Personal Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cancel "${booking.sessionTitle}" with ${booking.playerName}? This action is preserved in booking history.',
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.cancelBooking(
        bookingId: booking.id,
        reason: reasonController.text.trim(),
      );
    }
  }
}
