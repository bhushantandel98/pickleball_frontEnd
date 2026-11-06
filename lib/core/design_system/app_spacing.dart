import 'package:flutter/material.dart';

/// Centralized layout tokens: Spacing scale, Border Radii, Elevations,
/// Component Dimensions, and Animation Durations.
///
/// Follows a 4pt/8pt grid system.
class AppSpacing {
  AppSpacing._();

  // --- Spacing Scale (4pt / 8pt grid) ---
  static const double xxxs = 2.0;
  static const double xxs = 4.0;
  static const double xs = 8.0;
  static const double sm = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // --- Common Insets ---
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: lg,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets dialogPadding = EdgeInsets.all(lg);
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );

  // --- Border Radii ---
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  static const BorderRadius borderRadiusXs = BorderRadius.all(Radius.circular(radiusXs));
  static const BorderRadius borderRadiusSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius borderRadiusMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius borderRadiusLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius borderRadiusXl = BorderRadius.all(Radius.circular(radiusXl));
  static const BorderRadius borderRadiusFull = BorderRadius.all(Radius.circular(radiusFull));

  // --- Elevations & Shadows ---
  static const double elevationNone = 0.0;
  static const double elevationLow = 1.0;
  static const double elevationMedium = 3.0;
  static const double elevationHigh = 6.0;

  static const List<BoxShadow> shadowLow = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x14000000),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> shadowHigh = [
    BoxShadow(
      color: Color(0x1A000000),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // --- Icon Sizes ---
  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  // --- Standard Component Dimensions ---
  static const double minTouchTarget = 48.0; // Accessibility standard
  static const double buttonHeight = 48.0;
  static const double inputHeight = 52.0;
  static const double chipHeight = 32.0;
  static const double appBarHeight = 56.0;

  // --- Responsive & Web Maximum Widths ---
  static const double maxContentWidth = 1200.0;
  static const double maxFormWidth = 640.0;
  static const double maxModalWidth = 560.0;
  static const double maxTableWidth = 1440.0;

  // --- Animation Durations ---
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);

  // --- Curves ---
  static const Curve curveStandard = Curves.easeInOut;
  static const Curve curveDecelerate = Curves.easeOut;
  static const Curve curveAccelerate = Curves.easeIn;
}
