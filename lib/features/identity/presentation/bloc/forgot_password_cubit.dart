import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/features/identity/data/models/forgot_password_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/resend_password_reset_otp_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/reset_password_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/verify_password_reset_otp_request_model.dart';
import 'package:pickleball_platform/features/identity/domain/entities/password_reset_entities.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/auth_repository.dart';

/// Presentation state hierarchy for the Forgot Password flow.
sealed class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

/// Step 1: Input or editing state for the registered mobile number.
final class ForgotPasswordPhoneState extends ForgotPasswordState {
  final bool isSubmitting;
  final String? errorMessage;
  final String? initialPhone;

  const ForgotPasswordPhoneState({
    this.isSubmitting = false,
    this.errorMessage,
    this.initialPhone,
  });

  ForgotPasswordPhoneState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? initialPhone,
  }) {
    return ForgotPasswordPhoneState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      initialPhone: initialPhone ?? this.initialPhone,
    );
  }

  @override
  List<Object?> get props => [isSubmitting, errorMessage, initialPhone];
}

/// Step 2: OTP verification awaiting 6-digit entry with active countdown.
final class ForgotPasswordOtpState extends ForgotPasswordState {
  final ForgotPasswordRequestModel request;
  final PasswordResetInitiatedEntity resetSession;
  final int countdown;
  final bool isVerifying;
  final bool isResending;
  final String? errorMessage;

  const ForgotPasswordOtpState({
    required this.request,
    required this.resetSession,
    this.countdown = 30,
    this.isVerifying = false,
    this.isResending = false,
    this.errorMessage,
  });

  bool get canResend => countdown <= 0 && !isResending && !isVerifying;

  ForgotPasswordOtpState copyWith({
    PasswordResetInitiatedEntity? resetSession,
    int? countdown,
    bool? isVerifying,
    bool? isResending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordOtpState(
      request: request,
      resetSession: resetSession ?? this.resetSession,
      countdown: countdown ?? this.countdown,
      isVerifying: isVerifying ?? this.isVerifying,
      isResending: isResending ?? this.isResending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        request,
        resetSession,
        countdown,
        isVerifying,
        isResending,
        errorMessage,
      ];
}

/// Step 3: Input state for entering and confirming the new password.
final class ForgotPasswordNewPasswordState extends ForgotPasswordState {
  final ForgotPasswordRequestModel request;
  final PasswordResetVerifiedEntity verifiedSession;
  final bool isSubmitting;
  final String? errorMessage;

  const ForgotPasswordNewPasswordState({
    required this.request,
    required this.verifiedSession,
    this.isSubmitting = false,
    this.errorMessage,
  });

  ForgotPasswordNewPasswordState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ForgotPasswordNewPasswordState(
      request: request,
      verifiedSession: verifiedSession,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [request, verifiedSession, isSubmitting, errorMessage];
}

/// Step 4: Password reset successfully completed.
final class ForgotPasswordSuccessState extends ForgotPasswordState {
  final PasswordResetSuccessEntity success;

  const ForgotPasswordSuccessState({required this.success});

  @override
  List<Object?> get props => [success];
}

/// Cubit orchestrating the 4-step Forgot Password and recovery workflow.
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository authRepository;
  Timer? _countdownTimer;

  ForgotPasswordCubit({required this.authRepository})
      : super(const ForgotPasswordPhoneState());

  /// Step 1: Submits mobile number and initiates OTP recovery dispatch.
  Future<void> submitPhone(String phone) async {
    emit(const ForgotPasswordPhoneState(isSubmitting: true));

    final request = ForgotPasswordRequestModel(phone: phone);
    final result = await authRepository.initiatePasswordReset(request);

    result.when(
      success: (resetSession) {
        _startCountdown(resetSession.resendCountdownSeconds);
        emit(
          ForgotPasswordOtpState(
            request: request,
            resetSession: resetSession,
            countdown: resetSession.resendCountdownSeconds,
          ),
        );
      },
      failure: (failure) {
        emit(
          ForgotPasswordPhoneState(
            isSubmitting: false,
            errorMessage: failure.message,
            initialPhone: phone,
          ),
        );
      },
    );
  }

  /// Step 2: Verifies the entered 6-digit OTP code.
  Future<void> submitOtp(String otp) async {
    final current = state;
    if (current is! ForgotPasswordOtpState || current.isVerifying) return;

    emit(current.copyWith(isVerifying: true, clearError: true));

    final verifyRequest = VerifyPasswordResetOtpRequestModel(
      phone: current.request.fullPhoneNumber,
      otp: otp.trim(),
      resetSessionId: current.resetSession.resetSessionId,
    );

    final result = await authRepository.verifyPasswordResetOtp(verifyRequest);

    result.when(
      success: (verifiedSession) {
        _cancelTimer();
        emit(
          ForgotPasswordNewPasswordState(
            request: current.request,
            verifiedSession: verifiedSession,
          ),
        );
      },
      failure: (failure) {
        emit(
          current.copyWith(
            isVerifying: false,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }

  /// Step 2: Requests a fresh OTP code and updates the active reset session.
  Future<void> resendOtp() async {
    final current = state;
    if (current is! ForgotPasswordOtpState || !current.canResend) return;

    emit(current.copyWith(isResending: true, clearError: true));

    final resendRequest = ResendPasswordResetOtpRequestModel(
      phone: current.request.fullPhoneNumber,
      resetSessionId: current.resetSession.resetSessionId,
    );

    final result = await authRepository.resendPasswordResetOtp(resendRequest);

    result.when(
      success: (updatedSession) {
        _startCountdown(updatedSession.resendCountdownSeconds);
        emit(
          current.copyWith(
            resetSession: updatedSession,
            isResending: false,
            countdown: updatedSession.resendCountdownSeconds,
          ),
        );
      },
      failure: (failure) {
        emit(
          current.copyWith(
            isResending: false,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }

  /// Step 3: Submits the new password using the verified reset session.
  Future<void> submitNewPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    final current = state;
    if (current is! ForgotPasswordNewPasswordState || current.isSubmitting) return;

    if (newPassword != confirmPassword) {
      emit(current.copyWith(errorMessage: 'Passwords do not match'));
      return;
    }

    emit(current.copyWith(isSubmitting: true, clearError: true));

    final resetRequest = ResetPasswordRequestModel(
      phone: current.request.fullPhoneNumber,
      resetSessionId: current.verifiedSession.resetSessionId,
      resetToken: current.verifiedSession.resetToken,
      newPassword: newPassword,
    );

    final result = await authRepository.completePasswordReset(resetRequest);

    result.when(
      success: (successEntity) {
        emit(ForgotPasswordSuccessState(success: successEntity));
      },
      failure: (failure) {
        emit(
          current.copyWith(
            isSubmitting: false,
            errorMessage: failure.message,
          ),
        );
      },
    );
  }

  /// Allows user to return from OTP verification to edit their mobile number.
  void backToPhone() {
    _cancelTimer();
    final current = state;
    if (current is ForgotPasswordOtpState) {
      emit(ForgotPasswordPhoneState(initialPhone: current.request.phone));
    } else {
      emit(const ForgotPasswordPhoneState());
    }
  }

  /// Cancels active countdown timer.
  void cancelCountdownTimer() {
    _cancelTimer();
  }

  void _startCountdown(int seconds) {
    _cancelTimer();
    int remaining = seconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      if (remaining <= 0) {
        _cancelTimer();
        if (state is ForgotPasswordOtpState) {
          emit((state as ForgotPasswordOtpState).copyWith(countdown: 0));
        }
      } else {
        if (state is ForgotPasswordOtpState) {
          emit((state as ForgotPasswordOtpState).copyWith(countdown: remaining));
        }
      }
    });
  }

  void _cancelTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }
}
