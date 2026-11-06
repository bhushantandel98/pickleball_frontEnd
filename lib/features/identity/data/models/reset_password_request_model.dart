import 'package:equatable/equatable.dart';

/// Request DTO for committing a new password using the verified reset session.
final class ResetPasswordRequestModel extends Equatable {
  final String phone;
  final String resetSessionId;
  final String resetToken;
  final String newPassword;

  const ResetPasswordRequestModel({
    required this.phone,
    required this.resetSessionId,
    required this.resetToken,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'resetSessionId': resetSessionId,
        'resetToken': resetToken,
        'newPassword': newPassword,
      };

  @override
  String toString() =>
      'ResetPasswordRequestModel(phone: $phone, resetSessionId: $resetSessionId, resetToken: [REDACTED], newPassword: [REDACTED])';

  @override
  List<Object?> get props => [phone, resetSessionId, resetToken, newPassword];
}
