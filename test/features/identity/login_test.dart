import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/mock/mock_config.dart';
import 'package:pickleball_platform/core/mock/mock_network_harness.dart';
import 'package:pickleball_platform/core/mock/simulated_error_type.dart';
import 'package:pickleball_platform/core/router/app_router.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/identity/data/models/auth_response_model.dart';
import 'package:pickleball_platform/features/identity/data/models/login_request_model.dart';
import 'package:pickleball_platform/features/identity/data/repositories/mock_auth_repository.dart';
import 'package:pickleball_platform/features/identity/data/repositories/remote_auth_repository.dart';
import 'package:pickleball_platform/features/identity/domain/entities/auth_session.dart';
import 'package:pickleball_platform/features/identity/presentation/bloc/login_cubit.dart';
import 'package:pickleball_platform/features/identity/presentation/pages/login_page.dart';
import 'package:pickleball_platform/features/identity/presentation/validators/login_validators.dart';
import 'package:pickleball_platform/features/identity/presentation/widgets/brand_logo_emblem.dart';

void main() {
  group('Login Validators Unit Tests', () {
    test('validatePhone requires non-empty input', () {
      expect(LoginValidators.validatePhone(null), equals('Mobile number is required'));
      expect(LoginValidators.validatePhone(''), equals('Mobile number is required'));
      expect(LoginValidators.validatePhone('   '), equals('Mobile number is required'));
    });

    test('validatePhone rejects invalid Indian phone formats', () {
      expect(
        LoginValidators.validatePhone('12345'),
        equals('Enter a valid 10-digit Indian mobile number'),
      );
      expect(
        LoginValidators.validatePhone('1234567890'), // Starts with 1
        equals('Enter a valid 10-digit Indian mobile number'),
      );
      expect(
        LoginValidators.validatePhone('5550101010'), // Starts with 5
        equals('Enter a valid 10-digit Indian mobile number'),
      );
      expect(
        LoginValidators.validatePhone('98765432101'), // 11 digits
        equals('Enter a valid 10-digit Indian mobile number'),
      );
    });

    test('validatePhone accepts valid 10-digit Indian mobile numbers (starts with 6-9)', () {
      expect(LoginValidators.validatePhone('9876543210'), isNull);
      expect(LoginValidators.validatePhone('8123456789'), isNull);
      expect(LoginValidators.validatePhone('7999888777'), isNull);
      expect(LoginValidators.validatePhone('6300112233'), isNull);
      expect(LoginValidators.validatePhone('98765 43210'), isNull);
      expect(LoginValidators.validatePhone('9876-543-210'), isNull);
    });

    test('validatePassword requires non-empty input', () {
      expect(LoginValidators.validatePassword(null), equals('Password is required'));
      expect(LoginValidators.validatePassword(''), equals('Password is required'));
      expect(LoginValidators.validatePassword('Password123'), isNull);
    });
  });

  group('Login Models & Repository Unit Tests', () {
    late MockConfig mockConfig;
    late MockNetworkHarness harness;
    late MockAuthRepository repository;

    setUp(() {
      mockConfig = MockConfig.instance;
      mockConfig.setLatencyEnabled(false);
      mockConfig.clearSimulatedError();
      harness = MockNetworkHarness(config: mockConfig);
      repository = MockAuthRepository(harness: harness);
    });

    tearDown(() {
      mockConfig.setLatencyEnabled(true);
      mockConfig.clearSimulatedError();
    });

    test('LoginRequestModel serializes with +91 country prefix', () {
      const model = LoginRequestModel(
        phone: '9876543210',
        password: 'Password123',
      );

      expect(model.fullPhoneNumber, equals('+919876543210'));
      expect(model.rawPhone, equals('9876543210'));
      expect(model.toJson(), equals({
        'phone': '+919876543210',
        'password': 'Password123',
      }));
    });

    test('AuthResponseModel correctly parses JSON into AuthSession domain entity', () {
      final json = {
        'token': 'jwt_mock_token_abc',
        'refreshToken': 'jwt_refresh_token_xyz',
        'tokenType': 'Bearer',
        'expiresIn': 3600,
        'user': {
          'id': 'usr_99',
          'name': 'Test User',
          'phone': '+919876543210',
          'roles': ['player', 'coach'],
          'activeRole': 'player',
        },
      };

      final responseModel = AuthResponseModel.fromJson(json);
      final entity = responseModel.toEntity();

      expect(entity.userId, equals('usr_99'));
      expect(entity.accessToken, equals('jwt_mock_token_abc'));
      expect(entity.name, equals('Test User'));
      expect(entity.availableRoles, equals([UserRole.player, UserRole.coach]));
      expect(entity.activeRole, equals(UserRole.player));
      expect(entity.hasMultipleRoles, isTrue);
    });

    test('AuthResponseModel preserves empty roles array without granting fallback role', () {
      final json = {
        'token': 'jwt_mock_token_empty',
        'user': {
          'id': 'usr_no_roles',
          'name': 'No Role User',
          'phone': '+919876543210',
          'roles': <String>[],
        },
      };

      final responseModel = AuthResponseModel.fromJson(json);
      final entity = responseModel.toEntity();

      expect(entity.availableRoles, isEmpty);
      expect(entity.activeRole, isNull);
      expect(entity.hasMultipleRoles, isFalse);
    });

    test('RemoteAuthRepository placeholder returns FailureResult instead of throwing', () async {
      const remoteRepo = RemoteAuthRepository();
      const request = LoginRequestModel(
        phone: '9876543210',
        password: 'Password123',
      );

      final result = await remoteRepo.login(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ServerFailure>());
      expect(result.failureOrNull?.statusCode, equals(503));
      expect(
        result.failureOrNull?.message,
        contains('currently unavailable'),
      );
    });

    test('MockAuthRepository authenticates valid multi-role credentials', () async {
      const request = LoginRequestModel(
        phone: '9876543210',
        password: 'Password123',
      );

      final result = await repository.login(request);

      expect(result.isSuccess, isTrue);
      final session = result.dataOrNull!;
      expect(session.name, equals('Alex Rivera'));
      expect(session.availableRoles.length, equals(3));
      expect(session.availableRoles, contains(UserRole.player));
      expect(session.availableRoles, contains(UserRole.coach));
      expect(session.availableRoles, contains(UserRole.referee));
      expect(session.hasMultipleRoles, isTrue);
    });

    test('MockAuthRepository authenticates valid single-role credentials', () async {
      const request = LoginRequestModel(
        phone: '9876543211',
        password: 'Password123',
      );

      final result = await repository.login(request);

      expect(result.isSuccess, isTrue);
      final session = result.dataOrNull!;
      expect(session.name, equals('Samira Khan'));
      expect(session.availableRoles, equals([UserRole.player]));
      expect(session.hasMultipleRoles, isFalse);
    });

    test('MockAuthRepository returns UnauthorizedFailure for wrong password', () async {
      const request = LoginRequestModel(
        phone: '9876543210',
        password: 'wrongpass',
      );

      final result = await repository.login(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });

    test('MockAuthRepository returns ForbiddenFailure for suspended account', () async {
      const request = LoginRequestModel(
        phone: '9876543219',
        password: 'Password123',
      );

      final result = await repository.login(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ForbiddenFailure>());
      expect(result.failureOrNull?.message, contains('suspended'));
    });

    test('MockAuthRepository respects simulated network timeout', () async {
      mockConfig.simulateError(SimulatedErrorType.networkTimeout);

      const request = LoginRequestModel(
        phone: '9876543210',
        password: 'Password123',
      );

      final result = await repository.login(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('LoginCubit State Transitions', () {
    late MockConfig mockConfig;
    late MockAuthRepository repository;
    late LoginCubit cubit;

    setUp(() {
      mockConfig = MockConfig.instance;
      mockConfig.setLatencyEnabled(false);
      mockConfig.clearSimulatedError();
      repository = MockAuthRepository(harness: MockNetworkHarness(config: mockConfig));
      cubit = LoginCubit(authRepository: repository);
    });

    tearDown(() {
      cubit.close();
      mockConfig.setLatencyEnabled(true);
      mockConfig.clearSimulatedError();
    });

    test('initial state is LoginInitial', () {
      expect(cubit.state, equals(const LoginInitial()));
    });

    test('emits [LoginLoading, LoginSuccess] upon successful authentication', () async {
      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<LoginLoading>(),
          isA<LoginSuccess>().having(
            (s) => s.session.name,
            'session name',
            equals('Alex Rivera'),
          ),
        ]),
      );

      await cubit.submitLogin(
        phone: '9876543210',
        password: 'Password123',
      );
    });

    test('emits [LoginLoading, LoginFailure] when credentials are invalid', () async {
      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<LoginLoading>(),
          isA<LoginFailure>().having(
            (s) => s.message,
            'error message',
            contains('Invalid mobile number or password'),
          ),
        ]),
      );

      await cubit.submitLogin(
        phone: '9876543210',
        password: 'wrongpass',
      );
    });

    test('reset() restores LoginInitial state', () async {
      await cubit.submitLogin(
        phone: '9876543210',
        password: 'wrongpass',
      );
      expect(cubit.state, isA<LoginFailure>());

      cubit.reset();
      expect(cubit.state, equals(const LoginInitial()));
    });
  });

  group('LoginPage UI & Widget Tests', () {
    Widget buildTestableWidget({
      LoginCubit? cubit,
      ThemeMode themeMode = ThemeMode.light,
      void Function(AuthSession)? onLoginSuccess,
      VoidCallback? onForgotPassword,
      VoidCallback? onCreateAccount,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: LoginPage(
          cubit: cubit,
          onLoginSuccess: onLoginSuccess,
          onForgotPasswordPressed: onForgotPassword,
          onCreateAccountPressed: onCreateAccount,
        ),
      );
    }

    testWidgets('renders brand emblem, heading, form fields, and action buttons',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // Brand & Heading
      expect(find.byType(BrandLogoEmblem), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(
        find.text('Sign in to your account with your registered mobile number and password.'),
        findsOneWidget,
      );

      // Inputs
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('+91 '), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Actions
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Sign In'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('displays inline validation errors when submitting empty form',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // Tap Sign In without filling inputs
      await tester.tap(find.widgetWithText(AppButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Mobile number is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('displays validation error for non-Indian or incomplete mobile number',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // Enter an invalid number starting with 2
      await tester.enterText(
        find.widgetWithText(TextFormField, '').first,
        '2345678901',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '').last,
        'Password123',
      );

      await tester.tap(find.widgetWithText(AppButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter a valid 10-digit Indian mobile number'),
        findsOneWidget,
      );
    });

    testWidgets('toggles password visibility when visibility icon button is clicked',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      final toggleFinder = find.byTooltip('Show password');
      expect(toggleFinder, findsOneWidget);

      // Tap show password
      await tester.tap(toggleFinder);
      await tester.pumpAndSettle();

      // Tooltip updates to 'Hide password'
      expect(find.byTooltip('Hide password'), findsOneWidget);
    });

    testWidgets('displays error banner when cubit emits LoginFailure', (tester) async {
      final config = MockConfig.instance;
      config.setLatencyEnabled(false);
      final repo = MockAuthRepository(harness: MockNetworkHarness(config: config));
      final cubit = LoginCubit(authRepository: repo);
      addTearDown(cubit.close);

      await tester.pumpWidget(buildTestableWidget(cubit: cubit));

      // Enter invalid credentials
      await tester.enterText(find.byType(TextFormField).first, '9876543210');
      await tester.enterText(find.byType(TextFormField).last, 'wrongpass');

      await tester.tap(find.widgetWithText(AppButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Invalid mobile number or password'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('invokes onLoginSuccess callback with session upon valid credentials',
        (tester) async {
      final config = MockConfig.instance;
      config.setLatencyEnabled(false);
      final repo = MockAuthRepository(harness: MockNetworkHarness(config: config));
      final cubit = LoginCubit(authRepository: repo);
      addTearDown(cubit.close);

      AuthSession? capturedSession;
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: cubit,
          onLoginSuccess: (session) => capturedSession = session,
        ),
      );

      // Enter valid credentials
      await tester.enterText(find.byType(TextFormField).first, '9876543210');
      await tester.enterText(find.byType(TextFormField).last, 'Password123');

      await tester.tap(find.widgetWithText(AppButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(capturedSession, isNotNull);
      expect(capturedSession?.name, equals('Alex Rivera'));
      expect(capturedSession?.availableRoles, contains(UserRole.player));
    });

    testWidgets('triggers onForgotPasswordPressed when Forgot Password link is tapped',
        (tester) async {
      bool forgotPasswordCalled = false;
      await tester.pumpWidget(
        buildTestableWidget(
          onForgotPassword: () => forgotPasswordCalled = true,
        ),
      );

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(forgotPasswordCalled, isTrue);
    });

    testWidgets('triggers onCreateAccountPressed when Create Account link is tapped',
        (tester) async {
      bool createAccountCalled = false;
      await tester.pumpWidget(
        buildTestableWidget(
          onCreateAccount: () => createAccountCalled = true,
        ),
      );

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(createAccountCalled, isTrue);
    });

    testWidgets('renders cleanly in dark mode', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(themeMode: ThemeMode.dark),
      );

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.byType(BrandLogoEmblem), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Sign In'), findsOneWidget);
    });

    testWidgets('mobile viewport (<600dp) renders direct content layout without outer AppCard',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AppCard), findsNothing);
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('desktop viewport (>1024dp) renders content wrapped in AppCard with max width constraint',
        (tester) async {
      tester.view.physicalSize = const Size(1280 * 1.0, 900 * 1.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AppCard), findsOneWidget);
      final cardFinder = find.byType(AppCard);
      final cardSize = tester.getSize(cardFinder);
      expect(cardSize.width, lessThanOrEqualTo(AppSpacing.maxFormWidth));
    });
  });

  group('LoginPage Navigation Integration Tests', () {
    late SessionCubit sessionCubit;
    late GoRouter router;

    setUp(() {
      sessionCubit = SessionCubit();
      router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: AppRoutes.login,
      );
    });

    tearDown(() {
      sessionCubit.close();
    });

    testWidgets('navigates to forgot-password route when link clicked', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password'), findsOneWidget);
    });

    testWidgets('navigates to register route when Create Account link clicked', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Create Player Account'), findsOneWidget);
    });

    testWidgets('successful login navigates to temporary placeholder destination (/auth/login-success)',
        (tester) async {
      final config = MockConfig.instance;
      config.setLatencyEnabled(false);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '9876543210');
      await tester.enterText(find.byType(TextFormField).last, 'Password123');

      await tester.tap(find.widgetWithText(AppButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Login Successful'), findsOneWidget);
      expect(find.text('Route Path: ${AppRoutes.loginSuccess}'), findsOneWidget);
    });
  });
}
