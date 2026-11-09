import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_item.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';

/// Repository contract for discovering venues, courts, and facilities.
abstract class VenueRepository {
  /// Fetches a list of venues matching the specified [filter] criteria.
  Future<Result<List<VenueItem>>> getVenues({VenueFilter? filter});

  /// Fetches details for a single venue by its [id].
  Future<Result<VenueItem>> getVenueById(String id);

  /// Fetches the list of courts for a given [venueId] with available slot counts for [date].
  Future<Result<List<CourtItem>>> getCourts(String venueId, {DateTime? date});

  /// Fetches the time slots for a specific [courtId] and [date].
  Future<Result<List<CourtSlot>>> getCourtSlots({
    required String venueId,
    required String courtId,
    required DateTime date,
  });
}
