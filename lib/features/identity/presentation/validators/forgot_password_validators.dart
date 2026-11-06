/// Pure validation rules for the Forgot Password and recovery workflow.
abstract final class ForgotPasswordValidators {
  /// Validates that [value] is a valid 10-digit Indian mobile number.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    final clean = value.replaceAll(RegExp(r'\D'), '');
    if (clean.length != 10) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(clean)) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  /// Validates that [value] contains exactly 6 numeric digits.
  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Verification code is required';
    }
    final clean = value.trim();
    if (clean.length != 6 || !RegExp(r'^\d{6}$').hasMatch(clean)) {
      return 'Verification code must be 6 digits';
    }
    return null;
  }

  /// Validates that [value] meets the password requirements (min 8 chars, 1 letter, 1 number).
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$').hasMatch(value)) {
      return 'Password must contain at least one letter and one number';
    }
    return null;
  }

  /// Validates that [confirmPassword] matches [originalPassword].
  static String? validateConfirmPassword(String? originalPassword, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Confirm password is required';
    }
    if (confirmPassword != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }
}
