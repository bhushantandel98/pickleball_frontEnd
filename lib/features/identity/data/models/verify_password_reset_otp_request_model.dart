import 'package:equatable/equatable.dart';

/// Request DTO for validating a 6-digit OTP code to authorize password recovery.
final class VerifyPasswordResetOtpRequestModel extends Equatable {
  final String phone;
  final String otp;
  final String resetSessionId;

  const VerifyPasswordResetOtpRequestModel({
    required this.phone,
    required this.otp,
    required this.resetSessionId,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'otp': otp,
        'resetSessionId': resetSessionId,
      };

  @override
  List<Object?> get props => [phone, otp, resetSessionId];
}
