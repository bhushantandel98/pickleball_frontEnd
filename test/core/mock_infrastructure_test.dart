import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/role_preference_storage.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/mock/data/mock_data.dart';
import 'package:pickleball_platform/core/mock/mock_config.dart';
import 'package:pickleball_platform/core/mock/mock_network_harness.dart';
import 'package:pickleball_platform/core/mock/simulated_error_type.dart';
import 'package:pickleball_platform/core/widgets/async_state_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/account_suspended_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/permission_denied_view.dart';
import 'package:pickleball_platform/features/identity/data/datasources/mock_user_profile_data_source.dart';
import 'package:pickleball_platform/features/identity/data/datasources/user_profile_data_source.dart';
import 'package:pickleball_platform/features/identity/data/repositories/mock_user_profile_repository.dart';
import 'package:pickleball_platform/features/identity/data/repositories/remote_user_profile_repository.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/user_profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MockConfig & MockNetworkHarness Tests', () {
    late MockConfig config;
    late MockNetworkHarness harness;

    setUp(() {
      config = MockConfig.instance;
      config.reset();
      config.setLatencyEnabled(false); // disable latency for rapid unit testing
      harness = MockNetworkHarness(config: config);
    });

    tearDown(() {
      config.reset();
    });

    test('executes successful request when error simulation is disabled', () async {
      final result = await harness.request(() async => 'success_payload');
      expect(result, equals('success_payload'));
    });

    test('simulates server error (500) when configured', () async {
      config.simulateError(SimulatedErrorType.serverError);

      final result = await harness.requestResult<String>(() async => 'data');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.statusCode, equals(500));
    });

    test('simulates unauthorized (401) when configured', () async {
      config.simulateError(SimulatedErrorType.unauthorized);

      final result = await harness.requestResult<String>(() async => 'data');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      expect(result.failureOrNull?.statusCode, equals(401));
    });

    test('clearing simulated error restores successful responses', () async {
      config.simulateError(SimulatedErrorType.networkTimeout);
      expect(config.isFailureSimulated, isTrue);

      config.clearSimulatedError();
      expect(config.isFailureSimulated, isFalse);

      final result = await harness.requestResult<String>(() async => 'restored');
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, equals('restored'));
    });

    test('sanitizes unexpected exceptions without exposing internal details', () async {
      final result = await harness.requestResult<String>(() async {
        throw const FormatException('Sensitive database syntax error: table_users_001');
      });

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnknownFailure>());
      expect(
        result.failureOrNull?.message,
        equals('An unexpected error occurred. Please try again.'),
      );
      expect(result.failureOrNull?.message.contains('table_users_001'), isFalse);
    });
  });

  group('MockUserProfileRepository Clean Architecture Integration Tests', () {
    late MockConfig config;
    late MockUserProfileDataSource dataSource;
    late MockUserProfileRepository repository;

    setUp(() {
      config = MockConfig.instance;
      config.reset();
      config.setLatencyEnabled(false);
      dataSource = MockUserProfileDataSource(harness: MockNetworkHarness(config: config));
      repository = MockUserProfileRepository(dataSource: dataSource);
    });

    tearDown(() {
      config.reset();
    });

    test('retrieves player profile successfully from MockData', () async {
      final result = await repository.getUserProfile(MockData.playerUser.id);
      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull?.id, equals(MockData.playerUser.id));
      expect(result.dataOrNull?.name, equals('Alex Rivera'));
    });

    test('returns NotFoundFailure when user identifier does not exist', () async {
      final result = await repository.getUserProfile('non_existent_user');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('simulates forbidden failure (403) across repository boundary', () async {
      config.simulateError(SimulatedErrorType.forbidden);

      final result = await repository.getUserProfile(MockData.playerUser.id);
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ForbiddenFailure>());
      expect(result.failureOrNull?.statusCode, equals(403));
    });

    test('getUserRoles retrieves roles directly without nested harness calls', () async {
      final result = await repository.getUserRoles(MockData.multiRoleUser.id);
      expect(result.isSuccess, isTrue);
      expect(
        result.dataOrNull,
        equals([UserRole.player, UserRole.coach, UserRole.referee]),
      );
    });
  });

  group('RolePreferenceStorage Production & Mock DI Tests', () {
    test('SharedPrefsRolePreferenceStorage persists and retrieves preferred role', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = const SharedPrefsRolePreferenceStorage();

      expect(await storage.getPreferredRole('user_123'), isNull);

      await storage.setPreferredRole('user_123', UserRole.venuePartner);
      expect(await storage.getPreferredRole('user_123'), equals(UserRole.venuePartner));

      await storage.clearPreferredRole('user_123');
      expect(await storage.getPreferredRole('user_123'), isNull);
    });

    test('MockRolePreferenceStorage stores roles in-memory for testing', () async {
      final mockStorage = MockRolePreferenceStorage();
      await mockStorage.setPreferredRole('user_999', UserRole.coach);
      expect(await mockStorage.getPreferredRole('user_999'), equals(UserRole.coach));
      mockStorage.reset();
      expect(await mockStorage.getPreferredRole('user_999'), isNull);
    });
  });

  group('Dependency Injection Isolation Tests (ADR-015)', () {
    setUp(() async {
      await sl.reset();
    });

    tearDown(() async {
      await sl.reset();
    });

    test('initMockServiceLocator() registers mock storage, mock data source and mock repository', () {
      initMockServiceLocator();

      expect(sl.isRegistered<RolePreferenceStorage>(), isTrue);
      expect(sl<RolePreferenceStorage>(), isA<MockRolePreferenceStorage>());

      expect(sl.isRegistered<UserProfileDataSource>(), isTrue);
      expect(sl<UserProfileDataSource>(), isA<MockUserProfileDataSource>());

      expect(sl.isRegistered<UserProfileRepository>(), isTrue);
      expect(sl<UserProfileRepository>(), isA<MockUserProfileRepository>());

      expect(sl.isRegistered<MockConfig>(), isTrue);
      expect(sl.isRegistered<MockNetworkHarness>(), isTrue);
    });

    test('initRemoteServiceLocator() registers SharedPrefsRolePreferenceStorage and the remote repository', () {
      initRemoteServiceLocator();

      expect(sl.isRegistered<RolePreferenceStorage>(), isTrue);
      expect(sl<RolePreferenceStorage>(), isA<SharedPrefsRolePreferenceStorage>());

      expect(sl.isRegistered<UserProfileRepository>(), isTrue);
      expect(sl<UserProfileRepository>(), isA<RemoteUserProfileRepository>());
    });

    test(
      'remote registration path does not register MockRolePreferenceStorage, MockUserProfileDataSource, MockUserProfileRepository, MockConfig or MockNetworkHarness',
      () {
        initRemoteServiceLocator();

        // Ensure mock infrastructure classes are NOT registered in GetIt
        expect(sl.isRegistered<MockConfig>(), isFalse);
        expect(sl.isRegistered<MockNetworkHarness>(), isFalse);
        expect(sl.isRegistered<MockUserProfileDataSource>(), isFalse);
        expect(sl.isRegistered<UserProfileDataSource>(), isFalse);

        // Ensure registered instances are strictly NOT the mock implementations
        expect(sl<RolePreferenceStorage>() is MockRolePreferenceStorage, isFalse);
        expect(sl<UserProfileRepository>() is MockUserProfileRepository, isFalse);
      },
    );
  });

  group('AsyncStateView Widget State Tests', () {
    Widget buildFrame(Widget child) {
      return MaterialApp(
        home: Scaffold(body: child),
      );
    }

    testWidgets('renders LoadingView during AsyncLoading', (tester) async {
      await tester.pumpWidget(
        buildFrame(
          AsyncStateView<String>(
            state: const AsyncState.loading(message: 'Fetching profile...'),
            builder: (context, data) => Text('Data: $data'),
          ),
        ),
      );

      expect(find.byType(LoadingView), findsOneWidget);
      expect(find.text('Fetching profile...'), findsOneWidget);
    });

    testWidgets('renders content builder during AsyncSuccess', (tester) async {
      await tester.pumpWidget(
        buildFrame(
          AsyncStateView<String>(
            state: const AsyncState.success('Loaded Profile Data'),
            builder: (context, data) => Text('Data: $data'),
          ),
        ),
      );

      expect(find.byType(LoadingView), findsNothing);
      expect(find.text('Data: Loaded Profile Data'), findsOneWidget);
    });

    testWidgets('renders EmptyStateView during AsyncEmpty', (tester) async {
      await tester.pumpWidget(
        buildFrame(
          AsyncStateView<List<String>>(
            state: const AsyncState.empty(
              title: 'No Tournaments',
              message: 'Check back later for tournaments.',
            ),
            builder: (context, data) => const Text('Has data'),
          ),
        ),
      );

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('No Tournaments'), findsOneWidget);
    });

    testWidgets('renders ErrorStateView during AsyncError', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        buildFrame(
          AsyncStateView<String>(
            state: AsyncState.error(
              failure: const ServerFailure(message: 'Internal server error 500'),
              onRetry: () => retried = true,
            ),
            builder: (context, data) => const Text('Has data'),
          ),
        ),
      );

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Internal server error 500'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('renders PermissionDeniedView during AsyncPermissionDenied', (tester) async {
      await tester.pumpWidget(
        buildFrame(
          AsyncStateView<String>(
            state: const AsyncState.permissionDenied(
              message: 'Custom permission denied description.',
            ),
            builder: (context, data) => const Text('Has data'),
          ),
        ),
      );

      expect(find.byType(PermissionDeniedView), findsOneWidget);
      expect(find.text('Custom permission denied description.'), findsOneWidget);
    });

    testWidgets('renders AccountSuspendedView during AsyncSuspended', (tester) async {
      await tester.pumpWidget(
        buildFrame(
          AsyncStateView<String>(
            state: const AsyncState.suspended(
              supportContact: 'appeals@pickleballplatform.org',
            ),
            builder: (context, data) => const Text('Has data'),
          ),
        ),
      );

      expect(find.byType(AccountSuspendedView), findsOneWidget);
      expect(find.text('Contact: appeals@pickleballplatform.org'), findsOneWidget);
    });
  });
}
