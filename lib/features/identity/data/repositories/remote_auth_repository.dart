import 'package:pickleball_platform/core/errors/failures.dart';
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

/// Production implementation of [AuthRepository] communicating with the Spring Boot backend.
///
/// Will connect via Dio HTTP client to `POST /api/v1/auth/*` in future integration phases.
class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository();

  @override
  Future<Result<AuthSession>> login(LoginRequestModel request) async {
    // Safe placeholder until live backend endpoints are connected in Phase 1+
    return const FailureResult<AuthSession>(
      ServerFailure(
        message: 'Authentication service is currently unavailable. Please try again later.',
        statusCode: 503,
      ),
    );
  }

  @override
  Future<Result<RegistrationInitiatedEntity>> initiateRegistration(
    RegisterRequestModel request,
  ) async {
    return const FailureResult<RegistrationInitiatedEntity>(
      ServerFailure(
        message: 'Registration service is currently unavailable. Please try again later.',
        statusCode: 503,
      ),
    );
  }

  @override
  Future<Result<PlayerRegistrationSuccessEntity>> verifyOtp(
    VerifyOtpRequestModel request,
  ) async {
    return const FailureResult<PlayerRegistrationSuccessEntity>(
      ServerFailure(
        message: 'Registration service is currently unavailable. Please try again later.',
        statusCode: 503,
      ),
    );
  }

  @override
  Future<Result<RegistrationInitiatedEntity>> resendOtp(
    ResendOtpRequestModel request,
  ) async {
    return const FailureResult<RegistrationInitiatedEntity>(
      ServerFailure(
        message: 'Registration service is currently unavailable. Please try again later.',
        statusCode: 503,
      ),
    );
  }

  @override
  Future<Result<PasswordResetInitiatedEntity>> initiatePasswordReset(
    ForgotPasswordRequestModel request,
  ) async {
    return const FailureResult<PasswordResetInitiatedEntity>(
      ServerFailure(
        message: 'Password reset service is currently unavailable. Please try again later.',
        statusCode: 503,
      ),
    );
  }

  @override
  Future<Result<PasswordResetInitiatedEntity>> resendPasswordResetOtp(
    ResendPasswordResetOtpRequestModel request,
  ) async {
    return const FailureResult<PasswordResetInitiatedEntity>(
      ServerFailure(
        message: 'Password reset service is currently unavailable. Please try again later.',
        statusCode: 503,
      ),
    );
  }

  @override
  Future<Result<PasswordResetVerifiedEntity>> verifyPasswordResetOtp(
    VerifyPasswordResetOtpRequestModel request,
  ) async {
    return const FailureResult<PasswordResetVerifiedEntity>(
      ServerFailure(
        message: 'Password reset service is currently unavailable. Please try again later.',
        statusCode: 503,
      ),
    );
  }

  @override
  Future<Result<PasswordResetSuccessEntity>> completePasswordReset(
    ResetPasswordRequestModel request,
  ) async {
    return const FailureResult<PasswordResetSuccessEntity>(
      ServerFailure(
        message: 'Password reset service is currently unavailable. Please try again later.',
        statusCode: 503,
      ),
    );
  }
}
