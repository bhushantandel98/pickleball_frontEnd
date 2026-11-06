import 'package:equatable/equatable.dart';

/// Data Transfer Object for requesting a new OTP verification code.
class ResendOtpRequestModel extends Equatable {
  final String phone;
  final String otpSessionId;

  const ResendOtpRequestModel({
    required this.phone,
    required this.otpSessionId,
  });

  /// Serialization for proposed Spring Boot backend integration:
  /// POST /api/v1/auth/register/resend-otp
  Map<String, dynamic> toJson() => {
        'phone': phone,
        'otpSessionId': otpSessionId,
      };

  @override
  List<Object?> get props => [phone, otpSessionId];
}
