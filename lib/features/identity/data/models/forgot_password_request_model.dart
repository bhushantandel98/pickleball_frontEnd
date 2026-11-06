import 'package:equatable/equatable.dart';

/// Request DTO for requesting an OTP code to initiate password recovery.
final class ForgotPasswordRequestModel extends Equatable {
  final String phone;
  final String countryCode;

  const ForgotPasswordRequestModel({
    required this.phone,
    this.countryCode = '+91',
  });

  /// Formatted telephone number with dial code (e.g. `+919876543210`).
  String get fullPhoneNumber {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    return '$countryCode$cleanPhone';
  }

  /// Raw 10-digit phone digits without prefix.
  String get rawPhone => phone.replaceAll(RegExp(r'\D'), '');

  Map<String, dynamic> toJson() => {
        'phone': fullPhoneNumber,
        'countryCode': countryCode,
      };

  @override
  List<Object?> get props => [phone, countryCode];
}
