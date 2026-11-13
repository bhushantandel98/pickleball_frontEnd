import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/entities/tournament_organizer_entities.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/repositories/tournament_organizer_repository.dart';

/// Mock implementation of [TournamentOrganizerRepository] for Feature 5.1.
///
/// Enforces:
/// - Strict [organizerId] ownership across tournaments, categories, draws,
///   registrations, matches, and staff/referee assignments.
/// - Singles, Doubles, Mixed Doubles, and Team formats.
/// - Round Robin and Knockout draw generation & manual seeding.
/// - Automatic registration when eligibility and capacity requirements pass.
class MockTournamentOrganizerRepository
    implements TournamentOrganizerRepository {
  bool shouldFail;

  final String _activeOrganizerId = 'org_tourn_001';
  final String _organizationName = 'Pacific Pickleball Series';

  late List<OrganizerTournament> _tournaments;
  late List<OrganizerRegistrationRecord> _registrations;
  late Map<String, List<DrawSeedEntry>> _categoryDraws;
  late List<OrganizerMatchSlot> _matches;
  late List<OrganizerStaffAssignment> _staffAssignments;

  MockTournamentOrganizerRepository({this.shouldFail = false}) {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();
    final start1 = DateTime(now.year, now.month, now.day + 5);
    final end1 = DateTime(now.year, now.month, now.day + 7);
    final deadline1 = DateTime(now.year, now.month, now.day + 3);

    _tournaments = [
      OrganizerTournament(
        id: 'tourn_org_001',
        organizerId: _activeOrganizerId,
        organizationName: _organizationName,
        name: 'Mumbai Monsoon Championship 2026',
        venueName: 'Grand Slam Pickleball Arena',
        city: 'Mumbai',
        address: 'Plot 42, Link Road, Andheri West, Mumbai',
        startDate: start1,
        endDate: end1,
        registrationDeadline: deadline1,
        prizePool: '₹2,50,000',
        description:
            'Flagship multi-discipline tournament featuring Singles, Doubles, Mixed Doubles, and Club Team events.',
        rules: const [
          'USAPA / IPA 2026 official rules apply.',
          'Players must check in 20 minutes before scheduled match time.',
          'Official ball: Franklin X-40 optic yellow.',
        ],
        status: OrganizerTournamentStatus.registrationOpen,
        defaultScoring: const TournamentScoringConfig(
          method: TournamentScoringMethod.sideOutScoring,
          pointsPerGame: 11,
          bestOfGames: 3,
          winBy: 2,
          trackPositionsAndServiceOrder: true,
        ),
        courts: const ['Court 1', 'Court 2', 'Court 3', 'Show Court'],
        isPubliclyPublished: true,
        categories: const [
          OrganizerCategoryConfig(
            id: 'cat_ms_open',
            tournamentId: 'tourn_org_001',
            organizerId: 'org_tourn_001',
            name: "Men's Singles Open",
            eventFormat: TournamentEventFormat.singles,
            bracketFormat: TournamentBracketFormat.knockout,
            minRating: 3.5,
            maxRating: 5.5,
            minAge: 16,
            entryFeeInr: 1500,
            maxParticipants: 16,
            registeredCount: 4,
            autoApproveEligible: true,
          ),
          OrganizerCategoryConfig(
            id: 'cat_md_35',
            tournamentId: 'tourn_org_001',
            organizerId: 'org_tourn_001',
            name: 'Mixed Doubles 3.5',
            eventFormat: TournamentEventFormat.mixedDoubles,
            bracketFormat: TournamentBracketFormat.roundRobin,
            minRating: 3.0,
            maxRating: 3.75,
            minAge: 18,
            entryFeeInr: 2400,
            maxParticipants: 8,
            registeredCount: 3,
            autoApproveEligible: true,
          ),
          OrganizerCategoryConfig(
            id: 'cat_team_cup',
            tournamentId: 'tourn_org_001',
            organizerId: 'org_tourn_001',
            name: 'Corporate & Club Team Cup',
            eventFormat: TournamentEventFormat.team,
            bracketFormat: TournamentBracketFormat.roundRobin,
            entryFeeInr: 6000,
            maxParticipants: 6,
            registeredCount: 2,
            teamSize: 4,
            autoApproveEligible: true,
          ),
        ],
      ),
      OrganizerTournament(
        id: 'tourn_org_002',
        organizerId: _activeOrganizerId,
        organizationName: _organizationName,
        name: 'Winter Amateur Cup 2026',
        venueName: 'Pinnacle Sports Academy',
        city: 'Mumbai',
        address: 'Senapati Bapat Marg, Lower Parel, Mumbai',
        startDate: DateTime(now.year, now.month, now.day + 21),
        endDate: DateTime(now.year, now.month, now.day + 22),
        registrationDeadline: DateTime(now.year, now.month, now.day + 18),
        prizePool: '₹75,000',
        description: 'Beginner and intermediate community bracket.',
        status: OrganizerTournamentStatus.draft,
        courts: const ['Court A', 'Court B'],
        isPubliclyPublished: false,
        categories: const [
          OrganizerCategoryConfig(
            id: 'cat_wd_30',
            tournamentId: 'tourn_org_002',
            organizerId: 'org_tourn_001',
            name: "Women's Doubles 3.0",
            eventFormat: TournamentEventFormat.doubles,
            bracketFormat: TournamentBracketFormat.knockout,
            maxRating: 3.25,
            entryFeeInr: 1800,
            maxParticipants: 16,
            registeredCount: 0,
            autoApproveEligible: true,
          ),
        ],
      ),
      // Cross-organizer record that must never be exposed to org_tourn_001.
      OrganizerTournament(
        id: 'tourn_other_999',
        organizerId: 'org_tourn_999',
        organizationName: 'Other Organizer Federation',
        name: 'Restricted Rival Open',
        venueName: 'Delhi Central Courts',
        city: 'Delhi',
        address: 'Connaught Place, Delhi',
        startDate: start1,
        endDate: end1,
        registrationDeadline: deadline1,
        prizePool: '₹1,00,000',
        description: 'Belongs to another organizer.',
        status: OrganizerTournamentStatus.published,
        isPubliclyPublished: true,
      ),
    ];

    _registrations = [
      OrganizerRegistrationRecord(
        id: 'reg_001',
        tournamentId: 'tourn_org_001',
        organizerId: _activeOrganizerId,
        categoryId: 'cat_ms_open',
        categoryName: "Men's Singles Open",
        eventFormat: TournamentEventFormat.singles,
        playerName: 'Aarav Mehta',
        playerEmail: 'aarav.mehta@example.com',
        playerPhone: '+91 98201 10001',
        playerRating: 4.4,
        playerAge: 24,
        status: OrganizerRegistrationStatus.autoConfirmed,
        feePaidInr: 1500,
        registeredAt: now.subtract(const Duration(days: 2)),
      ),
      OrganizerRegistrationRecord(
        id: 'reg_002',
        tournamentId: 'tourn_org_001',
        organizerId: _activeOrganizerId,
        categoryId: 'cat_ms_open',
        categoryName: "Men's Singles Open",
        eventFormat: TournamentEventFormat.singles,
        playerName: 'Rohan Kapoor',
        playerEmail: 'rohan.kapoor@example.com',
        playerPhone: '+91 98201 10002',
        playerRating: 4.2,
        playerAge: 27,
        status: OrganizerRegistrationStatus.autoConfirmed,
        feePaidInr: 1500,
        registeredAt: now.subtract(const Duration(days: 2)),
      ),
      OrganizerRegistrationRecord(
        id: 'reg_003',
        tournamentId: 'tourn_org_001',
        organizerId: _activeOrganizerId,
        categoryId: 'cat_ms_open',
        categoryName: "Men's Singles Open",
        eventFormat: TournamentEventFormat.singles,
        playerName: 'Vikram Singh',
        playerEmail: 'vikram.singh@example.com',
        playerPhone: '+91 98201 10003',
        playerRating: 3.9,
        playerAge: 29,
        status: OrganizerRegistrationStatus.autoConfirmed,
        feePaidInr: 1500,
        registeredAt: now.subtract(const Duration(days: 1)),
      ),
      OrganizerRegistrationRecord(
        id: 'reg_004',
        tournamentId: 'tourn_org_001',
        organizerId: _activeOrganizerId,
        categoryId: 'cat_ms_open',
        categoryName: "Men's Singles Open",
        eventFormat: TournamentEventFormat.singles,
        playerName: 'Devansh Joshi',
        playerEmail: 'devansh.joshi@example.com',
        playerPhone: '+91 98201 10004',
        playerRating: 3.7,
        playerAge: 22,
        status: OrganizerRegistrationStatus.autoConfirmed,
        feePaidInr: 1500,
        registeredAt: now.subtract(const Duration(hours: 18)),
      ),
      OrganizerRegistrationRecord(
        id: 'reg_005',
        tournamentId: 'tourn_org_001',
        organizerId: _activeOrganizerId,
        categoryId: 'cat_md_35',
        categoryName: 'Mixed Doubles 3.5',
        eventFormat: TournamentEventFormat.mixedDoubles,
        playerName: 'Ananya Verma',
        partnerOrTeamName: 'Karan Shah',
        playerEmail: 'ananya.verma@example.com',
        playerPhone: '+91 98201 10005',
        playerRating: 3.5,
        playerAge: 25,
        status: OrganizerRegistrationStatus.autoConfirmed,
        feePaidInr: 2400,
        registeredAt: now.subtract(const Duration(days: 1)),
      ),
      OrganizerRegistrationRecord(
        id: 'reg_006',
        tournamentId: 'tourn_org_001',
        organizerId: _activeOrganizerId,
        categoryId: 'cat_md_35',
        categoryName: 'Mixed Doubles 3.5',
        eventFormat: TournamentEventFormat.mixedDoubles,
        playerName: 'Neha Nair',
        partnerOrTeamName: 'Siddharth Rao',
        playerEmail: 'neha.nair@example.com',
        playerPhone: '+91 98201 10006',
        playerRating: 3.4,
        playerAge: 28,
        status: OrganizerRegistrationStatus.autoConfirmed,
        feePaidInr: 2400,
        registeredAt: now.subtract(const Duration(hours: 12)),
      ),
      OrganizerRegistrationRecord(
        id: 'reg_007',
        tournamentId: 'tourn_org_001',
        organizerId: _activeOrganizerId,
        categoryId: 'cat_md_35',
        categoryName: 'Mixed Doubles 3.5',
        eventFormat: TournamentEventFormat.mixedDoubles,
        playerName: 'Pooja Desai',
        partnerOrTeamName: 'Kabir Malhotra',
        playerEmail: 'pooja.desai@example.com',
        playerPhone: '+91 98201 10007',
        playerRating: 3.3,
        playerAge: 26,
        status: OrganizerRegistrationStatus.autoConfirmed,
        feePaidInr: 2400,
        registeredAt: now.subtract(const Duration(hours: 6)),
      ),
      OrganizerRegistrationRecord(
        id: 'reg_008',
        tournamentId: 'tourn_org_001',
        organizerId: _activeOrganizerId,
        categoryId: 'cat_team_cup',
        categoryName: 'Corporate & Club Team Cup',
        eventFormat: TournamentEventFormat.team,
        playerName: 'Andheri Smashers',
        partnerOrTeamName: '4-Player Squad',
        playerEmail: 'captain@andherismashers.in',
        playerPhone: '+91 98201 10008',
        playerRating: 4.0,
        playerAge: 30,
        status: OrganizerRegistrationStatus.autoConfirmed,
        feePaidInr: 6000,
        registeredAt: now.subtract(const Duration(days: 1)),
      ),
      OrganizerRegistrationRecord(
        id: 'reg_009',
        tournamentId: 'tourn_org_001',
        organizerId: _activeOrganizerId,
        categoryId: 'cat_team_cup',
        categoryName: 'Corporate & Club Team Cup',
        eventFormat: TournamentEventFormat.team,
        playerName: 'Bandra Dinkers',
        partnerOrTeamName: '4-Player Squad',
        playerEmail: 'captain@bandradinkers.in',
        playerPhone: '+91 98201 10009',
        playerRating: 3.8,
        playerAge: 31,
        status: OrganizerRegistrationStatus.autoConfirmed,
        feePaidInr: 6000,
        registeredAt: now.subtract(const Duration(hours: 8)),
      ),
      // Cross-organizer registration — must never leak.
      OrganizerRegistrationRecord(
        id: 'reg_other_999',
        tournamentId: 'tourn_other_999',
        organizerId: 'org_tourn_999',
        categoryId: 'cat_other',
        categoryName: 'Rival Open',
        eventFormat: TournamentEventFormat.singles,
        playerName: 'Hidden Player',
        playerEmail: 'hidden@rival.com',
        playerPhone: '+91 90000 00000',
        playerRating: 4.0,
        playerAge: 25,
        status: OrganizerRegistrationStatus.autoConfirmed,
        feePaidInr: 1000,
        registeredAt: now,
      ),
    ];

    _staffAssignments = [
      const OrganizerStaffAssignment(
        id: 'stf_t_001',
        tournamentId: 'tourn_org_001',
        organizerId: 'org_tourn_001',
        userId: 'user_tstaff_001',
        name: 'Sneha Kulkarni',
        email: 'sneha.kulkarni@pacificseries.in',
        role: OrganizerStaffRole.tournamentStaff,
        delegatedPermissions: {'VIEW_DASHBOARD', 'MANAGE_CHECK_IN'},
        isActive: true,
      ),
      const OrganizerStaffAssignment(
        id: 'stf_t_002',
        tournamentId: 'tourn_org_001',
        organizerId: 'org_tourn_001',
        userId: 'user_ref_001',
        name: 'Rajesh Iyer',
        email: 'rajesh.iyer@refereeindia.org',
        role: OrganizerStaffRole.referee,
        delegatedPermissions: {'SCORE_ASSIGNED_MATCHES'},
        isActive: true,
      ),
      const OrganizerStaffAssignment(
        id: 'stf_t_003',
        tournamentId: 'tourn_org_001',
        organizerId: 'org_tourn_001',
        userId: 'user_ref_002',
        name: 'Meera Krishnan',
        email: 'meera.krishnan@refereeindia.org',
        role: OrganizerStaffRole.referee,
        delegatedPermissions: {'SCORE_ASSIGNED_MATCHES'},
        isActive: true,
      ),
    ];

    _categoryDraws = {};
    _matches = [];
    // Pre-generate Knockout draw for Men's Singles Open so Match Day monitor has live data.
    _buildDrawForCategory(
      tournament: _tournaments.first,
      category: _tournaments.first.categories.first,
    );
  }

  FailureResult<TournamentOrganizerWorkspaceData>? _validateOrganizer(
    String organizerId,
  ) {
    if (organizerId.trim().isEmpty || organizerId != _activeOrganizerId) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Unauthorized: tournament organizer context mismatch.',
        ),
      );
    }
    return null;
  }

  OrganizerTournament? _findOwnedTournament(
    String organizerId,
    String tournamentId,
  ) {
    for (final t in _tournaments) {
      if (t.id == tournamentId && t.organizerId == organizerId) {
        return t;
      }
    }
    return null;
  }

  TournamentOrganizerWorkspaceData _buildWorkspace() {
    final ownedTournaments = _tournaments
        .where((t) => t.organizerId == _activeOrganizerId)
        .toList();
    final ownedIds = ownedTournaments.map((t) => t.id).toSet();

    return TournamentOrganizerWorkspaceData(
      organizerId: _activeOrganizerId,
      organizationName: _organizationName,
      tournaments: ownedTournaments,
      registrations: _registrations
          .where((r) =>
              r.organizerId == _activeOrganizerId &&
              ownedIds.contains(r.tournamentId))
          .toList(),
      categoryDraws: Map<String, List<DrawSeedEntry>>.unmodifiable(
        _categoryDraws,
      ),
      matches: _matches
          .where((m) =>
              m.organizerId == _activeOrganizerId &&
              ownedIds.contains(m.tournamentId))
          .toList(),
      staffAssignments: _staffAssignments
          .where((s) =>
              s.organizerId == _activeOrganizerId &&
              ownedIds.contains(s.tournamentId))
          .toList(),
    );
  }

  @override
  Future<Result<TournamentOrganizerWorkspaceData>> getWorkspace({
    required String organizerId,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        NetworkFailure(message: 'Unable to load tournament organizer workspace.'),
      );
    }
    final authErr = _validateOrganizer(organizerId);
    if (authErr != null) return authErr;

    return Success(_buildWorkspace());
  }

  @override
  Future<Result<TournamentOrganizerWorkspaceData>> createTournament({
    required String organizerId,
    required OrganizerTournament tournament,
  }) async {
    final authErr = _validateOrganizer(organizerId);
    if (authErr != null) return authErr;

    if (tournament.name.trim().isEmpty ||
        tournament.venueName.trim().isEmpty ||
        tournament.city.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Tournament name, venue, and city are required.',
        ),
      );
    }
    if (tournament.endDate.isBefore(tournament.startDate)) {
      return const FailureResult(
        ValidationFailure(
          message: 'End date cannot be earlier than start date.',
        ),
      );
    }
    if (tournament.registrationDeadline.isAfter(tournament.startDate)) {
      return const FailureResult(
        ValidationFailure(
          message: 'Registration deadline must be on or before start date.',
        ),
      );
    }
    if (tournament.categories.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Add at least one tournament category before saving.',
        ),
      );
    }
    if (tournament.defaultScoring.pointsPerGame <= 0 ||
        tournament.defaultScoring.bestOfGames < 1 ||
        tournament.defaultScoring.bestOfGames.isEven ||
        (tournament.defaultScoring.winBy != 1 &&
            tournament.defaultScoring.winBy != 2)) {
      return const FailureResult(
        ValidationFailure(
          message: 'Scoring configuration must use valid points, odd best-of games, and win-by 1 or 2.',
        ),
      );
    }

    final newId = 'tourn_org_${_tournaments.length + 1}';
    final normalizedCategories = <OrganizerCategoryConfig>[];
    for (var i = 0; i < tournament.categories.length; i++) {
      final cat = tournament.categories[i];
      if (cat.maxParticipants < 2) {
        return const FailureResult(
          ValidationFailure(
            message: 'Each category must allow at least 2 participants/teams.',
          ),
        );
      }
      normalizedCategories.add(
        OrganizerCategoryConfig(
          id: 'cat_${newId}_${i + 1}',
          tournamentId: newId,
          organizerId: organizerId,
          name: cat.name.trim(),
          eventFormat: cat.eventFormat,
          bracketFormat: cat.bracketFormat,
          minRating: cat.minRating,
          maxRating: cat.maxRating,
          minAge: cat.minAge,
          maxAge: cat.maxAge,
          entryFeeInr: cat.entryFeeInr,
          maxParticipants: cat.maxParticipants,
          registeredCount: 0,
          teamSize: cat.teamSize,
          autoApproveEligible: cat.autoApproveEligible,
          isRegistrationOpen: cat.isRegistrationOpen,
        ),
      );
    }

    _tournaments = [
      OrganizerTournament(
        id: newId,
        organizerId: organizerId,
        organizationName: _organizationName,
        name: tournament.name.trim(),
        venueName: tournament.venueName.trim(),
        city: tournament.city.trim(),
        address: tournament.address.trim(),
        startDate: tournament.startDate,
        endDate: tournament.endDate,
        registrationDeadline: tournament.registrationDeadline,
        prizePool: tournament.prizePool.trim(),
        description: tournament.description.trim(),
        rules: tournament.rules,
        status: tournament.status,
        defaultScoring: tournament.defaultScoring,
        categories: normalizedCategories,
        courts: tournament.courts.isEmpty
            ? const ['Court 1', 'Court 2']
            : tournament.courts,
        isPubliclyPublished:
            tournament.status != OrganizerTournamentStatus.draft,
      ),
      ..._tournaments,
    ];

    return Success(_buildWorkspace());
  }

  @override
  Future<Result<TournamentOrganizerWorkspaceData>> updateTournamentStatus({
    required String organizerId,
    required String tournamentId,
    required OrganizerTournamentStatus status,
  }) async {
    final authErr = _validateOrganizer(organizerId);
    if (authErr != null) return authErr;

    final existing = _findOwnedTournament(organizerId, tournamentId);
    if (existing == null) {
      return const FailureResult(
        ForbiddenFailure(message: 'Tournament not found or access denied.'),
      );
    }

    if (status != OrganizerTournamentStatus.draft &&
        status != OrganizerTournamentStatus.cancelled &&
        existing.categories.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Cannot publish a tournament with zero categories.',
        ),
      );
    }

    _tournaments = _tournaments
        .map(
          (t) => t.id == tournamentId
              ? t.copyWith(
                  status: status,
                  isPubliclyPublished:
                      status != OrganizerTournamentStatus.draft &&
                          status != OrganizerTournamentStatus.cancelled,
                )
              : t,
        )
        .toList();

    return Success(_buildWorkspace());
  }

  @override
  Future<Result<TournamentOrganizerWorkspaceData>> addCategory({
    required String organizerId,
    required String tournamentId,
    required OrganizerCategoryConfig category,
  }) async {
    final authErr = _validateOrganizer(organizerId);
    if (authErr != null) return authErr;

    final tournament = _findOwnedTournament(organizerId, tournamentId);
    if (tournament == null) {
      return const FailureResult(
        ForbiddenFailure(message: 'Tournament not found or access denied.'),
      );
    }
    if (category.name.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Category name is required.'),
      );
    }
    if (category.maxParticipants < 2) {
      return const FailureResult(
        ValidationFailure(
          message: 'Category capacity must be at least 2 entries.',
        ),
      );
    }
    if (category.minRating != null &&
        category.maxRating != null &&
        category.minRating! > category.maxRating!) {
      return const FailureResult(
        ValidationFailure(
          message: 'Minimum DUPR rating cannot exceed maximum rating.',
        ),
      );
    }
    if (category.minAge != null &&
        category.maxAge != null &&
        category.minAge! > category.maxAge!) {
      return const FailureResult(
        ValidationFailure(message: 'Minimum age cannot exceed maximum age.'),
      );
    }

    final created = OrganizerCategoryConfig(
      id: 'cat_${tournamentId}_${tournament.categories.length + 1}',
      tournamentId: tournamentId,
      organizerId: organizerId,
      name: category.name.trim(),
      eventFormat: category.eventFormat,
      bracketFormat: category.bracketFormat,
      minRating: category.minRating,
      maxRating: category.maxRating,
      minAge: category.minAge,
      maxAge: category.maxAge,
      entryFeeInr: category.entryFeeInr,
      maxParticipants: category.maxParticipants,
      teamSize: category.teamSize,
      autoApproveEligible: category.autoApproveEligible,
      isRegistrationOpen: category.isRegistrationOpen,
    );

    _tournaments = _tournaments
        .map(
          (t) => t.id == tournamentId
              ? t.copyWith(categories: [...t.categories, created])
              : t,
        )
        .toList();

    return Success(_buildWorkspace());
  }

  @override
  Future<Result<TournamentOrganizerWorkspaceData>> submitAutoRegistration({
    required String organizerId,
    required String tournamentId,
    required String categoryId,
    required String playerName,
    String? partnerOrTeamName,
    required String playerEmail,
    required String playerPhone,
    required double playerRating,
    required int playerAge,
  }) async {
    final authErr = _validateOrganizer(organizerId);
    if (authErr != null) return authErr;

    final tournament = _findOwnedTournament(organizerId, tournamentId);
    if (tournament == null) {
      return const FailureResult(
        ForbiddenFailure(message: 'Tournament not found or access denied.'),
      );
    }
    if (tournament.status != OrganizerTournamentStatus.registrationOpen &&
        tournament.status != OrganizerTournamentStatus.published) {
      return const FailureResult(
        ValidationFailure(
          message: 'Tournament is not currently open for registration.',
        ),
      );
    }

    final catIndex = tournament.categories.indexWhere((c) => c.id == categoryId);
    if (catIndex == -1) {
      return const FailureResult(
        ValidationFailure(message: 'Category not found in this tournament.'),
      );
    }
    final category = tournament.categories[catIndex];
    if (!category.isRegistrationOpen) {
      return const FailureResult(
        ValidationFailure(message: 'Registration is closed for this category.'),
      );
    }
    if (category.isCapacityFull) {
      return const FailureResult(
        ValidationFailure(
          message: 'Registration rejected: category capacity is full.',
        ),
      );
    }
    if (playerName.trim().isEmpty || playerEmail.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Participant name and email are required.'),
      );
    }
    if (category.eventFormat != TournamentEventFormat.singles &&
        (partnerOrTeamName == null || partnerOrTeamName.trim().isEmpty)) {
      return FailureResult(
        ValidationFailure(
          message:
              '${category.eventFormat.label} requires a partner or team name.',
        ),
      );
    }
    if (!category.isRatingEligible(playerRating)) {
      return const FailureResult(
        ValidationFailure(
          message:
              'Registration rejected: player DUPR rating does not meet category eligibility.',
        ),
      );
    }
    if (!category.isAgeEligible(playerAge)) {
      return const FailureResult(
        ValidationFailure(
          message:
              'Registration rejected: player age does not meet category eligibility.',
        ),
      );
    }

    final status = category.autoApproveEligible
        ? OrganizerRegistrationStatus.autoConfirmed
        : OrganizerRegistrationStatus.pendingReview;

    final newReg = OrganizerRegistrationRecord(
      id: 'reg_${_registrations.length + 1}',
      tournamentId: tournamentId,
      organizerId: organizerId,
      categoryId: categoryId,
      categoryName: category.name,
      eventFormat: category.eventFormat,
      playerName: playerName.trim(),
      partnerOrTeamName: partnerOrTeamName?.trim(),
      playerEmail: playerEmail.trim(),
      playerPhone: playerPhone.trim(),
      playerRating: playerRating,
      playerAge: playerAge,
      status: status,
      feePaidInr: category.entryFeeInr,
      registeredAt: DateTime.now(),
    );

    _registrations = [newReg, ..._registrations];

    final updatedCategories = [...tournament.categories];
    updatedCategories[catIndex] =
        category.copyWith(registeredCount: category.registeredCount + 1);
    _tournaments = _tournaments
        .map(
          (t) => t.id == tournamentId
              ? t.copyWith(categories: updatedCategories)
              : t,
        )
        .toList();

    return Success(_buildWorkspace());
  }

  @override
  Future<Result<TournamentOrganizerWorkspaceData>> generateDraw({
    required String organizerId,
    required String tournamentId,
    required String categoryId,
  }) async {
    final authErr = _validateOrganizer(organizerId);
    if (authErr != null) return authErr;

    final tournament = _findOwnedTournament(organizerId, tournamentId);
    if (tournament == null) {
      return const FailureResult(
        ForbiddenFailure(message: 'Tournament not found or access denied.'),
      );
    }

    final cat = tournament.categories.where((c) => c.id == categoryId).firstOrNull;
    if (cat == null) {
      return const FailureResult(
        ValidationFailure(message: 'Category not found in this tournament.'),
      );
    }

    final confirmed = _registrations
        .where((r) =>
            r.tournamentId == tournamentId &&
            r.organizerId == organizerId &&
            r.categoryId == categoryId &&
            r.status == OrganizerRegistrationStatus.autoConfirmed)
        .toList();

    if (confirmed.length < 2) {
      return const FailureResult(
        ValidationFailure(
          message: 'At least 2 confirmed entries are required to generate a draw.',
        ),
      );
    }

    _buildDrawForCategory(tournament: tournament, category: cat);
    return Success(_buildWorkspace());
  }

  void _buildDrawForCategory({
    required OrganizerTournament tournament,
    required OrganizerCategoryConfig category,
  }) {
    final confirmed = _registrations
        .where((r) =>
            r.tournamentId == tournament.id &&
            r.organizerId == tournament.organizerId &&
            r.categoryId == category.id &&
            r.status == OrganizerRegistrationStatus.autoConfirmed)
        .toList()
      ..sort((a, b) => b.playerRating.compareTo(a.playerRating));

    final seeds = <DrawSeedEntry>[];
    for (var i = 0; i < confirmed.length; i++) {
      final groupLabel = category.bracketFormat == TournamentBracketFormat.roundRobin
          ? (i.isEven ? 'Pool A' : 'Pool B')
          : null;
      seeds.add(
        DrawSeedEntry(
          registrationId: confirmed[i].id,
          categoryId: category.id,
          participantLabel: confirmed[i].displayParticipant,
          seedNumber: i + 1,
          groupName: groupLabel,
        ),
      );
    }

    _categoryDraws[category.id] = seeds;
    _rebuildMatchesForCategory(tournament: tournament, category: category, seeds: seeds);
  }

  void _rebuildMatchesForCategory({
    required OrganizerTournament tournament,
    required OrganizerCategoryConfig category,
    required List<DrawSeedEntry> seeds,
  }) {
    _matches.removeWhere((m) => m.categoryId == category.id);
    final generated = <OrganizerMatchSlot>[];
    var matchSeq = 1;

    if (category.bracketFormat == TournamentBracketFormat.roundRobin) {
      for (var i = 0; i < seeds.length; i++) {
        for (var j = i + 1; j < seeds.length; j++) {
          generated.add(
            OrganizerMatchSlot(
              id: 'm_${category.id}_$matchSeq',
              tournamentId: tournament.id,
              organizerId: tournament.organizerId,
              categoryId: category.id,
              categoryName: category.name,
              bracketFormat: category.bracketFormat,
              roundLabel: 'Round Robin • Match $matchSeq',
              matchNumber: matchSeq,
              participantA:
                  '(#${seeds[i].seedNumber}) ${seeds[i].participantLabel}',
              participantB:
                  '(#${seeds[j].seedNumber}) ${seeds[j].participantLabel}',
              courtName: tournament.courts.isNotEmpty
                  ? tournament.courts[(matchSeq - 1) % tournament.courts.length]
                  : null,
              scheduledTime: tournament.startDate
                  .add(Duration(hours: 9 + (matchSeq - 1))),
            ),
          );
          matchSeq++;
        }
      }
    } else {
      final half = (seeds.length / 2).ceil();
      for (var i = 0; i < half; i++) {
        final top = seeds[i];
        final oppIndex = seeds.length - 1 - i;
        final opponentLabel = oppIndex > i
            ? '(#${seeds[oppIndex].seedNumber}) ${seeds[oppIndex].participantLabel}'
            : 'BYE';
        generated.add(
          OrganizerMatchSlot(
            id: 'm_${category.id}_$matchSeq',
            tournamentId: tournament.id,
            organizerId: tournament.organizerId,
            categoryId: category.id,
            categoryName: category.name,
            bracketFormat: category.bracketFormat,
            roundLabel: seeds.length <= 2
                ? 'Final'
                : (seeds.length <= 4 ? 'Semifinal' : 'Round of ${half * 2}'),
            matchNumber: matchSeq,
            participantA: '(#${top.seedNumber}) ${top.participantLabel}',
            participantB: opponentLabel,
            courtName: tournament.courts.isNotEmpty
                ? tournament.courts[(matchSeq - 1) % tournament.courts.length]
                : null,
            scheduledTime:
                tournament.startDate.add(Duration(hours: 10 + (matchSeq - 1))),
          ),
        );
        matchSeq++;
      }
    }

    _matches = [..._matches, ...generated];
  }

  @override
  Future<Result<TournamentOrganizerWorkspaceData>> swapSeedOrder({
    required String organizerId,
    required String tournamentId,
    required String categoryId,
    required int indexA,
    required int indexB,
  }) async {
    final authErr = _validateOrganizer(organizerId);
    if (authErr != null) return authErr;

    final tournament = _findOwnedTournament(organizerId, tournamentId);
    if (tournament == null) {
      return const FailureResult(
        ForbiddenFailure(message: 'Tournament not found or access denied.'),
      );
    }

    final cat = tournament.categories.where((c) => c.id == categoryId).firstOrNull;
    final currentSeeds = _categoryDraws[categoryId];
    if (cat == null || currentSeeds == null) {
      return const FailureResult(
        ValidationFailure(message: 'Generate the draw before adjusting seeds.'),
      );
    }
    if (indexA < 0 ||
        indexB < 0 ||
        indexA >= currentSeeds.length ||
        indexB >= currentSeeds.length) {
      return const FailureResult(
        ValidationFailure(message: 'Invalid seed position.'),
      );
    }

    final updated = [...currentSeeds];
    final a = updated[indexA];
    final b = updated[indexB];
    updated[indexA] = b.copyWith(seedNumber: indexA + 1);
    updated[indexB] = a.copyWith(seedNumber: indexB + 1);

    _categoryDraws[categoryId] = updated;
    _rebuildMatchesForCategory(
      tournament: tournament,
      category: cat,
      seeds: updated,
    );

    return Success(_buildWorkspace());
  }

  @override
  Future<Result<TournamentOrganizerWorkspaceData>> assignMatchScheduleAndReferee({
    required String organizerId,
    required String tournamentId,
    required String matchId,
    required String courtName,
    required DateTime scheduledTime,
    String? refereeAssignmentId,
  }) async {
    final authErr = _validateOrganizer(organizerId);
    if (authErr != null) return authErr;

    final tournament = _findOwnedTournament(organizerId, tournamentId);
    if (tournament == null) {
      return const FailureResult(
        ForbiddenFailure(message: 'Tournament not found or access denied.'),
      );
    }
    if (!tournament.courts.contains(courtName)) {
      return const FailureResult(
        ValidationFailure(
          message: 'Selected court does not belong to this tournament.',
        ),
      );
    }

    final matchIndex = _matches.indexWhere(
      (m) =>
          m.id == matchId &&
          m.tournamentId == tournamentId &&
          m.organizerId == organizerId,
    );
    if (matchIndex == -1) {
      return const FailureResult(
        ForbiddenFailure(message: 'Match not found or access denied.'),
      );
    }

    // Court schedule conflict check (within 45-minute window on same court).
    final hasConflict = _matches.any(
      (m) =>
          m.id != matchId &&
          m.tournamentId == tournamentId &&
          m.courtName == courtName &&
          m.scheduledTime != null &&
          m.scheduledTime!.difference(scheduledTime).inMinutes.abs() < 45,
    );
    if (hasConflict) {
      return FailureResult(
        ValidationFailure(
          message: '$courtName already has a match scheduled within 45 minutes.',
        ),
      );
    }

    String? refereeId;
    String? refereeName;
    if (refereeAssignmentId != null && refereeAssignmentId.isNotEmpty) {
      final ref = _staffAssignments
          .where((s) =>
              s.id == refereeAssignmentId &&
              s.tournamentId == tournamentId &&
              s.organizerId == organizerId &&
              s.role == OrganizerStaffRole.referee &&
              s.isActive)
          .firstOrNull;
      if (ref == null) {
        return const FailureResult(
          ForbiddenFailure(
            message: 'Selected referee is inactive or not assigned to this tournament.',
          ),
        );
      }
      refereeId = ref.userId;
      refereeName = ref.name;
    }

    _matches[matchIndex] = _matches[matchIndex].copyWith(
      courtName: courtName,
      scheduledTime: scheduledTime,
      refereeId: refereeId,
      refereeName: refereeName,
    );

    return Success(_buildWorkspace());
  }

  @override
  Future<Result<TournamentOrganizerWorkspaceData>> updateMatchScore({
    required String organizerId,
    required String tournamentId,
    required String matchId,
    required String scoreSummary,
    required String winnerLabel,
  }) async {
    final authErr = _validateOrganizer(organizerId);
    if (authErr != null) return authErr;

    final idx = _matches.indexWhere(
      (m) =>
          m.id == matchId &&
          m.tournamentId == tournamentId &&
          m.organizerId == organizerId,
    );
    if (idx == -1) {
      return const FailureResult(
        ForbiddenFailure(message: 'Match not found or access denied.'),
      );
    }
    if (scoreSummary.trim().isEmpty || winnerLabel.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Score summary and winner are required.'),
      );
    }

    _matches[idx] = _matches[idx].copyWith(
      status: OrganizerMatchStatus.completed,
      scoreSummary: scoreSummary.trim(),
      winnerLabel: winnerLabel.trim(),
    );

    return Success(_buildWorkspace());
  }

  @override
  Future<Result<TournamentOrganizerWorkspaceData>> addStaffOrReferee({
    required String organizerId,
    required String tournamentId,
    required String name,
    required String email,
    required OrganizerStaffRole role,
    required Set<String> delegatedPermissions,
  }) async {
    final authErr = _validateOrganizer(organizerId);
    if (authErr != null) return authErr;

    final tournament = _findOwnedTournament(organizerId, tournamentId);
    if (tournament == null) {
      return const FailureResult(
        ForbiddenFailure(message: 'Tournament not found or access denied.'),
      );
    }
    if (name.trim().isEmpty || email.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Name and email are required.'),
      );
    }

    final normalizedPerms = role == OrganizerStaffRole.referee
        ? {'SCORE_ASSIGNED_MATCHES'}
        : delegatedPermissions;

    _staffAssignments = [
      ..._staffAssignments,
      OrganizerStaffAssignment(
        id: 'stf_t_${_staffAssignments.length + 1}',
        tournamentId: tournamentId,
        organizerId: organizerId,
        userId: 'user_t_${_staffAssignments.length + 1}',
        name: name.trim(),
        email: email.trim(),
        role: role,
        delegatedPermissions: normalizedPerms,
        isActive: true,
      ),
    ];

    return Success(_buildWorkspace());
  }

  @override
  Future<Result<TournamentOrganizerWorkspaceData>> toggleStaffActive({
    required String organizerId,
    required String tournamentId,
    required String assignmentId,
    required bool isActive,
  }) async {
    final authErr = _validateOrganizer(organizerId);
    if (authErr != null) return authErr;

    final idx = _staffAssignments.indexWhere(
      (s) =>
          s.id == assignmentId &&
          s.tournamentId == tournamentId &&
          s.organizerId == organizerId,
    );
    if (idx == -1) {
      return const FailureResult(
        ForbiddenFailure(message: 'Staff assignment not found or access denied.'),
      );
    }

    _staffAssignments[idx] = _staffAssignments[idx].copyWith(isActive: isActive);
    return Success(_buildWorkspace());
  }

  @override
  Future<Result<TournamentOrganizerWorkspaceData>> updateStaffPermissions({
    required String organizerId,
    required String tournamentId,
    required String assignmentId,
    required Set<String> delegatedPermissions,
  }) async {
    final authErr = _validateOrganizer(organizerId);
    if (authErr != null) return authErr;

    final idx = _staffAssignments.indexWhere(
      (s) =>
          s.id == assignmentId &&
          s.tournamentId == tournamentId &&
          s.organizerId == organizerId,
    );
    if (idx == -1) {
      return const FailureResult(
        ForbiddenFailure(message: 'Staff assignment not found or access denied.'),
      );
    }

    _staffAssignments[idx] = _staffAssignments[idx].copyWith(
      delegatedPermissions: delegatedPermissions,
    );
    return Success(_buildWorkspace());
  }
}
