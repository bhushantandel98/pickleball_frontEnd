import 'package:flutter/foundation.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/errors/exceptions.dart';
import 'package:pickleball_platform/core/mock/mock_network_harness.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/identity/data/models/forgot_password_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/login_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/register_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/resend_otp_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/resend_password_reset_otp_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/reset_password_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/verify_otp_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/verify_password_reset_otp_request_model.dart';
import 'package:pickleball_platform/features/identity/domain/entities/auth_session.dart';
import 'package:pickleball_platform/features/identity/domain/entities/password_reset_entities.dart';
import 'package:pickleball_platform/features/identity/domain/entities/registration_entities.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/auth_repository.dart';

/// Mock implementation of [AuthRepository] for local UI development and testing.
///
/// Implements ADR-011 and ADR-015: Strictly isolated from production builds.
class MockAuthRepository implements AuthRepository {
  final MockNetworkHarness _harness;

  MockAuthRepository({MockNetworkHarness? harness})
      : _harness = harness ?? MockNetworkHarness() {
    assert(
      !kReleaseMode,
      'MockAuthRepository must NEVER be initialized in release builds (ADR-015)',
    );
  }

  @override
  Future<Result<AuthSession>> login(LoginRequestModel request) async {
    return _harness.requestResult<AuthSession>(() async {
      final digits = request.rawPhone;

      // 1. Account Suspended Scenario (e.g. 9876543219)
      if (digits == '9876543219') {
        throw const ForbiddenException(
          message: 'Your account has been suspended. Please contact platform support.',
        );
      }

      // 2. Invalid Credentials Scenario
      // Known valid test accounts: 9876543210 (multi-role) and 9876543211 (single role)
      final isValidPhone = digits == '9876543210' || digits == '9876543211';
      final isValidPassword = request.password.isNotEmpty && request.password != 'wrongpass';

      if (!isValidPhone || !isValidPassword) {
        throw const UnauthorizedException(
          message: 'Invalid mobile number or password. Please verify your credentials.',
        );
      }

      // 3. Multi-role user: Alex Rivera (Player, Coach, Referee)
      if (digits == '9876543210') {
        return const AuthSession(
          userId: 'usr_mock_multi_001',
          accessToken: 'mock_jwt_token_multi_role_alex',
          refreshToken: 'mock_refresh_token_multi_role_alex',
          name: 'Alex Rivera',
          phone: '+919876543210',
          email: 'alex.rivera@example.com',
          availableRoles: [
            UserRole.player,
            UserRole.coach,
            UserRole.referee,
          ],
          activeRole: null, // User will select role
        );
      }

      // 4. Single-role user: Samira Khan (Player only)
      return const AuthSession(
        userId: 'usr_mock_single_002',
        accessToken: 'mock_jwt_token_single_role_samira',
        refreshToken: 'mock_refresh_token_single_role_samira',
        name: 'Samira Khan',
        phone: '+919876543211',
        email: 'samira.khan@example.com',
        availableRoles: [UserRole.player],
        activeRole: UserRole.player,
      );
    });
  }

  @override
  Future<Result<RegistrationInitiatedEntity>> initiateRegistration(
    RegisterRequestModel request,
  ) async {
    return _harness.requestResult<RegistrationInitiatedEntity>(() async {
      final digits = request.rawPhone;

      // Existing mobile conflict check
      if (digits == '9876543210' || digits == '9876543211' || digits == '9876543219') {
        throw const ValidationException(
          message: 'An account with this mobile number already exists. Please sign in instead.',
        );
      }

      return RegistrationInitiatedEntity(
        phone: request.fullPhoneNumber,
        otpSessionId: 'mock_otp_session_$digits',
        resendCountdownSeconds: 30,
      );
    });
  }

  @override
  Future<Result<PlayerRegistrationSuccessEntity>> verifyOtp(
    VerifyOtpRequestModel request,
  ) async {
    return _harness.requestResult<PlayerRegistrationSuccessEntity>(() async {
      // Expired OTP simulation scenario
      if (request.otp == '000000') {
        throw const ValidationException(
          message: 'Verification code has expired. Please request a new code.',
        );
      }

      // Invalid OTP verification scenario (Default valid test OTP is 123456)
      if (request.otp != '123456') {
        throw const ValidationException(
          message: 'Invalid verification code. Please check and try again.',
        );
      }

      final digits = request.phone.replaceAll(RegExp(r'\D'), '');
      return PlayerRegistrationSuccessEntity(
        userId: 'usr_player_$digits',
        fullName: request.fullName,
        phone: request.phone,
        assignedRole: UserRole.player,
        createdAt: DateTime.now(),
      );
    });
  }

  @override
  Future<Result<RegistrationInitiatedEntity>> resendOtp(
    ResendOtpRequestModel request,
  ) async {
    return _harness.requestResult<RegistrationInitiatedEntity>(() async {
      return RegistrationInitiatedEntity(
        phone: request.phone,
        otpSessionId: request.otpSessionId,
        resendCountdownSeconds: 30,
      );
    });
  }

  @override
  Future<Result<PasswordResetInitiatedEntity>> initiatePasswordReset(
    ForgotPasswordRequestModel request,
  ) async {
    return _harness.requestResult<PasswordResetInitiatedEntity>(() async {
      final digits = request.rawPhone;

      // Non-existent account simulation scenario
      if (digits == '9999999999') {
        throw const NotFoundException(
          message: 'No account found associated with this mobile number. Please check the number or create an account.',
        );
      }

      return PasswordResetInitiatedEntity(
        phone: request.fullPhoneNumber,
        resetSessionId: 'mock_reset_session_$digits',
        resendCountdownSeconds: 30,
      );
    });
  }

  @override
  Future<Result<PasswordResetInitiatedEntity>> resendPasswordResetOtp(
    ResendPasswordResetOtpRequestModel request,
  ) async {
    return _harness.requestResult<PasswordResetInitiatedEntity>(() async {
      final digits = request.phone.replaceAll(RegExp(r'\D'), '');
      return PasswordResetInitiatedEntity(
        phone: request.phone,
        resetSessionId: 'mock_reset_session_${digits}_resend',
        resendCountdownSeconds: 30,
      );
    });
  }

  @override
  Future<Result<PasswordResetVerifiedEntity>> verifyPasswordResetOtp(
    VerifyPasswordResetOtpRequestModel request,
  ) async {
    return _harness.requestResult<PasswordResetVerifiedEntity>(() async {
      // Expired OTP simulation scenario
      if (request.otp == '000000') {
        throw const ValidationException(
          message: 'Verification code has expired. Please request a new code.',
        );
      }

      // Invalid OTP verification scenario (Default valid test OTP is 123456)
      if (request.otp != '123456') {
        throw const ValidationException(
          message: 'Invalid verification code. Please check and try again.',
        );
      }

      return PasswordResetVerifiedEntity(
        phone: request.phone,
        resetSessionId: request.resetSessionId,
        resetToken: 'mock_reset_token_${request.resetSessionId}',
      );
    });
  }

  @override
  Future<Result<PasswordResetSuccessEntity>> completePasswordReset(
    ResetPasswordRequestModel request,
  ) async {
    return _harness.requestResult<PasswordResetSuccessEntity>(() async {
      if (request.newPassword.length < 8) {
        throw const ValidationException(
          message: 'Password must be at least 8 characters.',
        );
      }

      return PasswordResetSuccessEntity(
        phone: request.phone,
        message: 'Password has been reset successfully. Please sign in with your new password.',
        timestamp: DateTime.now(),
      );
    });
  }
}
