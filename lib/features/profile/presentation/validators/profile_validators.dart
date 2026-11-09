/// Pure validation utility functions for user profile updates.
///
/// Follows FSD §3.3 & Clean Architecture.
abstract final class ProfileValidators {
  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z\s\.'-]+$");
  static final RegExp _emailRegex =
      RegExp(r'^[\w\.\+-]+@([\w-]+\.)+[\w-]{2,}$');

  /// Validates the full name field.
  ///
  /// Full name is required and must contain at least 2 valid alphabetic characters.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    if (!_nameRegex.hasMatch(trimmed)) {
      return 'Name contains invalid characters';
    }
    return null;
  }

  /// Validates an optional email address.
  ///
  /// If provided, must match standard email formatting.
  /// If empty or null, validation succeeds (email is optional for player accounts).
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final trimmed = value.trim();
    if (!_emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }
}
