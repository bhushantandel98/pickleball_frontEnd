import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_tournament_repository.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/tournament_details_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/tournament_details_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/tournament_discovery_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/tournament_discovery_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/tournament_registration_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/tournament_registration_state.dart';
import 'package:pickleball_platform/features/player/presentation/pages/tournament_confirmation_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/tournament_details_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/tournament_discovery_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/tournament_registration_page.dart';

void setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  group('MockTournamentRepository Unit Tests', () {
    test('getTournaments returns default mock list', () async {
      final repo = MockTournamentRepository();
      final result = await repo.getTournaments();

      expect(result, isA<Success<List<TournamentItem>>>());
      final tournaments = (result as Success<List<TournamentItem>>).data;
      expect(tournaments.length, equals(5));
      expect(tournaments.any((t) => t.id == 'tourn_001'), isTrue);
      expect(tournaments.any((t) => t.id == 'tourn_002'), isTrue);
    });

    test('getTournaments returns empty list when isEmpty is true', () async {
      final repo = MockTournamentRepository(isEmpty: true);
      final result = await repo.getTournaments();

      expect(result, isA<Success<List<TournamentItem>>>());
      expect((result as Success<List<TournamentItem>>).data, isEmpty);
    });

    test('getTournaments returns ServerFailure when shouldFail is true', () async {
      final repo = MockTournamentRepository(shouldFail: true);
      final result = await repo.getTournaments();

      expect(result, isA<FailureResult<List<TournamentItem>>>());
      expect((result as FailureResult<List<TournamentItem>>).failure, isA<ServerFailure>());
    });

    test('getTournaments filters by search query', () async {
      final repo = MockTournamentRepository();
      final result = await repo.getTournaments(
        filter: const TournamentFilter(searchQuery: 'Monsoon'),
      );

      expect(result, isA<Success<List<TournamentItem>>>());
      final list = (result as Success<List<TournamentItem>>).data;
      expect(list.length, equals(1));
      expect(list.first.name, equals('Monsoon Community Cup 2026'));
    });

    test('getTournaments filters by registration open only', () async {
      final repo = MockTournamentRepository();
      final result = await repo.getTournaments(
        filter: const TournamentFilter(onlyOpenForRegistration: true),
      );

      expect(result, isA<Success<List<TournamentItem>>>());
      final list = (result as Success<List<TournamentItem>>).data;
      expect(list.every((t) => t.isRegistrationOpen), isTrue);
    });

    test('getTournaments sorts by fee lowest', () async {
      final repo = MockTournamentRepository();
      final result = await repo.getTournaments(
        filter: const TournamentFilter(sortBy: TournamentSortOption.feeLowest),
      );

      expect(result, isA<Success<List<TournamentItem>>>());
      final list = (result as Success<List<TournamentItem>>).data;
      for (int i = 0; i < list.length - 1; i++) {
        expect(list[i].entryFeeFrom <= list[i + 1].entryFeeFrom, isTrue);
      }
    });

    test('getTournamentById returns tournament item or NotFoundFailure', () async {
      final repo = MockTournamentRepository();

      final found = await repo.getTournamentById('tourn_002');
      expect(found, isA<Success<TournamentItem>>());
      expect((found as Success<TournamentItem>).data.name, equals('Monsoon Community Cup 2026'));

      final notFound = await repo.getTournamentById('non_existent');
      expect(notFound, isA<FailureResult<TournamentItem>>());
      expect((notFound as FailureResult<TournamentItem>).failure, isA<NotFoundFailure>());
    });

    test('registerForTournament successfully registers eligible player', () async {
      final repo = MockTournamentRepository();
      final payload = TournamentRegistrationPayload(
        tournamentId: 'tourn_002',
        categoryId: 'cat_002_ms',
        playerName: 'Alex Rivera',
        playerPhone: '+91 98765 43210',
        playerEmail: 'alex@example.com',
        playerRating: 3.5,
        emergencyContactName: 'Emergency',
        emergencyContactPhone: '+91 99999 88888',
        acceptedWaiver: true,
        acceptedRules: true,
        entryFee: 800.0,
      );

      final result = await repo.registerForTournament(payload);
      expect(result, isA<Success<TournamentRegistration>>());
      final reg = (result as Success<TournamentRegistration>).data;
      expect(reg.status, equals(TournamentRegistrationStatus.confirmed));
      expect(reg.id, startsWith('PKL-TRN-'));

      // Check category registered count incremented
      final tResult = await repo.getTournamentById('tourn_002');
      final updatedCat = (tResult as Success<TournamentItem>)
          .data
          .categories
          .firstWhere((c) => c.id == 'cat_002_ms');
      expect(updatedCat.registeredCount, equals(13));
    });

    test('registerForTournament rejects if waivers not accepted', () async {
      final repo = MockTournamentRepository();
      final payload = TournamentRegistrationPayload(
        tournamentId: 'tourn_002',
        categoryId: 'cat_002_ms',
        playerName: 'Alex Rivera',
        playerPhone: '+91 98765 43210',
        playerEmail: 'alex@example.com',
        playerRating: 3.5,
        emergencyContactName: 'Emergency',
        emergencyContactPhone: '+91 99999 88888',
        acceptedWaiver: false, // not accepted
        acceptedRules: true,
        entryFee: 800.0,
      );

      final result = await repo.registerForTournament(payload);
      expect(result, isA<FailureResult<TournamentRegistration>>());
      expect((result as FailureResult<TournamentRegistration>).failure, isA<ValidationFailure>());
    });

    test('registerForTournament rejects doubles without partner name', () async {
      final repo = MockTournamentRepository();
      final payload = TournamentRegistrationPayload(
        tournamentId: 'tourn_002',
        categoryId: 'cat_002_md', // Doubles category
        playerName: 'Alex Rivera',
        playerPhone: '+91 98765 43210',
        playerEmail: 'alex@example.com',
        playerRating: 3.5,
        partnerName: '', // empty
        emergencyContactName: 'Emergency',
        emergencyContactPhone: '+91 99999 88888',
        acceptedWaiver: true,
        acceptedRules: true,
        entryFee: 1400.0,
      );

      final result = await repo.registerForTournament(payload);
      expect(result, isA<FailureResult<TournamentRegistration>>());
      expect((result as FailureResult<TournamentRegistration>).failure, isA<ValidationFailure>());
    });

    test('withdrawFromTournament marks registration as withdrawn', () async {
      final repo = MockTournamentRepository();
      final regs = await repo.getMyRegistrations();
      final regId = (regs as Success<List<TournamentRegistration>>).data.first.id;

      final withdrawResult = await repo.withdrawFromTournament(regId);
      expect(withdrawResult, isA<Success<TournamentRegistration>>());
      expect(
        (withdrawResult as Success<TournamentRegistration>).data.status,
        equals(TournamentRegistrationStatus.withdrawn),
      );
    });

    test('registerForTournament rejects ineligible DUPR rating', () async {
      final repo = MockTournamentRepository();
      final payload = TournamentRegistrationPayload(
        tournamentId: 'tourn_002',
        categoryId: 'cat_002_ms', // maxRating is 3.75
        playerName: 'Alex Rivera',
        playerPhone: '+91 98765 43210',
        playerEmail: 'alex@example.com',
        playerRating: 4.5, // Exceeds 3.75
        playerAge: 28,
        emergencyContactName: 'Elena Rivera',
        emergencyContactPhone: '+91 98765 00000',
        acceptedWaiver: true,
        acceptedRules: true,
        entryFee: 800.0,
      );

      final result = await repo.registerForTournament(payload);
      expect(result, isA<FailureResult<TournamentRegistration>>());
      final failure = (result as FailureResult<TournamentRegistration>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, contains('Player rating'));
    });

    test('registerForTournament rejects ineligible age', () async {
      final repo = MockTournamentRepository();
      final payload = TournamentRegistrationPayload(
        tournamentId: 'tourn_002',
        categoryId: 'cat_002_sr', // minAge 50
        playerName: 'Alex Rivera',
        playerPhone: '+91 98765 43210',
        playerEmail: 'alex@example.com',
        playerRating: 3.5,
        playerAge: 28, // Under 50
        partnerName: 'Senior Partner',
        emergencyContactName: 'Elena Rivera',
        emergencyContactPhone: '+91 98765 00000',
        acceptedWaiver: true,
        acceptedRules: true,
        entryFee: 1200.0,
      );

      final result = await repo.registerForTournament(payload);
      expect(result, isA<FailureResult<TournamentRegistration>>());
      final failure = (result as FailureResult<TournamentRegistration>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, contains('Player age'));
    });

    test('registerForTournament rejects closed category registration', () async {
      final repo = MockTournamentRepository();
      final payload = TournamentRegistrationPayload(
        tournamentId: 'tourn_002',
        categoryId: 'cat_002_pro', // isRegistrationOpen: false
        playerName: 'Alex Rivera',
        playerPhone: '+91 98765 43210',
        playerEmail: 'alex@example.com',
        playerRating: 4.8,
        playerAge: 28,
        emergencyContactName: 'Elena Rivera',
        emergencyContactPhone: '+91 98765 00000',
        acceptedWaiver: true,
        acceptedRules: true,
        entryFee: 2500.0,
      );

      final result = await repo.registerForTournament(payload);
      expect(result, isA<FailureResult<TournamentRegistration>>());
      final failure = (result as FailureResult<TournamentRegistration>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, contains('is closed'));
    });

    test('registerForTournament handles full category as waitlist without increasing confirmed count', () async {
      const fullCategory = TournamentCategory(
        id: 'cat_full_test',
        name: 'Full Open Singles',
        entryFee: 1000.0,
        maxParticipants: 16,
        registeredCount: 16,
        isRegistrationOpen: true,
      );
      final customTourn = TournamentItem(
        id: 'tourn_full_test',
        name: 'Full Test Tournament',
        organizerName: 'Test Org',
        venueName: 'Test Venue',
        address: 'Test Address',
        city: 'Mumbai',
        description: 'Full test tournament description.',
        status: TournamentStatus.registrationOpen,
        startDate: DateTime.now().add(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 12)),
        registrationDeadline: DateTime.now().add(const Duration(days: 8)),
        prizePool: '₹10,000',
        entryFeeFrom: 1000.0,
        categories: const [fullCategory],
      );
      final customRepo = MockTournamentRepository(
        customTournaments: [customTourn],
        customRegistrations: [],
      );

      const payload = TournamentRegistrationPayload(
        tournamentId: 'tourn_full_test',
        categoryId: 'cat_full_test',
        playerName: 'Alex Rivera',
        playerPhone: '+91 98765 43210',
        playerEmail: 'alex@example.com',
        playerRating: 3.5,
        playerAge: 28,
        emergencyContactName: 'Elena Rivera',
        emergencyContactPhone: '+91 98765 00000',
        acceptedWaiver: true,
        acceptedRules: true,
        entryFee: 1000.0,
      );

      final result = await customRepo.registerForTournament(payload);
      expect(result, isA<Success<TournamentRegistration>>());
      final reg = (result as Success<TournamentRegistration>).data;
      expect(reg.status, equals(TournamentRegistrationStatus.waitlisted));
      expect(reg.isWaitlisted, isTrue);

      // Verify category registeredCount did NOT increase beyond 16!
      final tournResult = await customRepo.getTournamentById('tourn_full_test');
      final fetchedCategory = (tournResult as Success<TournamentItem>).data.categories.first;
      expect(fetchedCategory.registeredCount, equals(16));
    });

    test('withdrawFromTournament correctly updates capacity for confirmed vs waitlisted registrations', () async {
      const confirmedCategory = TournamentCategory(
        id: 'cat_conf',
        name: 'Confirmed Cat',
        entryFee: 1000.0,
        maxParticipants: 16,
        registeredCount: 10,
        isRegistrationOpen: true,
      );
      const waitlistedCategory = TournamentCategory(
        id: 'cat_wait',
        name: 'Waitlisted Cat',
        entryFee: 1000.0,
        maxParticipants: 16,
        registeredCount: 16,
        isRegistrationOpen: true,
      );
      final testTourn = TournamentItem(
        id: 'tourn_cap_test',
        name: 'Capacity Test Tournament',
        organizerName: 'Test Org',
        venueName: 'Test Venue',
        address: 'Test Address',
        city: 'Mumbai',
        description: 'Capacity test description.',
        status: TournamentStatus.registrationOpen,
        startDate: DateTime.now().add(const Duration(days: 10)),
        endDate: DateTime.now().add(const Duration(days: 12)),
        registrationDeadline: DateTime.now().add(const Duration(days: 8)),
        prizePool: '₹10,000',
        entryFeeFrom: 1000.0,
        categories: const [confirmedCategory, waitlistedCategory],
      );

      final confirmedReg = TournamentRegistration(
        id: 'reg_conf_001',
        tournamentId: 'tourn_cap_test',
        tournamentName: 'Capacity Test Tournament',
        categoryId: 'cat_conf',
        categoryName: 'Confirmed Cat',
        venueName: 'Test Venue',
        dates: 'Nov 2026',
        playerName: 'Alex Rivera',
        entryFee: 1000.0,
        status: TournamentRegistrationStatus.confirmed,
        registeredAt: DateTime.now(),
      );

      final waitlistedReg = TournamentRegistration(
        id: 'reg_wait_002',
        tournamentId: 'tourn_cap_test',
        tournamentName: 'Capacity Test Tournament',
        categoryId: 'cat_wait',
        categoryName: 'Waitlisted Cat',
        venueName: 'Test Venue',
        dates: 'Nov 2026',
        playerName: 'Alex Rivera',
        entryFee: 1000.0,
        status: TournamentRegistrationStatus.waitlisted,
        registeredAt: DateTime.now(),
      );

      final customRepo = MockTournamentRepository(
        customTournaments: [testTourn],
        customRegistrations: [confirmedReg, waitlistedReg],
      );

      // Withdraw confirmed
      final wConfResult = await customRepo.withdrawFromTournament('reg_conf_001');
      expect(wConfResult, isA<Success<TournamentRegistration>>());
      expect((wConfResult as Success<TournamentRegistration>).data.status, equals(TournamentRegistrationStatus.withdrawn));

      // Check category count decremented from 10 to 9
      final t1 = (await customRepo.getTournamentById('tourn_cap_test') as Success<TournamentItem>).data;
      expect(t1.categories.firstWhere((c) => c.id == 'cat_conf').registeredCount, equals(9));

      // Withdraw waitlisted
      final wWaitResult = await customRepo.withdrawFromTournament('reg_wait_002');
      expect(wWaitResult, isA<Success<TournamentRegistration>>());
      expect((wWaitResult as Success<TournamentRegistration>).data.status, equals(TournamentRegistrationStatus.withdrawn));

      // Check waitlisted category count stayed at 16 (did NOT decrement)
      final t2 = (await customRepo.getTournamentById('tourn_cap_test') as Success<TournamentItem>).data;
      expect(t2.categories.firstWhere((c) => c.id == 'cat_wait').registeredCount, equals(16));
    });
  });

  group('Tournament Discovery & Details Cubits Unit Tests', () {
    test('TournamentDiscoveryCubit loads tournaments successfully', () async {
      final repo = MockTournamentRepository();
      final cubit = TournamentDiscoveryCubit(repository: repo);

      await cubit.loadTournaments();

      expect(cubit.state, isA<TournamentDiscoveryLoaded>());
      final loaded = cubit.state as TournamentDiscoveryLoaded;
      expect(loaded.allTournaments.length, equals(5));
      expect(loaded.filteredTournaments.length, equals(5));
    });

    test('TournamentDiscoveryCubit updateSearchQuery filters locally without loading state', () async {
      final repo = MockTournamentRepository();
      final cubit = TournamentDiscoveryCubit(repository: repo);

      await cubit.loadTournaments();
      cubit.updateSearchQuery('Metro');

      final loaded = cubit.state as TournamentDiscoveryLoaded;
      expect(loaded.filteredTournaments.length, equals(1));
      expect(loaded.filteredTournaments.first.id, equals('tourn_004'));
    });

    test('TournamentDetailsCubit loads tournament and checks player registration', () async {
      final repo = MockTournamentRepository();
      final cubit = TournamentDetailsCubit(repository: repo, tournamentId: 'tourn_001');

      await cubit.loadTournament();

      expect(cubit.state, isA<TournamentDetailsLoaded>());
      final loaded = cubit.state as TournamentDetailsLoaded;
      expect(loaded.tournament.name, equals('National Pickleball Open 2026'));
      expect(loaded.playerRegistration, isNotNull);
    });

    test('TournamentRegistrationCubit validates required fields before submit', () async {
      final repo = MockTournamentRepository();
      final cubit = TournamentRegistrationCubit(repository: repo);

      final tournaments = MockTournamentRepository.createDefaultTournaments();
      final tournament = tournaments.firstWhere((t) => t.id == 'tourn_002');
      final doublesCategory = tournament.categories.firstWhere((c) => c.isDoubles);

      cubit.init(
        tournament: tournament,
        initialCategory: doublesCategory,
      );

      // Submit without partner, emergency contacts, and waiver
      final success = await cubit.submit();
      expect(success, isFalse);

      final ready = cubit.state as TournamentRegistrationReady;
      expect(ready.errors.containsKey('partnerName'), isTrue);
      expect(ready.errors.containsKey('emergencyContactName'), isTrue);
      expect(ready.errors.containsKey('emergencyContactPhone'), isTrue);
      expect(ready.errors.containsKey('waiver'), isTrue);
      expect(ready.errors.containsKey('rules'), isTrue);
    });

    test('TournamentRegistrationCubit.selectCategory rejects closed or ineligible category', () async {
      final repo = MockTournamentRepository();
      final cubit = TournamentRegistrationCubit(repository: repo);

      final tournaments = MockTournamentRepository.createDefaultTournaments();
      final tournament = tournaments.firstWhere((t) => t.id == 'tourn_002');
      final openCategory = tournament.categories.firstWhere((c) => c.id == 'cat_002_md');
      final seniorCategory = tournament.categories.firstWhere((c) => c.id == 'cat_002_sr'); // minAge 50
      final proClosed = tournament.categories.firstWhere((c) => c.id == 'cat_002_pro'); // closed

      cubit.init(
        tournament: tournament,
        initialCategory: openCategory,
        playerRating: 3.5,
        playerAge: 28,
      );

      // Try selecting senior category (ineligible age 28 < 50)
      cubit.selectCategory(seniorCategory);
      expect((cubit.state as TournamentRegistrationReady).selectedCategory.id, equals(openCategory.id));

      // Try selecting pro closed category
      cubit.selectCategory(proClosed);
      expect((cubit.state as TournamentRegistrationReady).selectedCategory.id, equals(openCategory.id));
    });

    test('TournamentRegistrationCubit validates emergency contact and passes actual payload values', () async {
      final repo = MockTournamentRepository();
      final cubit = TournamentRegistrationCubit(repository: repo);

      final tournaments = MockTournamentRepository.createDefaultTournaments();
      final tournament = tournaments.firstWhere((t) => t.id == 'tourn_002');
      final singlesCategory = tournament.categories.firstWhere((c) => !c.isDoubles && c.isRatingEligible(3.5));

      cubit.init(
        tournament: tournament,
        initialCategory: singlesCategory,
        playerRating: 3.5,
        playerAge: 28,
      );

      // Fill waivers
      cubit.toggleWaiver(true);
      cubit.toggleRules(true);

      // Submit without emergency contact
      final submitFail = await cubit.submit();
      expect(submitFail, isFalse);
      final readyState = cubit.state as TournamentRegistrationReady;
      expect(readyState.errors.containsKey('emergencyContactName'), isTrue);
      expect(readyState.errors.containsKey('emergencyContactPhone'), isTrue);

      // Update emergency contact with actual values
      cubit.updateEmergencyContactName('Maria Rivera');
      cubit.updateEmergencyContactPhone('+91 91234 56789');

      final submitSuccess = await cubit.submit();
      expect(submitSuccess, isTrue);
      expect(cubit.state, isA<TournamentRegistrationSuccess>());
    });
  });

  group('Tournament Discovery Page Widget Tests', () {
    testWidgets('renders tournament discovery page with search and cards', (tester) async {
      setTallViewport(tester);
      final repo = MockTournamentRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: TournamentDiscoveryPage(
            cubit: TournamentDiscoveryCubit(repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tournaments'), findsOneWidget);
      expect(find.text('Compete & Excel'), findsOneWidget);
      expect(find.byKey(const Key('tournament_search_input')), findsOneWidget);
      expect(find.text('National Pickleball Open 2026'), findsOneWidget);
      expect(find.text('Monsoon Community Cup 2026'), findsOneWidget);
      expect(find.text('Mumbai Metro Pickleball Championship 2026'), findsOneWidget);
    });

    testWidgets('typing in search bar filters tournaments dynamically', (tester) async {
      setTallViewport(tester);
      final repo = MockTournamentRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: TournamentDiscoveryPage(
            cubit: TournamentDiscoveryCubit(repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchInput = find.byKey(const Key('tournament_search_input'));
      await tester.enterText(searchInput, 'Monsoon');
      await tester.pumpAndSettle();

      expect(find.text('Monsoon Community Cup 2026'), findsOneWidget);
      expect(find.text('National Pickleball Open 2026'), findsNothing);
    });

    testWidgets('renders empty state when no tournaments match query', (tester) async {
      setTallViewport(tester);
      final repo = MockTournamentRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: TournamentDiscoveryPage(
            cubit: TournamentDiscoveryCubit(repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchInput = find.byKey(const Key('tournament_search_input'));
      await tester.enterText(searchInput, 'NonExistentTournamentXYZ');
      await tester.pumpAndSettle();

      expect(find.text('No Tournaments Found'), findsOneWidget);
      expect(find.byKey(const Key('tournament_reset_filters_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('tournament_reset_filters_button')));
      await tester.pumpAndSettle();

      expect(find.text('National Pickleball Open 2026'), findsOneWidget);
    });

    testWidgets('tapping filter button opens modal filter sheet', (tester) async {
      setTallViewport(tester);
      final repo = MockTournamentRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: TournamentDiscoveryPage(
            cubit: TournamentDiscoveryCubit(repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('tournament_filter_button')));
      await tester.pumpAndSettle();

      expect(find.text('Filter Tournaments'), findsOneWidget);
      expect(find.byKey(const Key('tournament_filter_apply_button')), findsOneWidget);
    });

    testWidgets('tapping tournament card navigates to tournament details', (tester) async {
      setTallViewport(tester);
      final repo = MockTournamentRepository();
      String? navigatedRoute;

      final router = GoRouter(
        initialLocation: AppRoutes.playerTournaments,
        routes: [
          GoRoute(
            path: AppRoutes.playerTournaments,
            builder: (_, _) => TournamentDiscoveryPage(
              cubit: TournamentDiscoveryCubit(repository: repo),
            ),
          ),
          GoRoute(
            path: AppRoutes.playerTournamentDetails,
            builder: (context, state) {
              navigatedRoute = state.uri.toString();
              return const Scaffold(body: Text('Tournament Details Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('tournament_card_tourn_002'));
      expect(card, findsOneWidget);

      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(navigatedRoute, equals('/player/tournaments/tourn_002'));
      expect(find.text('Tournament Details Screen'), findsOneWidget);
    });

    testWidgets('renders ErrorStateView on repository failure', (tester) async {
      setTallViewport(tester);
      final repo = MockTournamentRepository(shouldFail: true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: TournamentDiscoveryPage(
            cubit: TournamentDiscoveryCubit(repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to Load Tournaments'), findsOneWidget);
      expect(find.byType(ErrorStateView), findsOneWidget);
    });

    testWidgets('renders cleanly in dark theme and wide desktop viewport', (tester) async {
      setWideViewport(tester);
      final repo = MockTournamentRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: TournamentDiscoveryPage(
            cubit: TournamentDiscoveryCubit(repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tournaments'), findsOneWidget);
      expect(find.text('National Pickleball Open 2026'), findsOneWidget);
    });
  });

  group('Tournament Details Page Widget Tests', () {
    testWidgets('renders tournament details, hero banner, tabs, and register action', (tester) async {
      setTallViewport(tester);
      final repo = MockTournamentRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: TournamentDetailsPage(
            tournamentId: 'tourn_002',
            cubit: TournamentDetailsCubit(repository: repo, tournamentId: 'tourn_002'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tournament Details'), findsOneWidget);
      expect(find.text('Monsoon Community Cup 2026'), findsOneWidget);
      expect(find.textContaining('Pinnacle Sports Academy (Downtown)'), findsWidgets);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Rules'), findsOneWidget);
      expect(find.byKey(const Key('tournament_register_now_button')), findsOneWidget);
    });

    testWidgets('switching to Categories tab displays category cards', (tester) async {
      setTallViewport(tester);
      final repo = MockTournamentRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: TournamentDetailsPage(
            tournamentId: 'tourn_002',
            cubit: TournamentDetailsCubit(repository: repo, tournamentId: 'tourn_002'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();

      expect(find.text('Men\'s Singles 3.5'), findsOneWidget);
      expect(find.text('Mixed Doubles Open'), findsOneWidget);
      expect(find.text('Senior Doubles 50+'), findsOneWidget);
    });

    testWidgets('entered tournament displays Match Day or Withdraw options', (tester) async {
      setTallViewport(tester);
      final repo = MockTournamentRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: TournamentDetailsPage(
            tournamentId: 'tourn_001', // In Progress and entered
            cubit: TournamentDetailsCubit(repository: repo, tournamentId: 'tourn_001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('National Pickleball Open 2026'), findsOneWidget);
      expect(find.byKey(const Key('tournament_match_day_button')), findsOneWidget);
    });
  });

  group('Tournament Registration & Confirmation Widget Tests', () {
    testWidgets('renders registration form and validates required fields', (tester) async {
      setTallViewport(tester);
      final repo = MockTournamentRepository();
      final cubit = TournamentRegistrationCubit(repository: repo);

      final tournaments = MockTournamentRepository.createDefaultTournaments();
      final tournament = tournaments.firstWhere((t) => t.id == 'tourn_002');
      final doublesCat = tournament.categories.firstWhere((c) => c.isDoubles);

      cubit.init(
        tournament: tournament,
        initialCategory: doublesCat,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: TournamentRegistrationPage(
            tournamentId: 'tourn_002',
            initialCategoryId: doublesCat.id,
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tournament Registration'), findsOneWidget);
      expect(find.text('Monsoon Community Cup 2026'), findsOneWidget);
      expect(find.byKey(const Key('registration_partner_name_input')), findsOneWidget);
      expect(find.byKey(const Key('registration_emergency_name_input')), findsOneWidget);
      expect(find.byKey(const Key('registration_emergency_phone_input')), findsOneWidget);
      expect(find.byKey(const Key('registration_waiver_checkbox')), findsOneWidget);

      // Attempt to submit without filling required fields
      await tester.tap(find.byKey(const Key('tournament_confirm_registration_button')));
      await tester.pumpAndSettle();

      expect(find.text('Partner full name is required for doubles.'), findsOneWidget);
      expect(find.text('Emergency contact full name is required.'), findsOneWidget);
      expect(find.text('Emergency contact phone number is required.'), findsOneWidget);
      expect(find.text('You must accept the liability waiver.'), findsOneWidget);
    });

    testWidgets('disabled category selection in the registration UI prevents selection and shows feedback', (tester) async {
      setTallViewport(tester);
      final repo = MockTournamentRepository();
      final cubit = TournamentRegistrationCubit(repository: repo);

      final tournaments = MockTournamentRepository.createDefaultTournaments();
      final tournament = tournaments.firstWhere((t) => t.id == 'tourn_002');
      final openCat = tournament.categories.firstWhere((c) => c.id == 'cat_002_md');

      cubit.init(
        tournament: tournament,
        initialCategory: openCat,
        playerRating: 3.5,
        playerAge: 28,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: TournamentRegistrationPage(
            tournamentId: 'tourn_002',
            initialCategoryId: openCat.id,
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify category cards render with their keys
      expect(find.byKey(const Key('select_category_cat_002_sr')), findsOneWidget);
      expect(find.byKey(const Key('select_category_cat_002_pro')), findsOneWidget);

      // Tap ineligible Senior category (age 28 < 50)
      await tester.tap(find.byKey(const Key('select_category_cat_002_sr')));
      await tester.pumpAndSettle();

      // Feedback SnackBar appears
      expect(find.text('You do not meet the age requirements for Senior Doubles 50+.'), findsOneWidget);
      // Selected category has NOT changed
      expect((cubit.state as TournamentRegistrationReady).selectedCategory.id, equals('cat_002_md'));
    });

    testWidgets('completing required inputs and submitting navigates to confirmation', (tester) async {
      setTallViewport(tester);
      final repo = MockTournamentRepository();
      final cubit = TournamentRegistrationCubit(repository: repo);

      final tournaments = MockTournamentRepository.createDefaultTournaments();
      final tournament = tournaments.firstWhere((t) => t.id == 'tourn_002');
      final singlesCat = tournament.categories.firstWhere((c) => !c.isDoubles);

      cubit.init(
        tournament: tournament,
        initialCategory: singlesCat,
        playerRating: 3.5,
        playerAge: 28,
      );

      final router = GoRouter(
        initialLocation: AppRoutes.playerTournamentRegistrationPath('tourn_002'),
        routes: [
          GoRoute(
            path: AppRoutes.playerTournamentRegistration,
            builder: (_, _) => TournamentRegistrationPage(
              tournamentId: 'tourn_002',
              initialCategoryId: singlesCat.id,
              cubit: cubit,
            ),
          ),
          GoRoute(
            path: AppRoutes.playerTournamentConfirmation,
            builder: (context, state) {
              final reg = state.extra as TournamentRegistration?;
              return TournamentConfirmationPage(
                tournamentId: 'tourn_002',
                registration: reg,
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Fill required emergency contact inputs
      await tester.ensureVisible(find.byKey(const Key('registration_emergency_name_input')));
      await tester.enterText(
        find.byKey(const Key('registration_emergency_name_input')),
        'Elena Rivera',
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('registration_emergency_phone_input')));
      await tester.enterText(
        find.byKey(const Key('registration_emergency_phone_input')),
        '+91 98765 00000',
      );
      await tester.pumpAndSettle();

      // Check waivers
      await tester.ensureVisible(find.byKey(const Key('registration_waiver_checkbox')));
      await tester.tap(find.byKey(const Key('registration_waiver_checkbox')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('registration_rules_checkbox')));
      await tester.tap(find.byKey(const Key('registration_rules_checkbox')));
      await tester.pumpAndSettle();

      // Confirm registration
      await tester.tap(find.byKey(const Key('tournament_confirm_registration_button')));
      await tester.pumpAndSettle();

      // Should arrive on Confirmation screen
      expect(find.text('Registration Confirmed!'), findsOneWidget);
      expect(find.byKey(const Key('confirmation_match_day_button')), findsOneWidget);
      expect(find.byKey(const Key('confirmation_tournaments_button')), findsOneWidget);
    });

    testWidgets('confirmation page renders reference and copy button triggers SnackBar', (tester) async {
      setTallViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const TournamentConfirmationPage(
            tournamentId: 'tourn_002',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Registration Confirmed!'), findsOneWidget);
      expect(find.text('PKL-TRN-20261120-4821'), findsOneWidget);

      await tester.tap(find.byKey(const Key('copy_registration_reference_button')));
      await tester.pumpAndSettle();

      expect(find.text('Registration reference copied to clipboard!'), findsOneWidget);
    });
  });
}
