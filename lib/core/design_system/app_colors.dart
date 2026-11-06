import 'package:flutter/material.dart';

/// Centralized semantic color tokens for the Pickleball Multi-Role Platform.
///
/// Brand Color: Court Green (`#1B5E20`) is provisional and easily replaceable.
/// Follows Material 3 color harmony with accessible contrast ratios.
class AppColors {
  AppColors._();

  // --- Brand & Primary Tokens ---
  static const Color primary = Color(0xFF1B5E20); // Court Green
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFA5D6A7); // Muted Green Accent
  static const Color onPrimaryContainer = Color(0xFF002204);

  // --- Secondary & Accent Tokens ---
  static const Color secondary = Color(0xFF2E7D32);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFC8E6C9);
  static const Color onSecondaryContainer = Color(0xFF052B07);

  // --- Neutral / Background / Surface (Light Mode) ---
  static const Color backgroundLight = Color(0xFFF9FAF9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFEFF2EF);
  static const Color onBackgroundLight = Color(0xFF191C19);
  static const Color onSurfaceLight = Color(0xFF191C19);
  static const Color onSurfaceVariantLight = Color(0xFF414941);

  // --- Neutral / Background / Surface (Dark Mode) ---
  static const Color backgroundDark = Color(0xFF111411);
  static const Color surfaceDark = Color(0xFF191C19);
  static const Color surfaceVariantDark = Color(0xFF232B23);
  static const Color onBackgroundDark = Color(0xFFE1E4E0);
  static const Color onSurfaceDark = Color(0xFFE1E4E0);
  static const Color onSurfaceVariantDark = Color(0xFFC1C9BF);

  // --- Text Hierarchy Tokens ---
  static const Color textPrimaryLight = Color(0xFF191C19);
  static const Color textSecondaryLight = Color(0xFF555E54);
  static const Color textDisabledLight = Color(0xFF9E9E9E);

  static const Color textPrimaryDark = Color(0xFFE1E4E0);
  static const Color textSecondaryDark = Color(0xFFA0A79E);
  static const Color textDisabledDark = Color(0xFF6B726A);

  // --- Semantic Feedback Tokens (Success, Warning, Error, Info) ---
  static const Color success = Color(0xFF2E7D32);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color successContainer = Color(0xFFD4EDDA);
  static const Color onSuccessContainer = Color(0xFF0E3813);
  static const Color successDark = Color(0xFF81C784);

  static const Color warning = Color(0xFFE65100);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color warningContainer = Color(0xFFFFE0B2);
  static const Color onWarningContainer = Color(0xFF4E1600);
  static const Color warningDark = Color(0xFFFFB74D);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);
  static const Color errorDark = Color(0xFFFFB4AB);

  static const Color info = Color(0xFF0277BD);
  static const Color onInfo = Color(0xFFFFFFFF);
  static const Color infoContainer = Color(0xFFB3E5FC);
  static const Color onInfoContainer = Color(0xFF002947);
  static const Color infoDark = Color(0xFF81D4FA);

  // --- Borders, Dividers, and Overlays ---
  static const Color borderLight = Color(0xFFDDE3DC);
  static const Color borderDark = Color(0xFF333C33);
  static const Color dividerLight = Color(0xFFE6EAE5);
  static const Color dividerDark = Color(0xFF262E26);

  static const Color overlayLight = Color(0x66000000);
  static const Color overlayDark = Color(0x99000000);
}
