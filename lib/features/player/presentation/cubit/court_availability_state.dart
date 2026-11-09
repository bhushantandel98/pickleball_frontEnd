import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_item.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';

/// Sealed state representation for the Court Availability & Slot Selection screen.
sealed class CourtAvailabilityState extends Equatable {
  const CourtAvailabilityState();

  @override
  List<Object?> get props => [];
}

/// Initial state before court availability loading begins.
class CourtAvailabilityInitial extends CourtAvailabilityState {
  const CourtAvailabilityInitial();
}

/// Loading state while court availability data is retrieved.
class CourtAvailabilityLoading extends CourtAvailabilityState {
  const CourtAvailabilityLoading();
}

/// Loaded state containing selected date, courts, time slots, and slot selection.
class CourtAvailabilityLoaded extends CourtAvailabilityState {
  final VenueItem venue;
  final List<DateTime> availableDates;
  final DateTime selectedDate;
  final List<CourtItem> courts;
  final CourtItem? selectedCourt;
  final List<CourtSlot> slots;
  final CourtSlot? selectedSlot;
  final bool isRefreshingSlots;

  const CourtAvailabilityLoaded({
    required this.venue,
    required this.availableDates,
    required this.selectedDate,
    required this.courts,
    this.selectedCourt,
    required this.slots,
    this.selectedSlot,
    this.isRefreshingSlots = false,
  });

  bool get hasSelection => selectedSlot != null && selectedCourt != null;
  bool get hasCourts => courts.isNotEmpty;

  CourtAvailabilityLoaded copyWith({
    VenueItem? venue,
    List<DateTime>? availableDates,
    DateTime? selectedDate,
    List<CourtItem>? courts,
    CourtItem? Function()? selectedCourt,
    List<CourtSlot>? slots,
    CourtSlot? Function()? selectedSlot,
    bool? isRefreshingSlots,
  }) {
    return CourtAvailabilityLoaded(
      venue: venue ?? this.venue,
      availableDates: availableDates ?? this.availableDates,
      selectedDate: selectedDate ?? this.selectedDate,
      courts: courts ?? this.courts,
      selectedCourt: selectedCourt != null ? selectedCourt() : this.selectedCourt,
      slots: slots ?? this.slots,
      selectedSlot: selectedSlot != null ? selectedSlot() : this.selectedSlot,
      isRefreshingSlots: isRefreshingSlots ?? this.isRefreshingSlots,
    );
  }

  @override
  List<Object?> get props => [
        venue,
        availableDates,
        selectedDate,
        courts,
        selectedCourt,
        slots,
        selectedSlot,
        isRefreshingSlots,
      ];
}

/// Failure state when fetching court availability encounters an error.
class CourtAvailabilityFailure extends CourtAvailabilityState {
  final Failure failure;

  const CourtAvailabilityFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
