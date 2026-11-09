import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/features/notifications/data/repositories/mock_notification_preferences_repository.dart';
import 'package:pickleball_platform/features/notifications/domain/entities/notification_preferences.dart';
import 'package:pickleball_platform/features/notifications/presentation/cubit/notification_preferences_cubit.dart';
import 'package:pickleball_platform/features/notifications/presentation/cubit/notification_preferences_state.dart';
import 'package:pickleball_platform/features/notifications/presentation/pages/notification_preferences_page.dart';
import 'package:pickleball_platform/features/notifications/presentation/widgets/preference_switch_tile.dart';

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

  final defaultPrefs = NotificationPreferences.defaults(userId: 'user_001');

  group('NotificationPreferences Entity Unit Tests', () {
    test('defaults() initializes verified baseline settings', () {
      final prefs = NotificationPreferences.defaults(userId: 'test_user');

      expect(prefs.userId, equals('test_user'));
      expect(prefs.pushMasterEnabled, isTrue);
      expect(prefs.emailMasterEnabled, isTrue);

      // Push defaults
      expect(prefs.push.accountSecurity, isTrue);
      expect(prefs.push.bookingUpdates, isTrue);
      expect(prefs.push.tournamentUpdates, isTrue);
      expect(prefs.push.matchScoringUpdates, isTrue);
      expect(prefs.push.coachingAcademyUpdates, isTrue);
      expect(prefs.push.marketplaceUpdates, isTrue);
      expect(prefs.push.communityUpdates, isTrue);
      expect(prefs.push.promotions, isFalse);

      // Email defaults
      expect(prefs.email.accountSecurity, isTrue);
      expect(prefs.email.bookingUpdates, isTrue);
      expect(prefs.email.tournamentUpdates, isTrue);
      expect(prefs.email.coachingAcademyUpdates, isTrue);
      expect(prefs.email.marketplaceUpdates, isTrue);
      expect(prefs.email.communityUpdates, isFalse);
      expect(prefs.email.promotions, isFalse);

      // General defaults
      expect(prefs.general.soundEnabled, isTrue);
      expect(prefs.general.detailedPreviews, isTrue);
    });

    test('copyWith updates nested channels without mutating untouched fields', () {
      final updated = defaultPrefs.copyWith(
        pushMasterEnabled: false,
        push: defaultPrefs.push.copyWith(promotions: true),
      );

      expect(updated.pushMasterEnabled, isFalse);
      expect(updated.push.promotions, isTrue);
      expect(updated.push.accountSecurity, isTrue);
      expect(updated.emailMasterEnabled, isTrue);
      expect(updated.email.promotions, isFalse);
    });

    test('toMap and fromMap serialize and deserialize cleanly', () {
      final map = defaultPrefs.toMap();
      final reconstituted = NotificationPreferences.fromMap(map);

      expect(reconstituted, equals(defaultPrefs));
    });
  });

  group('NotificationPreferencesCubit Unit Tests', () {
    late MockNotificationPreferencesRepository repository;
    late NotificationPreferencesCubit cubit;

    setUp(() {
      repository = MockNotificationPreferencesRepository();
      cubit = NotificationPreferencesCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is NotificationPreferencesInitial', () {
      expect(cubit.state, isA<NotificationPreferencesInitial>());
    });

    test('loadPreferences emits [Loading, Loaded] with default preferences', () async {
      await cubit.loadPreferences(userId: 'u_1');

      expect(cubit.state, isA<NotificationPreferencesLoaded>());
      final loaded = cubit.state as NotificationPreferencesLoaded;
      expect(loaded.preferences.userId, equals('u_1'));
      expect(loaded.preferences.pushMasterEnabled, isTrue);
      expect(loaded.preferences.emailMasterEnabled, isTrue);
    });

    test('togglePushMaster disables master switch and emits feedback without resetting sub-preferences', () async {
      await cubit.loadPreferences(userId: 'u_1');
      await cubit.togglePushMaster(false);

      expect(cubit.state, isA<NotificationPreferencesLoaded>());
      final loaded = cubit.state as NotificationPreferencesLoaded;
      expect(loaded.preferences.pushMasterEnabled, isFalse);
      expect(loaded.preferences.push.tournamentUpdates, isTrue);
      expect(loaded.feedbackMessage, equals('Push notifications disabled'));

      // Re-enable
      await cubit.togglePushMaster(true);
      final reEnabled = cubit.state as NotificationPreferencesLoaded;
      expect(reEnabled.preferences.pushMasterEnabled, isTrue);
      expect(reEnabled.preferences.push.tournamentUpdates, isTrue);
      expect(reEnabled.feedbackMessage, equals('Push notifications enabled'));
    });

    test('toggleEmailMaster updates email master switch cleanly', () async {
      await cubit.loadPreferences(userId: 'u_1');
      await cubit.toggleEmailMaster(false);

      final loaded = cubit.state as NotificationPreferencesLoaded;
      expect(loaded.preferences.emailMasterEnabled, isFalse);
      expect(loaded.feedbackMessage, equals('Email notifications disabled'));
    });

    test('updatePushCategory modifies target push switch', () async {
      await cubit.loadPreferences(userId: 'u_1');
      await cubit.updatePushCategory(key: 'promotions', value: true);

      final loaded = cubit.state as NotificationPreferencesLoaded;
      expect(loaded.preferences.push.promotions, isTrue);
      expect(loaded.feedbackMessage, equals('Preference updated'));
    });

    test('updateEmailCategory modifies target email switch', () async {
      await cubit.loadPreferences(userId: 'u_1');
      await cubit.updateEmailCategory(key: 'communityUpdates', value: true);

      final loaded = cubit.state as NotificationPreferencesLoaded;
      expect(loaded.preferences.email.communityUpdates, isTrue);
    });

    test('updateGeneralSetting modifies sound and preview preferences', () async {
      await cubit.loadPreferences(userId: 'u_1');
      await cubit.updateGeneralSetting(key: 'soundEnabled', value: false);

      final loaded = cubit.state as NotificationPreferencesLoaded;
      expect(loaded.preferences.general.soundEnabled, isFalse);
    });

    test('resetToDefaults restores defaults and emits reset feedback', () async {
      await cubit.loadPreferences(userId: 'u_1');
      await cubit.togglePushMaster(false);
      await cubit.updateGeneralSetting(key: 'soundEnabled', value: false);

      await cubit.resetToDefaults();

      final loaded = cubit.state as NotificationPreferencesLoaded;
      expect(loaded.preferences.pushMasterEnabled, isTrue);
      expect(loaded.preferences.general.soundEnabled, isTrue);
      expect(loaded.feedbackMessage, contains('restored to default'));
    });
  });

  group('NotificationPreferencesPage Widget Tests', () {
    late MockNotificationPreferencesRepository repository;
    late NotificationPreferencesCubit cubit;

    setUp(() {
      repository = MockNotificationPreferencesRepository();
      cubit = NotificationPreferencesCubit(repository: repository);
    });

    tearDown(() {
      cubit.close();
    });

    testWidgets('renders Push, Email, and General sections with master switches', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestFrame(
          child: NotificationPreferencesPage(
            cubit: cubit,
            userId: 'user_001',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Email Notifications'), findsOneWidget);
      expect(find.text('General Settings'), findsOneWidget);

      // Section A items
      expect(find.text('Account & Security Alerts'), findsWidgets);
      expect(find.text('Booking Updates'), findsWidgets);
      expect(find.text('Tournament Updates'), findsWidgets);
      expect(find.text('Match & Scoring Updates'), findsOneWidget);
      expect(find.text('Coaching & Academy Updates'), findsWidgets);
      expect(find.text('Marketplace Order Updates'), findsWidgets);
      expect(find.text('Community & Social Updates'), findsWidgets);
      expect(find.text('Promotional Announcements'), findsWidgets);

      // Section C items
      expect(find.text('In-App Sound'), findsOneWidget);
      expect(find.text('Notification Preview Details'), findsOneWidget);

      // Section D Reset
      expect(find.text('Reset to Default Settings'), findsOneWidget);
    });

    testWidgets('toggling push master switch disables sub-switches and displays warning banner', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestFrame(
          child: NotificationPreferencesPage(
            cubit: cubit,
            userId: 'user_001',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Push notifications are turned off'), findsNothing);

      // Master switch for push is the first switch in the widget tree
      final pushMasterSwitch = find.byType(Switch).first;
      await tester.tap(pushMasterSwitch);
      await tester.pumpAndSettle();

      // Warning banner now visible
      expect(find.textContaining('Push notifications are turned off'), findsOneWidget);
      expect(find.text('Push notifications disabled'), findsOneWidget);

      // Sub switches are now disabled (onChanged == null)
      final matchTile = tester.widget<PreferenceSwitchTile>(
        find.widgetWithText(PreferenceSwitchTile, 'Match & Scoring Updates'),
      );
      expect(matchTile.isChannelEnabled, isFalse);

      // Toggle master back ON
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Push notifications are turned off'), findsNothing);
      expect(find.text('Push notifications enabled'), findsOneWidget);

      final matchTileRestored = tester.widget<PreferenceSwitchTile>(
        find.widgetWithText(PreferenceSwitchTile, 'Match & Scoring Updates'),
      );
      expect(matchTileRestored.isChannelEnabled, isTrue);
      expect(matchTileRestored.value, isTrue);
    });

    testWidgets('toggling individual category updates state immediately and shows feedback', (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestFrame(
          child: NotificationPreferencesPage(
            cubit: cubit,
            userId: 'user_001',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Booking Updates tile in Section A
      final bookingTile = find.widgetWithText(PreferenceSwitchTile, 'Booking Updates').first;
      await tester.tap(bookingTile);
      await tester.pumpAndSettle();

      expect(find.text('Preference updated'), findsOneWidget);
      final updatedBookingTile = tester.widget<PreferenceSwitchTile>(bookingTile);
      expect(updatedBookingTile.value, isFalse);
    });

    testWidgets('reset button prompts confirmation dialog and restores defaults when confirmed', (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestFrame(
          child: NotificationPreferencesPage(
            cubit: cubit,
            userId: 'user_001',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // First change a setting in Section A
      final bookingTile = find.widgetWithText(PreferenceSwitchTile, 'Booking Updates').first;
      await tester.tap(bookingTile);
      await tester.pumpAndSettle();
      expect(tester.widget<PreferenceSwitchTile>(bookingTile).value, isFalse);

      // Tap Reset
      final resetButton = find.text('Reset to Default Settings');
      await tester.ensureVisible(resetButton);
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Confirmation dialog displayed
      expect(find.text('Reset Notification Preferences?'), findsOneWidget);

      // Cancel first
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Notification Preferences?'), findsNothing);
      expect(tester.widget<PreferenceSwitchTile>(bookingTile).value, isFalse);

      // Tap Reset again and confirm
      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      final confirmButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(AppButton, 'Reset to Defaults'),
      );
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('restored to default settings'), findsOneWidget);
      expect(tester.widget<PreferenceSwitchTile>(bookingTile).value, isTrue);
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestFrame(
          mode: ThemeMode.dark,
          child: NotificationPreferencesPage(
            cubit: cubit,
            userId: 'user_001',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Email Notifications'), findsOneWidget);
    });

    testWidgets('handles back button navigation callback', (tester) async {
      bool backPressed = false;

      await tester.pumpWidget(
        _buildTestFrame(
          child: NotificationPreferencesPage(
            cubit: cubit,
            userId: 'user_001',
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
}
