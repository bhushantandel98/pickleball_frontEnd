import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Event discipline format supported by Tournament Organizer PRD v1.2.
enum TournamentEventFormat {
  singles('Singles', 1),
  doubles('Doubles', 2),
  mixedDoubles('Mixed Doubles', 2),
  team('Team', 4);

  final String label;
  final int defaultTeamSize;
  const TournamentEventFormat(this.label, this.defaultTeamSize);
}

/// Competition draw format supported by Tournament Organizer PRD v1.2.
enum TournamentBracketFormat {
  roundRobin('Round Robin'),
  knockout('Knockout');

  final String label;
  const TournamentBracketFormat(this.label);
}

/// Lifecycle status of an organizer-managed tournament.
enum OrganizerTournamentStatus {
  draft('Draft'),
  published('Published'),
  registrationOpen('Registration Open'),
  inProgress('In Progress'),
  completed('Completed'),
  cancelled('Cancelled');

  final String label;
  const OrganizerTournamentStatus(this.label);
}

/// Scoring method defined by the Tournament Organizer and enforced by Referees.
enum TournamentScoringMethod {
  rallyScoring('Rally Scoring'),
  sideOutScoring('Side-Out Scoring');

  final String label;
  const TournamentScoringMethod(this.label);
}

/// Organizer-defined scoring rules loaded by the Referee scoring UI.
class TournamentScoringConfig extends Equatable {
  final TournamentScoringMethod method;
  final int pointsPerGame;
  final int bestOfGames;
  final int winBy;
  final bool trackPositionsAndServiceOrder;

  const TournamentScoringConfig({
    this.method = TournamentScoringMethod.sideOutScoring,
    this.pointsPerGame = 11,
    this.bestOfGames = 3,
    this.winBy = 2,
    this.trackPositionsAndServiceOrder = true,
  });

  String get formattedSummary =>
      'Best of $bestOfGames to $pointsPerGame (win by $winBy • ${method.label})';

  TournamentScoringConfig copyWith({
    TournamentScoringMethod? method,
    int? pointsPerGame,
    int? bestOfGames,
    int? winBy,
    bool? trackPositionsAndServiceOrder,
  }) {
    return TournamentScoringConfig(
      method: method ?? this.method,
      pointsPerGame: pointsPerGame ?? this.pointsPerGame,
      bestOfGames: bestOfGames ?? this.bestOfGames,
      winBy: winBy ?? this.winBy,
      trackPositionsAndServiceOrder:
          trackPositionsAndServiceOrder ?? this.trackPositionsAndServiceOrder,
    );
  }

  @override
  List<Object?> get props => [
        method,
        pointsPerGame,
        bestOfGames,
        winBy,
        trackPositionsAndServiceOrder,
      ];
}

/// Category / division configuration within a tournament.
class OrganizerCategoryConfig extends Equatable {
  final String id;
  final String tournamentId;
  final String organizerId;
  final String name;
  final TournamentEventFormat eventFormat;
  final TournamentBracketFormat bracketFormat;
  final double? minRating;
  final double? maxRating;
  final int? minAge;
  final int? maxAge;
  final double entryFeeInr;
  final int maxParticipants;
  final int registeredCount;
  final int? _teamSize;
  final bool autoApproveEligible;
  final bool isRegistrationOpen;
  final TournamentScoringConfig? scoringOverride;

  const OrganizerCategoryConfig({
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
    this.registeredCount = 0,
    int? teamSize,
    this.autoApproveEligible = true,
    this.isRegistrationOpen = true,
    this.scoringOverride,
    // ignore: prefer_initializing_formals
  }) : _teamSize = teamSize;

  int get teamSize => _teamSize ?? eventFormat.defaultTeamSize;

  bool get isCapacityFull => registeredCount >= maxParticipants;
  int get spotsRemaining => (maxParticipants - registeredCount).clamp(0, 9999);

  bool isRatingEligible(double rating) {
    if (minRating != null && rating < minRating!) return false;
    if (maxRating != null && rating > maxRating!) return false;
    return true;
  }

  bool isAgeEligible(int age) {
    if (minAge != null && age < minAge!) return false;
    if (maxAge != null && age > maxAge!) return false;
    return true;
  }

  String get eligibilitySummary {
    final parts = <String>[eventFormat.label, bracketFormat.label];
    if (minRating != null && maxRating != null) {
      parts.add('DUPR $minRating–$maxRating');
    } else if (minRating != null) {
      parts.add('DUPR $minRating+');
    } else if (maxRating != null) {
      parts.add('DUPR ≤ $maxRating');
    } else {
      parts.add('Open Skill');
    }

    if (minAge != null && maxAge != null) {
      parts.add('Age $minAge–$maxAge');
    } else if (minAge != null) {
      parts.add('Age $minAge+');
    } else if (maxAge != null) {
      parts.add('U-$maxAge');
    }
    return parts.join(' • ');
  }

  OrganizerCategoryConfig copyWith({
    String? name,
    TournamentEventFormat? eventFormat,
    TournamentBracketFormat? bracketFormat,
    double? minRating,
    double? maxRating,
    int? minAge,
    int? maxAge,
    double? entryFeeInr,
    int? maxParticipants,
    int? registeredCount,
    int? teamSize,
    bool? autoApproveEligible,
    bool? isRegistrationOpen,
    TournamentScoringConfig? scoringOverride,
  }) {
    return OrganizerCategoryConfig(
      id: id,
      tournamentId: tournamentId,
      organizerId: organizerId,
      name: name ?? this.name,
      eventFormat: eventFormat ?? this.eventFormat,
      bracketFormat: bracketFormat ?? this.bracketFormat,
      minRating: minRating ?? this.minRating,
      maxRating: maxRating ?? this.maxRating,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      entryFeeInr: entryFeeInr ?? this.entryFeeInr,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      registeredCount: registeredCount ?? this.registeredCount,
      teamSize: teamSize ?? this.teamSize,
      autoApproveEligible: autoApproveEligible ?? this.autoApproveEligible,
      isRegistrationOpen: isRegistrationOpen ?? this.isRegistrationOpen,
      scoringOverride: scoringOverride ?? this.scoringOverride,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        organizerId,
        name,
        eventFormat,
        bracketFormat,
        minRating,
        maxRating,
        minAge,
        maxAge,
        entryFeeInr,
        maxParticipants,
        registeredCount,
        teamSize,
        autoApproveEligible,
        isRegistrationOpen,
        scoringOverride,
      ];
}

/// Top-level tournament owned and managed by a Tournament Organizer.
class OrganizerTournament extends Equatable {
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
  final OrganizerTournamentStatus status;
  final TournamentScoringConfig defaultScoring;
  final List<OrganizerCategoryConfig> categories;
  final List<String> courts;
  final bool isPubliclyPublished;

  const OrganizerTournament({
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
    this.rules = const [],
    this.status = OrganizerTournamentStatus.draft,
    this.defaultScoring = const TournamentScoringConfig(),
    this.categories = const [],
    this.courts = const ['Court 1', 'Court 2', 'Court 3'],
    this.isPubliclyPublished = false,
  });

  int get totalCapacity =>
      categories.fold<int>(0, (sum, c) => sum + c.maxParticipants);

  int get totalRegistered =>
      categories.fold<int>(0, (sum, c) => sum + c.registeredCount);

  String get formattedDateRange {
    final startFmt = DateFormat('MMM d').format(startDate);
    final endFmt = DateFormat('MMM d, yyyy').format(endDate);
    return '$startFmt – $endFmt';
  }

  OrganizerTournament copyWith({
    String? name,
    String? venueName,
    String? city,
    String? address,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    String? prizePool,
    String? description,
    List<String>? rules,
    OrganizerTournamentStatus? status,
    TournamentScoringConfig? defaultScoring,
    List<OrganizerCategoryConfig>? categories,
    List<String>? courts,
    bool? isPubliclyPublished,
  }) {
    return OrganizerTournament(
      id: id,
      organizerId: organizerId,
      organizationName: organizationName,
      name: name ?? this.name,
      venueName: venueName ?? this.venueName,
      city: city ?? this.city,
      address: address ?? this.address,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      prizePool: prizePool ?? this.prizePool,
      description: description ?? this.description,
      rules: rules ?? this.rules,
      status: status ?? this.status,
      defaultScoring: defaultScoring ?? this.defaultScoring,
      categories: categories ?? this.categories,
      courts: courts ?? this.courts,
      isPubliclyPublished: isPubliclyPublished ?? this.isPubliclyPublished,
    );
  }

  @override
  List<Object?> get props => [
        id,
        organizerId,
        organizationName,
        name,
        venueName,
        city,
        address,
        startDate,
        endDate,
        registrationDeadline,
        prizePool,
        description,
        rules,
        status,
        defaultScoring,
        categories,
        courts,
        isPubliclyPublished,
      ];
}

/// Registration approval status.
enum OrganizerRegistrationStatus {
  autoConfirmed('Auto-Confirmed'),
  pendingReview('Pending Review'),
  rejected('Rejected'),
  withdrawn('Withdrawn');

  final String label;
  const OrganizerRegistrationStatus(this.label);
}

/// Participant or team registration record within a tournament category.
class OrganizerRegistrationRecord extends Equatable {
  final String id;
  final String tournamentId;
  final String organizerId;
  final String categoryId;
  final String categoryName;
  final TournamentEventFormat eventFormat;
  final String playerName;
  final String? partnerOrTeamName;
  final String playerEmail;
  final String playerPhone;
  final double playerRating;
  final int playerAge;
  final OrganizerRegistrationStatus status;
  final double feePaidInr;
  final DateTime registeredAt;
  final String? notes;

  const OrganizerRegistrationRecord({
    required this.id,
    required this.tournamentId,
    required this.organizerId,
    required this.categoryId,
    required this.categoryName,
    required this.eventFormat,
    required this.playerName,
    this.partnerOrTeamName,
    required this.playerEmail,
    required this.playerPhone,
    required this.playerRating,
    required this.playerAge,
    required this.status,
    required this.feePaidInr,
    required this.registeredAt,
    this.notes,
  });

  String get displayParticipant =>
      partnerOrTeamName != null && partnerOrTeamName!.trim().isNotEmpty
          ? '$playerName / $partnerOrTeamName'
          : playerName;

  OrganizerRegistrationRecord copyWith({
    OrganizerRegistrationStatus? status,
    String? notes,
  }) {
    return OrganizerRegistrationRecord(
      id: id,
      tournamentId: tournamentId,
      organizerId: organizerId,
      categoryId: categoryId,
      categoryName: categoryName,
      eventFormat: eventFormat,
      playerName: playerName,
      partnerOrTeamName: partnerOrTeamName,
      playerEmail: playerEmail,
      playerPhone: playerPhone,
      playerRating: playerRating,
      playerAge: playerAge,
      status: status ?? this.status,
      feePaidInr: feePaidInr,
      registeredAt: registeredAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        organizerId,
        categoryId,
        categoryName,
        eventFormat,
        playerName,
        partnerOrTeamName,
        playerEmail,
        playerPhone,
        playerRating,
        playerAge,
        status,
        feePaidInr,
        registeredAt,
        notes,
      ];
}

/// Seeded entry inside a category's generated draw.
class DrawSeedEntry extends Equatable {
  final String registrationId;
  final String categoryId;
  final String participantLabel;
  final int seedNumber;
  final String? groupName;

  const DrawSeedEntry({
    required this.registrationId,
    required this.categoryId,
    required this.participantLabel,
    required this.seedNumber,
    this.groupName,
  });

  DrawSeedEntry copyWith({
    int? seedNumber,
    String? groupName,
  }) {
    return DrawSeedEntry(
      registrationId: registrationId,
      categoryId: categoryId,
      participantLabel: participantLabel,
      seedNumber: seedNumber ?? this.seedNumber,
      groupName: groupName ?? this.groupName,
    );
  }

  @override
  List<Object?> get props => [
        registrationId,
        categoryId,
        participantLabel,
        seedNumber,
        groupName,
      ];
}

/// Operational status of a scheduled tournament match.
enum OrganizerMatchStatus {
  scheduled('Scheduled'),
  inProgress('In Progress'),
  completed('Completed');

  final String label;
  const OrganizerMatchStatus(this.label);
}

/// Scheduled match slot inside a tournament draw.
class OrganizerMatchSlot extends Equatable {
  final String id;
  final String tournamentId;
  final String organizerId;
  final String categoryId;
  final String categoryName;
  final TournamentBracketFormat bracketFormat;
  final String roundLabel;
  final int matchNumber;
  final String participantA;
  final String participantB;
  final String? courtName;
  final DateTime? scheduledTime;
  final String? refereeId;
  final String? refereeName;
  final OrganizerMatchStatus status;
  final String? scoreSummary;
  final String? winnerLabel;

  const OrganizerMatchSlot({
    required this.id,
    required this.tournamentId,
    required this.organizerId,
    required this.categoryId,
    required this.categoryName,
    required this.bracketFormat,
    required this.roundLabel,
    required this.matchNumber,
    required this.participantA,
    required this.participantB,
    this.courtName,
    this.scheduledTime,
    this.refereeId,
    this.refereeName,
    this.status = OrganizerMatchStatus.scheduled,
    this.scoreSummary,
    this.winnerLabel,
  });

  OrganizerMatchSlot copyWith({
    String? courtName,
    DateTime? scheduledTime,
    String? refereeId,
    String? refereeName,
    OrganizerMatchStatus? status,
    String? scoreSummary,
    String? winnerLabel,
  }) {
    return OrganizerMatchSlot(
      id: id,
      tournamentId: tournamentId,
      organizerId: organizerId,
      categoryId: categoryId,
      categoryName: categoryName,
      bracketFormat: bracketFormat,
      roundLabel: roundLabel,
      matchNumber: matchNumber,
      participantA: participantA,
      participantB: participantB,
      courtName: courtName ?? this.courtName,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      refereeId: refereeId ?? this.refereeId,
      refereeName: refereeName ?? this.refereeName,
      status: status ?? this.status,
      scoreSummary: scoreSummary ?? this.scoreSummary,
      winnerLabel: winnerLabel ?? this.winnerLabel,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        organizerId,
        categoryId,
        categoryName,
        bracketFormat,
        roundLabel,
        matchNumber,
        participantA,
        participantB,
        courtName,
        scheduledTime,
        refereeId,
        refereeName,
        status,
        scoreSummary,
        winnerLabel,
      ];
}

/// Personnel role assignable by a Tournament Organizer.
enum OrganizerStaffRole {
  tournamentStaff('Tournament Staff'),
  referee('Referee');

  final String label;
  const OrganizerStaffRole(this.label);
}

/// Delegated Tournament Staff or Referee assignment scoped to a tournament.
class OrganizerStaffAssignment extends Equatable {
  final String id;
  final String tournamentId;
  final String organizerId;
  final String userId;
  final String name;
  final String email;
  final OrganizerStaffRole role;
  final Set<String> delegatedPermissions;
  final bool isActive;

  const OrganizerStaffAssignment({
    required this.id,
    required this.tournamentId,
    required this.organizerId,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.delegatedPermissions,
    this.isActive = true,
  });

  OrganizerStaffAssignment copyWith({
    Set<String>? delegatedPermissions,
    bool? isActive,
  }) {
    return OrganizerStaffAssignment(
      id: id,
      tournamentId: tournamentId,
      organizerId: organizerId,
      userId: userId,
      name: name,
      email: email,
      role: role,
      delegatedPermissions: delegatedPermissions ?? this.delegatedPermissions,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        organizerId,
        userId,
        name,
        email,
        role,
        delegatedPermissions,
        isActive,
      ];
}

/// Aggregated Tournament Organizer workspace scoped strictly to [organizerId].
class TournamentOrganizerWorkspaceData extends Equatable {
  final String organizerId;
  final String organizationName;
  final List<OrganizerTournament> tournaments;
  final List<OrganizerRegistrationRecord> registrations;
  final Map<String, List<DrawSeedEntry>> categoryDraws;
  final List<OrganizerMatchSlot> matches;
  final List<OrganizerStaffAssignment> staffAssignments;

  const TournamentOrganizerWorkspaceData({
    required this.organizerId,
    required this.organizationName,
    required this.tournaments,
    required this.registrations,
    required this.categoryDraws,
    required this.matches,
    required this.staffAssignments,
  });

  @override
  List<Object?> get props => [
        organizerId,
        organizationName,
        tournaments,
        registrations,
        categoryDraws,
        matches,
        staffAssignments,
      ];
}
