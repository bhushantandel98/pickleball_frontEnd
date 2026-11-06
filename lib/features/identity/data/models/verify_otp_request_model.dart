import 'package:equatable/equatable.dart';

/// Data Transfer Object for submitting a 6-digit OTP verification request.
class VerifyOtpRequestModel extends Equatable {
  final String phone;
  final String otp;
  final String otpSessionId;
  final String fullName;
  final String password;

  const VerifyOtpRequestModel({
    required this.phone,
    required this.otp,
    required this.otpSessionId,
    required this.fullName,
    required this.password,
  });

  /// Serialization for proposed Spring Boot backend integration:
  /// POST /api/v1/auth/register/verify-otp
  Map<String, dynamic> toJson() => {
        'phone': phone,
        'otp': otp,
        'otpSessionId': otpSessionId,
        'fullName': fullName,
        'password': password,
      };

  @override
  List<Object?> get props => [phone, otp, otpSessionId, fullName, password];
}
