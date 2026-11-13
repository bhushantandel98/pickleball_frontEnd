import 'package:pickleball_platform/features/tournament_organizer/domain/entities/tournament_organizer_entities.dart';

/// DTO for [TournamentScoringConfig].
class TournamentScoringConfigModel {
  final String method;
  final int pointsPerGame;
  final int bestOfGames;
  final int winBy;
  final bool trackPositionsAndServiceOrder;

  const TournamentScoringConfigModel({
    required this.method,
    required this.pointsPerGame,
    required this.bestOfGames,
    required this.winBy,
    required this.trackPositionsAndServiceOrder,
  });

  factory TournamentScoringConfigModel.fromJson(Map<String, dynamic> json) {
    return TournamentScoringConfigModel(
      method: json['method'] as String? ?? 'SIDE_OUT_SCORING',
      pointsPerGame: (json['pointsPerGame'] as num?)?.toInt() ?? 11,
      bestOfGames: (json['bestOfGames'] as num?)?.toInt() ?? 3,
      winBy: (json['winBy'] as num?)?.toInt() ?? 2,
      trackPositionsAndServiceOrder:
          json['trackPositionsAndServiceOrder'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'method': method,
        'pointsPerGame': pointsPerGame,
        'bestOfGames': bestOfGames,
        'winBy': winBy,
        'trackPositionsAndServiceOrder': trackPositionsAndServiceOrder,
      };

  TournamentScoringConfig toEntity() {
    final normalized = method.trim().toUpperCase();
    return TournamentScoringConfig(
      method: normalized == 'RALLY_SCORING'
          ? TournamentScoringMethod.rallyScoring
          : TournamentScoringMethod.sideOutScoring,
      pointsPerGame: pointsPerGame,
      bestOfGames: bestOfGames,
      winBy: winBy,
      trackPositionsAndServiceOrder: trackPositionsAndServiceOrder,
    );
  }
}

/// DTO for [OrganizerCategoryConfig].
class OrganizerCategoryConfigModel {
  final String id;
  final String tournamentId;
  final String organizerId;
  final String name;
  final String eventFormat;
  final String bracketFormat;
  final double? minRating;
  final double? maxRating;
  final int? minAge;
  final int? maxAge;
  final double entryFeeInr;
  final int maxParticipants;
  final int registeredCount;
  final int teamSize;
  final bool autoApproveEligible;
  final bool isRegistrationOpen;

  const OrganizerCategoryConfigModel({
    required this.id,
    required this.tournamentId,
    required this.organizerId,
    required this.name,
    required this.eventFormat,
    required this.bracketFormat,
    this.minRating,
    this.maxRating,
    this.minAge,
    this.maxAge,
    required this.entryFeeInr,
    required this.maxParticipants,
    required this.registeredCount,
    required this.teamSize,
    required this.autoApproveEligible,
    required this.isRegistrationOpen,
  });

  factory OrganizerCategoryConfigModel.fromJson(Map<String, dynamic> json) {
    return OrganizerCategoryConfigModel(
      id: json['id'] as String? ?? '',
      tournamentId: json['tournamentId'] as String? ?? '',
      organizerId: json['organizerId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      eventFormat: json['eventFormat'] as String? ?? 'SINGLES',
      bracketFormat: json['bracketFormat'] as String? ?? 'KNOCKOUT',
      minRating: (json['minRating'] as num?)?.toDouble(),
      maxRating: (json['maxRating'] as num?)?.toDouble(),
      minAge: (json['minAge'] as num?)?.toInt(),
      maxAge: (json['maxAge'] as num?)?.toInt(),
      entryFeeInr: (json['entryFeeInr'] as num?)?.toDouble() ?? 0,
      maxParticipants: (json['maxParticipants'] as num?)?.toInt() ?? 16,
      registeredCount: (json['registeredCount'] as num?)?.toInt() ?? 0,
      teamSize: (json['teamSize'] as num?)?.toInt() ?? 1,
      autoApproveEligible: json['autoApproveEligible'] as bool? ?? true,
      isRegistrationOpen: json['isRegistrationOpen'] as bool? ?? true,
    );
  }

  OrganizerCategoryConfig toEntity() {
    final format = switch (eventFormat.trim().toUpperCase()) {
      'DOUBLES' => TournamentEventFormat.doubles,
      'MIXED_DOUBLES' => TournamentEventFormat.mixedDoubles,
      'TEAM' => TournamentEventFormat.team,
      _ => TournamentEventFormat.singles,
    };
    final bracket = bracketFormat.trim().toUpperCase() == 'ROUND_ROBIN'
        ? TournamentBracketFormat.roundRobin
        : TournamentBracketFormat.knockout;

    return OrganizerCategoryConfig(
      id: id,
      tournamentId: tournamentId,
      organizerId: organizerId,
      name: name,
      eventFormat: format,
      bracketFormat: bracket,
      minRating: minRating,
      maxRating: maxRating,
      minAge: minAge,
      maxAge: maxAge,
      entryFeeInr: entryFeeInr,
      maxParticipants: maxParticipants,
      registeredCount: registeredCount,
      teamSize: teamSize,
      autoApproveEligible: autoApproveEligible,
      isRegistrationOpen: isRegistrationOpen,
    );
  }
}

/// DTO for [OrganizerTournament].
class OrganizerTournamentModel {
  final String id;
  final String organizerId;
  final String organizationName;
  final String name;
  final String venueName;
  final String city;
  final String address;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime registrationDeadline;
  final String prizePool;
  final String description;
  final List<String> rules;
  final String status;
  final TournamentScoringConfigModel defaultScoring;
  final List<OrganizerCategoryConfigModel> categories;
  final List<String> courts;
  final bool isPubliclyPublished;

  const OrganizerTournamentModel({
    required this.id,
    required this.organizerId,
    required this.organizationName,
    required this.name,
    required this.venueName,
    required this.city,
    required this.address,
    required this.startDate,
    required this.endDate,
    required this.registrationDeadline,
    required this.prizePool,
    required this.description,
    required this.rules,
    required this.status,
    required this.defaultScoring,
    required this.categories,
    required this.courts,
    required this.isPubliclyPublished,
  });

  OrganizerTournament toEntity() {
    final mappedStatus = switch (status.trim().toUpperCase()) {
      'PUBLISHED' => OrganizerTournamentStatus.published,
      'REGISTRATION_OPEN' => OrganizerTournamentStatus.registrationOpen,
      'IN_PROGRESS' => OrganizerTournamentStatus.inProgress,
      'COMPLETED' => OrganizerTournamentStatus.completed,
      'CANCELLED' => OrganizerTournamentStatus.cancelled,
      _ => OrganizerTournamentStatus.draft,
    };

    return OrganizerTournament(
      id: id,
      organizerId: organizerId,
      organizationName: organizationName,
      name: name,
      venueName: venueName,
      city: city,
      address: address,
      startDate: startDate,
      endDate: endDate,
      registrationDeadline: registrationDeadline,
      prizePool: prizePool,
      description: description,
      rules: rules,
      status: mappedStatus,
      defaultScoring: defaultScoring.toEntity(),
      categories: categories.map((c) => c.toEntity()).toList(),
      courts: courts,
      isPubliclyPublished: isPubliclyPublished,
    );
  }
}
