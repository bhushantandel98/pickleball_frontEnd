/// Validation logic for the Player self-registration and OTP verification flow.
///
/// Kept strictly isolated from UI widgets to facilitate unit testing.
abstract final class RegistrationValidators {
  /// Regular expression for standard 10-digit Indian mobile number.
  static final RegExp _indianPhoneRegex = RegExp(r'^[6-9]\d{9}$');

  /// Regular expression for 6-digit numeric OTP.
  static final RegExp _otpRegex = RegExp(r'^\d{6}$');

  /// Validates the player's full name.
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

  /// Validates the 10-digit Indian mobile number.
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

  /// Validates the password according to security baseline:
  /// Minimum 8 characters, containing both letters and numbers.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(value);
    final hasDigit = RegExp(r'[0-9]').hasMatch(value);
    if (!hasLetter || !hasDigit) {
      return 'Password must contain both letters and numbers';
    }
    return null;
  }

  /// Validates that confirm password matches original password.
  static String? validateConfirmPassword(String? confirmPassword, String? password) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (confirmPassword != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates 6-digit numeric OTP entry.
  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Verification code is required';
    }

    final cleanOtp = value.replaceAll(RegExp(r'\D'), '');
    if (!_otpRegex.hasMatch(cleanOtp)) {
      return 'Enter a valid 6-digit verification code';
    }

    return null;
  }
}
