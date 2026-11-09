import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Lifecycle status for tournament operations.
enum TournamentStatus {
  registrationOpen('Registration Open'),
  upcoming('Upcoming'),
  inProgress('In Progress'),
  completed('Completed'),
  cancelled('Cancelled');

  final String displayName;
  const TournamentStatus(this.displayName);
}

/// Skill classification tiers for tournament brackets.
enum SkillTier {
  open('Open / All Levels'),
  tier3_0('Skill 3.0'),
  tier3_5('Skill 3.5'),
  tier4_0('Skill 4.0'),
  tier4_5Plus('Skill 4.5+');

  final String displayName;
  const SkillTier(this.displayName);
}

/// Sort criteria for tournament discovery.
enum TournamentSortOption {
  dateSoonest('Date: Soonest First'),
  dateLatest('Date: Latest First'),
  feeLowest('Entry Fee: Low to High'),
  feeHighest('Entry Fee: High to Low'),
  prizeHighest('Prize Pool: High to Low');

  final String label;
  const TournamentSortOption(this.label);
}

/// Category / division within a tournament.
class TournamentCategory extends Equatable {
  final String id;
  final String name;
  final bool isDoubles;
  final double? minRating;
  final double? maxRating;
  final int? minAge;
  final int? maxAge;
  final double entryFee;
  final int maxParticipants;
  final int registeredCount;
  final bool isRegistrationOpen;

  const TournamentCategory({
    required this.id,
    required this.name,
    this.isDoubles = false,
    this.minRating,
    this.maxRating,
    this.minAge,
    this.maxAge,
    required this.entryFee,
    required this.maxParticipants,
    this.registeredCount = 0,
    this.isRegistrationOpen = true,
  });

  bool get isCapacityFull => registeredCount >= maxParticipants;
  int get spotsRemaining => (maxParticipants - registeredCount).clamp(0, 9999);

  /// Evaluates player rating eligibility for this category.
  bool isRatingEligible(double playerRating) {
    if (minRating != null && playerRating < minRating!) return false;
    if (maxRating != null && playerRating > maxRating!) return false;
    return true;
  }

  /// Evaluates player age eligibility for this category.
  bool isAgeEligible(int playerAge) {
    if (minAge != null && playerAge < minAge!) return false;
    if (maxAge != null && playerAge > maxAge!) return false;
    return true;
  }

  String get formattedFee => NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 0,
        locale: 'en_IN',
      ).format(entryFee);

  String get eligibilitySummary {
    final parts = <String>[];
    if (minRating != null && maxRating != null) {
      parts.add('DUPR $minRating - $maxRating');
    } else if (maxRating != null) {
      parts.add('DUPR up to $maxRating');
    } else if (minRating != null) {
      parts.add('DUPR $minRating+');
    } else {
      parts.add('Open Skill');
    }

    if (minAge != null) {
      parts.add('Age $minAge+');
    } else if (maxAge != null) {
      parts.add('Under-$maxAge');
    }

    parts.add(isDoubles ? 'Doubles' : 'Singles');
    return parts.join(' • ');
  }

  TournamentCategory copyWith({
    String? id,
    String? name,
    bool? isDoubles,
    double? minRating,
    double? maxRating,
    int? minAge,
    int? maxAge,
    double? entryFee,
    int? maxParticipants,
    int? registeredCount,
    bool? isRegistrationOpen,
  }) {
    return TournamentCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      isDoubles: isDoubles ?? this.isDoubles,
      minRating: minRating ?? this.minRating,
      maxRating: maxRating ?? this.maxRating,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      entryFee: entryFee ?? this.entryFee,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      registeredCount: registeredCount ?? this.registeredCount,
      isRegistrationOpen: isRegistrationOpen ?? this.isRegistrationOpen,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        isDoubles,
        minRating,
        maxRating,
        minAge,
        maxAge,
        entryFee,
        maxParticipants,
        registeredCount,
        isRegistrationOpen,
      ];
}

/// Domain entity representing a tournament in discovery and details views.
class TournamentItem extends Equatable {
  final String id;
  final String name;
  final String organizerName;
  final String venueName;
  final String address;
  final String city;
  final String? imageUrl;
  final TournamentStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime registrationDeadline;
  final String prizePool;
  final double entryFeeFrom;
  final String description;
  final String scoringFormat;
  final List<String> rules;
  final List<TournamentCategory> categories;
  final bool isRegistered;
  final List<String> registeredCategoryIds;

  const TournamentItem({
    required this.id,
    required this.name,
    required this.organizerName,
    required this.venueName,
    required this.address,
    required this.city,
    this.imageUrl,
    this.status = TournamentStatus.registrationOpen,
    required this.startDate,
    required this.endDate,
    required this.registrationDeadline,
    required this.prizePool,
    required this.entryFeeFrom,
    required this.description,
    this.scoringFormat = 'Best 2 of 3 games to 11 (win by 2)',
    this.rules = const [],
    this.categories = const [],
    this.isRegistered = false,
    this.registeredCategoryIds = const [],
  });

  bool get isRegistrationOpen =>
      status == TournamentStatus.registrationOpen &&
      DateTime.now().isBefore(registrationDeadline);

  int get totalCapacity =>
      categories.fold(0, (acc, c) => acc + c.maxParticipants);

  int get totalRegistered =>
      categories.fold(0, (acc, c) => acc + c.registeredCount);

  int get spotsRemaining => (totalCapacity - totalRegistered).clamp(0, 9999);

  String get formattedDateRange {
    final startFmt = DateFormat('MMM d').format(startDate);
    final endFmt = DateFormat('MMM d, yyyy').format(endDate);
    return '$startFmt - $endFmt';
  }

  String get formattedDeadline =>
      DateFormat('d MMM yyyy, hh:mm a').format(registrationDeadline);

  String get formattedFeeFrom => NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 0,
        locale: 'en_IN',
      ).format(entryFeeFrom);

  TournamentItem copyWith({
    String? id,
    String? name,
    String? organizerName,
    String? venueName,
    String? address,
    String? city,
    String? imageUrl,
    TournamentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? registrationDeadline,
    String? prizePool,
    double? entryFeeFrom,
    String? description,
    String? scoringFormat,
    List<String>? rules,
    List<TournamentCategory>? categories,
    bool? isRegistered,
    List<String>? registeredCategoryIds,
  }) {
    return TournamentItem(
      id: id ?? this.id,
      name: name ?? this.name,
      organizerName: organizerName ?? this.organizerName,
      venueName: venueName ?? this.venueName,
      address: address ?? this.address,
      city: city ?? this.city,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      registrationDeadline: registrationDeadline ?? this.registrationDeadline,
      prizePool: prizePool ?? this.prizePool,
      entryFeeFrom: entryFeeFrom ?? this.entryFeeFrom,
      description: description ?? this.description,
      scoringFormat: scoringFormat ?? this.scoringFormat,
      rules: rules ?? this.rules,
      categories: categories ?? this.categories,
      isRegistered: isRegistered ?? this.isRegistered,
      registeredCategoryIds:
          registeredCategoryIds ?? this.registeredCategoryIds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        organizerName,
        venueName,
        address,
        city,
        imageUrl,
        status,
        startDate,
        endDate,
        registrationDeadline,
        prizePool,
        entryFeeFrom,
        description,
        scoringFormat,
        rules,
        categories,
        isRegistered,
        registeredCategoryIds,
      ];
}

/// Filter criteria for querying tournaments in discovery.
class TournamentFilter extends Equatable {
  final String searchQuery;
  final TournamentStatus? status;
  final String? category;
  final SkillTier? skillTier;
  final bool onlyOpenForRegistration;
  final bool onlyMyEntries;
  final TournamentSortOption sortBy;

  const TournamentFilter({
    this.searchQuery = '',
    this.status,
    this.category,
    this.skillTier,
    this.onlyOpenForRegistration = false,
    this.onlyMyEntries = false,
    this.sortBy = TournamentSortOption.dateSoonest,
  });

  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      status != null ||
      category != null ||
      skillTier != null ||
      onlyOpenForRegistration ||
      onlyMyEntries ||
      sortBy != TournamentSortOption.dateSoonest;

  int get activeFilterCount {
    int count = 0;
    if (status != null) count++;
    if (category != null) count++;
    if (skillTier != null) count++;
    if (onlyOpenForRegistration) count++;
    if (onlyMyEntries) count++;
    return count;
  }

  TournamentFilter copyWith({
    String? searchQuery,
    TournamentStatus? status,
    String? category,
    SkillTier? skillTier,
    bool? onlyOpenForRegistration,
    bool? onlyMyEntries,
    TournamentSortOption? sortBy,
    bool clearStatus = false,
    bool clearCategory = false,
    bool clearSkillTier = false,
  }) {
    return TournamentFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      status: clearStatus ? null : (status ?? this.status),
      category: clearCategory ? null : (category ?? this.category),
      skillTier: clearSkillTier ? null : (skillTier ?? this.skillTier),
      onlyOpenForRegistration:
          onlyOpenForRegistration ?? this.onlyOpenForRegistration,
      onlyMyEntries: onlyMyEntries ?? this.onlyMyEntries,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        status,
        category,
        skillTier,
        onlyOpenForRegistration,
        onlyMyEntries,
        sortBy,
      ];
}

/// Registration status values.
enum TournamentRegistrationStatus {
  confirmed('Confirmed'),
  waitlisted('Waitlisted'),
  withdrawn('Withdrawn'),
  cancelled('Cancelled');

  final String displayName;
  const TournamentRegistrationStatus(this.displayName);
}

/// Submission payload for registering a player in a tournament category.
class TournamentRegistrationPayload extends Equatable {
  final String tournamentId;
  final String categoryId;
  final String playerName;
  final String playerPhone;
  final String playerEmail;
  final double playerRating;
  final String? partnerName;
  final String? partnerPhone;
  final String? partnerEmail;
  final double? partnerRating;
  final String tshirtSize;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final bool acceptedWaiver;
  final bool acceptedRules;
  final double entryFee;
  final String paymentMethod;

  const TournamentRegistrationPayload({
    required this.tournamentId,
    required this.categoryId,
    required this.playerName,
    required this.playerPhone,
    required this.playerEmail,
    required this.playerRating,
    this.partnerName,
    this.partnerPhone,
    this.partnerEmail,
    this.partnerRating,
    this.tshirtSize = 'L',
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.acceptedWaiver,
    required this.acceptedRules,
    required this.entryFee,
    this.paymentMethod = 'Pay at Tournament Desk',
  });

  @override
  List<Object?> get props => [
        tournamentId,
        categoryId,
        playerName,
        playerPhone,
        playerEmail,
        playerRating,
        partnerName,
        partnerPhone,
        partnerEmail,
        partnerRating,
        tshirtSize,
        emergencyContactName,
        emergencyContactPhone,
        acceptedWaiver,
        acceptedRules,
        entryFee,
        paymentMethod,
      ];
}

/// Confirmation and receipt entity for a tournament registration.
class TournamentRegistration extends Equatable {
  final String id;
  final String tournamentId;
  final String tournamentName;
  final String categoryId;
  final String categoryName;
  final String venueName;
  final String dates;
  final String playerName;
  final String? partnerName;
  final double entryFee;
  final TournamentRegistrationStatus status;
  final DateTime registeredAt;
  final String paymentStatus;

  const TournamentRegistration({
    required this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.categoryId,
    required this.categoryName,
    required this.venueName,
    required this.dates,
    required this.playerName,
    this.partnerName,
    required this.entryFee,
    this.status = TournamentRegistrationStatus.confirmed,
    required this.registeredAt,
    this.paymentStatus = 'Confirmed (Pay at Venue Desk)',
  });

  bool get isConfirmed => status == TournamentRegistrationStatus.confirmed;
  bool get isWaitlisted => status == TournamentRegistrationStatus.waitlisted;
  bool get isWithdrawn => status == TournamentRegistrationStatus.withdrawn;

  String get formattedFee => NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 0,
        locale: 'en_IN',
      ).format(entryFee);

  TournamentRegistration copyWith({
    String? id,
    String? tournamentId,
    String? tournamentName,
    String? categoryId,
    String? categoryName,
    String? venueName,
    String? dates,
    String? playerName,
    String? partnerName,
    double? entryFee,
    TournamentRegistrationStatus? status,
    DateTime? registeredAt,
    String? paymentStatus,
  }) {
    return TournamentRegistration(
      id: id ?? this.id,
      tournamentId: tournamentId ?? this.tournamentId,
      tournamentName: tournamentName ?? this.tournamentName,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      venueName: venueName ?? this.venueName,
      dates: dates ?? this.dates,
      playerName: playerName ?? this.playerName,
      partnerName: partnerName ?? this.partnerName,
      entryFee: entryFee ?? this.entryFee,
      status: status ?? this.status,
      registeredAt: registeredAt ?? this.registeredAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        tournamentName,
        categoryId,
        categoryName,
        venueName,
        dates,
        playerName,
        partnerName,
        entryFee,
        status,
        registeredAt,
        paymentStatus,
      ];
}
