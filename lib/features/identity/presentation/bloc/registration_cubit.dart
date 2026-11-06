import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/features/identity/data/models/register_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/resend_otp_request_model.dart';
import 'package:pickleball_platform/features/identity/data/models/verify_otp_request_model.dart';
import 'package:pickleball_platform/features/identity/domain/entities/registration_entities.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/auth_repository.dart';

/// Presentation state hierarchy for Player self-registration and OTP verification.
sealed class RegistrationState extends Equatable {
  const RegistrationState();

  @override
  List<Object?> get props => [];
}

/// Step 1: Initial or editing state for the player registration form.
final class RegistrationFormState extends RegistrationState {
  final bool isSubmitting;
  final String? errorMessage;
  final String? initialFullName;
  final String? initialPhone;

  const RegistrationFormState({
    this.isSubmitting = false,
    this.errorMessage,
    this.initialFullName,
    this.initialPhone,
  });

  RegistrationFormState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? initialFullName,
    String? initialPhone,
  }) {
    return RegistrationFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      initialFullName: initialFullName ?? this.initialFullName,
      initialPhone: initialPhone ?? this.initialPhone,
    );
  }

  @override
  List<Object?> get props => [isSubmitting, errorMessage, initialFullName, initialPhone];
}

/// Step 2: OTP verification screen awaiting 6-digit entry with active countdown.
final class RegistrationOtpState extends RegistrationState {
  final RegisterRequestModel request;
  final RegistrationInitiatedEntity otpSession;
  final int countdown;
  final bool isVerifying;
  final bool isResending;
  final String? errorMessage;

  const RegistrationOtpState({
    required this.request,
    required this.otpSession,
    this.countdown = 30,
    this.isVerifying = false,
    this.isResending = false,
    this.errorMessage,
  });

  bool get canResend => countdown <= 0 && !isResending && !isVerifying;

  RegistrationOtpState copyWith({
    RegistrationInitiatedEntity? otpSession,
    int? countdown,
    bool? isVerifying,
    bool? isResending,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RegistrationOtpState(
      request: request,
      otpSession: otpSession ?? this.otpSession,
      countdown: countdown ?? this.countdown,
      isVerifying: isVerifying ?? this.isVerifying,
      isResending: isResending ?? this.isResending,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        request,
        otpSession,
        countdown,
        isVerifying,
        isResending,
        errorMessage,
      ];
}

/// Step 3: Registration confirmed and player account successfully created.
final class RegistrationCompletedState extends RegistrationState {
  final PlayerRegistrationSuccessEntity success;

  const RegistrationCompletedState({required this.success});

  @override
  List<Object?> get props => [success];
}

/// Cubit managing multi-step Player registration, OTP verification, and resend countdown.
class RegistrationCubit extends Cubit<RegistrationState> {
  final AuthRepository authRepository;
  Timer? _countdownTimer;

  RegistrationCubit({required this.authRepository})
      : super(const RegistrationFormState());

  /// Step 1 Submission: Validates data with backend/mock and sends initial OTP.
  Future<void> submitRegistrationForm({
    required String fullName,
    required String phone,
    required String password,
  }) async {
    emit(const RegistrationFormState(isSubmitting: true));

    final request = RegisterRequestModel(
      fullName: fullName,
      phone: phone,
      password: password,
    );

    final result = await authRepository.initiateRegistration(request);

    result.when(
      success: (otpSession) {
        _startCountdown(otpSession.resendCountdownSeconds);
        emit(
          RegistrationOtpState(
            request: request,
            otpSession: otpSession,
            countdown: otpSession.resendCountdownSeconds,
          ),
        );
      },
      failure: (failure) {
        emit(
          RegistrationFormState(
            isSubmitting: false,
            errorMessage: failure.message,
            initialFullName: fullName,
            initialPhone: phone,
          ),
        );
      },
    );
  }

  /// Step 2 Submission: Verifies the entered 6-digit OTP code.
  Future<void> submitOtp(String otp) async {
    final current = state;
    if (current is! RegistrationOtpState || current.isVerifying) return;

    emit(current.copyWith(isVerifying: true, clearError: true));

    final verifyRequest = VerifyOtpRequestModel(
      phone: current.request.fullPhoneNumber,
      otp: otp.trim(),
      otpSessionId: current.otpSession.otpSessionId,
      fullName: current.request.fullName,
      password: current.request.password,
    );

    final result = await authRepository.verifyOtp(verifyRequest);

    result.when(
      success: (successEntity) {
        _cancelTimer();
        emit(RegistrationCompletedState(success: successEntity));
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

  /// Resends a fresh OTP and resets the visible countdown.
  Future<void> resendOtp() async {
    final current = state;
    if (current is! RegistrationOtpState || !current.canResend) return;

    emit(current.copyWith(isResending: true, clearError: true));

    final resendRequest = ResendOtpRequestModel(
      phone: current.request.fullPhoneNumber,
      otpSessionId: current.otpSession.otpSessionId,
    );

    final result = await authRepository.resendOtp(resendRequest);

    result.when(
      success: (updatedSession) {
        _startCountdown(updatedSession.resendCountdownSeconds);
        emit(
          current.copyWith(
            otpSession: updatedSession,
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

  /// Allows user to navigate back from OTP entry to the form to edit their phone number.
  void backToForm() {
    _cancelTimer();
    final current = state;
    if (current is RegistrationOtpState) {
      emit(
        RegistrationFormState(
          initialFullName: current.request.fullName,
          initialPhone: current.request.phone,
        ),
      );
    } else {
      emit(const RegistrationFormState());
    }
  }

  /// Stops any active resend countdown timer.
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
        if (state is RegistrationOtpState) {
          emit((state as RegistrationOtpState).copyWith(countdown: 0));
        }
      } else {
        if (state is RegistrationOtpState) {
          emit((state as RegistrationOtpState).copyWith(countdown: remaining));
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
