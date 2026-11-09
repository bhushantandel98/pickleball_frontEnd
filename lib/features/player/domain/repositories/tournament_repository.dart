import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';

/// Contract defining tournament discovery, details, registration, and status actions for players.
abstract class TournamentRepository {
  /// Queries tournaments matching optional search and filter criteria.
  Future<Result<List<TournamentItem>>> getTournaments({TournamentFilter? filter});

  /// Retrieves full tournament details by ID.
  Future<Result<TournamentItem>> getTournamentById(String tournamentId);

  /// Registers a player for a specific tournament category.
  Future<Result<TournamentRegistration>> registerForTournament(
    TournamentRegistrationPayload payload,
  );

  /// Withdraws the player from an active registration.
  Future<Result<TournamentRegistration>> withdrawFromTournament(
    String registrationId,
  );

  /// Retrieves the current player's existing tournament registrations.
  Future<Result<List<TournamentRegistration>>> getMyRegistrations();
}
