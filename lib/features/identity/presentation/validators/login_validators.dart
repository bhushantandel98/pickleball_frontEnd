/// Validation helpers for the Login flow.
///
/// Kept separate from presentation widgets to support unit testing and reuse.
abstract final class LoginValidators {
  /// Regular expression for a standard 10-digit Indian mobile number (starts with 6-9).
  static final RegExp _indianPhoneRegex = RegExp(r'^[6-9]\d{9}$');

  /// Validates the mobile number input.
  ///
  /// - Requires non-empty input.
  /// - Strips whitespace, hyphens, and non-digits.
  /// - Enforces 10-digit Indian mobile number format starting with digits 6, 7, 8, or 9.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (!_indianPhoneRegex.hasMatch(digits)) {
      return 'Enter a valid 10-digit Indian mobile number';
    }

    return null;
  }

  /// Validates the password input.
  ///
  /// - Requires non-empty input.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    return null;
  }
}
