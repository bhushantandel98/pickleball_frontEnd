import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_item.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/venue_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/court_availability_state.dart';

/// Cubit managing court availability, date navigation, court switching, and slot selection.
class CourtAvailabilityCubit extends Cubit<CourtAvailabilityState> {
  final VenueRepository repository;

  String? _lastVenueId;
  DateTime? _startDate;
  DateTime? _lastSelectedDate;
  String? _lastSelectedCourtId;

  CourtAvailabilityCubit({
    required this.repository,
  }) : super(const CourtAvailabilityInitial());

  /// Normalizes a [DateTime] to start-of-day (year, month, day).
  static DateTime normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Generates the next [count] days starting from normalized [start].
  static List<DateTime> generateDateRange({DateTime? start, int count = 14}) {
    final base = normalizeDate(start ?? DateTime.now());
    return List.generate(count, (index) => base.add(Duration(days: index)));
  }

  /// Initial load of venue details, courts, and time-slots for [venueId].
  Future<void> loadAvailability(
    String venueId, {
    DateTime? startDate,
    DateTime? selectedDate,
    DateTime? initialDate,
  }) async {
    _lastVenueId = venueId;
    _startDate = startDate ?? initialDate;

    emit(const CourtAvailabilityLoading());

    // 1. Fetch Venue
    final venueResult = await repository.getVenueById(venueId);
    if (venueResult case FailureResult(:final failure)) {
      emit(CourtAvailabilityFailure(failure));
      return;
    }
    final venue = (venueResult as Success<VenueItem>).data;

    // 2. Setup Available Dates
    final dates = generateDateRange(start: _startDate);
    final activeDate = selectedDate != null
        ? normalizeDate(selectedDate)
        : (initialDate != null ? normalizeDate(initialDate) : dates.first);
    _lastSelectedDate = activeDate;

    // 3. Fetch Courts for Venue on activeDate
    final courtsResult = await repository.getCourts(venueId, date: activeDate);
    if (courtsResult case FailureResult(:final failure)) {
      emit(CourtAvailabilityFailure(failure));
      return;
    }
    final courts = (courtsResult as Success<List<CourtItem>>).data;

    // Handle empty court list gracefully
    if (courts.isEmpty) {
      _lastSelectedCourtId = null;
      emit(
        CourtAvailabilityLoaded(
          venue: venue,
          availableDates: dates,
          selectedDate: activeDate,
          courts: const [],
          selectedCourt: null,
          slots: const [],
          selectedSlot: null,
          isRefreshingSlots: false,
        ),
      );
      return;
    }

    final activeCourt = courts.firstWhere(
      (c) => c.id == _lastSelectedCourtId,
      orElse: () => courts.first,
    );
    _lastSelectedCourtId = activeCourt.id;

    // 4. Fetch Slots for First Court & Date
    final slotsResult = await repository.getCourtSlots(
      venueId: venueId,
      courtId: activeCourt.id,
      date: activeDate,
    );
    if (slotsResult case FailureResult(:final failure)) {
      emit(CourtAvailabilityFailure(failure));
      return;
    }
    final slots = (slotsResult as Success<List<CourtSlot>>).data;

    emit(
      CourtAvailabilityLoaded(
        venue: venue,
        availableDates: dates,
        selectedDate: activeDate,
        courts: courts,
        selectedCourt: activeCourt,
        slots: slots,
        selectedSlot: null,
      ),
    );
  }

  /// Changes the active reservation date, re-querying courts and slots.
  Future<void> selectDate(DateTime date) async {
    if (state is! CourtAvailabilityLoaded) return;
    final current = state as CourtAvailabilityLoaded;
    final normalized = normalizeDate(date);

    // Prevent selecting dates prior to the first available date (today)
    if (current.availableDates.isNotEmpty && normalized.isBefore(current.availableDates.first)) {
      return;
    }

    _lastSelectedDate = normalized;
    emit(current.copyWith(isRefreshingSlots: true));

    final courtsResult = await repository.getCourts(current.venue.id, date: normalized);
    if (courtsResult case FailureResult(:final failure)) {
      // Explicitly handle repository failure - do not retain previous selections as valid
      emit(CourtAvailabilityFailure(failure));
      return;
    }
    final updatedCourts = (courtsResult as Success<List<CourtItem>>).data;

    // Check whether the updated court list is empty before accessing its first element
    if (updatedCourts.isEmpty) {
      _lastSelectedCourtId = null;
      emit(
        current.copyWith(
          selectedDate: normalized,
          courts: const [],
          selectedCourt: () => null,
          slots: const [],
          selectedSlot: () => null, // Clear time slot when no courts available
          isRefreshingSlots: false,
        ),
      );
      return;
    }

    // Match currently selected court or fallback to first
    final activeCourt = updatedCourts.firstWhere(
      (c) => c.id == current.selectedCourt?.id,
      orElse: () => updatedCourts.first,
    );
    _lastSelectedCourtId = activeCourt.id;

    final slotsResult = await repository.getCourtSlots(
      venueId: current.venue.id,
      courtId: activeCourt.id,
      date: normalized,
    );
    if (slotsResult case FailureResult(:final failure)) {
      // Explicitly handle repository failure - do not silently treat as empty availability
      emit(CourtAvailabilityFailure(failure));
      return;
    }
    final updatedSlots = (slotsResult as Success<List<CourtSlot>>).data;

    emit(
      current.copyWith(
        selectedDate: normalized,
        courts: updatedCourts,
        selectedCourt: () => activeCourt,
        slots: updatedSlots,
        selectedSlot: () => null, // Reset selected slot on date change
        isRefreshingSlots: false,
      ),
    );
  }

  /// Selects a court, re-querying available time slots.
  Future<void> selectCourt(CourtItem court) async {
    if (state is! CourtAvailabilityLoaded) return;
    final current = state as CourtAvailabilityLoaded;
    if (current.selectedCourt?.id == court.id) return;

    _lastSelectedCourtId = court.id;
    emit(current.copyWith(isRefreshingSlots: true));

    final slotsResult = await repository.getCourtSlots(
      venueId: current.venue.id,
      courtId: court.id,
      date: current.selectedDate,
    );

    if (slotsResult case FailureResult(:final failure)) {
      // Explicitly handle repository failure - do not silently treat as empty availability
      emit(CourtAvailabilityFailure(failure));
      return;
    }
    final updatedSlots = (slotsResult as Success<List<CourtSlot>>).data;

    emit(
      current.copyWith(
        selectedCourt: () => court,
        slots: updatedSlots,
        selectedSlot: () => null, // Reset selected slot on court switch
        isRefreshingSlots: false,
      ),
    );
  }

  /// Retries the last attempted operation.
  Future<void> retry([String? fallbackVenueId]) async {
    final venueId = _lastVenueId ?? fallbackVenueId;
    if (venueId == null) return;

    await loadAvailability(
      venueId,
      startDate: _startDate,
      selectedDate: _lastSelectedDate,
    );
  }

  /// Selects or switches the active bookable slot.
  void selectSlot(CourtSlot slot) {
    if (state is! CourtAvailabilityLoaded) return;
    final current = state as CourtAvailabilityLoaded;

    // Only available slots can be chosen
    if (slot.status != SlotStatus.available) return;

    // Toggle if tapped again, or select new
    if (current.selectedSlot?.id == slot.id) {
      emit(current.copyWith(selectedSlot: () => null));
    } else {
      emit(current.copyWith(selectedSlot: () => slot));
    }
  }

  /// Explicitly clears current slot selection.
  void clearSlotSelection() {
    if (state is! CourtAvailabilityLoaded) return;
    final current = state as CourtAvailabilityLoaded;
    emit(current.copyWith(selectedSlot: () => null));
  }
}
