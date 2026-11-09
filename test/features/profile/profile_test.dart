import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/access/role_preference_storage.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/user_profile_repository.dart';
import 'package:pickleball_platform/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pickleball_platform/features/profile/presentation/cubit/profile_state.dart';
import 'package:pickleball_platform/features/profile/presentation/pages/account_settings_page.dart';
import 'package:pickleball_platform/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:pickleball_platform/features/profile/presentation/pages/profile_page.dart';
import 'package:pickleball_platform/features/profile/presentation/validators/profile_validators.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

class _FakeUserProfileRepository implements UserProfileRepository {
  Result<UserProfile> profileResult;
  UserProfile? lastUpdatedProfile;

  _FakeUserProfileRepository(this.profileResult);

  @override
  Future<Result<UserProfile>> getUserProfile(String userId) async {
    return profileResult;
  }

  @override
  Future<Result<UserProfile>> updateUserProfile(UserProfile profile) async {
    lastUpdatedProfile = profile;
    return Success(profile);
  }

  @override
  Future<Result<List<UserRole>>> getUserRoles(String userId) async {
    return const Success([UserRole.player]);
  }
}

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

  final sampleProfile = UserProfile(
    id: 'user_player_001',
    name: 'Alex Rivera',
    email: 'alex.rivera@example.com',
    phone: '+91 9876543210',
    avatarUrl: null,
    availableRoles: const [UserRole.player, UserRole.coach],
    activeRole: UserRole.player,
    rating: 3.8,
    createdAt: DateTime(2025, 3, 15),
  );

  final sampleProfileNoEmail = UserProfile(
    id: 'user_player_002',
    name: 'Rohan Sharma',
    email: '',
    phone: '+91 9999911111',
    avatarUrl: 'avatar:champion',
    availableRoles: const [UserRole.player],
    activeRole: UserRole.player,
    createdAt: DateTime(2024, 6, 1),
  );

  group('ProfileValidators Unit Tests', () {
    test('validateName accepts valid alphabetic names with hyphens and apostrophes', () {
      expect(ProfileValidators.validateName('Alex Rivera'), isNull);
      expect(ProfileValidators.validateName("O'Connor"), isNull);
      expect(ProfileValidators.validateName('Jean-Luc Picard'), isNull);
      expect(ProfileValidators.validateName('Dr. Jordan Cruz'), isNull);
    });

    test('validateName rejects empty, short, or invalid characters', () {
      expect(ProfileValidators.validateName(null), equals('Please enter your full name'));
      expect(ProfileValidators.validateName('   '), equals('Please enter your full name'));
      expect(ProfileValidators.validateName('A'), equals('Full name must be at least 2 characters'));
      expect(ProfileValidators.validateName('Alex123'), equals('Name contains invalid characters'));
      expect(ProfileValidators.validateName('Alex @Court'), equals('Name contains invalid characters'));
    });

    test('validateEmail allows null or empty strings as email is optional', () {
      expect(ProfileValidators.validateEmail(null), isNull);
      expect(ProfileValidators.validateEmail(''), isNull);
      expect(ProfileValidators.validateEmail('   '), isNull);
    });

    test('validateEmail validates correctly when provided', () {
      expect(ProfileValidators.validateEmail('alex@example.com'), isNull);
      expect(ProfileValidators.validateEmail('user.name+tag@sub.domain.org'), isNull);
      expect(ProfileValidators.validateEmail('invalid-email'), equals('Please enter a valid email address'));
      expect(ProfileValidators.validateEmail('@missing-username.com'), equals('Please enter a valid email address'));
      expect(ProfileValidators.validateEmail('missing-domain@'), equals('Please enter a valid email address'));
    });
  });

  group('ProfileCubit Unit Tests', () {
    test('Initial state is ProfileInitial', () {
      final repo = _FakeUserProfileRepository(Success(sampleProfile));
      final cubit = ProfileCubit(repository: repo);
      expect(cubit.state, equals(const ProfileInitial()));
      cubit.close();
    });

    test('loadProfile emits [ProfileLoading, ProfileLoaded] on success', () async {
      final repo = _FakeUserProfileRepository(Success(sampleProfile));
      final cubit = ProfileCubit(repository: repo);

      final expected = [
        const ProfileLoading(),
        ProfileLoaded(profile: sampleProfile),
      ];

      expectLater(cubit.stream, emitsInOrder(expected));
      await cubit.loadProfile(userId: 'user_player_001');
      cubit.close();
    });

    test('loadProfile emits [ProfileLoading, ProfileFailure] on error', () async {
      final repo = _FakeUserProfileRepository(
        const FailureResult(NotFoundFailure(message: 'User not found')),
      );
      final cubit = ProfileCubit(repository: repo);

      final expected = [
        const ProfileLoading(),
        const ProfileFailure(message: 'User not found'),
      ];

      expectLater(cubit.stream, emitsInOrder(expected));
      await cubit.loadProfile(userId: 'unknown');
      cubit.close();
    });

    test('updateProfile commits changes and emits ProfileLoaded with feedback message', () async {
      final repo = _FakeUserProfileRepository(Success(sampleProfile));
      final cubit = ProfileCubit(repository: repo);
      await cubit.loadProfile(userId: 'user_player_001');

      final updated = sampleProfile.copyWith(name: 'Alexander Rivera');
      final success = await cubit.updateProfile(updated);

      expect(success, isTrue);
      expect(repo.lastUpdatedProfile?.name, equals('Alexander Rivera'));
      expect(cubit.state, isA<ProfileLoaded>());
      final loaded = cubit.state as ProfileLoaded;
      expect(loaded.profile.name, equals('Alexander Rivera'));
      expect(loaded.successMessage, equals('Profile updated successfully'));

      cubit.close();
    });
  });

  group('ProfilePage Widget Tests', () {
    testWidgets('renders user profile details, status chips, and member since date', (tester) async {
      final repo = _FakeUserProfileRepository(Success(sampleProfile));
      final cubit = ProfileCubit(repository: repo);

      await tester.pumpWidget(
        _buildTestFrame(
          child: ProfilePage(
            cubit: cubit,
            userId: 'user_player_001',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('User Profile'), findsOneWidget);
      expect(find.text('Alex Rivera'), findsWidgets);
      expect(find.text('+91 9876543210'), findsWidgets);
      expect(find.text('alex.rivera@example.com'), findsOneWidget);
      expect(find.text('Active Account'), findsOneWidget);
      expect(find.text('Verified Mobile'), findsOneWidget);
      expect(find.text('March 2025'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Account Settings'), findsOneWidget);
    });

    testWidgets('handles missing email gracefully by displaying placeholder', (tester) async {
      final repo = _FakeUserProfileRepository(Success(sampleProfileNoEmail));
      final cubit = ProfileCubit(repository: repo);

      await tester.pumpWidget(
        _buildTestFrame(
          child: ProfilePage(
            cubit: cubit,
            userId: 'user_player_002',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Rohan Sharma'), findsWidgets);
      expect(find.text('Not provided'), findsOneWidget);
    });

    testWidgets('triggers onEditProfile and onAccountSettings callbacks', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _FakeUserProfileRepository(Success(sampleProfile));
      final cubit = ProfileCubit(repository: repo);
      bool editTapped = false;
      bool settingsTapped = false;

      await tester.pumpWidget(
        _buildTestFrame(
          child: ProfilePage(
            cubit: cubit,
            userId: 'user_player_001',
            onEditProfile: () => editTapped = true,
            onAccountSettings: () => settingsTapped = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();
      expect(editTapped, isTrue);

      await tester.tap(find.text('Account Settings'));
      await tester.pumpAndSettle();
      expect(settingsTapped, isTrue);
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      final repo = _FakeUserProfileRepository(Success(sampleProfile));
      final cubit = ProfileCubit(repository: repo);

      await tester.pumpWidget(
        _buildTestFrame(
          mode: ThemeMode.dark,
          child: ProfilePage(
            cubit: cubit,
            userId: 'user_player_001',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Alex Rivera'), findsWidgets);
      expect(find.text('Personal Information'), findsOneWidget);
    });

    testWidgets('editing profile and saving immediately updates previous ProfilePage', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _FakeUserProfileRepository(Success(sampleProfile));
      final profileCubit = ProfileCubit(repository: repo);

      final router = GoRouter(
        initialLocation: AppRoutes.profile,
        routes: [
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => ProfilePage(cubit: profileCubit),
          ),
          GoRoute(
            path: AppRoutes.editProfile,
            builder: (context, state) => EditProfilePage(
              initialProfile: state.extra as UserProfile?,
              cubit: ProfileCubit(repository: repo),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Alex Rivera'), findsWidgets);
      expect(find.text('Alexander The Great'), findsNothing);

      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Alex Rivera'),
        'Alexander The Great',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(find.text('User Profile'), findsOneWidget);
      expect(find.text('Alexander The Great'), findsWidgets);
      expect(find.text('Alex Rivera'), findsNothing);
      expect(profileCubit.state, isA<ProfileLoaded>());
      expect((profileCubit.state as ProfileLoaded).profile.name, equals('Alexander The Great'));
    });
  });

  group('EditProfilePage Widget Tests', () {
    testWidgets('pre-fills name, email, and renders mobile number as read-only', (tester) async {
      final repo = _FakeUserProfileRepository(Success(sampleProfile));
      final cubit = ProfileCubit(repository: repo);

      await tester.pumpWidget(
        _buildTestFrame(
          child: EditProfilePage(
            initialProfile: sampleProfile,
            cubit: cubit,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Alex Rivera'), findsWidgets);
      expect(find.text('alex.rivera@example.com'), findsOneWidget);
      expect(find.text('+91 9876543210'), findsOneWidget);
      expect(find.textContaining('Mobile number is your primary verified identifier'), findsOneWidget);
    });

    testWidgets('validates name field and blocks save when invalid', (tester) async {
      final repo = _FakeUserProfileRepository(Success(sampleProfile));
      final cubit = ProfileCubit(repository: repo);

      await tester.pumpWidget(
        _buildTestFrame(
          child: EditProfilePage(
            initialProfile: sampleProfile,
            cubit: cubit,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Clear full name
      await tester.enterText(find.widgetWithText(TextFormField, 'Alex Rivera'), '');
      await tester.pumpAndSettle();

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(repo.lastUpdatedProfile, isNull);
    });

    testWidgets('cancelling when clean pops directly without dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _FakeUserProfileRepository(Success(sampleProfile));
      final cubit = ProfileCubit(repository: repo);
      bool cancelled = false;

      await tester.pumpWidget(
        _buildTestFrame(
          child: EditProfilePage(
            initialProfile: sampleProfile,
            cubit: cubit,
            onCancel: () => cancelled = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(cancelled, isTrue);
      expect(find.text('Discard Changes?'), findsNothing);
    });

    testWidgets('cancelling when dirty prompts AppConfirmationDialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _FakeUserProfileRepository(Success(sampleProfile));
      final cubit = ProfileCubit(repository: repo);
      bool cancelled = false;

      await tester.pumpWidget(
        _buildTestFrame(
          child: EditProfilePage(
            initialProfile: sampleProfile,
            cubit: cubit,
            onCancel: () => cancelled = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Modify name to trigger dirty state
      await tester.enterText(find.widgetWithText(TextFormField, 'Alex Rivera'), 'Alex Super Rivera');
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Confirmation dialog should be shown
      expect(find.text('Discard Changes?'), findsOneWidget);
      expect(find.text('You have unsaved changes. Are you sure you want to discard them?'), findsOneWidget);

      // Tap Keep Editing
      await tester.tap(find.text('Keep Editing'));
      await tester.pumpAndSettle();

      expect(cancelled, isFalse);
      expect(find.text('Discard Changes?'), findsNothing);

      // Tap Cancel again and tap Discard
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(cancelled, isTrue);
    });

    testWidgets('saves valid updates and triggers onSaveSuccess callback', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = _FakeUserProfileRepository(Success(sampleProfile));
      final cubit = ProfileCubit(repository: repo);
      UserProfile? saved;

      await tester.pumpWidget(
        _buildTestFrame(
          child: EditProfilePage(
            initialProfile: sampleProfile,
            cubit: cubit,
            onSaveSuccess: (profile) => saved = profile,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextFormField, 'Alex Rivera'), 'Alex Rivera Pro');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      expect(saved?.name, equals('Alex Rivera Pro'));
      expect(repo.lastUpdatedProfile?.name, equals('Alex Rivera Pro'));
    });

    testWidgets('avatar picker opens and selects preset badge', (tester) async {
      final repo = _FakeUserProfileRepository(Success(sampleProfile));
      final cubit = ProfileCubit(repository: repo);

      await tester.pumpWidget(
        _buildTestFrame(
          child: EditProfilePage(
            initialProfile: sampleProfile,
            cubit: cubit,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Change Badge / Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Select Profile Badge'), findsOneWidget);
      expect(find.text('Champion'), findsOneWidget);
      expect(find.text('Pro Star'), findsOneWidget);

      // Tap on Champion preset
      await tester.tap(find.text('Champion'));
      await tester.pumpAndSettle();

      // Picker should close
      expect(find.text('Select Profile Badge'), findsNothing);
    });
  });

  group('AccountSettingsPage Widget Tests', () {
    late SessionCubit sessionCubit;

    setUp(() {
      sessionCubit = SessionCubit(preferenceStorage: MockRolePreferenceStorage());
    });

    tearDown(() {
      sessionCubit.close();
    });

    testWidgets('renders profile snapshot tile, security, preferences, and logout CTA', (tester) async {
      final repo = _FakeUserProfileRepository(Success(sampleProfile));
      final cubit = ProfileCubit(repository: repo);
      await cubit.loadProfile(userId: 'user_player_001');

      await tester.pumpWidget(
        _buildTestFrame(
          sessionCubit: sessionCubit,
          child: AccountSettingsPage(cubit: cubit),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Account Settings'), findsOneWidget);
      expect(find.text('Alex Rivera'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Privacy & Security'), findsOneWidget);
      expect(find.text('Notification Preferences'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets('tapping settings tiles shows informational placeholder dialogs', (tester) async {
      final repo = _FakeUserProfileRepository(Success(sampleProfile));
      final cubit = ProfileCubit(repository: repo);
      await cubit.loadProfile(userId: 'user_player_001');

      await tester.pumpWidget(
        _buildTestFrame(
          sessionCubit: sessionCubit,
          child: AccountSettingsPage(cubit: cubit),
        ),
      );

      await tester.pumpAndSettle();

      // Change Password tile
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Phase 1.3'), findsOneWidget);
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();

      // Notification preferences tile
      await tester.tap(find.text('Notification Preferences'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Phase 1.4'), findsOneWidget);
      await tester.tap(find.text('Understood'));
      await tester.pumpAndSettle();
    });

    testWidgets('logout prompts confirmation dialog and signs out session on confirm', (tester) async {
      await sessionCubit.signIn(
        userId: 'u-1',
        email: 'alex@test.com',
        roles: [UserRole.player],
        activeRole: UserRole.player,
      );
      expect(sessionCubit.state.isAuthenticated, isTrue);

      final repo = _FakeUserProfileRepository(Success(sampleProfile));
      final cubit = ProfileCubit(repository: repo);
      await cubit.loadProfile(userId: 'user_player_001');

      bool loggedOut = false;

      await tester.pumpWidget(
        _buildTestFrame(
          sessionCubit: sessionCubit,
          child: AccountSettingsPage(
            cubit: cubit,
            onLoggedOut: () => loggedOut = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Log Out
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out of your Pickleball account?'), findsOneWidget);

      // Cancel first
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(sessionCubit.state.isAuthenticated, isTrue);
      expect(loggedOut, isFalse);

      // Tap Log Out and confirm
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      // Confirm button has label 'Log Out' (finding the one inside dialog actions)
      final dialogLogoutButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(AppButton, 'Log Out'),
      );
      await tester.tap(dialogLogoutButton);
      await tester.pumpAndSettle();

      expect(sessionCubit.state.isAuthenticated, isFalse);
      expect(loggedOut, isTrue);
    });
  });
}
