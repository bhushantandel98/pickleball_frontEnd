import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/mock/mock_config.dart';
import 'package:pickleball_platform/core/mock/mock_network_harness.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/identity/data/models/forgot_password_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/login_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/register_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/resend_otp_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/resend_password_reset_otp_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/reset_password_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/verify_otp_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/verify_password_reset_otp_request_model.dart';
import 'package:pickleball_platform/features/identity/data/repositories/mock_auth_repository.dart';
import 'package:pickleball_platform/features/identity/data/repositories/remote_auth_repository.dart';
import 'package:pickleball_platform/features/identity/domain/entities/auth_session.dart';
import 'package:pickleball_platform/features/identity/domain/entities/password_reset_entities.dart';
import 'package:pickleball_platform/features/identity/domain/entities/registration_entities.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/auth_repository.dart';
import 'package:pickleball_platform/features/identity/presentation/bloc/registration_cubit.dart';
import 'package:pickleball_platform/features/identity/presentation/pages/register_page.dart';
import 'package:pickleball_platform/features/identity/presentation/validators/registration_validators.dart';
import 'package:pickleball_platform/features/identity/presentation/widgets/brand_logo_emblem.dart';

void main() {
  group('Registration Validators Unit Tests', () {
    test('validateFullName requires non-empty string with at least 2 characters', () {
      expect(RegistrationValidators.validateFullName(null), equals('Full name is required'));
      expect(RegistrationValidators.validateFullName(''), equals('Full name is required'));
      expect(RegistrationValidators.validateFullName('   '), equals('Full name is required'));
      expect(RegistrationValidators.validateFullName('A'), equals('Full name must be at least 2 characters'));
      expect(RegistrationValidators.validateFullName('Alex Rivera'), isNull);
    });

    test('validatePhone enforces 10-digit Indian mobile format', () {
      expect(RegistrationValidators.validatePhone(null), equals('Mobile number is required'));
      expect(RegistrationValidators.validatePhone(''), equals('Mobile number is required'));
      expect(RegistrationValidators.validatePhone('12345'), equals('Enter a valid 10-digit Indian mobile number'));
      expect(RegistrationValidators.validatePhone('5550101010'), equals('Enter a valid 10-digit Indian mobile number'));
      expect(RegistrationValidators.validatePhone('9876543210'), isNull);
      expect(RegistrationValidators.validatePhone('8123456789'), isNull);
      expect(RegistrationValidators.validatePhone('7999888777'), isNull);
      expect(RegistrationValidators.validatePhone('6300112233'), isNull);
    });

    test('validatePassword requires at least 8 chars with letters and numbers', () {
      expect(RegistrationValidators.validatePassword(null), equals('Password is required'));
      expect(RegistrationValidators.validatePassword(''), equals('Password is required'));
      expect(RegistrationValidators.validatePassword('short1'), equals('Password must be at least 8 characters long'));
      expect(RegistrationValidators.validatePassword('lettersallonly'), equals('Password must contain both letters and numbers'));
      expect(RegistrationValidators.validatePassword('1234567890'), equals('Password must contain both letters and numbers'));
      expect(RegistrationValidators.validatePassword('Password123'), isNull);
    });

    test('validateConfirmPassword enforces matching password', () {
      expect(RegistrationValidators.validateConfirmPassword(null, 'Password123'), equals('Please confirm your password'));
      expect(RegistrationValidators.validateConfirmPassword('', 'Password123'), equals('Please confirm your password'));
      expect(RegistrationValidators.validateConfirmPassword('Different123', 'Password123'), equals('Passwords do not match'));
      expect(RegistrationValidators.validateConfirmPassword('Password123', 'Password123'), isNull);
    });

    test('validateOtp requires exactly 6 numeric digits', () {
      expect(RegistrationValidators.validateOtp(null), equals('Verification code is required'));
      expect(RegistrationValidators.validateOtp(''), equals('Verification code is required'));
      expect(RegistrationValidators.validateOtp('123'), equals('Enter a valid 6-digit verification code'));
      expect(RegistrationValidators.validateOtp('1234567'), equals('Enter a valid 6-digit verification code'));
      expect(RegistrationValidators.validateOtp('123456'), isNull);
    });
  });

  group('Registration DTO Models Unit Tests', () {
    test('RegisterRequestModel serializes with +91 country prefix and player role', () {
      const model = RegisterRequestModel(
        fullName: 'Rohit Sharma',
        phone: '9123456789',
        password: 'Password123',
      );

      expect(model.fullPhoneNumber, equals('+919123456789'));
      expect(model.rawPhone, equals('9123456789'));
      expect(model.toJson(), equals({
        'fullName': 'Rohit Sharma',
        'phone': '+919123456789',
        'password': 'Password123',
        'role': 'PLAYER',
      }));
    });

    test('VerifyOtpRequestModel serializes to JSON', () {
      const model = VerifyOtpRequestModel(
        phone: '+919123456789',
        otp: '123456',
        otpSessionId: 'sess_123',
        fullName: 'Rohit Sharma',
        password: 'Password123',
      );

      expect(model.toJson(), equals({
        'phone': '+919123456789',
        'otp': '123456',
        'otpSessionId': 'sess_123',
        'fullName': 'Rohit Sharma',
        'password': 'Password123',
      }));
    });

    test('ResendOtpRequestModel serializes to JSON', () {
      const model = ResendOtpRequestModel(
        phone: '+919123456789',
        otpSessionId: 'sess_123',
      );

      expect(model.toJson(), equals({
        'phone': '+919123456789',
        'otpSessionId': 'sess_123',
      }));
    });
  });

  group('Registration Repository Unit Tests', () {
    late MockConfig mockConfig;
    late MockAuthRepository repository;

    setUp(() {
      mockConfig = MockConfig.instance;
      mockConfig.setLatencyEnabled(false);
      mockConfig.clearSimulatedError();
      repository = MockAuthRepository(harness: MockNetworkHarness(config: mockConfig));
    });

    tearDown(() {
      mockConfig.setLatencyEnabled(true);
      mockConfig.clearSimulatedError();
    });

    test('initiateRegistration returns conflict error for existing mobile number', () async {
      const request = RegisterRequestModel(
        fullName: 'Alex Duplicate',
        phone: '9876543210', // Existing mock account
        password: 'Password123',
      );

      final result = await repository.initiateRegistration(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, contains('already exists'));
    });

    test('initiateRegistration returns RegistrationInitiatedEntity for new mobile', () async {
      const request = RegisterRequestModel(
        fullName: 'Karan Patel',
        phone: '9123456789', // New number
        password: 'Password123',
      );

      final result = await repository.initiateRegistration(request);

      expect(result.isSuccess, isTrue);
      final initiated = result.dataOrNull!;
      expect(initiated.phone, equals('+919123456789'));
      expect(initiated.resendCountdownSeconds, equals(30));
    });

    test('verifyOtp succeeds with valid code (123456) and assigns strictly Player role', () async {
      const request = VerifyOtpRequestModel(
        phone: '+919123456789',
        otp: '123456',
        otpSessionId: 'sess_123',
        fullName: 'Karan Patel',
        password: 'Password123',
      );

      final result = await repository.verifyOtp(request);

      expect(result.isSuccess, isTrue);
      final success = result.dataOrNull!;
      expect(success.fullName, equals('Karan Patel'));
      expect(success.assignedRole, equals(UserRole.player));
    });

    test('verifyOtp returns failure for invalid code', () async {
      const request = VerifyOtpRequestModel(
        phone: '+919123456789',
        otp: '654321', // Wrong code
        otpSessionId: 'sess_123',
        fullName: 'Karan Patel',
        password: 'Password123',
      );

      final result = await repository.verifyOtp(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('Invalid verification code'));
    });

    test('verifyOtp returns failure for expired code (000000)', () async {
      const request = VerifyOtpRequestModel(
        phone: '+919123456789',
        otp: '000000', // Expired code simulation
        otpSessionId: 'sess_123',
        fullName: 'Karan Patel',
        password: 'Password123',
      );

      final result = await repository.verifyOtp(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('expired'));
    });

    test('RemoteAuthRepository placeholders return safe FailureResult without throwing', () async {
      const remoteRepo = RemoteAuthRepository();
      const regReq = RegisterRequestModel(fullName: 'A', phone: '9123456789', password: 'P');
      const verifyReq = VerifyOtpRequestModel(
        phone: '+91',
        otp: '123456',
        otpSessionId: 's',
        fullName: 'A',
        password: 'P',
      );
      const resendReq = ResendOtpRequestModel(phone: '+91', otpSessionId: 's');

      final regResult = await remoteRepo.initiateRegistration(regReq);
      final verifyResult = await remoteRepo.verifyOtp(verifyReq);
      final resendResult = await remoteRepo.resendOtp(resendReq);

      expect(regResult.isFailure, isTrue);
      expect(verifyResult.isFailure, isTrue);
      expect(resendResult.isFailure, isTrue);
      expect(regResult.failureOrNull?.statusCode, equals(503));
    });
  });

  group('RegistrationCubit State Transitions', () {
    late MockConfig mockConfig;
    late MockAuthRepository repository;
    late RegistrationCubit cubit;

    setUp(() {
      mockConfig = MockConfig.instance;
      mockConfig.setLatencyEnabled(false);
      mockConfig.clearSimulatedError();
      repository = MockAuthRepository(harness: MockNetworkHarness(config: mockConfig));
      cubit = RegistrationCubit(authRepository: repository);
    });

    tearDown(() {
      cubit.close();
      mockConfig.setLatencyEnabled(true);
      mockConfig.clearSimulatedError();
    });

    test('initial state is RegistrationFormState', () {
      expect(cubit.state, equals(const RegistrationFormState()));
    });

    test('submitRegistrationForm emits [Submitting, RegistrationOtpState] on success', () async {
      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<RegistrationFormState>().having((s) => s.isSubmitting, 'isSubmitting', isTrue),
          isA<RegistrationOtpState>(),
        ]),
      );

      await cubit.submitRegistrationForm(
        fullName: 'Karan Patel',
        phone: '9123456789',
        password: 'Password123',
      );
    });

    test('submitRegistrationForm emits failure message on mobile conflict', () async {
      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<RegistrationFormState>().having((s) => s.isSubmitting, 'isSubmitting', isTrue),
          isA<RegistrationFormState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            contains('already exists'),
          ),
        ]),
      );

      await cubit.submitRegistrationForm(
        fullName: 'Alex Rivera',
        phone: '9876543210',
        password: 'Password123',
      );
    });

    test('backToForm returns to RegistrationFormState preserving inputs', () async {
      await cubit.submitRegistrationForm(
        fullName: 'Karan Patel',
        phone: '9123456789',
        password: 'Password123',
      );
      expect(cubit.state, isA<RegistrationOtpState>());

      cubit.backToForm();
      expect(cubit.state, isA<RegistrationFormState>());
      final formState = cubit.state as RegistrationFormState;
      expect(formState.initialFullName, equals('Karan Patel'));
      expect(formState.initialPhone, equals('9123456789'));
    });

    test('resendOtp updates otpSessionId from session A to session B and subsequent verify uses session B', () async {
      final testRepo = _SessionSwitchingAuthRepository();
      final testCubit = RegistrationCubit(authRepository: testRepo);
      addTearDown(() => testCubit.close());

      // 1. Initiate registration with session ID A
      await testCubit.submitRegistrationForm(
        fullName: 'Session User',
        phone: '9876543210',
        password: 'Password123',
      );

      expect(testCubit.state, isA<RegistrationOtpState>());
      final stateA = testCubit.state as RegistrationOtpState;
      expect(stateA.otpSession.otpSessionId, equals('session_id_A'));
      expect(stateA.canResend, isTrue);

      // 2. Resend OTP and return session ID B
      await testCubit.resendOtp();
      testCubit.cancelCountdownTimer();

      expect(testCubit.state, isA<RegistrationOtpState>());
      final stateB = testCubit.state as RegistrationOtpState;
      expect(stateB.otpSession.otpSessionId, equals('session_id_B'));
      expect(testRepo.capturedResendRequest?.otpSessionId, equals('session_id_A'));

      // 3. Verify that the subsequent OTP request uses session ID B
      await testCubit.submitOtp('123456');

      expect(testRepo.capturedVerifyRequest, isNotNull);
      expect(testRepo.capturedVerifyRequest?.otpSessionId, equals('session_id_B'));
      expect(testCubit.state, isA<RegistrationCompletedState>());
    });
  });

  group('RegisterPage UI & Widget Tests', () {
    Widget buildTestableWidget({
      RegistrationCubit? cubit,
      ThemeMode themeMode = ThemeMode.light,
      VoidCallback? onNavigateToLogin,
      void Function(PlayerRegistrationSuccessEntity)? onRegistrationComplete,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: RegisterPage(
          cubit: cubit,
          onNavigateToLogin: onNavigateToLogin,
          onRegistrationComplete: onRegistrationComplete,
        ),
      );
    }

    testWidgets('renders all Step 1 registration form fields and CTAs', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.byType(BrandLogoEmblem), findsOneWidget);
      expect(find.text('Create Player Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('+91 '), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Send Verification Code'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('displays inline validation errors on empty form submission', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.widgetWithText(AppButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Mobile number is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);
    });

    testWidgets('displays password mismatch validation error', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // Enter fields with mismatched passwords
      await tester.enterText(find.byType(TextFormField).at(0), 'Karan Patel');
      await tester.enterText(find.byType(TextFormField).at(1), '9123456789');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'DifferentPassword123');

      await tester.tap(find.widgetWithText(AppButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('displays conflict error banner when mobile already exists', (tester) async {
      final config = MockConfig.instance;
      config.setLatencyEnabled(false);
      final repo = MockAuthRepository(harness: MockNetworkHarness(config: config));
      final cubit = RegistrationCubit(authRepository: repo);
      addTearDown(cubit.close);

      await tester.pumpWidget(buildTestableWidget(cubit: cubit));

      // Enter existing mock phone
      await tester.enterText(find.byType(TextFormField).at(0), 'Alex Rivera');
      await tester.enterText(find.byType(TextFormField).at(1), '9876543210');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123');

      await tester.tap(find.widgetWithText(AppButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      expect(find.textContaining('already exists'), findsOneWidget);
    });

    testWidgets('valid form transitions to Step 2 OTP screen', (tester) async {
      final config = MockConfig.instance;
      config.setLatencyEnabled(false);
      final repo = MockAuthRepository(harness: MockNetworkHarness(config: config));
      final cubit = RegistrationCubit(authRepository: repo);
      addTearDown(cubit.close);

      await tester.pumpWidget(buildTestableWidget(cubit: cubit));

      // Enter new phone
      await tester.enterText(find.byType(TextFormField).at(0), 'Karan Patel');
      await tester.enterText(find.byType(TextFormField).at(1), '9123456789');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123');

      await tester.tap(find.widgetWithText(AppButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      expect(find.text('Verify Mobile Number'), findsOneWidget);
      expect(find.textContaining('+919123456789'), findsOneWidget);
      expect(find.text('Change mobile number'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Verify & Complete Registration'), findsOneWidget);

      cubit.cancelCountdownTimer();
    });

    testWidgets('Step 2 Change mobile number returns to form with populated fields', (tester) async {
      final config = MockConfig.instance;
      config.setLatencyEnabled(false);
      final repo = MockAuthRepository(harness: MockNetworkHarness(config: config));
      final cubit = RegistrationCubit(authRepository: repo);
      addTearDown(cubit.close);

      await tester.pumpWidget(buildTestableWidget(cubit: cubit));

      await tester.enterText(find.byType(TextFormField).at(0), 'Karan Patel');
      await tester.enterText(find.byType(TextFormField).at(1), '9123456789');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123');

      await tester.tap(find.widgetWithText(AppButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      expect(find.text('Verify Mobile Number'), findsOneWidget);

      await tester.tap(find.text('Change mobile number'));
      await tester.pumpAndSettle();

      expect(find.text('Create Player Account'), findsOneWidget);
      expect(find.text('Karan Patel'), findsOneWidget);
    });

    testWidgets('Step 2 displays error on invalid OTP code', (tester) async {
      final config = MockConfig.instance;
      config.setLatencyEnabled(false);
      final repo = MockAuthRepository(harness: MockNetworkHarness(config: config));
      final cubit = RegistrationCubit(authRepository: repo);
      addTearDown(cubit.close);

      await tester.pumpWidget(buildTestableWidget(cubit: cubit));

      await tester.enterText(find.byType(TextFormField).at(0), 'Karan Patel');
      await tester.enterText(find.byType(TextFormField).at(1), '9123456789');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123');

      await tester.tap(find.widgetWithText(AppButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      // Enter invalid OTP
      await tester.enterText(find.byType(TextFormField).first, '654321');
      await tester.tap(find.widgetWithText(AppButton, 'Verify & Complete Registration'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Invalid verification code'), findsOneWidget);

      cubit.cancelCountdownTimer();
    });

    testWidgets('Step 2 valid OTP (123456) completes registration and renders Step 3 Success', (tester) async {
      final config = MockConfig.instance;
      config.setLatencyEnabled(false);
      final repo = MockAuthRepository(harness: MockNetworkHarness(config: config));
      final cubit = RegistrationCubit(authRepository: repo);
      addTearDown(cubit.close);

      PlayerRegistrationSuccessEntity? capturedSuccess;

      await tester.pumpWidget(
        buildTestableWidget(
          cubit: cubit,
          onRegistrationComplete: (entity) => capturedSuccess = entity,
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Karan Patel');
      await tester.enterText(find.byType(TextFormField).at(1), '9123456789');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123');

      await tester.tap(find.widgetWithText(AppButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      // Enter valid OTP
      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.tap(find.widgetWithText(AppButton, 'Verify & Complete Registration'));
      await tester.pumpAndSettle();

      // Step 3: Success Screen
      expect(find.text('Account Created!'), findsOneWidget);
      expect(find.textContaining('Karan Patel'), findsWidgets);
      expect(find.text('Player Role'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Proceed to Sign In'), findsOneWidget);
      expect(capturedSuccess, isNotNull);
      expect(capturedSuccess?.assignedRole, equals(UserRole.player));
    });

    testWidgets('tapping Proceed to Sign In triggers login navigation', (tester) async {
      final config = MockConfig.instance;
      config.setLatencyEnabled(false);
      final repo = MockAuthRepository(harness: MockNetworkHarness(config: config));
      final cubit = RegistrationCubit(authRepository: repo);
      addTearDown(cubit.close);

      bool loginNavigated = false;

      await tester.pumpWidget(
        buildTestableWidget(
          cubit: cubit,
          onNavigateToLogin: () => loginNavigated = true,
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'Karan Patel');
      await tester.enterText(find.byType(TextFormField).at(1), '9123456789');
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123');
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123');

      await tester.tap(find.widgetWithText(AppButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '123456');
      await tester.tap(find.widgetWithText(AppButton, 'Verify & Complete Registration'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'Proceed to Sign In'));
      await tester.pumpAndSettle();

      expect(loginNavigated, isTrue);
    });

    testWidgets('renders cleanly in dark mode', (tester) async {
      await tester.pumpWidget(buildTestableWidget(themeMode: ThemeMode.dark));

      expect(find.text('Create Player Account'), findsOneWidget);
      expect(find.byType(BrandLogoEmblem), findsOneWidget);
    });

    testWidgets('desktop viewport (>1024dp) wraps content in AppCard with max width constraint', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
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
}

class _SessionSwitchingAuthRepository implements AuthRepository {
  VerifyOtpRequestModel? capturedVerifyRequest;
  ResendOtpRequestModel? capturedResendRequest;
  final String sessionA = 'session_id_A';
  final String sessionB = 'session_id_B';

  @override
  Future<Result<AuthSession>> login(LoginRequestModel request) async =>
      throw UnimplementedError();

  @override
  Future<Result<RegistrationInitiatedEntity>> initiateRegistration(
    RegisterRequestModel request,
  ) async {
    return Success(
      RegistrationInitiatedEntity(
        phone: request.fullPhoneNumber,
        otpSessionId: sessionA,
        resendCountdownSeconds: 0,
      ),
    );
  }

  @override
  Future<Result<RegistrationInitiatedEntity>> resendOtp(
    ResendOtpRequestModel request,
  ) async {
    capturedResendRequest = request;
    return Success(
      RegistrationInitiatedEntity(
        phone: request.phone,
        otpSessionId: sessionB,
        resendCountdownSeconds: 30,
      ),
    );
  }

  @override
  Future<Result<PlayerRegistrationSuccessEntity>> verifyOtp(
    VerifyOtpRequestModel request,
  ) async {
    capturedVerifyRequest = request;
    return Success(
      PlayerRegistrationSuccessEntity(
        userId: 'usr_test',
        fullName: request.fullName,
        phone: request.phone,
        assignedRole: UserRole.player,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<Result<PasswordResetInitiatedEntity>> initiatePasswordReset(
    ForgotPasswordRequestModel request,
  ) =>
      throw UnimplementedError();

  @override
  Future<Result<PasswordResetInitiatedEntity>> resendPasswordResetOtp(
    ResendPasswordResetOtpRequestModel request,
  ) =>
      throw UnimplementedError();

  @override
  Future<Result<PasswordResetVerifiedEntity>> verifyPasswordResetOtp(
    VerifyPasswordResetOtpRequestModel request,
  ) =>
      throw UnimplementedError();

  @override
  Future<Result<PasswordResetSuccessEntity>> completePasswordReset(
    ResetPasswordRequestModel request,
  ) =>
      throw UnimplementedError();
}
