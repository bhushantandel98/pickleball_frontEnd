import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';

/// Centralized typography definitions for the Pickleball Multi-Role Platform.
///
/// Follows Material 3 text scales with readable hierarchy, appropriate
/// line-heights, letter-spacing, and accessible contrast.
class AppTypography {
  AppTypography._();

  // --- Base TextTheme Generator ---
  static TextTheme createTextTheme({required bool isDark}) {
    final primaryColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return TextTheme(
      // --- Display Styles (Large hero headers) ---
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: 1.12,
        color: primaryColor,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.15,
        color: primaryColor,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.22,
        color: primaryColor,
      ),

      // --- Headline Styles (Page & section titles) ---
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
        color: primaryColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.28,
        color: primaryColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
        color: primaryColor,
      ),

      // --- Title Styles (Card headers, modal titles, app bars) ---
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.27,
        color: primaryColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
        color: primaryColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
        color: primaryColor,
      ),

      // --- Body Styles (Standard content paragraphs) ---
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
        color: primaryColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
        color: primaryColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: secondaryColor,
      ),

      // --- Label Styles (Buttons, chips, form labels, captions) ---
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
        color: primaryColor,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.33,
        color: secondaryColor,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: 1.45,
        color: secondaryColor,
      ),
    );
  }
}
