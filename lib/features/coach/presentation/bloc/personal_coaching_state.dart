import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/coach/domain/entities/personal_coaching_booking.dart';

/// Base state hierarchy for Coach Personal Coaching Management.
sealed class PersonalCoachingState extends Equatable {
  const PersonalCoachingState();

  @override
  List<Object?> get props => [];
}

class PersonalCoachingInitial extends PersonalCoachingState {
  const PersonalCoachingInitial();
}

class PersonalCoachingLoading extends PersonalCoachingState {
  const PersonalCoachingLoading();
}

class PersonalCoachingLoaded extends PersonalCoachingState {
  final String coachId;
  final List<PersonalCoachingBooking> bookings;
  final PersonalBookingFilter activeFilter;
  final String searchQuery;
  final String? feedbackMessage;
  final bool isErrorFeedback;

  const PersonalCoachingLoaded({
    required this.coachId,
    required this.bookings,
    this.activeFilter = PersonalBookingFilter.all,
    this.searchQuery = '',
    this.feedbackMessage,
    this.isErrorFeedback = false,
  });

  List<PersonalCoachingBooking> get filteredBookings {
    final now = DateTime.now();
    final query = searchQuery.trim().toLowerCase();

    return bookings.where((b) {
      final matchesFilter = switch (activeFilter) {
        PersonalBookingFilter.all => true,
        PersonalBookingFilter.upcoming => b.isUpcoming(now),
        PersonalBookingFilter.pending =>
          b.status == PersonalBookingStatus.pendingPlayerApproval,
        PersonalBookingFilter.confirmed =>
          b.status == PersonalBookingStatus.confirmed,
        PersonalBookingFilter.declined =>
          b.status == PersonalBookingStatus.declined,
        PersonalBookingFilter.cancelled =>
          b.status == PersonalBookingStatus.cancelled,
      };
      if (!matchesFilter) return false;

      if (query.isEmpty) return true;
      return b.playerName.toLowerCase().contains(query) ||
          b.sessionTitle.toLowerCase().contains(query) ||
          b.venueName.toLowerCase().contains(query);
    }).toList();
  }

  int countFor(PersonalBookingFilter filter) {
    final now = DateTime.now();
    return bookings.where((b) {
      return switch (filter) {
        PersonalBookingFilter.all => true,
        PersonalBookingFilter.upcoming => b.isUpcoming(now),
        PersonalBookingFilter.pending =>
          b.status == PersonalBookingStatus.pendingPlayerApproval,
        PersonalBookingFilter.confirmed =>
          b.status == PersonalBookingStatus.confirmed,
        PersonalBookingFilter.declined =>
          b.status == PersonalBookingStatus.declined,
        PersonalBookingFilter.cancelled =>
          b.status == PersonalBookingStatus.cancelled,
      };
    }).length;
  }

  PersonalCoachingLoaded copyWith({
    List<PersonalCoachingBooking>? bookings,
    PersonalBookingFilter? activeFilter,
    String? searchQuery,
    String? feedbackMessage,
    bool clearFeedback = false,
    bool? isErrorFeedback,
  }) {
    return PersonalCoachingLoaded(
      coachId: coachId,
      bookings: bookings ?? this.bookings,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      isErrorFeedback:
          clearFeedback ? false : (isErrorFeedback ?? this.isErrorFeedback),
    );
  }

  @override
  List<Object?> get props => [
        coachId,
        bookings,
        activeFilter,
        searchQuery,
        feedbackMessage,
        isErrorFeedback,
      ];
}

class PersonalCoachingFailure extends PersonalCoachingState {
  final Failure failure;

  const PersonalCoachingFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
