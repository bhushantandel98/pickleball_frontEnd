import 'package:equatable/equatable.dart';

/// Request DTO for requesting a fresh password reset OTP.
final class ResendPasswordResetOtpRequestModel extends Equatable {
  final String phone;
  final String resetSessionId;

  const ResendPasswordResetOtpRequestModel({
    required this.phone,
    required this.resetSessionId,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'resetSessionId': resetSessionId,
      };

  @override
  List<Object?> get props => [phone, resetSessionId];
}
