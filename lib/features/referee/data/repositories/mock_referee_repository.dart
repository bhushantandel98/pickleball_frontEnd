import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/referee/domain/entities/referee_entities.dart';
import 'package:pickleball_platform/features/referee/domain/repositories/referee_repository.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/entities/tournament_organizer_entities.dart';

/// Mock implementation of [RefereeRepository] enforcing tournament-scoped and
/// referee-assignment-scoped access control.
class MockRefereeRepository implements RefereeRepository {
  static const String _seededTournamentId = 'tourn_org_001';
  static const String _seededOrganizerId = 'org_001';
  static const String _seededRefereeId = 'user_ref_001';

  final RefereeProfile _profile = const RefereeProfile(
    refereeId: _seededRefereeId,
    tournamentId: _seededTournamentId,
    tournamentName: 'Metro Open Pickleball Championship',
    venueName: 'Grand Slam Pickleball Arena',
    refereeName: 'Vikram Rao',
    refereeEmail: 'vikram.rao@pickleball.app',
    certificationLevel: 'USAPA Certified L2',
    isActive: true,
  );

  final List<RefereeMatchAssignment> _matches = [
    RefereeMatchAssignment(
      id: 'm_cat_ms_open_1',
      tournamentId: _seededTournamentId,
      categoryName: "Men's Singles Open",
      eventFormat: TournamentEventFormat.singles,
      roundLabel: 'Quarterfinal 1',
      courtName: 'Center Court 1',
      scheduledTime: DateTime(2026, 11, 15, 9, 0),
      participantA: 'Arjun Mehta',
      participantB: 'Rohan Kapoor',
      refereeId: _seededRefereeId,
      scoringConfig: const TournamentScoringConfig(
        method: TournamentScoringMethod.rallyScoring,
        pointsPerGame: 11,
        winBy: 2,
        bestOfGames: 3,
        trackPositionsAndServiceOrder: true,
      ),
      status: OrganizerMatchStatus.inProgress,
      games: const [
        RefereeGameScore(gameNumber: 1, scoreA: 11, scoreB: 8, isComplete: true),
        RefereeGameScore(gameNumber: 2, scoreA: 7, scoreB: 9, isComplete: false),
      ],
      currentGameIndex: 1,
      servingSide: 'B',
      serverNumber: 1,
    ),
    RefereeMatchAssignment(
      id: 'm_cat_ms_open_3',
      tournamentId: _seededTournamentId,
      categoryName: 'Mixed Doubles 4.0',
      eventFormat: TournamentEventFormat.doubles,
      roundLabel: 'Semifinal 1',
      courtName: 'Court 2',
      scheduledTime: DateTime(2026, 11, 15, 11, 30),
      participantA: 'Neha / Kabir',
      participantB: 'Sanya / Dev',
      refereeId: _seededRefereeId,
      scoringConfig: const TournamentScoringConfig(
        method: TournamentScoringMethod.sideOutScoring,
        pointsPerGame: 11,
        winBy: 2,
        bestOfGames: 3,
        trackPositionsAndServiceOrder: true,
      ),
      status: OrganizerMatchStatus.scheduled,
      games: const [RefereeGameScore(gameNumber: 1)],
      currentGameIndex: 0,
      servingSide: 'A',
      serverNumber: 2,
    ),
    // Match assigned to another referee in the same tournament (must be excluded).
    RefereeMatchAssignment(
      id: 'm_cat_ms_open_2',
      tournamentId: _seededTournamentId,
      categoryName: "Men's Singles Open",
      eventFormat: TournamentEventFormat.singles,
      roundLabel: 'Quarterfinal 2',
      courtName: 'Court 3',
      scheduledTime: DateTime(2026, 11, 15, 10, 0),
      participantA: 'Siddharth Nair',
      participantB: 'Karan Verma',
      refereeId: 'user_ref_002',
      scoringConfig: const TournamentScoringConfig(
        method: TournamentScoringMethod.rallyScoring,
        pointsPerGame: 11,
        winBy: 2,
        bestOfGames: 3,
      ),
      status: OrganizerMatchStatus.scheduled,
    ),
    // Cross-tournament match (must be excluded from all lists and mutations).
    RefereeMatchAssignment(
      id: 'm_other_999',
      tournamentId: 'tourn_other_999',
      categoryName: "Women's Singles",
      eventFormat: TournamentEventFormat.singles,
      roundLabel: 'Final',
      courtName: 'Arena 1',
      scheduledTime: DateTime(2026, 11, 16, 14, 0),
      participantA: 'Ananya Sen',
      participantB: 'Meera Joshi',
      refereeId: _seededRefereeId,
      scoringConfig: const TournamentScoringConfig(
        method: TournamentScoringMethod.sideOutScoring,
        pointsPerGame: 15,
        winBy: 2,
        bestOfGames: 1,
      ),
      status: OrganizerMatchStatus.scheduled,
    ),
  ];

  final List<OrganizerMatchSlot> _schedule = [
    OrganizerMatchSlot(
      id: 'm_cat_ms_open_1',
      tournamentId: _seededTournamentId,
      organizerId: _seededOrganizerId,
      categoryId: 'cat_ms_open',
      categoryName: "Men's Singles Open",
      bracketFormat: TournamentBracketFormat.knockout,
      roundLabel: 'Quarterfinal 1',
      matchNumber: 1,
      courtName: 'Center Court 1',
      scheduledTime: DateTime(2026, 11, 15, 9, 0),
      participantA: 'Arjun Mehta',
      participantB: 'Rohan Kapoor',
      status: OrganizerMatchStatus.inProgress,
      refereeId: _seededRefereeId,
      refereeName: 'Vikram Rao',
    ),
    OrganizerMatchSlot(
      id: 'm_cat_ms_open_2',
      tournamentId: _seededTournamentId,
      organizerId: _seededOrganizerId,
      categoryId: 'cat_ms_open',
      categoryName: "Men's Singles Open",
      bracketFormat: TournamentBracketFormat.knockout,
      roundLabel: 'Quarterfinal 2',
      matchNumber: 2,
      courtName: 'Court 3',
      scheduledTime: DateTime(2026, 11, 15, 10, 0),
      participantA: 'Siddharth Nair',
      participantB: 'Karan Verma',
      status: OrganizerMatchStatus.scheduled,
      refereeId: 'user_ref_002',
      refereeName: 'Priya Sharma',
    ),
    OrganizerMatchSlot(
      id: 'm_cat_ms_open_3',
      tournamentId: _seededTournamentId,
      organizerId: _seededOrganizerId,
      categoryId: 'cat_xd_40',
      categoryName: 'Mixed Doubles 4.0',
      bracketFormat: TournamentBracketFormat.knockout,
      roundLabel: 'Semifinal 1',
      matchNumber: 3,
      courtName: 'Court 2',
      scheduledTime: DateTime(2026, 11, 15, 11, 30),
      participantA: 'Neha / Kabir',
      participantB: 'Sanya / Dev',
      status: OrganizerMatchStatus.scheduled,
      refereeId: _seededRefereeId,
      refereeName: 'Vikram Rao',
    ),
  ];

  final List<RefereeStandingEntry> _standings = const [
    RefereeStandingEntry(
      categoryName: "Men's Singles Open",
      participantLabel: 'Arjun Mehta',
      played: 3,
      won: 3,
      lost: 0,
      pointDifferential: 18,
    ),
    RefereeStandingEntry(
      categoryName: "Men's Singles Open",
      participantLabel: 'Rohan Kapoor',
      played: 3,
      won: 2,
      lost: 1,
      pointDifferential: 9,
    ),
    RefereeStandingEntry(
      categoryName: 'Mixed Doubles 4.0',
      participantLabel: 'Neha / Kabir',
      played: 2,
      won: 2,
      lost: 0,
      pointDifferential: 14,
    ),
    RefereeStandingEntry(
      categoryName: 'Mixed Doubles 4.0',
      participantLabel: 'Sanya / Dev',
      played: 2,
      won: 1,
      lost: 1,
      pointDifferential: 4,
    ),
  ];

  Failure? _validateContext(String tournamentId, String refereeId) {
    if (tournamentId != _profile.tournamentId ||
        refereeId != _profile.refereeId) {
      return const ForbiddenFailure(
        message: 'Access denied: Referee session does not match this tournament.',
      );
    }
    if (!_profile.isActive) {
      return const ForbiddenFailure(
        message: 'Access denied: Referee profile is inactive for this tournament.',
      );
    }
    return null;
  }

  int _findAuthorizedMatchIndex(
    String tournamentId,
    String refereeId,
    String matchId,
  ) {
    return _matches.indexWhere(
      (m) =>
          m.id == matchId &&
          m.tournamentId == tournamentId &&
          m.refereeId == refereeId,
    );
  }

  RefereeWorkspaceData _buildWorkspace(String tournamentId, String refereeId) {
    final assigned = _matches
        .where(
          (m) => m.tournamentId == tournamentId && m.refereeId == refereeId,
        )
        .toList(growable: false);

    final schedule = _schedule
        .where((s) => s.tournamentId == tournamentId)
        .toList(growable: false);

    return RefereeWorkspaceData(
      profile: _profile,
      assignedMatches: assigned,
      tournamentSchedule: schedule,
      standings: List.unmodifiable(_standings),
    );
  }

  void _syncScheduleStatus(
    String matchId,
    OrganizerMatchStatus status, {
    String? scoreSummary,
    String? winnerLabel,
  }) {
    final idx = _schedule.indexWhere((s) => s.id == matchId);
    if (idx == -1) return;
    _schedule[idx] = _schedule[idx].copyWith(
      status: status,
      scoreSummary: scoreSummary,
      winnerLabel: winnerLabel,
    );
  }

  @override
  Future<Result<RefereeWorkspaceData>> getWorkspace({
    required String tournamentId,
    required String refereeId,
  }) async {
    final failure = _validateContext(tournamentId, refereeId);
    if (failure != null) return FailureResult(failure);
    return Success(_buildWorkspace(tournamentId, refereeId));
  }

  @override
  Future<Result<RefereeWorkspaceData>> startMatch({
    required String tournamentId,
    required String refereeId,
    required String matchId,
  }) async {
    final failure = _validateContext(tournamentId, refereeId);
    if (failure != null) return FailureResult(failure);

    final idx = _findAuthorizedMatchIndex(tournamentId, refereeId, matchId);
    if (idx == -1) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Match is not assigned to your referee session.',
        ),
      );
    }

    final match = _matches[idx];
    if (match.isSubmitted) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Submitted match results are locked and cannot be modified.',
        ),
      );
    }

    _matches[idx] = match.copyWith(status: OrganizerMatchStatus.inProgress);
    _syncScheduleStatus(matchId, OrganizerMatchStatus.inProgress);

    return Success(_buildWorkspace(tournamentId, refereeId));
  }

  @override
  Future<Result<RefereeWorkspaceData>> awardPoint({
    required String tournamentId,
    required String refereeId,
    required String matchId,
    required String side,
  }) async {
    final failure = _validateContext(tournamentId, refereeId);
    if (failure != null) return FailureResult(failure);

    if (side != 'A' && side != 'B') {
      return const FailureResult(
        ValidationFailure(
          message: 'Invalid scoring side. Must be A or B.',
        ),
      );
    }

    final idx = _findAuthorizedMatchIndex(tournamentId, refereeId, matchId);
    if (idx == -1) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Match is not assigned to your referee session.',
        ),
      );
    }

    final match = _matches[idx];
    if (match.isSubmitted) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Submitted match results are locked and cannot be modified.',
        ),
      );
    }

    final games = List<RefereeGameScore>.from(match.games);
    final activeIdx = match.currentGameIndex.clamp(0, games.length - 1);
    final currentGame = games[activeIdx];

    if (currentGame.isComplete) {
      return const FailureResult(
        ValidationFailure(
          message: 'Current game is already complete. Submit the match result.',
        ),
      );
    }

    final nextScoreA = side == 'A' ? currentGame.scoreA + 1 : currentGame.scoreA;
    final nextScoreB = side == 'B' ? currentGame.scoreB + 1 : currentGame.scoreB;
    final target = match.scoringConfig.pointsPerGame;
    final winBy = match.scoringConfig.winBy;
    final diff = (nextScoreA - nextScoreB).abs();
    final gameWon =
        (nextScoreA >= target || nextScoreB >= target) && diff >= winBy;

    games[activeIdx] = currentGame.copyWith(
      scoreA: nextScoreA,
      scoreB: nextScoreB,
      isComplete: gameWon,
    );

    var nextGameIndex = activeIdx;
    if (gameWon) {
      final gamesToWin = (match.scoringConfig.bestOfGames ~/ 2) + 1;
      final wonA = games.where((g) => g.isComplete && g.scoreA > g.scoreB).length;
      final wonB = games.where((g) => g.isComplete && g.scoreB > g.scoreA).length;
      final matchDecided = wonA >= gamesToWin || wonB >= gamesToWin;
      if (!matchDecided && games.length < match.scoringConfig.bestOfGames) {
        games.add(RefereeGameScore(gameNumber: games.length + 1));
        nextGameIndex = games.length - 1;
      }
    }

    _matches[idx] = match.copyWith(
      status: OrganizerMatchStatus.inProgress,
      games: games,
      currentGameIndex: nextGameIndex,
      servingSide: side,
    );
    _syncScheduleStatus(matchId, OrganizerMatchStatus.inProgress);

    return Success(_buildWorkspace(tournamentId, refereeId));
  }

  @override
  Future<Result<RefereeWorkspaceData>> switchServe({
    required String tournamentId,
    required String refereeId,
    required String matchId,
  }) async {
    final failure = _validateContext(tournamentId, refereeId);
    if (failure != null) return FailureResult(failure);

    final idx = _findAuthorizedMatchIndex(tournamentId, refereeId, matchId);
    if (idx == -1) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Match is not assigned to your referee session.',
        ),
      );
    }

    final match = _matches[idx];
    if (match.isSubmitted) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Submitted match results are locked and cannot be modified.',
        ),
      );
    }

    var nextSide = match.servingSide;
    var nextServer = match.serverNumber;
    if (match.eventFormat == TournamentEventFormat.doubles) {
      if (match.serverNumber == 1) {
        nextServer = 2;
      } else {
        nextSide = match.servingSide == 'A' ? 'B' : 'A';
        nextServer = 1;
      }
    } else {
      nextSide = match.servingSide == 'A' ? 'B' : 'A';
      nextServer = 1;
    }

    _matches[idx] = match.copyWith(
      servingSide: nextSide,
      serverNumber: nextServer,
    );

    return Success(_buildWorkspace(tournamentId, refereeId));
  }

  @override
  Future<Result<RefereeWorkspaceData>> submitMatchResult({
    required String tournamentId,
    required String refereeId,
    required String matchId,
    String? finalScoreOverride,
    String? winnerOverride,
  }) async {
    final failure = _validateContext(tournamentId, refereeId);
    if (failure != null) return FailureResult(failure);

    final idx = _findAuthorizedMatchIndex(tournamentId, refereeId, matchId);
    if (idx == -1) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Match is not assigned to your referee session.',
        ),
      );
    }

    final match = _matches[idx];
    if (match.isSubmitted) {
      return const FailureResult(
        ForbiddenFailure(
          message:
              'Result already submitted. Referee cannot modify submitted scores.',
        ),
      );
    }

    final updatedGames = List<RefereeGameScore>.from(match.games);
    String? computedWinner = winnerOverride?.trim();

    if (finalScoreOverride != null && finalScoreOverride.trim().isNotEmpty) {
      final parsed = _parseScoreOverride(finalScoreOverride.trim());
      if (parsed == null || parsed.isEmpty) {
        return const FailureResult(
          ValidationFailure(
            message:
                'Enter final scores as comma-separated pairs (e.g. 11-7, 11-9).',
          ),
        );
      }
      updatedGames
        ..clear()
        ..addAll(parsed);
    } else {
      for (var i = 0; i < updatedGames.length; i++) {
        final g = updatedGames[i];
        if (!g.isComplete && (g.scoreA > 0 || g.scoreB > 0)) {
          updatedGames[i] = g.copyWith(isComplete: true);
        }
      }
    }

    final wonA =
        updatedGames.where((g) => g.isComplete && g.scoreA > g.scoreB).length;
    final wonB =
        updatedGames.where((g) => g.isComplete && g.scoreB > g.scoreA).length;

    if (computedWinner == null || computedWinner.isEmpty) {
      if (wonA > wonB) {
        computedWinner = match.participantA;
      } else if (wonB > wonA) {
        computedWinner = match.participantB;
      } else {
        return const FailureResult(
          ValidationFailure(
            message:
                'Cannot determine match winner from tied games. Specify winner or complete the deciding game.',
          ),
        );
      }
    }

    final submittedMatch = match.copyWith(
      status: OrganizerMatchStatus.completed,
      games: updatedGames,
      winnerLabel: computedWinner,
      submittedAt: DateTime.now(),
    );

    _matches[idx] = submittedMatch;
    _syncScheduleStatus(
      matchId,
      OrganizerMatchStatus.completed,
      scoreSummary: submittedMatch.formattedScoreSummary,
      winnerLabel: computedWinner,
    );

    return Success(_buildWorkspace(tournamentId, refereeId));
  }

  List<RefereeGameScore>? _parseScoreOverride(String raw) {
    final segments = raw.split(',');
    final result = <RefereeGameScore>[];
    for (var i = 0; i < segments.length; i++) {
      final parts = segments[i].trim().split('-');
      if (parts.length != 2) return null;
      final a = int.tryParse(parts[0].trim());
      final b = int.tryParse(parts[1].trim());
      if (a == null || b == null || a < 0 || b < 0 || a == b) return null;
      result.add(
        RefereeGameScore(
          gameNumber: i + 1,
          scoreA: a,
          scoreB: b,
          isComplete: true,
        ),
      );
    }
    return result;
  }
}
