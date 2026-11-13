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

    final nextGames = List<RefereeGameScore>.from(match.games);
    final activeIdx = match.currentGameIndex.clamp(0, nextGames.length - 1);
    final currentGame = nextGames[activeIdx];

    if (currentGame.isComplete) {
      return const FailureResult(
        ValidationFailure(
          message: 'Current game is already complete. Submit the match result.',
        ),
      );
    }

    var nextServingSide = match.servingSide;
    var nextServerNumber = match.serverNumber;
    var nextScoreA = currentGame.scoreA;
    var nextScoreB = currentGame.scoreB;

    if (match.scoringConfig.method == TournamentScoringMethod.sideOutScoring) {
      // Side-out scoring: only the serving side can score a point.
      // When the receiving side wins the rally, no point is awarded; serve
      // advances (server 1 -> 2 in doubles, or side-out to the other side).
      if (side == match.servingSide) {
        if (side == 'A') {
          nextScoreA += 1;
        } else {
          nextScoreB += 1;
        }
      } else {
        if (match.eventFormat == TournamentEventFormat.doubles &&
            match.serverNumber == 1) {
          nextServerNumber = 2;
        } else {
          nextServingSide = side;
          nextServerNumber = 1;
        }
      }
    } else {
      // Rally scoring: rally winner always scores a point and takes serve.
      if (side == 'A') {
        nextScoreA += 1;
      } else {
        nextScoreB += 1;
      }
      if (side != match.servingSide) {
        nextServingSide = side;
        nextServerNumber = 1;
      }
    }

    final target = match.scoringConfig.pointsPerGame;
    final winBy = match.scoringConfig.winBy;
    final diff = (nextScoreA - nextScoreB).abs();
    final gameWon =
        (nextScoreA >= target || nextScoreB >= target) && diff >= winBy;

    nextGames[activeIdx] = currentGame.copyWith(
      scoreA: nextScoreA,
      scoreB: nextScoreB,
      isComplete: gameWon,
    );

    var nextGameIndex = activeIdx;
    if (gameWon) {
      final gamesToWin = (match.scoringConfig.bestOfGames ~/ 2) + 1;
      final wonA =
          nextGames.where((g) => g.isComplete && g.scoreA > g.scoreB).length;
      final wonB =
          nextGames.where((g) => g.isComplete && g.scoreB > g.scoreA).length;
      final matchDecided = wonA >= gamesToWin || wonB >= gamesToWin;
      if (!matchDecided && nextGames.length < match.scoringConfig.bestOfGames) {
        nextGames.add(RefereeGameScore(gameNumber: nextGames.length + 1));
        nextGameIndex = nextGames.length - 1;
      }
    }

    _matches[idx] = match.copyWith(
      status: OrganizerMatchStatus.inProgress,
      games: nextGames,
      currentGameIndex: nextGameIndex,
      servingSide: nextServingSide,
      serverNumber: nextServerNumber,
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

    final cfg = match.scoringConfig;
    final gamesToWin = (cfg.bestOfGames ~/ 2) + 1;
    final updatedGames = List<RefereeGameScore>.from(match.games);

    if (finalScoreOverride != null && finalScoreOverride.trim().isNotEmpty) {
      final parsed = _parseAndValidateScoreOverride(
        finalScoreOverride.trim(),
        cfg,
      );
      if (parsed.failure != null) {
        return FailureResult(parsed.failure!);
      }
      updatedGames
        ..clear()
        ..addAll(parsed.games!);
    }

    final completedGames = updatedGames.where((g) => g.isComplete).toList();
    if (completedGames.length != updatedGames.length) {
      return const FailureResult(
        ValidationFailure(
          message:
              'Complete the active game or enter valid final game scores before submitting.',
        ),
      );
    }

    final wonA = completedGames.where((g) => g.scoreA > g.scoreB).length;
    final wonB = completedGames.where((g) => g.scoreB > g.scoreA).length;
    if (wonA != gamesToWin && wonB != gamesToWin) {
      return FailureResult(
        ValidationFailure(
          message:
              'Match is not yet decided under Best of ${cfg.bestOfGames} ($gamesToWin game(s) required to win).',
        ),
      );
    }

    final computedWinner =
        wonA > wonB ? match.participantA : match.participantB;

    if (winnerOverride != null && winnerOverride.trim().isNotEmpty) {
      final trimmedOverride = winnerOverride.trim();
      if (trimmedOverride != match.participantA &&
          trimmedOverride != match.participantB) {
        return const FailureResult(
          ValidationFailure(
            message: 'Winner must be one of the actual match participants.',
          ),
        );
      }
      if (trimmedOverride != computedWinner) {
        return FailureResult(
          ValidationFailure(
            message:
                'Selected winner ($trimmedOverride) does not match the game scores (winner: $computedWinner).',
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

  ({List<RefereeGameScore>? games, Failure? failure})
      _parseAndValidateScoreOverride(
    String raw,
    TournamentScoringConfig cfg,
  ) {
    final segments = raw
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (segments.isEmpty) {
      return (
        games: null,
        failure: const ValidationFailure(
          message:
              'Enter final scores as comma-separated pairs (e.g. 11-7, 11-9).',
        ),
      );
    }
    if (segments.length > cfg.bestOfGames) {
      return (
        games: null,
        failure: ValidationFailure(
          message:
              'Too many games (${segments.length}). Organizer rules allow Best of ${cfg.bestOfGames}.',
        ),
      );
    }

    final gamesToWin = (cfg.bestOfGames ~/ 2) + 1;
    var wonA = 0;
    var wonB = 0;
    final result = <RefereeGameScore>[];

    for (var i = 0; i < segments.length; i++) {
      if (wonA >= gamesToWin || wonB >= gamesToWin) {
        return (
          games: null,
          failure: const ValidationFailure(
            message:
                'Invalid score series: extra games cannot follow a decided match.',
          ),
        );
      }

      final parts = segments[i].split('-');
      if (parts.length != 2) {
        return (
          games: null,
          failure: const ValidationFailure(
            message:
                'Enter final scores as comma-separated pairs (e.g. 11-7, 11-9).',
          ),
        );
      }

      final a = int.tryParse(parts[0].trim());
      final b = int.tryParse(parts[1].trim());
      if (a == null || b == null || a < 0 || b < 0 || a == b) {
        return (
          games: null,
          failure: ValidationFailure(
            message: 'Game ${i + 1} has an invalid or tied score.',
          ),
        );
      }

      final high = a > b ? a : b;
      final low = a > b ? b : a;
      final diff = high - low;

      if (high < cfg.pointsPerGame || diff < cfg.winBy) {
        return (
          games: null,
          failure: ValidationFailure(
            message:
                'Game ${i + 1} ($a-$b) does not meet organizer rules (play to ${cfg.pointsPerGame}, win by ${cfg.winBy}).',
          ),
        );
      }
      if (high > cfg.pointsPerGame && diff != cfg.winBy) {
        return (
          games: null,
          failure: ValidationFailure(
            message:
                'Game ${i + 1} ($a-$b) exceeds ${cfg.pointsPerGame} without an exact win-by-${cfg.winBy} margin.',
          ),
        );
      }

      if (a > b) {
        wonA++;
      } else {
        wonB++;
      }

      result.add(
        RefereeGameScore(
          gameNumber: i + 1,
          scoreA: a,
          scoreB: b,
          isComplete: true,
        ),
      );
    }

    if (wonA != gamesToWin && wonB != gamesToWin) {
      return (
        games: null,
        failure: ValidationFailure(
          message:
              'Series is incomplete: $gamesToWin game win(s) required in Best of ${cfg.bestOfGames}.',
        ),
      );
    }

    return (games: result, failure: null);
  }
}
