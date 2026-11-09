import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Match operational lifecycle status.
enum MatchStatus {
  scheduled('Scheduled'),
  warmup('Warmup'),
  live('Live'),
  completed('Completed'),
  delayed('Delayed');

  final String displayName;
  const MatchStatus(this.displayName);
}

/// Domain entity representing a tournament match fixture involving the player.
class PlayerMatch extends Equatable {
  final String id;
  final String tournamentId;
  final String tournamentName;
  final String category;
  final String round;
  final String courtName;
  final DateTime scheduledTime;
  final MatchStatus status;
  final String player1Name;
  final int? player1Seed;
  final List<int> player1Score;
  final String player2Name;
  final int? player2Seed;
  final List<int> player2Score;
  final int currentSet;
  final int serverIndex;
  final String? refereeName;
  final String? winnerName;
  final bool isCheckedIn;
  final DateTime? checkInDeadline;

  const PlayerMatch({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.category,
    required this.round,
    required this.courtName,
    required this.scheduledTime,
    this.status = MatchStatus.scheduled,
    required this.player1Name,
    this.player1Seed,
    this.player1Score = const [],
    required this.player2Name,
    this.player2Seed,
    this.player2Score = const [],
    this.currentSet = 1,
    this.serverIndex = 1,
    this.refereeName,
    this.winnerName,
    this.isCheckedIn = false,
    this.checkInDeadline,
  });

  bool get isLive => status == MatchStatus.live;
  bool get isCompleted => status == MatchStatus.completed;
  bool get isScheduled =>
      status == MatchStatus.scheduled ||
      status == MatchStatus.warmup ||
      status == MatchStatus.delayed;

  String get formattedTime => DateFormat('hh:mm a').format(scheduledTime);

  String get scoreSummary {
    if (player1Score.isEmpty && player2Score.isEmpty) return 'Not Started';
    final sets = <String>[];
    final count = player1Score.length;
    for (int i = 0; i < count; i++) {
      final p1 = player1Score[i];
      final p2 = i < player2Score.length ? player2Score[i] : 0;
      sets.add('$p1-$p2');
    }
    return sets.join(', ');
  }

  PlayerMatch copyWith({
    String? id,
    String? tournamentId,
    String? tournamentName,
    String? category,
    String? round,
    String? courtName,
    DateTime? scheduledTime,
    MatchStatus? status,
    String? player1Name,
    int? player1Seed,
    List<int>? player1Score,
    String? player2Name,
    int? player2Seed,
    List<int>? player2Score,
    int? currentSet,
    int? serverIndex,
    String? refereeName,
    String? winnerName,
    bool? isCheckedIn,
    DateTime? checkInDeadline,
  }) {
    return PlayerMatch(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      tournamentName: tournamentName ?? this.tournamentName,
      category: category ?? this.category,
      round: round ?? this.round,
      courtName: courtName ?? this.courtName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      status: status ?? this.status,
      player1Name: player1Name ?? this.player1Name,
      player1Seed: player1Seed ?? this.player1Seed,
      player1Score: player1Score ?? this.player1Score,
      player2Name: player2Name ?? this.player2Name,
      player2Seed: player2Seed ?? this.player2Seed,
      player2Score: player2Score ?? this.player2Score,
      currentSet: currentSet ?? this.currentSet,
      serverIndex: serverIndex ?? this.serverIndex,
      refereeName: refereeName ?? this.refereeName,
      winnerName: winnerName ?? this.winnerName,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkInDeadline: checkInDeadline ?? this.checkInDeadline,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        tournamentName,
        category,
        round,
        courtName,
        scheduledTime,
        status,
        player1Name,
        player1Seed,
        player1Score,
        player2Name,
        player2Seed,
        player2Score,
        currentSet,
        serverIndex,
        refereeName,
        winnerName,
        isCheckedIn,
        checkInDeadline,
      ];
}

/// Domain entity representing a court's live status and assigned matches.
class CourtLiveMatch extends Equatable {
  final String courtId;
  final String courtName;
  final String tournamentName;
  final String category;
  final PlayerMatch? currentMatch;
  final PlayerMatch? nextMatch;

  const CourtLiveMatch({
    required this.courtId,
    required this.courtName,
    required this.tournamentName,
    required this.category,
    this.currentMatch,
    this.nextMatch,
  });

  @override
  List<Object?> get props => [
        courtId,
        courtName,
        tournamentName,
        category,
        currentMatch,
        nextMatch,
      ];
}

/// Row entry in a tournament pool or group standings table.
class StandingsRow extends Equatable {
  final int rank;
  final String playerName;
  final String pool;
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int pointDifferential;
  final bool isQualified;

  const StandingsRow({
    required this.rank,
    required this.playerName,
    required this.pool,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.matchesLost,
    required this.pointDifferential,
    this.isQualified = false,
  });

  @override
  List<Object?> get props => [
        rank,
        playerName,
        pool,
        matchesPlayed,
        matchesWon,
        matchesLost,
        pointDifferential,
        isQualified,
      ];
}

/// Fixture pairing node in an elimination bracket tree.
class BracketNode extends Equatable {
  final String id;
  final String roundName;
  final int matchIndex;
  final String player1;
  final int? player1Seed;
  final String player1Score;
  final String player2;
  final int? player2Seed;
  final String player2Score;
  final String? winner;
  final bool isLive;
  final String? court;

  const BracketNode({
    required this.id,
    required this.roundName,
    required this.matchIndex,
    required this.player1,
    this.player1Seed,
    this.player1Score = '',
    required this.player2,
    this.player2Seed,
    this.player2Score = '',
    this.winner,
    this.isLive = false,
    this.court,
  });

  @override
  List<Object?> get props => [
        id,
        roundName,
        matchIndex,
        player1,
        player1Seed,
        player1Score,
        player2,
        player2Seed,
        player2Score,
        winner,
        isLive,
        court,
      ];
}

/// Aggregate root entity encapsulating all player Match Day data.
class PlayerMatchDayData extends Equatable {
  final String tournamentId;
  final String tournamentName;
  final String tournamentVenue;
  final DateTime date;
  final List<PlayerMatch> myMatches;
  final List<CourtLiveMatch> courtMatches;
  final List<StandingsRow> standings;
  final List<BracketNode> bracket;

  const PlayerMatchDayData({
    required this.tournamentId,
    required this.tournamentName,
    required this.tournamentVenue,
    required this.date,
    required this.myMatches,
    required this.courtMatches,
    required this.standings,
    required this.bracket,
  });

  /// Player's currently active or next upcoming match.
  PlayerMatch? get activeOrNextMatch {
    final live = myMatches.where((m) => m.isLive);
    if (live.isNotEmpty) return live.first;
    final scheduled = myMatches.where((m) => m.isScheduled).toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    if (scheduled.isNotEmpty) return scheduled.first;
    return myMatches.isNotEmpty ? myMatches.first : null;
  }

  @override
  List<Object?> get props => [
        tournamentId,
        tournamentName,
        tournamentVenue,
        date,
        myMatches,
        courtMatches,
        standings,
        bracket,
      ];
}
