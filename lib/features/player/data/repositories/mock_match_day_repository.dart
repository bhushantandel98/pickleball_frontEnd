import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/match_day_data.dart';
import 'package:pickleball_platform/features/player/domain/repositories/match_day_repository.dart';

/// In-memory mock implementation of [MatchDayRepository].
class MockMatchDayRepository implements MatchDayRepository {
  final bool shouldFail;
  final bool isEmpty;
  PlayerMatchDayData? customData;

  MockMatchDayRepository({
    this.shouldFail = false,
    this.isEmpty = false,
    this.customData,
  });

  static PlayerMatchDayData createDefaultMockData() {
    final now = DateTime.now();

    final matchLive = PlayerMatch(
      id: 'match_live_001',
      tournamentId: 'tourn_001',
      tournamentName: 'National Pickleball Open 2026',
      category: 'Men\'s Singles Open',
      round: 'Semi-Final',
      courtName: 'Court 1 (Championship Court)',
      scheduledTime: DateTime(now.year, now.month, now.day, 15, 45),
      status: MatchStatus.live,
      player1Name: 'Alex Rivera',
      player1Seed: 5,
      player1Score: const [11, 8, 6],
      player2Name: 'Jordan Cruz',
      player2Seed: 3,
      player2Score: const [9, 11, 4],
      currentSet: 3,
      serverIndex: 1,
      refereeName: 'Carlos Vega',
      isCheckedIn: true,
    );

    final scheduledTime = now.hour >= 17
        ? now.add(const Duration(hours: 2, minutes: 30))
        : DateTime(now.year, now.month, now.day, 17, 30);
    final checkInDeadline = scheduledTime.subtract(const Duration(minutes: 15));

    final matchScheduled = PlayerMatch(
      id: 'match_sched_002',
      tournamentId: 'tourn_001',
      tournamentName: 'National Pickleball Open 2026',
      category: 'Mixed Doubles 3.5',
      round: 'Quarter-Final',
      courtName: 'Court 3',
      scheduledTime: scheduledTime,
      status: MatchStatus.scheduled,
      player1Name: 'Alex Rivera / Maya Lin',
      player1Seed: 2,
      player2Name: 'Rohan Verma / Priya Rao',
      player2Seed: 4,
      refereeName: 'Sara Connor',
      isCheckedIn: false,
      checkInDeadline: checkInDeadline,
    );

    final matchCompleted = PlayerMatch(
      id: 'match_comp_003',
      tournamentId: 'tourn_001',
      tournamentName: 'National Pickleball Open 2026',
      category: 'Men\'s Singles Open',
      round: 'Quarter-Final',
      courtName: 'Court 2',
      scheduledTime: DateTime(now.year, now.month, now.day, 10, 30),
      status: MatchStatus.completed,
      player1Name: 'Alex Rivera',
      player1Seed: 5,
      player1Score: const [11, 11],
      player2Name: 'David Miller',
      player2Seed: 8,
      player2Score: const [7, 5],
      winnerName: 'Alex Rivera',
      refereeName: 'Carlos Vega',
      isCheckedIn: true,
    );

    final courtMatches = [
      CourtLiveMatch(
        courtId: 'court_1',
        courtName: 'Court 1 (Championship Court)',
        tournamentName: 'National Pickleball Open 2026',
        category: 'Men\'s Singles Open',
        currentMatch: matchLive,
        nextMatch: PlayerMatch(
          id: 'court1_next',
          tournamentId: 'tourn_001',
          tournamentName: 'National Pickleball Open 2026',
          category: 'Men\'s Singles Open',
          round: 'Semi-Final 2',
          courtName: 'Court 1 (Championship Court)',
          scheduledTime: DateTime(2026, 11, 9, 17, 0),
          player1Name: 'Marcus Bell',
          player2Name: 'David Miller',
        ),
      ),
      CourtLiveMatch(
        courtId: 'court_2',
        courtName: 'Court 2',
        tournamentName: 'National Pickleball Open 2026',
        category: 'Women\'s Singles Open',
        currentMatch: PlayerMatch(
          id: 'court2_live',
          tournamentId: 'tourn_001',
          tournamentName: 'National Pickleball Open 2026',
          category: 'Women\'s Singles Open',
          round: 'Semi-Final',
          courtName: 'Court 2',
          scheduledTime: DateTime(now.year, now.month, now.day, 15, 30),
          status: MatchStatus.live,
          player1Name: 'Ananya Patel',
          player1Seed: 1,
          player1Score: const [11, 5],
          player2Name: 'Neha Singh',
          player2Seed: 4,
          player2Score: const [8, 3],
          currentSet: 2,
          serverIndex: 2,
          refereeName: 'Sara Connor',
          isCheckedIn: true,
        ),
      ),
      CourtLiveMatch(
        courtId: 'court_3',
        courtName: 'Court 3',
        tournamentName: 'National Pickleball Open 2026',
        category: 'Mixed Doubles 3.5',
        nextMatch: matchScheduled,
      ),
      const CourtLiveMatch(
        courtId: 'court_4',
        courtName: 'Court 4',
        tournamentName: 'National Pickleball Open 2026',
        category: 'Men\'s Singles 4.0',
      ),
    ];

    const standings = [
      StandingsRow(
        rank: 1,
        playerName: 'Alex Rivera',
        pool: 'Pool A',
        matchesPlayed: 3,
        matchesWon: 3,
        matchesLost: 0,
        pointDifferential: 18,
        isQualified: true,
      ),
      StandingsRow(
        rank: 2,
        playerName: 'Jordan Cruz',
        pool: 'Pool A',
        matchesPlayed: 3,
        matchesWon: 2,
        matchesLost: 1,
        pointDifferential: 8,
        isQualified: true,
      ),
      StandingsRow(
        rank: 3,
        playerName: 'David Miller',
        pool: 'Pool A',
        matchesPlayed: 3,
        matchesWon: 1,
        matchesLost: 2,
        pointDifferential: -6,
        isQualified: false,
      ),
      StandingsRow(
        rank: 4,
        playerName: 'Marcus Bell',
        pool: 'Pool A',
        matchesPlayed: 3,
        matchesWon: 0,
        matchesLost: 3,
        pointDifferential: -20,
        isQualified: false,
      ),
      StandingsRow(
        rank: 1,
        playerName: 'Vikram Rao',
        pool: 'Pool B',
        matchesPlayed: 3,
        matchesWon: 3,
        matchesLost: 0,
        pointDifferential: 15,
        isQualified: true,
      ),
      StandingsRow(
        rank: 2,
        playerName: 'Kabir Mehta',
        pool: 'Pool B',
        matchesPlayed: 3,
        matchesWon: 2,
        matchesLost: 1,
        pointDifferential: 5,
        isQualified: true,
      ),
    ];

    const bracket = [
      BracketNode(
        id: 'qf_1',
        roundName: 'Quarter-Finals',
        matchIndex: 1,
        player1: 'Alex Rivera',
        player1Seed: 5,
        player1Score: '11, 11',
        player2: 'David Miller',
        player2Seed: 8,
        player2Score: '7, 5',
        winner: 'Alex Rivera',
      ),
      BracketNode(
        id: 'qf_2',
        roundName: 'Quarter-Finals',
        matchIndex: 2,
        player1: 'Jordan Cruz',
        player1Seed: 3,
        player1Score: '11, 11',
        player2: 'Marcus Bell',
        player2Seed: 6,
        player2Score: '9, 8',
        winner: 'Jordan Cruz',
      ),
      BracketNode(
        id: 'qf_3',
        roundName: 'Quarter-Finals',
        matchIndex: 3,
        player1: 'Vikram Rao',
        player1Seed: 1,
        player1Score: '11, 11',
        player2: 'Sameer Khan',
        player2Seed: 7,
        player2Score: '6, 4',
        winner: 'Vikram Rao',
      ),
      BracketNode(
        id: 'qf_4',
        roundName: 'Quarter-Finals',
        matchIndex: 4,
        player1: 'Kabir Mehta',
        player1Seed: 2,
        player1Score: '11, 9, 11',
        player2: 'Rohan Verma',
        player2Seed: 4,
        player2Score: '8, 11, 9',
        winner: 'Kabir Mehta',
      ),
      BracketNode(
        id: 'sf_1',
        roundName: 'Semi-Finals',
        matchIndex: 1,
        player1: 'Alex Rivera',
        player1Seed: 5,
        player1Score: '11, 8, 6',
        player2: 'Jordan Cruz',
        player2Seed: 3,
        player2Score: '9, 11, 4',
        isLive: true,
        court: 'Court 1',
      ),
      BracketNode(
        id: 'sf_2',
        roundName: 'Semi-Finals',
        matchIndex: 2,
        player1: 'Vikram Rao',
        player1Seed: 1,
        player1Score: '-',
        player2: 'Kabir Mehta',
        player2Seed: 2,
        player2Score: '-',
        court: 'Court 2',
      ),
      BracketNode(
        id: 'fn_1',
        roundName: 'Final',
        matchIndex: 1,
        player1: 'Winner SF1',
        player1Score: '-',
        player2: 'Winner SF2',
        player2Score: '-',
        court: 'Court 1',
      ),
    ];

    return PlayerMatchDayData(
      tournamentId: 'tourn_001',
      tournamentName: 'National Pickleball Open 2026',
      tournamentVenue: 'Grand Slam Pickleball Arena',
      date: now,
      myMatches: [matchLive, matchScheduled, matchCompleted],
      courtMatches: courtMatches,
      standings: standings,
      bracket: bracket,
    );
  }

  @override
  Future<Result<PlayerMatchDayData>> getMatchDayData({String? playerId}) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to load Match Day schedule. Please try again.'),
      );
    }

    if (isEmpty) {
      final now = DateTime.now();
      return Success(
        PlayerMatchDayData(
          tournamentId: '',
          tournamentName: '',
          tournamentVenue: '',
          date: now,
          myMatches: const [],
          courtMatches: const [],
          standings: const [],
          bracket: const [],
        ),
      );
    }

    customData ??= createDefaultMockData();
    return Success(customData!);
  }

  @override
  Future<Result<PlayerMatch>> checkInToMatch(String matchId, {DateTime? currentTime}) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to check in for match. Please try again.'),
      );
    }

    customData ??= createDefaultMockData();

    final index = customData!.myMatches.indexWhere((m) => m.id == matchId);
    if (index == -1) {
      return const FailureResult(NotFoundFailure(message: 'Match fixture not found'));
    }

    final match = customData!.myMatches[index];

    // 1. Prevent duplicate check-in
    if (match.isCheckedIn) {
      return const FailureResult(
        ValidationFailure(message: 'Player is already checked in for this match.'),
      );
    }

    // 2. Reject check-in for completed, live, delayed or otherwise ineligible matches
    if (match.status != MatchStatus.scheduled) {
      return FailureResult(
        ValidationFailure(
          message: 'Check-in is only available for scheduled matches. Current status: ${match.status.displayName}.',
        ),
      );
    }

    // 3. Reject check-in when deadline has expired
    final now = currentTime ?? DateTime.now();
    if (match.isCheckInDeadlineExpired(now)) {
      return const FailureResult(
        ValidationFailure(message: 'Check-in deadline has expired for this match.'),
      );
    }

    final updated = match.copyWith(isCheckedIn: true);

    final updatedMatches = List<PlayerMatch>.from(customData!.myMatches);
    updatedMatches[index] = updated;

    customData = PlayerMatchDayData(
      tournamentId: customData!.tournamentId,
      tournamentName: customData!.tournamentName,
      tournamentVenue: customData!.tournamentVenue,
      date: customData!.date,
      myMatches: updatedMatches,
      courtMatches: customData!.courtMatches,
      standings: customData!.standings,
      bracket: customData!.bracket,
    );

    return Success(updated);
  }
}
