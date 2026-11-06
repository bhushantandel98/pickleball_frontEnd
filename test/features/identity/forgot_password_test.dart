import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:pickleball_platform/features/identity/presentation/bloc/forgot_password_cubit.dart';
import 'package:pickleball_platform/features/identity/presentation/pages/forgot_password_page.dart';
import 'package:pickleball_platform/features/identity/presentation/validators/forgot_password_validators.dart';
import 'package:pickleball_platform/features/identity/presentation/widgets/brand_logo_emblem.dart';

void main() {
  group('ForgotPasswordValidators Unit Tests', () {
    test('validatePhone requires non-empty 10-digit Indian mobile number', () {
      expect(ForgotPasswordValidators.validatePhone(null), equals('Mobile number is required'));
      expect(ForgotPasswordValidators.validatePhone(''), equals('Mobile number is required'));
      expect(ForgotPasswordValidators.validatePhone('123'), equals('Enter a valid 10-digit Indian mobile number'));
      expect(ForgotPasswordValidators.validatePhone('1234567890'), equals('Enter a valid 10-digit Indian mobile number'));
      expect(ForgotPasswordValidators.validatePhone('9876543210'), isNull);
      expect(ForgotPasswordValidators.validatePhone('6123456789'), isNull);
    });

    test('validateOtp requires exactly 6 numeric digits', () {
      expect(ForgotPasswordValidators.validateOtp(null), equals('Verification code is required'));
      expect(ForgotPasswordValidators.validateOtp(''), equals('Verification code is required'));
      expect(ForgotPasswordValidators.validateOtp('12345'), equals('Verification code must be 6 digits'));
      expect(ForgotPasswordValidators.validateOtp('1234567'), equals('Verification code must be 6 digits'));
      expect(ForgotPasswordValidators.validateOtp('abcdef'), equals('Verification code must be 6 digits'));
      expect(ForgotPasswordValidators.validateOtp('123456'), isNull);
    });

    test('validatePassword requires at least 8 chars with letters and numbers', () {
      expect(ForgotPasswordValidators.validatePassword(null), equals('Password is required'));
      expect(ForgotPasswordValidators.validatePassword(''), equals('Password is required'));
      expect(ForgotPasswordValidators.validatePassword('short'), equals('Password must be at least 8 characters'));
      expect(ForgotPasswordValidators.validatePassword('onlyletters'), equals('Password must contain at least one letter and one number'));
      expect(ForgotPasswordValidators.validatePassword('12345678'), equals('Password must contain at least one letter and one number'));
      expect(ForgotPasswordValidators.validatePassword('ValidPass123'), isNull);
    });

    test('validateConfirmPassword enforces exact match with original password', () {
      expect(ForgotPasswordValidators.validateConfirmPassword('Pass1234', null), equals('Confirm password is required'));
      expect(ForgotPasswordValidators.validateConfirmPassword('Pass1234', ''), equals('Confirm password is required'));
      expect(ForgotPasswordValidators.validateConfirmPassword('Pass1234', 'Mismatch1'), equals('Passwords do not match'));
      expect(ForgotPasswordValidators.validateConfirmPassword('Pass1234', 'Pass1234'), isNull);
    });
  });

  group('ForgotPassword DTO Models Unit Tests', () {
    test('ForgotPasswordRequestModel serializes with +91 country prefix', () {
      const model = ForgotPasswordRequestModel(phone: '9876543210');
      expect(model.fullPhoneNumber, equals('+919876543210'));
      expect(model.rawPhone, equals('9876543210'));
      expect(model.toJson(), equals({
        'phone': '+919876543210',
        'countryCode': '+91',
      }));
    });

    test('ResendPasswordResetOtpRequestModel serializes to JSON', () {
      const model = ResendPasswordResetOtpRequestModel(
        phone: '+919876543210',
        resetSessionId: 'sess_reset_123',
      );
      expect(model.toJson(), equals({
        'phone': '+919876543210',
        'resetSessionId': 'sess_reset_123',
      }));
    });

    test('VerifyPasswordResetOtpRequestModel serializes to JSON', () {
      const model = VerifyPasswordResetOtpRequestModel(
        phone: '+919876543210',
        otp: '123456',
        resetSessionId: 'sess_reset_123',
      );
      expect(model.toJson(), equals({
        'phone': '+919876543210',
        'otp': '123456',
        'resetSessionId': 'sess_reset_123',
      }));
    });

    test('ResetPasswordRequestModel serializes to JSON and redacts sensitive data in toString()', () {
      const model = ResetPasswordRequestModel(
        phone: '+919876543210',
        resetSessionId: 'sess_reset_123',
        resetToken: 'token_secret_123',
        newPassword: 'SuperSecretPassword123',
      );
      expect(model.toJson(), equals({
        'phone': '+919876543210',
        'resetSessionId': 'sess_reset_123',
        'resetToken': 'token_secret_123',
        'newPassword': 'SuperSecretPassword123',
      }));
      expect(model.toString(), contains('[REDACTED]'));
      expect(model.toString(), isNot(contains('SuperSecretPassword123')));
      expect(model.toString(), isNot(contains('token_secret_123')));
    });
  });

  group('ForgotPassword Repository Unit Tests', () {
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

    test('initiatePasswordReset returns not found for non-existent mobile number', () async {
      const request = ForgotPasswordRequestModel(phone: '9999999999');
      final result = await repository.initiatePasswordReset(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
      expect(result.failureOrNull?.message, contains('No account found'));
    });

    test('initiatePasswordReset returns PasswordResetInitiatedEntity for valid mobile number', () async {
      const request = ForgotPasswordRequestModel(phone: '9876543210');
      final result = await repository.initiatePasswordReset(request);

      expect(result.isSuccess, isTrue);
      final initiated = result.dataOrNull!;
      expect(initiated.phone, equals('+919876543210'));
      expect(initiated.resetSessionId, equals('mock_reset_session_9876543210'));
      expect(initiated.resendCountdownSeconds, equals(30));
    });

    test('resendPasswordResetOtp returns fresh session and countdown', () async {
      const request = ResendPasswordResetOtpRequestModel(
        phone: '+919876543210',
        resetSessionId: 'mock_reset_session_9876543210',
      );
      final result = await repository.resendPasswordResetOtp(request);

      expect(result.isSuccess, isTrue);
      final resent = result.dataOrNull!;
      expect(resent.resetSessionId, contains('_resend'));
      expect(resent.resendCountdownSeconds, equals(30));
    });

    test('verifyPasswordResetOtp succeeds with valid code (123456)', () async {
      const request = VerifyPasswordResetOtpRequestModel(
        phone: '+919876543210',
        otp: '123456',
        resetSessionId: 'mock_reset_session_9876543210',
      );
      final result = await repository.verifyPasswordResetOtp(request);

      expect(result.isSuccess, isTrue);
      final verified = result.dataOrNull!;
      expect(verified.resetToken, contains('mock_reset_token_'));
      expect(verified.resetSessionId, equals('mock_reset_session_9876543210'));
    });

    test('verifyPasswordResetOtp returns failure for invalid code', () async {
      const request = VerifyPasswordResetOtpRequestModel(
        phone: '+919876543210',
        otp: '999999',
        resetSessionId: 'mock_reset_session_9876543210',
      );
      final result = await repository.verifyPasswordResetOtp(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, contains('Invalid verification code'));
    });

    test('verifyPasswordResetOtp returns failure for expired code (000000)', () async {
      const request = VerifyPasswordResetOtpRequestModel(
        phone: '+919876543210',
        otp: '000000',
        resetSessionId: 'mock_reset_session_9876543210',
      );
      final result = await repository.verifyPasswordResetOtp(request);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull?.message, contains('expired'));
    });

    test('completePasswordReset completes successfully with valid password', () async {
      const request = ResetPasswordRequestModel(
        phone: '+919876543210',
        resetSessionId: 'mock_reset_session_9876543210',
        resetToken: 'mock_token',
        newPassword: 'NewPassword123',
      );
      final result = await repository.completePasswordReset(request);

      expect(result.isSuccess, isTrue);
      final success = result.dataOrNull!;
      expect(success.message, contains('reset successfully'));
      expect(success.phone, equals('+919876543210'));
    });

    test('RemoteAuthRepository placeholders return safe FailureResult without throwing', () async {
      const remoteRepo = RemoteAuthRepository();
      const initReq = ForgotPasswordRequestModel(phone: '9876543210');
      const resendReq = ResendPasswordResetOtpRequestModel(phone: '+91', resetSessionId: 's');
      const verifyReq = VerifyPasswordResetOtpRequestModel(phone: '+91', otp: '123456', resetSessionId: 's');
      const resetReq = ResetPasswordRequestModel(
        phone: '+91',
        resetSessionId: 's',
        resetToken: 't',
        newPassword: 'NewPassword123',
      );

      final initResult = await remoteRepo.initiatePasswordReset(initReq);
      final resendResult = await remoteRepo.resendPasswordResetOtp(resendReq);
      final verifyResult = await remoteRepo.verifyPasswordResetOtp(verifyReq);
      final resetResult = await remoteRepo.completePasswordReset(resetReq);

      expect(initResult.isFailure, isTrue);
      expect(resendResult.isFailure, isTrue);
      expect(verifyResult.isFailure, isTrue);
      expect(resetResult.isFailure, isTrue);
      expect(initResult.failureOrNull?.statusCode, equals(503));
    });
  });

  group('ForgotPasswordCubit State Transitions', () {
    late MockConfig mockConfig;
    late MockAuthRepository repository;
    late ForgotPasswordCubit cubit;

    setUp(() {
      mockConfig = MockConfig.instance;
      mockConfig.setLatencyEnabled(false);
      mockConfig.clearSimulatedError();
      repository = MockAuthRepository(harness: MockNetworkHarness(config: mockConfig));
      cubit = ForgotPasswordCubit(authRepository: repository);
    });

    tearDown(() {
      cubit.close();
      mockConfig.setLatencyEnabled(true);
      mockConfig.clearSimulatedError();
    });

    test('initial state is ForgotPasswordPhoneState', () {
      expect(cubit.state, equals(const ForgotPasswordPhoneState()));
    });

    test('submitPhone emits [Submitting, ForgotPasswordOtpState] on success', () async {
      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ForgotPasswordPhoneState>().having((s) => s.isSubmitting, 'isSubmitting', isTrue),
          isA<ForgotPasswordOtpState>(),
        ]),
      );

      await cubit.submitPhone('9876543210');
    });

    test('submitPhone emits failure on non-existent mobile number', () async {
      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<ForgotPasswordPhoneState>().having((s) => s.isSubmitting, 'isSubmitting', isTrue),
          isA<ForgotPasswordPhoneState>().having(
            (s) => s.errorMessage,
            'errorMessage',
            contains('No account found'),
          ),
        ]),
      );

      await cubit.submitPhone('9999999999');
    });

    test('backToPhone returns to ForgotPasswordPhoneState preserving entered phone', () async {
      await cubit.submitPhone('9876543210');
      expect(cubit.state, isA<ForgotPasswordOtpState>());

      cubit.backToPhone();
      expect(cubit.state, isA<ForgotPasswordPhoneState>());
      final phoneState = cubit.state as ForgotPasswordPhoneState;
      expect(phoneState.initialPhone, equals('9876543210'));
    });

    test('resendOtp updates resetSession and restarts countdown', () async {
      await cubit.submitPhone('9876543210');
      expect(cubit.state, isA<ForgotPasswordOtpState>());

      // Manually set countdown to 0 to simulate expired cooldown
      final otpState = cubit.state as ForgotPasswordOtpState;
      cubit.cancelCountdownTimer();

      final zeroCountdownState = otpState.copyWith(countdown: 0);
      expect(zeroCountdownState.canResend, isTrue);

      // Re-emit using private or verify through resend
      // We can test full flow by calling resendOtp when canResend is true
      final testRepo = _TrackingResetAuthRepository();
      final testCubit = ForgotPasswordCubit(authRepository: testRepo);
      addTearDown(() => testCubit.close());

      await testCubit.submitPhone('9876543210');
      testCubit.cancelCountdownTimer();

      await testCubit.resendOtp();
      testCubit.cancelCountdownTimer();

      expect(testCubit.state, isA<ForgotPasswordOtpState>());
      final updatedState = testCubit.state as ForgotPasswordOtpState;
      expect(updatedState.resetSession.resetSessionId, equals('session_B'));

      // Submit OTP uses the updated session ID
      await testCubit.submitOtp('123456');
      expect(testRepo.lastVerifyRequest?.resetSessionId, equals('session_B'));
    });

    test('submitNewPassword transitions to ForgotPasswordSuccessState upon matching passwords', () async {
      await cubit.submitPhone('9876543210');
      cubit.cancelCountdownTimer();

      await cubit.submitOtp('123456');
      expect(cubit.state, isA<ForgotPasswordNewPasswordState>());

      await cubit.submitNewPassword(
        newPassword: 'NewSecurePassword123',
        confirmPassword: 'NewSecurePassword123',
      );

      expect(cubit.state, isA<ForgotPasswordSuccessState>());
      final successState = cubit.state as ForgotPasswordSuccessState;
      expect(successState.success.phone, equals('+919876543210'));
    });
  });

  group('ForgotPasswordPage UI & Widget Tests', () {
    Widget buildTestableWidget({
      ForgotPasswordCubit? cubit,
      ThemeMode themeMode = ThemeMode.light,
      VoidCallback? onNavigateToLogin,
      void Function(PasswordResetSuccessEntity)? onResetComplete,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: ForgotPasswordPage(
          cubit: cubit,
          onNavigateToLogin: onNavigateToLogin,
          onResetComplete: onResetComplete,
        ),
      );
    }

    testWidgets('renders all Step 1 fields and controls', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.byType(BrandLogoEmblem), findsOneWidget);
      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('+91 '), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Send Verification Code'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('displays inline validation error on empty phone submission', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.widgetWithText(AppButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      expect(find.text('Mobile Number is required'), findsNothing);
      expect(find.text('Mobile number is required'), findsOneWidget);
    });

    testWidgets('displays error banner when mobile number is not found', (tester) async {
      final mockConfig = MockConfig.instance;
      mockConfig.setLatencyEnabled(false);
      final repo = MockAuthRepository(harness: MockNetworkHarness(config: mockConfig));
      final cubit = ForgotPasswordCubit(authRepository: repo);
      addTearDown(() {
        cubit.close();
        mockConfig.setLatencyEnabled(true);
      });

      await tester.pumpWidget(buildTestableWidget(cubit: cubit));

      await tester.enterText(find.widgetWithText(TextField, ''), '9999999999');
      await tester.tap(find.widgetWithText(AppButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      expect(find.textContaining('No account found'), findsOneWidget);
    });

    testWidgets('valid phone submission transitions to Step 2 OTP screen', (tester) async {
      final mockConfig = MockConfig.instance;
      mockConfig.setLatencyEnabled(false);
      final repo = MockAuthRepository(harness: MockNetworkHarness(config: mockConfig));
      final cubit = ForgotPasswordCubit(authRepository: repo);
      addTearDown(() {
        cubit.cancelCountdownTimer();
        cubit.close();
        mockConfig.setLatencyEnabled(true);
      });

      await tester.pumpWidget(buildTestableWidget(cubit: cubit));

      await tester.enterText(find.widgetWithText(TextField, ''), '9876543210');
      await tester.tap(find.widgetWithText(AppButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      expect(find.text('Verify Mobile Number'), findsOneWidget);
      expect(find.text('+919876543210'), findsOneWidget);
      expect(find.text('6-Digit Verification Code'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Verify Code'), findsOneWidget);

      cubit.cancelCountdownTimer();
    });

    testWidgets('Step 2 Change mobile number button returns to Step 1 preserving entered number', (tester) async {
      final mockConfig = MockConfig.instance;
      mockConfig.setLatencyEnabled(false);
      final repo = MockAuthRepository(harness: MockNetworkHarness(config: mockConfig));
      final cubit = ForgotPasswordCubit(authRepository: repo);
      addTearDown(() {
        cubit.close();
        mockConfig.setLatencyEnabled(true);
      });

      await tester.pumpWidget(buildTestableWidget(cubit: cubit));

      await tester.enterText(find.widgetWithText(TextField, ''), '9876543210');
      await tester.tap(find.widgetWithText(AppButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      expect(find.text('Verify Mobile Number'), findsOneWidget);

      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
    });

    testWidgets('Step 2 displays error on invalid OTP code', (tester) async {
      final mockConfig = MockConfig.instance;
      mockConfig.setLatencyEnabled(false);
      final repo = MockAuthRepository(harness: MockNetworkHarness(config: mockConfig));
      final cubit = ForgotPasswordCubit(authRepository: repo);
      addTearDown(() {
        cubit.close();
        mockConfig.setLatencyEnabled(true);
      });

      await tester.pumpWidget(buildTestableWidget(cubit: cubit));

      await tester.enterText(find.widgetWithText(TextField, ''), '9876543210');
      await tester.tap(find.widgetWithText(AppButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      // Enter invalid OTP
      await tester.enterText(find.widgetWithText(TextField, ''), '999999');
      await tester.tap(find.widgetWithText(AppButton, 'Verify Code'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Invalid verification code'), findsOneWidget);

      cubit.cancelCountdownTimer();
    });

    testWidgets('Step 2 valid OTP transitions to Step 3 Set New Password', (tester) async {
      final mockConfig = MockConfig.instance;
      mockConfig.setLatencyEnabled(false);
      final repo = MockAuthRepository(harness: MockNetworkHarness(config: mockConfig));
      final cubit = ForgotPasswordCubit(authRepository: repo);
      addTearDown(() {
        cubit.cancelCountdownTimer();
        cubit.close();
        mockConfig.setLatencyEnabled(true);
      });

      await tester.pumpWidget(buildTestableWidget(cubit: cubit));

      await tester.enterText(find.widgetWithText(TextField, ''), '9876543210');
      await tester.tap(find.widgetWithText(AppButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, ''), '123456');
      await tester.tap(find.widgetWithText(AppButton, 'Verify Code'));
      await tester.pumpAndSettle();

      expect(find.text('Set New Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Reset Password'), findsOneWidget);
    });

    testWidgets('Step 3 displays validation error on mismatched passwords', (tester) async {
      final mockConfig = MockConfig.instance;
      mockConfig.setLatencyEnabled(false);
      final repo = MockAuthRepository(harness: MockNetworkHarness(config: mockConfig));
      final cubit = ForgotPasswordCubit(authRepository: repo);
      addTearDown(() {
        cubit.cancelCountdownTimer();
        cubit.close();
        mockConfig.setLatencyEnabled(true);
      });

      await tester.pumpWidget(buildTestableWidget(cubit: cubit));

      await tester.enterText(find.widgetWithText(TextField, ''), '9876543210');
      await tester.tap(find.widgetWithText(AppButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, ''), '123456');
      await tester.tap(find.widgetWithText(AppButton, 'Verify Code'));
      await tester.pumpAndSettle();

      // Enter mismatched passwords
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Password123');
      await tester.enterText(textFields.at(1), 'DifferentPassword456');

      await tester.tap(find.widgetWithText(AppButton, 'Reset Password'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Step 3 valid password submission renders Step 4 Success and navigates to Login', (tester) async {
      final mockConfig = MockConfig.instance;
      mockConfig.setLatencyEnabled(false);
      final repo = MockAuthRepository(harness: MockNetworkHarness(config: mockConfig));
      final cubit = ForgotPasswordCubit(authRepository: repo);
      bool loginNavigated = false;
      addTearDown(() {
        cubit.cancelCountdownTimer();
        cubit.close();
        mockConfig.setLatencyEnabled(true);
      });

      await tester.pumpWidget(
        buildTestableWidget(
          cubit: cubit,
          onNavigateToLogin: () => loginNavigated = true,
        ),
      );

      await tester.enterText(find.widgetWithText(TextField, ''), '9876543210');
      await tester.tap(find.widgetWithText(AppButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, ''), '123456');
      await tester.tap(find.widgetWithText(AppButton, 'Verify Code'));
      await tester.pumpAndSettle();

      // Enter matching passwords
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'NewSecretPass123');
      await tester.enterText(textFields.at(1), 'NewSecretPass123');

      await tester.tap(find.widgetWithText(AppButton, 'Reset Password'));
      await tester.pumpAndSettle();

      expect(find.text('Password Reset Successful'), findsOneWidget);
      expect(find.text('+919876543210'), findsOneWidget);
      expect(find.text('Password Updated'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'Sign In with New Password'), findsOneWidget);

      await tester.tap(find.widgetWithText(AppButton, 'Sign In with New Password'));
      await tester.pumpAndSettle();

      expect(loginNavigated, isTrue);
    });

    testWidgets('renders cleanly in dark mode', (tester) async {
      await tester.pumpWidget(buildTestableWidget(themeMode: ThemeMode.dark));

      expect(find.text('Forgot Password'), findsOneWidget);
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

class _TrackingResetAuthRepository implements AuthRepository {
  VerifyPasswordResetOtpRequestModel? lastVerifyRequest;
  ResendPasswordResetOtpRequestModel? lastResendRequest;
  final String sessionA = 'session_A';
  final String sessionB = 'session_B';

  @override
  Future<Result<AuthSession>> login(LoginRequestModel request) =>
      throw UnimplementedError();

  @override
  Future<Result<RegistrationInitiatedEntity>> initiateRegistration(
    RegisterRequestModel request,
  ) =>
      throw UnimplementedError();

  @override
  Future<Result<PlayerRegistrationSuccessEntity>> verifyOtp(
    VerifyOtpRequestModel request,
  ) =>
      throw UnimplementedError();

  @override
  Future<Result<RegistrationInitiatedEntity>> resendOtp(
    ResendOtpRequestModel request,
  ) =>
      throw UnimplementedError();

  @override
  Future<Result<PasswordResetInitiatedEntity>> initiatePasswordReset(
    ForgotPasswordRequestModel request,
  ) async {
    return Success(
      PasswordResetInitiatedEntity(
        phone: request.fullPhoneNumber,
        resetSessionId: sessionA,
        resendCountdownSeconds: 0,
      ),
    );
  }

  @override
  Future<Result<PasswordResetInitiatedEntity>> resendPasswordResetOtp(
    ResendPasswordResetOtpRequestModel request,
  ) async {
    lastResendRequest = request;
    return Success(
      PasswordResetInitiatedEntity(
        phone: request.phone,
        resetSessionId: sessionB,
        resendCountdownSeconds: 30,
      ),
    );
  }

  @override
  Future<Result<PasswordResetVerifiedEntity>> verifyPasswordResetOtp(
    VerifyPasswordResetOtpRequestModel request,
  ) async {
    lastVerifyRequest = request;
    return Success(
      PasswordResetVerifiedEntity(
        phone: request.phone,
        resetSessionId: request.resetSessionId,
        resetToken: 'mock_token',
      ),
    );
  }

  @override
  Future<Result<PasswordResetSuccessEntity>> completePasswordReset(
    ResetPasswordRequestModel request,
  ) async {
    return Success(
      PasswordResetSuccessEntity(
        phone: request.phone,
        message: 'Password reset successful',
        timestamp: DateTime.now(),
      ),
    );
  }
}
