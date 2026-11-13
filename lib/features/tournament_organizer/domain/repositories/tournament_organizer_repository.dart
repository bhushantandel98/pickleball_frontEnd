import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/entities/tournament_organizer_entities.dart';

/// Repository contract for Feature 5.1 — Tournament Organizer Module.
///
/// Every method requires [organizerId] and enforces organizer-level ownership
/// across tournaments, categories, registrations, draws, matches, and staff.
abstract class TournamentOrganizerRepository {
  Future<Result<TournamentOrganizerWorkspaceData>> getWorkspace({
    required String organizerId,
  });

  Future<Result<TournamentOrganizerWorkspaceData>> createTournament({
    required String organizerId,
    required OrganizerTournament tournament,
  });

  Future<Result<TournamentOrganizerWorkspaceData>> updateTournamentStatus({
    required String organizerId,
    required String tournamentId,
    required OrganizerTournamentStatus status,
  });

  Future<Result<TournamentOrganizerWorkspaceData>> addCategory({
    required String organizerId,
    required String tournamentId,
    required OrganizerCategoryConfig category,
  });

  Future<Result<TournamentOrganizerWorkspaceData>> submitAutoRegistration({
    required String organizerId,
    required String tournamentId,
    required String categoryId,
    required String playerName,
    String? partnerOrTeamName,
    required String playerEmail,
    required String playerPhone,
    required double playerRating,
    required int playerAge,
  });

  Future<Result<TournamentOrganizerWorkspaceData>> generateDraw({
    required String organizerId,
    required String tournamentId,
    required String categoryId,
  });

  Future<Result<TournamentOrganizerWorkspaceData>> swapSeedOrder({
    required String organizerId,
    required String tournamentId,
    required String categoryId,
    required int indexA,
    required int indexB,
  });

  Future<Result<TournamentOrganizerWorkspaceData>> assignMatchScheduleAndReferee({
    required String organizerId,
    required String tournamentId,
    required String matchId,
    required String courtName,
    required DateTime scheduledTime,
    String? refereeAssignmentId,
  });

  Future<Result<TournamentOrganizerWorkspaceData>> updateMatchScore({
    required String organizerId,
    required String tournamentId,
    required String matchId,
    required String scoreSummary,
    required String winnerLabel,
  });

  Future<Result<TournamentOrganizerWorkspaceData>> addStaffOrReferee({
    required String organizerId,
    required String tournamentId,
    required String name,
    required String email,
    required OrganizerStaffRole role,
    required Set<String> delegatedPermissions,
  });

  Future<Result<TournamentOrganizerWorkspaceData>> toggleStaffActive({
    required String organizerId,
    required String tournamentId,
    required String assignmentId,
    required bool isActive,
  });

  Future<Result<TournamentOrganizerWorkspaceData>> updateStaffPermissions({
    required String organizerId,
    required String tournamentId,
    required String assignmentId,
    required Set<String> delegatedPermissions,
  });
}
