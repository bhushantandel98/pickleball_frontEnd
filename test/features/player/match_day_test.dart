import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_match_day_repository.dart';
import 'package:pickleball_platform/features/player/domain/entities/match_day_data.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/match_day_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/match_day_state.dart';
import 'package:pickleball_platform/features/player/presentation/pages/match_day_page.dart';

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
  group('MockMatchDayRepository Unit Tests', () {
    test('getMatchDayData returns default mock data with fixtures and courts', () async {
      final repo = MockMatchDayRepository();
      final result = await repo.getMatchDayData();

      expect(result, isA<Success<PlayerMatchDayData>>());
      final data = (result as Success<PlayerMatchDayData>).data;
      expect(data.tournamentName, equals('National Pickleball Open 2026'));
      expect(data.tournamentVenue, equals('Grand Slam Pickleball Arena'));
      expect(data.myMatches.length, equals(3));
      expect(data.courtMatches.length, equals(4));
      expect(data.standings.length, equals(6));
      expect(data.bracket.length, equals(7));
    });

    test('getMatchDayData returns empty data when isEmpty is true', () async {
      final repo = MockMatchDayRepository(isEmpty: true);
      final result = await repo.getMatchDayData();

      expect(result, isA<Success<PlayerMatchDayData>>());
      final data = (result as Success<PlayerMatchDayData>).data;
      expect(data.myMatches, isEmpty);
      expect(data.courtMatches, isEmpty);
    });

    test('getMatchDayData returns ServerFailure when shouldFail is true', () async {
      final repo = MockMatchDayRepository(shouldFail: true);
      final result = await repo.getMatchDayData();

      expect(result, isA<FailureResult<PlayerMatchDayData>>());
      final failure = (result as FailureResult<PlayerMatchDayData>).failure;
      expect(failure, isA<ServerFailure>());
    });

    // 1. Successful check-in before the deadline
    test('checkInToMatch succeeds before the deadline for eligible scheduled match', () async {
      final repo = MockMatchDayRepository();
      final result = await repo.checkInToMatch('match_sched_002');

      expect(result, isA<Success<PlayerMatch>>());
      final match = (result as Success<PlayerMatch>).data;
      expect(match.isCheckedIn, isTrue);

      // Verify in repository data
      final dataResult = await repo.getMatchDayData();
      final updatedMatch = (dataResult as Success<PlayerMatchDayData>)
          .data
          .myMatches
          .firstWhere((m) => m.id == 'match_sched_002');
      expect(updatedMatch.isCheckedIn, isTrue);
    });

    // 2. Rejected check-in after the deadline
    test('checkInToMatch rejects check-in when deadline has expired', () async {
      final repo = MockMatchDayRepository();
      final expiredTime = DateTime.now().add(const Duration(hours: 12));
      final result = await repo.checkInToMatch('match_sched_002', currentTime: expiredTime);

      expect(result, isA<FailureResult<PlayerMatch>>());
      final failure = (result as FailureResult<PlayerMatch>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, equals('Check-in deadline has expired for this match.'));
    });

    // 3. Rejected check-in for an ineligible match
    test('checkInToMatch rejects check-in for completed or live match', () async {
      final repo = MockMatchDayRepository();

      // Test with completed match fixture
      final compResult = await repo.checkInToMatch('match_comp_003');
      expect(compResult, isA<FailureResult<PlayerMatch>>());
      final failure = (compResult as FailureResult<PlayerMatch>).failure;
      expect(failure, isA<ValidationFailure>());
    });

    // 4. Duplicate check-in prevention
    test('checkInToMatch rejects duplicate check-in', () async {
      final repo = MockMatchDayRepository();

      // First check-in succeeds
      final first = await repo.checkInToMatch('match_sched_002');
      expect(first, isA<Success<PlayerMatch>>());

      // Second check-in must be rejected
      final second = await repo.checkInToMatch('match_sched_002');
      expect(second, isA<FailureResult<PlayerMatch>>());
      final failure = (second as FailureResult<PlayerMatch>).failure;
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, equals('Player is already checked in for this match.'));
    });

    test('checkInToMatch returns NotFoundFailure when match does not exist', () async {
      final repo = MockMatchDayRepository();
      final result = await repo.checkInToMatch('unknown_match_id');

      expect(result, isA<FailureResult<PlayerMatch>>());
      final failure = (result as FailureResult<PlayerMatch>).failure;
      expect(failure, isA<NotFoundFailure>());
    });
  });

  group('MatchDayCubit Unit Tests', () {
    test('initial state is MatchDayInitial', () {
      final cubit = MatchDayCubit(repository: MockMatchDayRepository());
      expect(cubit.state, isA<MatchDayInitial>());
    });

    test('loadMatchDay emits [MatchDayLoading, MatchDayLoaded]', () async {
      final repo = MockMatchDayRepository();
      final cubit = MatchDayCubit(repository: repo);

      await cubit.loadMatchDay();

      expect(cubit.state, isA<MatchDayLoaded>());
      final loaded = cubit.state as MatchDayLoaded;
      expect(loaded.data.tournamentName, equals('National Pickleball Open 2026'));
      expect(loaded.activeTab, equals(MatchDayTab.mySchedule));
    });

    test('setTab updates activeTab', () async {
      final repo = MockMatchDayRepository();
      final cubit = MatchDayCubit(repository: repo);

      await cubit.loadMatchDay();
      cubit.setTab(MatchDayTab.liveScores);

      final loaded = cubit.state as MatchDayLoaded;
      expect(loaded.activeTab, equals(MatchDayTab.liveScores));
    });

    test('checkIn updates fixture state and sets feedbackMessage on success', () async {
      final repo = MockMatchDayRepository();
      final cubit = MatchDayCubit(repository: repo);

      await cubit.loadMatchDay();
      final success = await cubit.checkIn('match_sched_002');

      expect(success, isTrue);
      final loaded = cubit.state as MatchDayLoaded;
      final match = loaded.data.myMatches.firstWhere((m) => m.id == 'match_sched_002');
      expect(match.isCheckedIn, isTrue);
      expect(loaded.feedbackMessage, contains('Checked in successfully'));
    });

    test('checkIn provides clear feedback when rejected due to expired deadline', () async {
      final repo = MockMatchDayRepository();
      final cubit = MatchDayCubit(repository: repo);

      await cubit.loadMatchDay();
      final expiredTime = DateTime.now().add(const Duration(hours: 12));
      final success = await cubit.checkIn('match_sched_002', currentTime: expiredTime);

      expect(success, isFalse);
      final loaded = cubit.state as MatchDayLoaded;
      expect(loaded.feedbackMessage, equals('Check-in deadline has expired for this match.'));
    });

    test('checkIn provides clear feedback when rejected due to duplicate check-in', () async {
      final repo = MockMatchDayRepository();
      final cubit = MatchDayCubit(repository: repo);

      await cubit.loadMatchDay();
      await cubit.checkIn('match_sched_002');
      final secondTry = await cubit.checkIn('match_sched_002');

      expect(secondTry, isFalse);
      final loaded = cubit.state as MatchDayLoaded;
      expect(loaded.feedbackMessage, equals('Player is already checked in for this match.'));
    });

    test('loadMatchDay emits MatchDayFailure on repository error', () async {
      final repo = MockMatchDayRepository(shouldFail: true);
      final cubit = MatchDayCubit(repository: repo);

      await cubit.loadMatchDay();

      expect(cubit.state, isA<MatchDayFailure>());
      final failure = cubit.state as MatchDayFailure;
      expect(failure.message, contains('Unable to load Match Day schedule'));
    });

    // 5. Empty-state logic test: personal matches empty, but court data exists
    test('MatchDayLoaded.isEmpty evaluates to true when myMatches is empty even if court data exists', () {
      final data = PlayerMatchDayData(
        tournamentId: 't1',
        tournamentName: 'Test Open',
        tournamentVenue: 'Test Arena',
        date: DateTime.now(),
        myMatches: const [],
        courtMatches: const [
          CourtLiveMatch(courtId: 'c1', courtName: 'Court 1', tournamentName: 'Test', category: 'Open'),
        ],
        standings: const [
          StandingsRow(rank: 1, playerName: 'P1', pool: 'Pool A', matchesPlayed: 1, matchesWon: 1, matchesLost: 0, pointDifferential: 5),
        ],
        bracket: const [],
      );

      final state = MatchDayLoaded(data: data);
      expect(state.isEmpty, isTrue);
    });
  });

  group('MatchDayPage Widget Tests', () {
    // 6. Normal Match Day rendering remains functional
    testWidgets('renders tournament header, tabs, and my schedule fixtures', (tester) async {
      setTallViewport(tester);
      final repo = MockMatchDayRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MatchDayPage(cubit: MatchDayCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      // Heading & Header Card
      expect(find.text('Match Day Hub'), findsOneWidget);
      expect(find.text('National Pickleball Open 2026'), findsOneWidget);
      expect(find.text('Grand Slam Pickleball Arena'), findsOneWidget);

      // Tab selector labels
      expect(find.text('My Schedule'), findsOneWidget);
      expect(find.text('Live Courts'), findsOneWidget);
      expect(find.text('Bracket & Pools'), findsOneWidget);

      // Section title
      expect(find.text('My Matches Today'), findsOneWidget);

      // Player fixtures
      expect(find.text('Alex Rivera'), findsWidgets);
      expect(find.text('Jordan Cruz'), findsWidgets);
      expect(find.text('Court 1 (Championship Court)'), findsWidgets);
      expect(find.text('LIVE'), findsWidgets);
    });

    testWidgets('tapping check in button checks player in and displays SnackBar', (tester) async {
      setTallViewport(tester);
      final repo = MockMatchDayRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MatchDayPage(cubit: MatchDayCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      // Check In button for scheduled match
      final checkInBtn = find.byKey(const Key('check_in_button_match_sched_002'));
      expect(checkInBtn, findsOneWidget);

      await tester.tap(checkInBtn);
      await tester.pumpAndSettle();

      // Should now show Checked In chip and SnackBar
      expect(find.text('Checked in successfully for Quarter-Final!'), findsOneWidget);
      expect(checkInBtn, findsNothing);
      expect(find.text('Checked In'), findsWidgets);
    });

    testWidgets('UI does not offer check-in button when check-in deadline has expired', (tester) async {
      setTallViewport(tester);
      final now = DateTime.now();

      // Custom mock match with expired check-in deadline
      final expiredMatch = PlayerMatch(
        id: 'match_expired_001',
        tournamentId: 'tourn_001',
        tournamentName: 'National Pickleball Open 2026',
        category: 'Mixed Doubles 3.5',
        round: 'Round 1',
        courtName: 'Court 4',
        scheduledTime: now.add(const Duration(hours: 1)),
        status: MatchStatus.scheduled,
        player1Name: 'Alex Rivera',
        player2Name: 'Mark Lee',
        checkInDeadline: now.subtract(const Duration(minutes: 10)),
      );

      final customData = PlayerMatchDayData(
        tournamentId: 'tourn_001',
        tournamentName: 'National Pickleball Open 2026',
        tournamentVenue: 'Grand Slam Pickleball Arena',
        date: now,
        myMatches: [expiredMatch],
        courtMatches: const [],
        standings: const [],
        bracket: const [],
      );

      final repo = MockMatchDayRepository(customData: customData);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MatchDayPage(cubit: MatchDayCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      // Check In button must NOT be offered
      expect(find.byKey(const Key('check_in_button_match_expired_001')), findsNothing);
      // "Check-in Closed" badge must be displayed
      expect(find.text('Check-in Closed'), findsOneWidget);
    });

    testWidgets('UI does not offer check-in button for completed or live match', (tester) async {
      setTallViewport(tester);
      final repo = MockMatchDayRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MatchDayPage(cubit: MatchDayCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      // Completed match and live match must not show check-in buttons
      expect(find.byKey(const Key('check_in_button_match_live_001')), findsNothing);
      expect(find.byKey(const Key('check_in_button_match_comp_003')), findsNothing);
    });

    testWidgets('switching to Live Courts tab displays active court tracker', (tester) async {
      setTallViewport(tester);
      final repo = MockMatchDayRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MatchDayPage(cubit: MatchDayCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Live Courts' tab
      await tester.tap(find.byKey(const Key('match_day_tab_liveScores')));
      await tester.pumpAndSettle();

      expect(find.text('Active Courts & Live Progress'), findsOneWidget);
      expect(find.text('Court 1 (Championship Court)'), findsOneWidget);
      expect(find.text('Court 2'), findsOneWidget);
      expect(find.text('Court 3'), findsOneWidget);
      expect(find.text('Court 4'), findsOneWidget);
    });

    testWidgets('switching to Bracket & Pools tab displays standings and elimination bracket', (tester) async {
      setTallViewport(tester);
      final repo = MockMatchDayRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MatchDayPage(cubit: MatchDayCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Bracket & Pools' tab
      await tester.tap(find.byKey(const Key('match_day_tab_bracketStandings')));
      await tester.pumpAndSettle();

      expect(find.text('Pool Standings & Qualifications'), findsOneWidget);
      expect(find.text('Elimination Bracket'), findsOneWidget);

      // Standings table columns
      expect(find.text('Player'), findsOneWidget);
      expect(find.text('Diff'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);

      // Bracket rounds
      expect(find.text('Quarter-Finals'), findsOneWidget);
    });

    // 5. Empty state when personal matches are empty but court data exists
    testWidgets('renders empty state when personal matches are empty but court data exists', (tester) async {
      setTallViewport(tester);
      final now = DateTime.now();

      final dataWithCourtsOnly = PlayerMatchDayData(
        tournamentId: 'tourn_001',
        tournamentName: 'National Pickleball Open 2026',
        tournamentVenue: 'Grand Slam Pickleball Arena',
        date: now,
        myMatches: const [], // Player has NO personal matches today
        courtMatches: [
          CourtLiveMatch(
            courtId: 'court_1',
            courtName: 'Court 1 (Championship Court)',
            tournamentName: 'National Pickleball Open 2026',
            category: 'Men\'s Singles Open',
            currentMatch: PlayerMatch(
              id: 'm1',
              tournamentId: 't1',
              tournamentName: 'Tourn',
              category: 'Cat',
              round: 'R1',
              courtName: 'C1',
              scheduledTime: now,
              player1Name: 'Player A',
              player2Name: 'Player B',
            ),
          ),
        ],
        standings: const [
          StandingsRow(
            rank: 1,
            playerName: 'Player A',
            pool: 'Pool A',
            matchesPlayed: 2,
            matchesWon: 2,
            matchesLost: 0,
            pointDifferential: 10,
          ),
        ],
        bracket: const [
          BracketNode(
            id: 'b1',
            roundName: 'Finals',
            matchIndex: 1,
            player1: 'Player A',
            player2: 'Player B',
          ),
        ],
      );

      final repo = MockMatchDayRepository(customData: dataWithCourtsOnly);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MatchDayPage(cubit: MatchDayCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      // Must display personal match empty state
      expect(find.text('No Tournament Matches Today'), findsOneWidget);
      expect(find.byKey(const Key('match_day_empty_explore_button')), findsOneWidget);
    });

    testWidgets('renders empty state when player has no tournament matches (isEmpty harness)', (tester) async {
      setTallViewport(tester);
      final repo = MockMatchDayRepository(isEmpty: true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MatchDayPage(cubit: MatchDayCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Tournament Matches Today'), findsOneWidget);
      expect(find.byKey(const Key('match_day_empty_explore_button')), findsOneWidget);
    });

    testWidgets('tapping explore tournaments navigates to tournament discovery', (tester) async {
      setTallViewport(tester);
      final repo = MockMatchDayRepository(isEmpty: true);
      String? navigatedRoute;

      final router = GoRouter(
        initialLocation: AppRoutes.playerMatchDay,
        routes: [
          GoRoute(
            path: AppRoutes.playerMatchDay,
            builder: (_, _) => MatchDayPage(cubit: MatchDayCubit(repository: repo)),
          ),
          GoRoute(
            path: AppRoutes.playerTournaments,
            builder: (context, state) {
              navigatedRoute = state.uri.toString();
              return const Scaffold(body: Text('Tournaments Destination'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final exploreBtn = find.byKey(const Key('match_day_empty_explore_button'));
      expect(exploreBtn, findsOneWidget);

      await tester.tap(exploreBtn);
      await tester.pumpAndSettle();

      expect(navigatedRoute, equals(AppRoutes.playerTournaments));
      expect(find.text('Tournaments Destination'), findsOneWidget);
    });

    testWidgets('renders ErrorStateView when repository fails', (tester) async {
      setTallViewport(tester);
      final repo = MockMatchDayRepository(shouldFail: true);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MatchDayPage(cubit: MatchDayCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Match Day Unavailable'), findsOneWidget);
      expect(find.byType(ErrorStateView), findsOneWidget);
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      setTallViewport(tester);
      final repo = MockMatchDayRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MatchDayPage(cubit: MatchDayCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Match Day Hub'), findsOneWidget);
      expect(find.text('National Pickleball Open 2026'), findsOneWidget);
    });

    testWidgets('renders cleanly on wide desktop viewport', (tester) async {
      setWideViewport(tester);
      final repo = MockMatchDayRepository();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MatchDayPage(cubit: MatchDayCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Match Day Hub'), findsOneWidget);
      expect(find.text('National Pickleball Open 2026'), findsOneWidget);
    });
  });
}
