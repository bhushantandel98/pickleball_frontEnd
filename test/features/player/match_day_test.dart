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

    test('checkInToMatch marks match as checked in', () async {
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

    test('checkIn updates fixture state and sets feedbackMessage', () async {
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

    test('loadMatchDay emits MatchDayFailure on repository error', () async {
      final repo = MockMatchDayRepository(shouldFail: true);
      final cubit = MatchDayCubit(repository: repo);

      await cubit.loadMatchDay();

      expect(cubit.state, isA<MatchDayFailure>());
      final failure = cubit.state as MatchDayFailure;
      expect(failure.message, contains('Unable to load Match Day schedule'));
    });
  });

  group('MatchDayPage Widget Tests', () {
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

    testWidgets('renders empty state when player has no tournament matches', (tester) async {
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
