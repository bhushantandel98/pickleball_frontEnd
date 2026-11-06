import 'package:equatable/equatable.dart';

/// Data Transfer Object for requesting player registration and initiating mobile OTP verification.
///
/// Complies with platform rules: self-registration strictly assigns the independent Player role.
class RegisterRequestModel extends Equatable {
  final String fullName;
  final String phone;
  final String password;
  final String countryCode;
  final String role;

  const RegisterRequestModel({
    required this.fullName,
    required this.phone,
    required this.password,
    this.countryCode = '+91',
    this.role = 'player',
  });

  /// Normalized full phone number with country code prefix (e.g., '+919876543210').
  String get fullPhoneNumber {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    return '$countryCode$cleanPhone';
  }

  /// Raw 10-digit phone number.
  String get rawPhone => phone.replaceAll(RegExp(r'\D'), '');

  /// Serialization for proposed Spring Boot backend integration:
  /// POST /api/v1/auth/register/initiate
  Map<String, dynamic> toJson() => {
        'fullName': fullName.trim(),
        'phone': fullPhoneNumber,
        'password': password,
        'role': role.toUpperCase(),
      };

  @override
  List<Object?> get props => [fullName, phone, password, countryCode, role];
}
