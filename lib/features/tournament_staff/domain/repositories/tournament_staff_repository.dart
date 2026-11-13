import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/tournament_staff/domain/entities/tournament_staff_entities.dart';

/// Repository contract for Feature 5.2 — Tournament Staff Module.
///
/// Every operation requires validated [tournamentId] and [staffId] context and
/// enforces delegated [TournamentStaffPermission] checks.
abstract class TournamentStaffRepository {
  Future<Result<TournamentStaffWorkspaceData>> getWorkspace({
    required String tournamentId,
    required String staffId,
  });

  Future<Result<TournamentStaffWorkspaceData>> toggleCheckIn({
    required String tournamentId,
    required String staffId,
    required String checkInId,
    required bool isCheckedIn,
  });

  Future<Result<TournamentStaffWorkspaceData>> assignMatchReferee({
    required String tournamentId,
    required String staffId,
    required String matchId,
    required String refereeAssignmentId,
  });

  Future<Result<TournamentStaffWorkspaceData>> correctMatchScore({
    required String tournamentId,
    required String staffId,
    required String matchId,
    required String scoreSummary,
    required String winnerLabel,
    required String correctionReason,
  });
}
