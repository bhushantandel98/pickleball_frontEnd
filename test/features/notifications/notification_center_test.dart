import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/access/session_context.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:pickleball_platform/features/notifications/domain/entities/notification_item.dart';
import 'package:pickleball_platform/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:pickleball_platform/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:pickleball_platform/features/notifications/presentation/pages/notification_center_page.dart';
import 'package:pickleball_platform/features/notifications/presentation/widgets/notification_category_chips.dart';
import 'package:pickleball_platform/features/notifications/presentation/widgets/notification_tile.dart';

Widget _buildTestFrame({
  required Widget child,
  ThemeMode mode = ThemeMode.light,
  SessionCubit? sessionCubit,
}) {
  Widget app = MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: mode,
    home: child,
  );

  if (sessionCubit != null) {
    return BlocProvider<SessionCubit>.value(
      value: sessionCubit,
      child: app,
    );
  }

  return app;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleNotification = NotificationItem(
    id: 'n_test_1',
    title: 'Court Booking Confirmed',
    description: 'Your slot is confirmed for tomorrow.',
    category: NotificationCategory.bookings,
    timestamp: DateTime(2026, 11, 6, 10, 30),
    isRead: false,
    destinationRoute: '/player/bookings',
    relatedEntityId: 'bk_123',
    organizationName: 'Apex Arena',
    roleContext: UserRole.player,
  );

  group('NotificationItem Entity Unit Tests', () {
    test('instantiates and supports copyWith correctly', () {
      expect(sampleNotification.isRead, isFalse);

      final updated = sampleNotification.copyWith(isRead: true);
      expect(updated.isRead, isTrue);
      expect(updated.id, equals('n_test_1'));
      expect(updated.title, equals('Court Booking Confirmed'));
    });

    test('toMap and fromMap serialize and deserialize cleanly', () {
      final map = sampleNotification.toMap();
      final reconstituted = NotificationItem.fromMap(map);

      expect(reconstituted, equals(sampleNotification));
    });
  });

  group('NotificationsCubit Unit Tests', () {
    late MockNotificationRepository repository;
    late NotificationsCubit cubit;

    setUp(() {
      repository = MockNotificationRepository();
      cubit = NotificationsCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is NotificationsInitial', () {
      expect(cubit.state, isA<NotificationsInitial>());
    });

    test('loadNotifications emits [Loading, Loaded] with sorted notifications', () async {
      await cubit.loadNotifications(userId: 'u_1');

      expect(cubit.state, isA<NotificationsLoaded>());
      final loaded = cubit.state as NotificationsLoaded;
      expect(loaded.allNotifications.isNotEmpty, isTrue);
      expect(loaded.selectedFilter, equals(NotificationFilterCategory.all));
      expect(loaded.unreadCount, greaterThan(0));
    });

    test('setFilter updates selectedFilter and filtered subset', () async {
      await cubit.loadNotifications(userId: 'u_1');

      cubit.setFilter(NotificationFilterCategory.bookings);
      final loaded = cubit.state as NotificationsLoaded;
      expect(loaded.selectedFilter, equals(NotificationFilterCategory.bookings));
      for (final n in loaded.filteredNotifications) {
        expect(n.category, equals(NotificationCategory.bookings));
      }

      cubit.setFilter(NotificationFilterCategory.unread);
      final unreadLoaded = cubit.state as NotificationsLoaded;
      expect(unreadLoaded.selectedFilter, equals(NotificationFilterCategory.unread));
      for (final n in unreadLoaded.filteredNotifications) {
        expect(n.isRead, isFalse);
      }
    });

    test('markAsRead and markAsUnread toggle notification read state optimistically', () async {
      await cubit.loadNotifications(userId: 'u_1');
      final first = (cubit.state as NotificationsLoaded).allNotifications.first;

      await cubit.markAsRead(first.id);
      final readLoaded = cubit.state as NotificationsLoaded;
      expect(readLoaded.allNotifications.firstWhere((n) => n.id == first.id).isRead, isTrue);

      await cubit.markAsUnread(first.id);
      final unreadLoaded = cubit.state as NotificationsLoaded;
      expect(unreadLoaded.allNotifications.firstWhere((n) => n.id == first.id).isRead, isFalse);
    });

    test('markAllAsRead sets all notifications to read and reduces unreadCount to 0', () async {
      await cubit.loadNotifications(userId: 'u_1');
      expect((cubit.state as NotificationsLoaded).unreadCount, greaterThan(0));

      await cubit.markAllAsRead();
      final loaded = cubit.state as NotificationsLoaded;
      expect(loaded.unreadCount, equals(0));
      for (final n in loaded.allNotifications) {
        expect(n.isRead, isTrue);
      }
    });

    test('deleteNotification removes targeted notification from list', () async {
      await cubit.loadNotifications(userId: 'u_1');
      final originalCount = (cubit.state as NotificationsLoaded).allNotifications.length;

      await cubit.deleteNotification('notif_001');
      final loaded = cubit.state as NotificationsLoaded;
      expect(loaded.allNotifications.length, equals(originalCount - 1));
      expect(loaded.allNotifications.any((n) => n.id == 'notif_001'), isFalse);
    });
  });

  group('NotificationCenterPage Widget Tests', () {
    late MockNotificationRepository repository;
    late NotificationsCubit cubit;

    setUp(() {
      repository = MockNotificationRepository();
      cubit = NotificationsCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets('renders Notification Centre, category chips, and sample notifications', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestFrame(
          child: NotificationCenterPage(cubit: cubit),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notification Centre'), findsOneWidget);
      expect(find.byType(NotificationCategoryChips), findsOneWidget);

      // Verify category chips are present
      expect(find.widgetWithText(FilterChip, 'All (8)'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Unread (4)'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Bookings'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Tournaments'), findsOneWidget);

      // Verify notifications rendered
      expect(find.text('Court Booking Confirmed'), findsOneWidget);
      expect(find.text('Quarterfinal Score Finalized'), findsOneWidget);
      expect(find.text('Tournament Draws Published'), findsOneWidget);
    });

    testWidgets('filtering by category displays only items matching that category', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestFrame(
          child: NotificationCenterPage(cubit: cubit),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Bookings' chip
      await tester.tap(find.widgetWithText(FilterChip, 'Bookings'));
      await tester.pumpAndSettle();

      expect(find.text('Court Booking Confirmed'), findsOneWidget);
      expect(find.text('Court Reservation Cancelled'), findsOneWidget);
      expect(find.text('Quarterfinal Score Finalized'), findsNothing);
      expect(find.text('Tournament Draws Published'), findsNothing);
    });

    testWidgets('filtering by Unread shows only unread items', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestFrame(
          child: NotificationCenterPage(cubit: cubit),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Unread' chip
      await tester.tap(find.widgetWithText(FilterChip, 'Unread (4)'));
      await tester.pumpAndSettle();

      // notif_001 is unread
      expect(find.text('Court Booking Confirmed'), findsOneWidget);
      // notif_005 is read in seed data
      expect(find.text('Pro Carbon Paddle Dispatched'), findsNothing);
    });

    testWidgets('category with no matching results displays empty filter state and restores on button tap', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Create repository with only booking items
      final customRepo = MockNotificationRepository(initialData: [sampleNotification]);
      final customCubit = NotificationsCubit(repository: customRepo);

      await tester.pumpWidget(
        _buildTestFrame(
          child: NotificationCenterPage(cubit: customCubit),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Tournaments' chip (no tournament notifications in customRepo)
      await tester.tap(find.widgetWithText(FilterChip, 'Tournaments'));
      await tester.pumpAndSettle();

      expect(find.text('No Tournaments Notifications'), findsOneWidget);
      expect(find.text('View All Notifications'), findsOneWidget);

      // Tap 'View All Notifications'
      await tester.tap(find.text('View All Notifications'));
      await tester.pumpAndSettle();

      expect(find.text('Court Booking Confirmed'), findsOneWidget);
      customCubit.close();
    });

    testWidgets('overall empty notifications list displays all caught up empty state', (tester) async {
      final emptyRepo = MockNotificationRepository(initialData: []);
      final emptyCubit = NotificationsCubit(repository: emptyRepo);

      await tester.pumpWidget(
        _buildTestFrame(
          child: NotificationCenterPage(cubit: emptyCubit),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Notifications'), findsOneWidget);
      expect(find.textContaining('all caught up'), findsOneWidget);
      emptyCubit.close();
    });

    testWidgets('tapping notification marks it as read and displays fallback destination dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestFrame(
          child: NotificationCenterPage(cubit: cubit),
        ),
      );

      await tester.pumpAndSettle();

      final firstNotificationTile = find.widgetWithText(NotificationTile, 'Court Booking Confirmed');
      expect(firstNotificationTile, findsOneWidget);

      await tester.tap(firstNotificationTile);
      await tester.pumpAndSettle();

      // Destination details fallback dialog displayed
      expect(find.text('Court Booking Confirmed'), findsWidgets);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Notification now marked read
      final updatedLoaded = cubit.state as NotificationsLoaded;
      expect(updatedLoaded.allNotifications.firstWhere((n) => n.id == 'notif_001').isRead, isTrue);
    });

    testWidgets('tapping popup action toggles read/unread status', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestFrame(
          child: NotificationCenterPage(cubit: cubit),
        ),
      );

      await tester.pumpAndSettle();

      // Open popup menu on first notification
      final popupMenu = find.byTooltip('Notification actions').first;
      await tester.tap(popupMenu);
      await tester.pumpAndSettle();

      expect(find.text('Mark as read'), findsOneWidget);
      await tester.tap(find.text('Mark as read'));
      await tester.pumpAndSettle();

      expect((cubit.state as NotificationsLoaded).allNotifications.first.isRead, isTrue);

      // Open popup menu again to mark unread
      await tester.tap(find.byTooltip('Notification actions').first);
      await tester.pumpAndSettle();

      expect(find.text('Mark as unread'), findsOneWidget);
      await tester.tap(find.text('Mark as unread'));
      await tester.pumpAndSettle();

      expect(find.text('Marked as unread'), findsOneWidget);
      expect((cubit.state as NotificationsLoaded).allNotifications.first.isRead, isFalse);
    });

    testWidgets('delete notification prompts confirmation and removes item on confirm', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestFrame(
          child: NotificationCenterPage(cubit: cubit),
        ),
      );

      await tester.pumpAndSettle();

      final originalCount = (cubit.state as NotificationsLoaded).allNotifications.length;

      // Open popup menu
      await tester.tap(find.byTooltip('Notification actions').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Confirmation dialog displayed
      expect(find.text('Delete Notification?'), findsOneWidget);

      // Cancel first
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect((cubit.state as NotificationsLoaded).allNotifications.length, equals(originalCount));

      // Tap Delete again and confirm
      await tester.tap(find.byTooltip('Notification actions').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      final confirmDelete = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(AppButton, 'Delete'),
      );
      await tester.tap(confirmDelete);
      await tester.pumpAndSettle();

      expect(find.text('Notification deleted'), findsOneWidget);
      expect((cubit.state as NotificationsLoaded).allNotifications.length, equals(originalCount - 1));
    });

    testWidgets('mark all as read button prompts confirmation and marks all read on confirm', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestFrame(
          child: NotificationCenterPage(cubit: cubit),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Mark all as read' in AppBar
      await tester.tap(find.byTooltip('Mark all as read'));
      await tester.pumpAndSettle();

      expect(find.text('Mark all as read?'), findsOneWidget);

      // Cancel first
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect((cubit.state as NotificationsLoaded).unreadCount, greaterThan(0));

      // Tap again and confirm
      await tester.tap(find.byTooltip('Mark all as read'));
      await tester.pumpAndSettle();

      final confirmButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(AppButton, 'Mark all as read'),
      );
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(find.text('All notifications marked as read'), findsOneWidget);
      expect((cubit.state as NotificationsLoaded).unreadCount, equals(0));
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestFrame(
          mode: ThemeMode.dark,
          child: NotificationCenterPage(cubit: cubit),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notification Centre'), findsOneWidget);
      expect(find.text('Court Booking Confirmed'), findsOneWidget);
    });

    testWidgets('handles back button navigation callback', (tester) async {
      bool backPressed = false;

      await tester.pumpWidget(
        _buildTestFrame(
          child: NotificationCenterPage(
            cubit: cubit,
            onBack: () => backPressed = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(backPressed, isTrue);
    });
  });

  group('Cross-Role & Context-Aware Notification Navigation Tests', () {
    Widget buildRouterTestApp({
      required SessionCubit sessionCubit,
      required NotificationsCubit notificationsCubit,
    }) {
      final router = GoRouter(
        initialLocation: AppRoutes.notifications,
        routes: [
          GoRoute(
            path: AppRoutes.notifications,
            builder: (context, state) =>
                NotificationCenterPage(cubit: notificationsCubit),
          ),
          GoRoute(
            path: AppRoutes.roleSelection,
            builder: (context, state) =>
                const Scaffold(body: Text('Role Selection Screen')),
          ),
          GoRoute(
            path: AppRoutes.coachBatches,
            builder: (context, state) =>
                const Scaffold(body: Text('Assigned Batches Screen')),
          ),
          GoRoute(
            path: AppRoutes.tournamentOrganizerDashboard,
            builder: (context, state) => const Scaffold(
              body: Text('Tournament Organizer Dashboard Screen'),
            ),
          ),
          GoRoute(
            path: AppRoutes.playerBookings,
            builder: (context, state) =>
                const Scaffold(body: Text('Player Bookings Screen')),
          ),
        ],
      );

      return BlocProvider<SessionCubit>.value(
        value: sessionCubit,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
        ),
      );
    }

    testWidgets('same-role and same-context notification navigates directly to destination', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final sessionCubit = SessionCubit(
        initialState: const SessionContext.authenticated(
          userId: 'user_coach_001',
          email: 'coach@example.com',
          availableRoles: [UserRole.player, UserRole.coach],
          activeRole: UserRole.coach,
          activeOrganizationId: 'org_acad_001',
          activeOrganizationName: 'Pinnacle Sports Academy',
        ),
      );
      final repository = MockNotificationRepository();
      final cubit = NotificationsCubit(repository: repository);

      await tester.pumpWidget(
        buildRouterTestApp(
          sessionCubit: sessionCubit,
          notificationsCubit: cubit,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Coach notification for Pinnacle Sports Academy (notif_004)
      final coachTile = find.widgetWithText(
        NotificationTile,
        'Academy Batch Schedule Update',
      );
      await tester.ensureVisible(coachTile);
      await tester.tap(coachTile);
      await tester.pumpAndSettle();

      // Directly navigated to /coach/batches without mismatch dialog
      expect(find.text('Assigned Batches Screen'), findsOneWidget);
      expect(find.text('Switch Role or Context'), findsNothing);

      await cubit.close();
      await sessionCubit.close();
    });

    testWidgets('different-role notification shows context mismatch dialog and Switch Role opens Role Selection', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Active role is Player
      final sessionCubit = SessionCubit(
        initialState: const SessionContext.authenticated(
          userId: 'user_multi_001',
          email: 'multi@example.com',
          availableRoles: [UserRole.player, UserRole.coach],
          activeRole: UserRole.player,
        ),
      );
      final repository = MockNotificationRepository();
      final cubit = NotificationsCubit(repository: repository);

      await tester.pumpWidget(
        buildRouterTestApp(
          sessionCubit: sessionCubit,
          notificationsCubit: cubit,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Coach notification (notif_004)
      final coachTile = find.widgetWithText(
        NotificationTile,
        'Academy Batch Schedule Update',
      );
      await tester.ensureVisible(coachTile);
      await tester.tap(coachTile);
      await tester.pumpAndSettle();

      // Did not navigate directly to /coach/batches
      expect(find.text('Assigned Batches Screen'), findsNothing);

      // Shows informative context mismatch dialog
      expect(find.text('Switch Role or Context'), findsOneWidget);
      expect(find.text('Role: Coach'), findsOneWidget);
      expect(find.text('Organization: Pinnacle Sports Academy'), findsOneWidget);
      expect(find.text('Switch Role'), findsOneWidget);

      // Tap Switch Role -> navigates to Role Selection screen
      await tester.tap(find.text('Switch Role'));
      await tester.pumpAndSettle();

      expect(find.text('Role Selection Screen'), findsOneWidget);

      await cubit.close();
      await sessionCubit.close();
    });

    testWidgets('different-organization notification with matching role shows context mismatch dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Active role is Coach at Smash Point Academy (org_acad_002)
      final sessionCubit = SessionCubit(
        initialState: const SessionContext.authenticated(
          userId: 'user_coach_001',
          email: 'coach@example.com',
          availableRoles: [UserRole.coach],
          activeRole: UserRole.coach,
          activeOrganizationId: 'org_acad_002',
          activeOrganizationName: 'Smash Point Academy',
        ),
      );
      final repository = MockNotificationRepository();
      final cubit = NotificationsCubit(repository: repository);

      await tester.pumpWidget(
        buildRouterTestApp(
          sessionCubit: sessionCubit,
          notificationsCubit: cubit,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Coach notification for Pinnacle Sports Academy (org_acad_001)
      final coachTile = find.widgetWithText(
        NotificationTile,
        'Academy Batch Schedule Update',
      );
      await tester.ensureVisible(coachTile);
      await tester.tap(coachTile);
      await tester.pumpAndSettle();

      // Blocked from opening wrong organization context
      expect(find.text('Assigned Batches Screen'), findsNothing);
      expect(find.text('Switch Role or Context'), findsOneWidget);
      expect(find.text('Role: Coach'), findsOneWidget);
      expect(find.text('Organization: Pinnacle Sports Academy'), findsOneWidget);

      // Tap Switch Role
      await tester.tap(find.text('Switch Role'));
      await tester.pumpAndSettle();

      expect(find.text('Role Selection Screen'), findsOneWidget);

      await cubit.close();
      await sessionCubit.close();
    });

    testWidgets('different-tournament notification with matching role shows context mismatch dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Active role is Tournament Organizer for National Pickleball Cup 2026 (tourn_002)
      final sessionCubit = SessionCubit(
        initialState: const SessionContext.authenticated(
          userId: 'user_org_001',
          email: 'organizer@example.com',
          availableRoles: [UserRole.tournamentOrganizer],
          activeRole: UserRole.tournamentOrganizer,
          activeOrganizationId: 'org_tourn_001',
          activeOrganizationName: 'Pacific Pickleball Series',
          activeTournamentId: 'tourn_002',
          activeTournamentName: 'National Pickleball Cup 2026',
        ),
      );
      final repository = MockNotificationRepository();
      final cubit = NotificationsCubit(repository: repository);

      await tester.pumpWidget(
        buildRouterTestApp(
          sessionCubit: sessionCubit,
          notificationsCubit: cubit,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Tournament Organizer notification for Mumbai Pickleball Championship 2026 (tourn_001)
      final tournTile = find.widgetWithText(
        NotificationTile,
        'Tournament Draws Published',
      );
      await tester.ensureVisible(tournTile);
      await tester.tap(tournTile);
      await tester.pumpAndSettle();

      // Blocked from opening wrong tournament context
      expect(find.text('Tournament Organizer Dashboard Screen'), findsNothing);
      expect(find.text('Switch Role or Context'), findsOneWidget);
      expect(find.text('Role: Tournament Organizer'), findsOneWidget);
      expect(
        find.text('Tournament: Mumbai Pickleball Championship 2026'),
        findsOneWidget,
      );

      // Tap Switch Role
      await tester.tap(find.text('Switch Role'));
      await tester.pumpAndSettle();

      expect(find.text('Role Selection Screen'), findsOneWidget);

      await cubit.close();
      await sessionCubit.close();
    });

    testWidgets('unimplemented destination with matching context shows notification-details fallback dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Active role is Player
      final sessionCubit = SessionCubit(
        initialState: const SessionContext.authenticated(
          userId: 'user_player_001',
          email: 'player@example.com',
          availableRoles: [UserRole.player],
          activeRole: UserRole.player,
        ),
      );
      final repository = MockNotificationRepository();
      final cubit = NotificationsCubit(repository: repository);

      await tester.pumpWidget(
        buildRouterTestApp(
          sessionCubit: sessionCubit,
          notificationsCubit: cubit,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Player notification with unimplemented destination (notif_006: destinationRoute == null)
      final communityTile = find.widgetWithText(
        NotificationTile,
        'Weekly Club Scramble Invite',
      );
      await tester.ensureVisible(communityTile);
      await tester.tap(communityTile);
      await tester.pumpAndSettle();

      // Shows notification details fallback dialog (not context mismatch dialog)
      expect(find.text('Switch Role or Context'), findsNothing);
      expect(find.text('Close'), findsOneWidget);
      expect(
        find.textContaining('social doubles round-robin scramble'),
        findsWidgets,
      );

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      await cubit.close();
      await sessionCubit.close();
    });
  });
}
