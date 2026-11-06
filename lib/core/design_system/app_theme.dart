import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/app_typography.dart';

/// Centralized ThemeData configuration for the Pickleball Multi-Role Platform.
///
/// Builds complete Material 3 Light and Dark themes, unifying ColorScheme,
/// Typography, Elevations, Component Themes, and Input Decorations.
class AppTheme {
  AppTheme._();

  // --- Material 3 Light Theme ---
  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.onSurfaceLight,
      surfaceContainerHighest: AppColors.surfaceVariantLight,
      onSurfaceVariant: AppColors.onSurfaceVariantLight,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.dividerLight,
      shadow: Colors.black26,
      scrim: AppColors.overlayLight,
    );

    final textTheme = AppTypography.createTextTheme(isDark: false);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.onSurfaceLight,
        elevation: AppSpacing.elevationNone,
        scrolledUnderElevation: AppSpacing.elevationLow,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(
          color: AppColors.onSurfaceLight,
          size: AppSpacing.iconMd,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceLight,
        elevation: AppSpacing.elevationNone,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          side: BorderSide(color: AppColors.borderLight),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppSpacing.elevationNone,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.buttonHeight),
          padding: AppSpacing.buttonPadding,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.buttonHeight),
          padding: AppSpacing.buttonPadding,
          side: const BorderSide(color: AppColors.primary),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.buttonHeight),
          padding: AppSpacing.buttonPadding,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: AppSpacing.inputPadding,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textDisabledLight),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryLight),
        border: const OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantLight,
        labelStyle: textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceLight),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxxs),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceLight,
        elevation: AppSpacing.elevationHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
    );
  }

  // --- Material 3 Dark Theme ---
  static ThemeData get darkTheme {
    final colorScheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryContainer,
      onPrimary: AppColors.onPrimaryContainer,
      primaryContainer: AppColors.primary,
      onPrimaryContainer: AppColors.onPrimary,
      secondary: AppColors.secondaryContainer,
      onSecondary: AppColors.onSecondaryContainer,
      secondaryContainer: AppColors.secondary,
      onSecondaryContainer: AppColors.onSecondary,
      error: AppColors.errorContainer,
      onError: AppColors.onErrorContainer,
      errorContainer: AppColors.error,
      onErrorContainer: AppColors.onError,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
      surfaceContainerHighest: AppColors.surfaceVariantDark,
      onSurfaceVariant: AppColors.onSurfaceVariantDark,
      outline: AppColors.borderDark,
      outlineVariant: AppColors.dividerDark,
      shadow: Colors.black54,
      scrim: AppColors.overlayDark,
    );

    final textTheme = AppTypography.createTextTheme(isDark: true);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: textTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 1,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.onSurfaceDark,
        elevation: AppSpacing.elevationNone,
        scrolledUnderElevation: AppSpacing.elevationLow,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(
          color: AppColors.onSurfaceDark,
          size: AppSpacing.iconMd,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceDark,
        elevation: AppSpacing.elevationNone,
        shape: RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          side: BorderSide(color: AppColors.borderDark),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: AppSpacing.elevationNone,
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.buttonHeight),
          padding: AppSpacing.buttonPadding,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryContainer,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.buttonHeight),
          padding: AppSpacing.buttonPadding,
          side: const BorderSide(color: AppColors.primaryContainer),
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryContainer,
          minimumSize: const Size(AppSpacing.minTouchTarget, AppSpacing.buttonHeight),
          padding: AppSpacing.buttonPadding,
          shape: const RoundedRectangleBorder(
            borderRadius: AppSpacing.borderRadiusMd,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding: AppSpacing.inputPadding,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textDisabledDark),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondaryDark),
        border: const OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.primaryContainer, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.errorContainer),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppSpacing.borderRadiusMd,
          borderSide: BorderSide(color: AppColors.errorContainer, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantDark,
        labelStyle: textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceDark),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxxs),
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusSm,
        ),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: AppSpacing.elevationHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.borderRadiusLg,
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
    );
  }
}
