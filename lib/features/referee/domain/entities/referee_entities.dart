import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/entities/tournament_organizer_entities.dart';

/// Authenticated Referee profile scoped to an assigned tournament.
class RefereeProfile extends Equatable {
  final String refereeId;
  final String tournamentId;
  final String tournamentName;
  final String venueName;
  final String refereeName;
  final String refereeEmail;
  final String certificationLevel;
  final bool isActive;

  const RefereeProfile({
    required this.refereeId,
    required this.tournamentId,
    required this.tournamentName,
    required this.venueName,
    required this.refereeName,
    required this.refereeEmail,
    required this.certificationLevel,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        refereeId,
        tournamentId,
        tournamentName,
        venueName,
        refereeName,
        refereeEmail,
        certificationLevel,
        isActive,
      ];
}

/// Individual game score inside a match.
class RefereeGameScore extends Equatable {
  final int gameNumber;
  final int scoreA;
  final int scoreB;
  final bool isComplete;

  const RefereeGameScore({
    required this.gameNumber,
    this.scoreA = 0,
    this.scoreB = 0,
    this.isComplete = false,
  });

  RefereeGameScore copyWith({
    int? scoreA,
    int? scoreB,
    bool? isComplete,
  }) {
    return RefereeGameScore(
      gameNumber: gameNumber,
      scoreA: scoreA ?? this.scoreA,
      scoreB: scoreB ?? this.scoreB,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  List<Object?> get props => [gameNumber, scoreA, scoreB, isComplete];
}

/// Match assigned to the authenticated Referee, carrying organizer-defined
/// read-only [scoringConfig].
class RefereeMatchAssignment extends Equatable {
  final String id;
  final String tournamentId;
  final String categoryName;
  final TournamentEventFormat eventFormat;
  final String roundLabel;
  final String courtName;
  final DateTime scheduledTime;
  final String participantA;
  final String participantB;
  final String refereeId;
  final TournamentScoringConfig scoringConfig;
  final OrganizerMatchStatus status;
  final List<RefereeGameScore> games;
  final int currentGameIndex;
  final String servingSide; // 'A' or 'B'
  final int serverNumber; // 1 or 2
  final String? winnerLabel;
  final DateTime? submittedAt;

  const RefereeMatchAssignment({
    required this.id,
    required this.tournamentId,
    required this.categoryName,
    required this.eventFormat,
    required this.roundLabel,
    required this.courtName,
    required this.scheduledTime,
    required this.participantA,
    required this.participantB,
    required this.refereeId,
    required this.scoringConfig,
    this.status = OrganizerMatchStatus.scheduled,
    this.games = const [RefereeGameScore(gameNumber: 1)],
    this.currentGameIndex = 0,
    this.servingSide = 'A',
    this.serverNumber = 1,
    this.winnerLabel,
    this.submittedAt,
  });

  bool get isSubmitted =>
      status == OrganizerMatchStatus.completed && submittedAt != null;

  String get formattedScoreSummary =>
      games.map((g) => '${g.scoreA}-${g.scoreB}').join(', ');

  int get gamesWonA => games
      .where((g) => g.isComplete && g.scoreA > g.scoreB)
      .length;

  int get gamesWonB => games
      .where((g) => g.isComplete && g.scoreB > g.scoreA)
      .length;

  RefereeMatchAssignment copyWith({
    OrganizerMatchStatus? status,
    List<RefereeGameScore>? games,
    int? currentGameIndex,
    String? servingSide,
    int? serverNumber,
    String? winnerLabel,
    DateTime? submittedAt,
  }) {
    return RefereeMatchAssignment(
      id: id,
      tournamentId: tournamentId,
      categoryName: categoryName,
      eventFormat: eventFormat,
      roundLabel: roundLabel,
      courtName: courtName,
      scheduledTime: scheduledTime,
      participantA: participantA,
      participantB: participantB,
      refereeId: refereeId,
      scoringConfig: scoringConfig,
      status: status ?? this.status,
      games: games ?? this.games,
      currentGameIndex: currentGameIndex ?? this.currentGameIndex,
      servingSide: servingSide ?? this.servingSide,
      serverNumber: serverNumber ?? this.serverNumber,
      winnerLabel: winnerLabel ?? this.winnerLabel,
      submittedAt: submittedAt ?? this.submittedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        categoryName,
        eventFormat,
        roundLabel,
        courtName,
        scheduledTime,
        participantA,
        participantB,
        refereeId,
        scoringConfig,
        status,
        games,
        currentGameIndex,
        servingSide,
        serverNumber,
        winnerLabel,
        submittedAt,
      ];
}

/// Permitted read-only tournament standings entry visible to the Referee.
class RefereeStandingEntry extends Equatable {
  final String categoryName;
  final String participantLabel;
  final int played;
  final int won;
  final int lost;
  final int pointDifferential;

  const RefereeStandingEntry({
    required this.categoryName,
    required this.participantLabel,
    required this.played,
    required this.won,
    required this.lost,
    required this.pointDifferential,
  });

  @override
  List<Object?> get props => [
        categoryName,
        participantLabel,
        played,
        won,
        lost,
        pointDifferential,
      ];
}

/// Aggregated Referee workspace scoped strictly to [profile.tournamentId]
/// and [profile.refereeId].
class RefereeWorkspaceData extends Equatable {
  final RefereeProfile profile;
  final List<RefereeMatchAssignment> assignedMatches;
  final List<OrganizerMatchSlot> tournamentSchedule;
  final List<RefereeStandingEntry> standings;

  const RefereeWorkspaceData({
    required this.profile,
    required this.assignedMatches,
    required this.tournamentSchedule,
    required this.standings,
  });

  @override
  List<Object?> get props => [
        profile,
        assignedMatches,
        tournamentSchedule,
        standings,
      ];
}
