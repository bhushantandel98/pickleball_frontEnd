import 'dart:math';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/tournament_repository.dart';

/// In-memory mock implementation of [TournamentRepository].
class MockTournamentRepository implements TournamentRepository {
  final bool shouldFail;
  final bool isEmpty;
  List<TournamentItem>? customTournaments;
  List<TournamentRegistration>? customRegistrations;

  MockTournamentRepository({
    this.shouldFail = false,
    this.isEmpty = false,
    this.customTournaments,
    this.customRegistrations,
  });

  static List<TournamentItem> createDefaultTournaments() {
    final now = DateTime.now();

    final tourn1 = TournamentItem(
      id: 'tourn_001',
      name: 'National Pickleball Open 2026',
      organizerName: 'Pacific Pickleball Series',
      venueName: 'Grand Slam Pickleball Arena',
      address: '742 Evergreen Terrace, Andheri West',
      city: 'Mumbai',
      imageUrl: 'assets/images/venues/grand_slam_arena.jpg',
      status: TournamentStatus.inProgress,
      startDate: DateTime(now.year, now.month, now.day - 4),
      endDate: DateTime(now.year, now.month, now.day + 1),
      registrationDeadline: DateTime(now.year, now.month, now.day - 7),
      prizePool: '₹2,50,000',
      entryFeeFrom: 1500.0,
      description:
          'The premier national championship sanctioned by the National Pickleball Association. '
          'Featuring top-tier competition across singles and doubles divisions on tournament-grade courts.',
      scoringFormat: 'Best 2 of 3 games to 11 (win by 2)',
      rules: const [
        'Official USAPA / IPA rules apply strictly.',
        'Players must report 20 minutes prior to scheduled match time.',
        'Non-marking indoor court shoes mandatory.',
        'Official ball: Franklin X-40 outdoor optic yellow.',
      ],
      categories: const [
        TournamentCategory(
          id: 'cat_001_ms',
          name: 'Men\'s Singles Open',
          entryFee: 1500.0,
          maxParticipants: 32,
          registeredCount: 32,
          isRegistrationOpen: false,
        ),
        TournamentCategory(
          id: 'cat_001_ws',
          name: 'Women\'s Singles Open',
          entryFee: 1500.0,
          maxParticipants: 16,
          registeredCount: 16,
          isRegistrationOpen: false,
        ),
        TournamentCategory(
          id: 'cat_001_md',
          name: 'Mixed Doubles 3.5',
          isDoubles: true,
          minRating: 3.0,
          maxRating: 3.75,
          entryFee: 2400.0,
          maxParticipants: 16,
          registeredCount: 16,
          isRegistrationOpen: false,
        ),
      ],
      isRegistered: true,
      registeredCategoryIds: const ['cat_001_ms'],
    );

    final tourn2 = TournamentItem(
      id: 'tourn_002',
      name: 'Monsoon Community Cup 2026',
      organizerName: 'Pinnacle Sports Academy',
      venueName: 'Pinnacle Sports Academy (Downtown)',
      address: 'Plot 12, Senapati Bapat Marg, Lower Parel',
      city: 'Mumbai',
      imageUrl: 'assets/images/venues/pinnacle_sports.jpg',
      status: TournamentStatus.registrationOpen,
      startDate: DateTime(now.year, now.month, now.day + 11),
      endDate: DateTime(now.year, now.month, now.day + 13),
      registrationDeadline: DateTime(now.year, now.month, now.day + 9, 23, 59),
      prizePool: '₹50,000',
      entryFeeFrom: 800.0,
      description:
          'Community-first weekend tournament designed for intermediate and advanced recreational players. '
          'Featuring singles, mixed doubles, and dedicated senior brackets with medals and cash prizes.',
      scoringFormat: 'Rounds 1-3: 1 game to 15 (win by 2). Finals: Best 2 of 3 to 11.',
      rules: const [
        'Paddle face must be smooth with no unapproved grit modifications.',
        'Withdrawal deadline with 100% refund is 48 hours prior to registration close.',
        'Light refreshments and hydration provided at the tournament desk.',
      ],
      categories: const [
        TournamentCategory(
          id: 'cat_002_ms',
          name: 'Men\'s Singles 3.5',
          minRating: 3.0,
          maxRating: 3.75,
          entryFee: 800.0,
          maxParticipants: 16,
          registeredCount: 12,
        ),
        TournamentCategory(
          id: 'cat_002_md',
          name: 'Mixed Doubles Open',
          isDoubles: true,
          entryFee: 1400.0,
          maxParticipants: 16,
          registeredCount: 10,
        ),
        TournamentCategory(
          id: 'cat_002_sr',
          name: 'Senior Doubles 50+',
          isDoubles: true,
          minAge: 50,
          entryFee: 1200.0,
          maxParticipants: 8,
          registeredCount: 6,
        ),
        TournamentCategory(
          id: 'cat_002_jr',
          name: 'Junior Singles Under-16',
          maxAge: 16,
          entryFee: 600.0,
          maxParticipants: 16,
          registeredCount: 8,
        ),
      ],
      isRegistered: false,
    );

    final tourn4 = TournamentItem(
      id: 'tourn_004',
      name: 'Mumbai Metro Pickleball Championship 2026',
      organizerName: 'Metro Pickleball Club',
      venueName: 'Metro Pickleball Club',
      address: 'Eastern Express Highway, Ghatkopar East',
      city: 'Mumbai',
      imageUrl: 'assets/images/venues/metro_pickleball.jpg',
      status: TournamentStatus.registrationOpen,
      startDate: DateTime(now.year, now.month, now.day + 26),
      endDate: DateTime(now.year, now.month, now.day + 28),
      registrationDeadline: DateTime(now.year, now.month, now.day + 22, 23, 59),
      prizePool: '₹1,00,000',
      entryFeeFrom: 1200.0,
      description:
          'High-stakes metropolitan open bringing together the top talent across Western India. '
          'Full digital live-scoring on all 6 courts and livestreaming for championship matches.',
      scoringFormat: 'Best 2 of 3 games to 11 (win by 2).',
      rules: const [
        'DUPR verification required during registration.',
        'Seeding strictly based on combined team DUPR scores.',
        'Official tournament t-shirt included with every entry.',
      ],
      categories: const [
        TournamentCategory(
          id: 'cat_004_mso',
          name: 'Men\'s Singles Open',
          entryFee: 1200.0,
          maxParticipants: 32,
          registeredCount: 20,
        ),
        TournamentCategory(
          id: 'cat_004_mdo',
          name: 'Men\'s Doubles 4.0+',
          isDoubles: true,
          minRating: 3.75,
          entryFee: 2000.0,
          maxParticipants: 16,
          registeredCount: 14,
        ),
        TournamentCategory(
          id: 'cat_004_wdo',
          name: 'Women\'s Doubles Open',
          isDoubles: true,
          entryFee: 1800.0,
          maxParticipants: 16,
          registeredCount: 8,
        ),
      ],
      isRegistered: false,
    );

    final tourn5 = TournamentItem(
      id: 'tourn_005',
      name: 'Pacific Autumn Smash 2026',
      organizerName: 'Pacific Pickleball Club',
      venueName: 'Pacific Pickleball Club',
      address: 'Carter Road, Bandra West',
      city: 'Bandra',
      imageUrl: 'assets/images/venues/pacific_pickleball.jpg',
      status: TournamentStatus.upcoming,
      startDate: DateTime(now.year, now.month, now.day + 47),
      endDate: DateTime(now.year, now.month, now.day + 49),
      registrationDeadline: DateTime(now.year, now.month, now.day + 40, 23, 59),
      prizePool: '₹75,000',
      entryFeeFrom: 1000.0,
      description:
          'Seaside tournament showcasing energetic outdoor pickleball under the coastal breeze. '
          'Double elimination draw guarantees at least two matches for all entrants.',
      scoringFormat: 'Double elimination bracket. Consolation to 15 points.',
      rules: const [
        'Registration opens 30 days prior to event start.',
        'Wind-resistant outdoor balls will be utilized.',
      ],
      categories: const [
        TournamentCategory(
          id: 'cat_005_ms',
          name: 'Men\'s Singles 3.5',
          minRating: 3.0,
          maxRating: 3.75,
          entryFee: 1000.0,
          maxParticipants: 16,
          registeredCount: 0,
        ),
        TournamentCategory(
          id: 'cat_005_xd',
          name: 'Mixed Doubles 3.5',
          isDoubles: true,
          minRating: 3.0,
          maxRating: 3.75,
          entryFee: 1600.0,
          maxParticipants: 16,
          registeredCount: 0,
        ),
      ],
      isRegistered: false,
    );

    final tourn3 = TournamentItem(
      id: 'tourn_003',
      name: 'Pacific Coast Masters 2026',
      organizerName: 'Pacific Pickleball Series',
      venueName: 'Ace Point Arena',
      address: 'Hiranandani Gardens, Powai',
      city: 'Powai',
      imageUrl: 'assets/images/venues/ace_point_arena.jpg',
      status: TournamentStatus.completed,
      startDate: DateTime(now.year, now.month, now.day - 30),
      endDate: DateTime(now.year, now.month, now.day - 28),
      registrationDeadline: DateTime(now.year, now.month, now.day - 35),
      prizePool: '₹1,50,000',
      entryFeeFrom: 1500.0,
      description:
          'The landmark autumn Masters event concluding the western regional circuit. '
          'Champion: Jordan Cruz.',
      scoringFormat: 'Best 2 of 3 games to 11 (win by 2).',
      rules: const [
        'Final tournament standings count towards annual state rankings.',
      ],
      categories: const [
        TournamentCategory(
          id: 'cat_003_open',
          name: 'Men\'s Singles Open',
          entryFee: 1500.0,
          maxParticipants: 16,
          registeredCount: 16,
          isRegistrationOpen: false,
        ),
      ],
      isRegistered: false,
    );

    return [tourn1, tourn2, tourn4, tourn5, tourn3];
  }

  static List<TournamentRegistration> createDefaultRegistrations() {
    final now = DateTime.now();
    return [
      TournamentRegistration(
        id: 'PKL-TRN-20261025-1044',
        tournamentId: 'tourn_001',
        tournamentName: 'National Pickleball Open 2026',
        categoryId: 'cat_001_ms',
        categoryName: 'Men\'s Singles Open',
        venueName: 'Grand Slam Pickleball Arena',
        dates: 'Nov 1 - Nov 5, 2026',
        playerName: 'Alex Rivera',
        entryFee: 1500.0,
        status: TournamentRegistrationStatus.confirmed,
        registeredAt: DateTime(now.year, now.month, now.day - 10, 14, 30),
        paymentStatus: 'Confirmed (Pay at Venue Desk)',
      ),
    ];
  }

  static String generateRegistrationReference() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final randomPart = (1000 + Random().nextInt(9000)).toString();
    return 'PKL-TRN-$dateStr-$randomPart';
  }

  @override
  Future<Result<List<TournamentItem>>> getTournaments({
    TournamentFilter? filter,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to retrieve tournaments. Please try again.'),
      );
    }

    if (isEmpty) {
      return const Success([]);
    }

    customTournaments ??= createDefaultTournaments();
    var list = List<TournamentItem>.from(customTournaments!);

    if (filter != null) {
      // 1. Text search
      final query = filter.searchQuery.trim().toLowerCase();
      if (query.isNotEmpty) {
        list = list.where((t) {
          return t.name.toLowerCase().contains(query) ||
              t.venueName.toLowerCase().contains(query) ||
              t.city.toLowerCase().contains(query) ||
              t.organizerName.toLowerCase().contains(query);
        }).toList();
      }

      // 2. Status filter
      if (filter.status != null) {
        list = list.where((t) => t.status == filter.status).toList();
      }

      // 3. Category name filter
      if (filter.category != null && filter.category!.isNotEmpty) {
        final catQuery = filter.category!.toLowerCase();
        list = list.where((t) {
          return t.categories.any((c) => c.name.toLowerCase().contains(catQuery));
        }).toList();
      }

      // 4. Open for registration toggle
      if (filter.onlyOpenForRegistration) {
        list = list.where((t) => t.isRegistrationOpen).toList();
      }

      // 5. Only my registered tournaments toggle
      if (filter.onlyMyEntries) {
        list = list.where((t) => t.isRegistered).toList();
      }

      // 6. Sorting
      switch (filter.sortBy) {
        case TournamentSortOption.dateSoonest:
          list.sort((a, b) => a.startDate.compareTo(b.startDate));
          break;
        case TournamentSortOption.dateLatest:
          list.sort((a, b) => b.startDate.compareTo(a.startDate));
          break;
        case TournamentSortOption.feeLowest:
          list.sort((a, b) => a.entryFeeFrom.compareTo(b.entryFeeFrom));
          break;
        case TournamentSortOption.feeHighest:
          list.sort((a, b) => b.entryFeeFrom.compareTo(a.entryFeeFrom));
          break;
        case TournamentSortOption.prizeHighest:
          list.sort((a, b) => b.prizePool.compareTo(a.prizePool));
          break;
      }
    }

    return Success(list);
  }

  @override
  Future<Result<TournamentItem>> getTournamentById(String tournamentId) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to retrieve tournament details.'),
      );
    }

    customTournaments ??= createDefaultTournaments();

    final found = customTournaments!.where((t) => t.id == tournamentId);
    if (found.isEmpty) {
      return const FailureResult(
        NotFoundFailure(message: 'Tournament not found or unlisted.'),
      );
    }

    return Success(found.first);
  }

  @override
  Future<Result<TournamentRegistration>> registerForTournament(
    TournamentRegistrationPayload payload,
  ) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Registration submission failed. Please try again.'),
      );
    }

    customTournaments ??= createDefaultTournaments();
    customRegistrations ??= createDefaultRegistrations();

    // Locate tournament
    final tIndex =
        customTournaments!.indexWhere((t) => t.id == payload.tournamentId);
    if (tIndex == -1) {
      return const FailureResult(
        NotFoundFailure(message: 'Target tournament does not exist.'),
      );
    }
    final tournament = customTournaments![tIndex];

    // Validate registration is open
    if (!tournament.isRegistrationOpen) {
      return const FailureResult(
        ValidationFailure(message: 'Registration for this tournament is closed.'),
      );
    }

    // Locate category
    final catIndex =
        tournament.categories.indexWhere((c) => c.id == payload.categoryId);
    if (catIndex == -1) {
      return const FailureResult(
        NotFoundFailure(message: 'Selected tournament category does not exist.'),
      );
    }
    final category = tournament.categories[catIndex];

    // Validate waiver acceptance
    if (!payload.acceptedWaiver || !payload.acceptedRules) {
      return const FailureResult(
        ValidationFailure(
          message: 'You must accept the tournament liability waiver and rules.',
        ),
      );
    }

    // Validate doubles partner requirement
    if (category.isDoubles &&
        (payload.partnerName == null || payload.partnerName!.trim().isEmpty)) {
      return const FailureResult(
        ValidationFailure(
          message: 'Partner name is required for doubles category entry.',
        ),
      );
    }

    // Validate rating eligibility
    if (!category.isRatingEligible(payload.playerRating)) {
      return FailureResult(
        ValidationFailure(
          message:
              'Player rating (DUPR ${payload.playerRating}) does not satisfy category requirements (${category.eligibilitySummary}).',
        ),
      );
    }

    // Prevent duplicate registration in the same category
    final alreadyRegistered = customRegistrations!.any(
      (r) =>
          r.tournamentId == payload.tournamentId &&
          r.categoryId == payload.categoryId &&
          r.status != TournamentRegistrationStatus.withdrawn,
    );
    if (alreadyRegistered) {
      return const FailureResult(
        ValidationFailure(
          message: 'You are already registered for this tournament category.',
        ),
      );
    }

    // Check capacity / waitlist
    final isWaitlist = category.isCapacityFull;
    final status = isWaitlist
        ? TournamentRegistrationStatus.waitlisted
        : TournamentRegistrationStatus.confirmed;

    final registration = TournamentRegistration(
      id: generateRegistrationReference(),
      tournamentId: tournament.id,
      tournamentName: tournament.name,
      categoryId: category.id,
      categoryName: category.name,
      venueName: tournament.venueName,
      dates: tournament.formattedDateRange,
      playerName: payload.playerName,
      partnerName: payload.partnerName,
      entryFee: payload.entryFee,
      status: status,
      registeredAt: DateTime.now(),
      paymentStatus: isWaitlist
          ? 'Waitlisted (Payment on Confirmation)'
          : 'Confirmed (Pay at Venue Desk)',
    );

    // Update in-memory tournament category count & registered flag
    final updatedCategory = category.copyWith(
      registeredCount: category.registeredCount + 1,
    );
    final updatedCategories =
        List<TournamentCategory>.from(tournament.categories);
    updatedCategories[catIndex] = updatedCategory;

    final updatedRegisteredIds =
        List<String>.from(tournament.registeredCategoryIds)..add(category.id);

    final updatedTournament = tournament.copyWith(
      categories: updatedCategories,
      isRegistered: true,
      registeredCategoryIds: updatedRegisteredIds,
    );

    customTournaments![tIndex] = updatedTournament;
    customRegistrations!.add(registration);

    return Success(registration);
  }

  @override
  Future<Result<TournamentRegistration>> withdrawFromTournament(
    String registrationId,
  ) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to withdraw from tournament registration.'),
      );
    }

    customTournaments ??= createDefaultTournaments();
    customRegistrations ??= createDefaultRegistrations();

    final rIndex =
        customRegistrations!.indexWhere((r) => r.id == registrationId);
    if (rIndex == -1) {
      return const FailureResult(
        NotFoundFailure(message: 'Registration record not found.'),
      );
    }

    final currentReg = customRegistrations![rIndex];
    if (currentReg.status == TournamentRegistrationStatus.withdrawn) {
      return const FailureResult(
        ValidationFailure(message: 'Registration is already withdrawn.'),
      );
    }

    final updatedReg = currentReg.copyWith(
      status: TournamentRegistrationStatus.withdrawn,
      paymentStatus: 'Cancelled / Withdrawn',
    );
    customRegistrations![rIndex] = updatedReg;

    // Adjust category registered count
    final tIndex =
        customTournaments!.indexWhere((t) => t.id == currentReg.tournamentId);
    if (tIndex != -1) {
      final tournament = customTournaments![tIndex];
      final catIndex = tournament.categories
          .indexWhere((c) => c.id == currentReg.categoryId);
      if (catIndex != -1) {
        final cat = tournament.categories[catIndex];
        final updatedCat = cat.copyWith(
          registeredCount: (cat.registeredCount - 1).clamp(0, 9999),
        );
        final updatedCats = List<TournamentCategory>.from(tournament.categories);
        updatedCats[catIndex] = updatedCat;

        final remainingCategoryIds = List<String>.from(tournament.registeredCategoryIds)
          ..remove(currentReg.categoryId);

        customTournaments![tIndex] = tournament.copyWith(
          categories: updatedCats,
          isRegistered: remainingCategoryIds.isNotEmpty,
          registeredCategoryIds: remainingCategoryIds,
        );
      }
    }

    return Success(updatedReg);
  }

  @override
  Future<Result<List<TournamentRegistration>>> getMyRegistrations() async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to retrieve your tournament registrations.'),
      );
    }

    if (isEmpty) {
      return const Success([]);
    }

    customRegistrations ??= createDefaultRegistrations();
    return Success(List<TournamentRegistration>.from(customRegistrations!));
  }
}
