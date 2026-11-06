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

/// Contract definition for identity authentication operations.
///
/// Follows Clean Architecture domain boundary principles. Concrete implementations
/// are supplied via MockAuthRepository (development) and RemoteAuthRepository (production).
abstract class AuthRepository {
  /// Authenticates a user using their mobile number and password credentials.
  ///
  /// Returns [Success] containing the validated [AuthSession] or [FailureResult] with typed failure.
  Future<Result<AuthSession>> login(LoginRequestModel request);

  /// Initiates Player self-registration and dispatches an OTP verification code.
  ///
  /// Returns [RegistrationInitiatedEntity] containing verification session details,
  /// or [FailureResult] (e.g. if an account with this mobile number already exists).
  Future<Result<RegistrationInitiatedEntity>> initiateRegistration(
    RegisterRequestModel request,
  );

  /// Verifies the 6-digit OTP code and finalizes creation of the independent Player account.
  ///
  /// Returns [PlayerRegistrationSuccessEntity] on success, or [FailureResult]
  /// if the OTP is invalid or expired.
  Future<Result<PlayerRegistrationSuccessEntity>> verifyOtp(
    VerifyOtpRequestModel request,
  );

  /// Requests a fresh OTP code for an active verification session with renewed countdown.
  Future<Result<RegistrationInitiatedEntity>> resendOtp(
    ResendOtpRequestModel request,
  );

  /// Initiates password recovery by validating account existence and dispatching an OTP.
  ///
  /// Returns [PasswordResetInitiatedEntity] on success or [FailureResult] (e.g. account not found).
  Future<Result<PasswordResetInitiatedEntity>> initiatePasswordReset(
    ForgotPasswordRequestModel request,
  );

  /// Requests a fresh OTP code for an active password reset verification session.
  Future<Result<PasswordResetInitiatedEntity>> resendPasswordResetOtp(
    ResendPasswordResetOtpRequestModel request,
  );

  /// Verifies the 6-digit OTP code authorizing the password reset operation.
  ///
  /// Returns [PasswordResetVerifiedEntity] containing a reset token on success.
  Future<Result<PasswordResetVerifiedEntity>> verifyPasswordResetOtp(
    VerifyPasswordResetOtpRequestModel request,
  );

  /// Commits the new password using the verified reset session credentials.
  ///
  /// Returns [PasswordResetSuccessEntity] confirming update completion.
  Future<Result<PasswordResetSuccessEntity>> completePasswordReset(
    ResetPasswordRequestModel request,
  );
}
