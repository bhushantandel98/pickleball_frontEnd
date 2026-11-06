import 'package:equatable/equatable.dart';

/// Data Transfer Object for initiating mobile number & password authentication.
///
/// Follows Clean Architecture DTO conventions without code generation.
class LoginRequestModel extends Equatable {
  final String phone;
  final String password;
  final String countryCode;

  const LoginRequestModel({
    required this.phone,
    required this.password,
    this.countryCode = '+91',
  });

  /// Normalized full phone number with country code prefix (e.g., '+919876543210').
  String get fullPhoneNumber {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    return '$countryCode$cleanPhone';
  }

  /// Only the raw 10-digit number.
  String get rawPhone => phone.replaceAll(RegExp(r'\D'), '');

  /// Serialization for live Spring Boot backend integration.
  Map<String, dynamic> toJson() => {
        'phone': fullPhoneNumber,
        'password': password,
      };

  @override
  List<Object?> get props => [phone, password, countryCode];
}
