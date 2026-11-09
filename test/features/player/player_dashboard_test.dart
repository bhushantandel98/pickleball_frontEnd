import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_player_dashboard_repository.dart';
import 'package:pickleball_platform/features/player/domain/entities/player_dashboard_data.dart';
import 'package:pickleball_platform/features/player/domain/repositories/player_dashboard_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/player_dashboard_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/player_dashboard_state.dart';
import 'package:pickleball_platform/features/player/presentation/pages/player_dashboard_page.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/player_header_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/player_quick_actions.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/player_stats_grid.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/recent_activity_section.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/upcoming_activities_section.dart';

class _FailingPlayerDashboardRepository implements PlayerDashboardRepository {
  final Failure failure;
  const _FailingPlayerDashboardRepository(this.failure);

  @override
  Future<Result<PlayerDashboardData>> getDashboardData({String? userId}) async {
    return FailureResult(failure);
  }
}

Widget _buildTestFrame({
  required Widget child,
  ThemeMode mode = ThemeMode.light,
  Size size = const Size(800, 1600),
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: mode,
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleProfile = PlayerProfileSummary(
    userId: 'user_player_001',
    fullName: 'Alex Rivera',
    avatarUrl: 'avatar:champion',
    skillRating: 3.85,
    ratingTier: 'Intermediate 3.5+',
    location: 'Mumbai, MH',
    playStyle: 'Right-handed • Mixed Doubles',
    memberSince: DateTime(2025, 3, 15),
  );

  const sampleStats = PlayerStats(
    matchesPlayed: 24,
    winRatePercentage: 68.0,
    upcomingBookingsCount: 2,
    tournamentsEnteredCount: 1,
    skillRating: 3.85,
  );

  final sampleUpcoming = [
    UpcomingActivity(
      id: 'up_001',
      title: 'Court Reservation',
      type: UpcomingActivityType.courtBooking,
      venueOrLocation: 'Grand Slam Pickleball Arena',
      courtName: 'Court 1',
      dateTime: DateTime.now().add(const Duration(days: 1)),
      timeSlot: '07:00 AM - 08:00 AM',
      status: ActivityStatus.confirmed,
      statusLabel: 'Confirmed',
      actionRoute: AppRoutes.playerBookings,
    ),
  ];

  final sampleRecent = [
    RecentActivityItem(
      id: 'rec_001',
      title: 'Quarter-final Match Won',
      description: 'Won against David Miller 11-7, 11-5.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      category: RecentActivityCategory.match,
      resultBadge: 'Won 2-0',
      actionRoute: AppRoutes.playerTournaments,
    ),
  ];

  final sampleDashboardData = PlayerDashboardData(
    profile: sampleProfile,
    stats: sampleStats,
    upcomingActivities: sampleUpcoming,
    recentActivities: sampleRecent,
    unreadNotificationsCount: 2,
  );

  group('Player Dashboard Entities Unit Tests', () {
    test('PlayerDashboardData supports copyWith and props equality', () {
      final updated = sampleDashboardData.copyWith(unreadNotificationsCount: 5);
      expect(updated.unreadNotificationsCount, 5);
      expect(updated.profile.fullName, 'Alex Rivera');
      expect(sampleDashboardData == updated, isFalse);
    });

    test('UpcomingActivity copyWith preserves unchanged attributes', () {
      final activity = sampleUpcoming.first;
      final copy = activity.copyWith(status: ActivityStatus.pending);
      expect(copy.id, activity.id);
      expect(copy.status, ActivityStatus.pending);
      expect(copy.courtName, 'Court 1');
    });

    test('PlayerStats equality and calculation verification', () {
      const statsA = PlayerStats(
        matchesPlayed: 10,
        winRatePercentage: 60.0,
        upcomingBookingsCount: 1,
        tournamentsEnteredCount: 1,
        skillRating: 3.5,
      );
      const statsB = PlayerStats(
        matchesPlayed: 10,
        winRatePercentage: 60.0,
        upcomingBookingsCount: 1,
        tournamentsEnteredCount: 1,
        skillRating: 3.5,
      );
      expect(statsA, equals(statsB));
    });
  });

  group('PlayerDashboardCubit Unit Tests', () {
    test('initial state is PlayerDashboardInitial', () {
      final cubit = PlayerDashboardCubit(
        repository: const MockPlayerDashboardRepository(),
      );
      expect(cubit.state, const PlayerDashboardInitial());
      cubit.close();
    });

    test('loadDashboard emits [Loading, Loaded] with valid data', () async {
      final cubit = PlayerDashboardCubit(
        repository: const MockPlayerDashboardRepository(),
      );

      expectLater(
        cubit.stream,
        emitsInOrder([
          const PlayerDashboardLoading(),
          isA<PlayerDashboardLoaded>(),
        ]),
      );

      await cubit.loadDashboard();
      expect(cubit.state, isA<PlayerDashboardLoaded>());

      final loaded = cubit.state as PlayerDashboardLoaded;
      expect(loaded.data.profile.fullName, 'Alex Rivera');
      expect(loaded.data.stats.matchesPlayed, 24);
      expect(loaded.data.upcomingActivities.isNotEmpty, isTrue);

      await cubit.close();
    });

    test('loadDashboard emits [Loading, Failure] when repository fails', () async {
      const failure = ServerFailure(message: 'Backend unavailable');
      final cubit = PlayerDashboardCubit(
        repository: const _FailingPlayerDashboardRepository(failure),
      );

      expectLater(
        cubit.stream,
        emitsInOrder([
          const PlayerDashboardLoading(),
          const PlayerDashboardFailure(failure),
        ]),
      );

      await cubit.loadDashboard();
      expect(cubit.state, const PlayerDashboardFailure(failure));

      await cubit.close();
    });

    test('refreshDashboard preserves state on successful refresh', () async {
      final cubit = PlayerDashboardCubit(
        repository: const MockPlayerDashboardRepository(),
      );

      await cubit.loadDashboard();
      expect(cubit.state, isA<PlayerDashboardLoaded>());

      await cubit.refreshDashboard();
      expect(cubit.state, isA<PlayerDashboardLoaded>());

      await cubit.close();
    });
  });

  group('PlayerDashboardPage Widget Tests', () {
    testWidgets('renders loading state initially', (tester) async {
      final cubit = PlayerDashboardCubit(
        repository: const MockPlayerDashboardRepository(),
      );

      await tester.pumpWidget(
        _buildTestFrame(
          child: PlayerDashboardPage(cubit: cubit),
        ),
      );

      expect(find.byType(LoadingView), findsOneWidget);
      expect(find.text('Loading player dashboard...'), findsOneWidget);

      await tester.pumpAndSettle();
      await cubit.close();
    });

    testWidgets('renders full player dashboard with sections when loaded', (tester) async {
      final cubit = PlayerDashboardCubit(
        repository: MockPlayerDashboardRepository(customData: sampleDashboardData),
      );

      await tester.pumpWidget(
        _buildTestFrame(
          child: PlayerDashboardPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Header verification
      expect(find.byType(PlayerHeaderCard), findsOneWidget);
      expect(find.text('Welcome back, Alex!'), findsOneWidget);
      expect(find.text('Alex Rivera'), findsOneWidget);
      expect(find.text('3.85 DUPR'), findsOneWidget);
      expect(find.text('Intermediate 3.5+'), findsOneWidget);

      // Quick actions verification
      expect(find.byType(PlayerQuickActions), findsOneWidget);
      expect(find.text('Book a Court'), findsOneWidget);
      expect(find.text('Find Coaches'), findsOneWidget);
      expect(find.text('Tournaments'), findsWidgets);
      expect(find.text('Match Day'), findsOneWidget);
      expect(find.text('Shop Gear'), findsOneWidget);
      expect(find.text('My Bookings'), findsOneWidget);

      // Stats grid verification
      expect(find.byType(PlayerStatsGrid), findsOneWidget);
      expect(find.text('Activity & Stats'), findsOneWidget);
      expect(find.text('24'), findsOneWidget);
      expect(find.text('68%'), findsOneWidget);

      // Upcoming schedule verification
      expect(find.byType(UpcomingActivitiesSection), findsOneWidget);
      expect(find.text('Upcoming Schedule'), findsOneWidget);
      expect(find.text('Court Reservation'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);

      // Recent activity verification
      expect(find.byType(RecentActivitySection), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Quarter-final Match Won'), findsOneWidget);
      expect(find.text('Won 2-0'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders empty state for upcoming schedule when list is empty', (tester) async {
      final cubit = PlayerDashboardCubit(
        repository: MockPlayerDashboardRepository(
          customData: sampleDashboardData.copyWith(upcomingActivities: []),
        ),
      );

      await tester.pumpWidget(
        _buildTestFrame(
          child: PlayerDashboardPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No upcoming activities scheduled'), findsOneWidget);
      expect(find.text('Book a Court'), findsWidgets);
      expect(find.text('Find Tournaments'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders error view with retry action on repository failure', (tester) async {
      const failure = NetworkFailure(message: 'Network connection timed out');
      final cubit = PlayerDashboardCubit(
        repository: const _FailingPlayerDashboardRepository(failure),
      );

      await tester.pumpWidget(
        _buildTestFrame(
          child: PlayerDashboardPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Failed to Load Dashboard'), findsOneWidget);
      expect(find.text('Network connection timed out'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('quick actions and header buttons navigate to expected routes', (tester) async {
      String? lastPushedRoute;

      final cubit = PlayerDashboardCubit(
        repository: MockPlayerDashboardRepository(customData: sampleDashboardData),
      );
      await cubit.loadDashboard();

      final router = GoRouter(
        initialLocation: AppRoutes.playerDashboard,
        routes: [
          GoRoute(
            path: AppRoutes.playerDashboard,
            builder: (context, state) => PlayerDashboardPage(cubit: cubit),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) {
              lastPushedRoute = AppRoutes.profile;
              return const Scaffold(body: Text('Profile Screen'));
            },
          ),
          GoRoute(
            path: AppRoutes.playerVenues,
            builder: (context, state) {
              lastPushedRoute = AppRoutes.playerVenues;
              return const Scaffold(body: Text('Venues Screen'));
            },
          ),
          GoRoute(
            path: AppRoutes.playerBookings,
            builder: (context, state) {
              lastPushedRoute = AppRoutes.playerBookings;
              return const Scaffold(body: Text('Bookings Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // Tap "My Profile" button in header
      final myProfileBtn = find.text('My Profile');
      expect(myProfileBtn, findsOneWidget);
      await tester.tap(myProfileBtn);
      await tester.pumpAndSettle();
      expect(lastPushedRoute, AppRoutes.profile);

      // Return to dashboard
      router.pop();
      await tester.pumpAndSettle();

      // Tap "Book a Court" quick action
      final bookCourtBtn = find.text('Book a Court');
      expect(bookCourtBtn, findsOneWidget);
      await tester.tap(bookCourtBtn);
      await tester.pumpAndSettle();
      expect(lastPushedRoute, AppRoutes.playerVenues);

      await cubit.close();
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      final cubit = PlayerDashboardCubit(
        repository: MockPlayerDashboardRepository(customData: sampleDashboardData),
      );

      await tester.pumpWidget(
        _buildTestFrame(
          mode: ThemeMode.dark,
          child: PlayerDashboardPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlayerHeaderCard), findsOneWidget);
      expect(find.text('Welcome back, Alex!'), findsOneWidget);
      expect(find.text('3.85 DUPR'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders responsive wide layout on desktop/tablet viewports', (tester) async {
      final cubit = PlayerDashboardCubit(
        repository: MockPlayerDashboardRepository(customData: sampleDashboardData),
      );

      // Desktop viewport size 1200x900
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestFrame(
          size: const Size(1200, 900),
          child: PlayerDashboardPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlayerHeaderCard), findsOneWidget);
      expect(find.byType(PlayerQuickActions), findsOneWidget);
      expect(find.byType(UpcomingActivitiesSection), findsOneWidget);
      expect(find.byType(PlayerStatsGrid), findsOneWidget);
      expect(find.byType(RecentActivitySection), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders empty state for recent activities when list is empty', (tester) async {
      final cubit = PlayerDashboardCubit(
        repository: MockPlayerDashboardRepository(
          customData: sampleDashboardData.copyWith(recentActivities: []),
        ),
      );

      await tester.pumpWidget(
        _buildTestFrame(
          child: PlayerDashboardPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No recent activity recorded yet.'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('tapping upcoming activity navigates to its action route', (tester) async {
      String? destination;

      final cubit = PlayerDashboardCubit(
        repository: MockPlayerDashboardRepository(customData: sampleDashboardData),
      );
      await cubit.loadDashboard();

      final router = GoRouter(
        initialLocation: AppRoutes.playerDashboard,
        routes: [
          GoRoute(
            path: AppRoutes.playerDashboard,
            builder: (context, state) => PlayerDashboardPage(cubit: cubit),
          ),
          GoRoute(
            path: AppRoutes.playerBookings,
            builder: (context, state) {
              destination = AppRoutes.playerBookings;
              return const Scaffold(body: Text('My Bookings Page'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      final activityTile = find.text('Court Reservation');
      expect(activityTile, findsOneWidget);
      await tester.tap(activityTile);
      await tester.pumpAndSettle();

      expect(destination, AppRoutes.playerBookings);
      await cubit.close();
    });

    testWidgets('displays upcoming activities in ascending chronological order by dateTime', (tester) async {
      final activityLater = UpcomingActivity(
        id: 'up_late',
        title: 'Later Activity (Day 3)',
        type: UpcomingActivityType.coachingSession,
        venueOrLocation: 'Academy',
        dateTime: DateTime(2026, 11, 9, 10, 0),
        timeSlot: 'Nov 9 • 10:00 AM',
        status: ActivityStatus.confirmed,
        statusLabel: 'Enrolled',
      );

      final activityEarliest = UpcomingActivity(
        id: 'up_early',
        title: 'Earliest Activity (Day 1)',
        type: UpcomingActivityType.tournamentMatch,
        venueOrLocation: 'Championship Court',
        dateTime: DateTime(2026, 11, 7, 8, 0),
        timeSlot: 'Nov 7 • 08:00 AM',
        status: ActivityStatus.scheduled,
        statusLabel: 'Scheduled',
      );

      final activityMiddle = UpcomingActivity(
        id: 'up_mid',
        title: 'Middle Activity (Day 2)',
        type: UpcomingActivityType.courtBooking,
        venueOrLocation: 'Arena Court 2',
        dateTime: DateTime(2026, 11, 8, 14, 0),
        timeSlot: 'Nov 8 • 02:00 PM',
        status: ActivityStatus.confirmed,
        statusLabel: 'Confirmed',
      );

      // Pass activities in reverse / unordered order: [Later, Earliest, Middle]
      final testData = sampleDashboardData.copyWith(
        upcomingActivities: [activityLater, activityEarliest, activityMiddle],
      );

      final cubit = PlayerDashboardCubit(
        repository: MockPlayerDashboardRepository(customData: testData),
      );

      await tester.pumpWidget(
        _buildTestFrame(
          child: PlayerDashboardPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      final earlyPosition = tester.getTopLeft(find.text('Earliest Activity (Day 1)')).dy;
      final midPosition = tester.getTopLeft(find.text('Middle Activity (Day 2)')).dy;
      final latePosition = tester.getTopLeft(find.text('Later Activity (Day 3)')).dy;

      // Earlier dates/times must appear above later dates/times
      expect(earlyPosition, lessThan(midPosition));
      expect(midPosition, lessThan(latePosition));

      await cubit.close();
    });
  });
}
