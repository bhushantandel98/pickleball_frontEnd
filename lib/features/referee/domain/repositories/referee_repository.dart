import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/referee/domain/entities/referee_entities.dart';

/// Repository contract for Feature 5.3 — Referee Module.
///
/// Every method requires validated [tournamentId] and [refereeId] context
/// and enforces tournament-scoped, match-assignment-level authorization.
abstract class RefereeRepository {
  Future<Result<RefereeWorkspaceData>> getWorkspace({
    required String tournamentId,
    required String refereeId,
  });

  Future<Result<RefereeWorkspaceData>> startMatch({
    required String tournamentId,
    required String refereeId,
    required String matchId,
  });

  Future<Result<RefereeWorkspaceData>> awardPoint({
    required String tournamentId,
    required String refereeId,
    required String matchId,
    required String side, // 'A' or 'B'
  });

  Future<Result<RefereeWorkspaceData>> switchServe({
    required String tournamentId,
    required String refereeId,
    required String matchId,
  });

  Future<Result<RefereeWorkspaceData>> submitMatchResult({
    required String tournamentId,
    required String refereeId,
    required String matchId,
    String? finalScoreOverride,
    String? winnerOverride,
  });
}
