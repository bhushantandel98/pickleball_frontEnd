import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';

/// Screen width breakpoints for responsive layouts.
///
/// Follows standard design tokens:
/// - Mobile: width < 600
/// - Tablet: 600 <= width <= 1024
/// - Desktop: width > 1024
enum DeviceScreenType {
  mobile,
  tablet,
  desktop,
}

class Breakpoints {
  Breakpoints._();

  static const double mobileMax = 599.0;
  static const double tabletMin = 600.0;
  static const double tabletMax = 1024.0;
  static const double desktopMin = 1025.0;

  static DeviceScreenType getDeviceType(double width) {
    if (width < tabletMin) {
      return DeviceScreenType.mobile;
    } else if (width <= tabletMax) {
      return DeviceScreenType.tablet;
    } else {
      return DeviceScreenType.desktop;
    }
  }
}

/// A lightweight responsive widget builder that provides tailored layouts
/// for mobile, tablet, and desktop without third-party dependencies.
class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context)? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static DeviceScreenType of(BuildContext context) {
    return Breakpoints.getDeviceType(MediaQuery.sizeOf(context).width);
  }

  static bool isMobile(BuildContext context) => of(context) == DeviceScreenType.mobile;
  static bool isTablet(BuildContext context) => of(context) == DeviceScreenType.tablet;
  static bool isDesktop(BuildContext context) => of(context) == DeviceScreenType.desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = Breakpoints.getDeviceType(constraints.maxWidth);
        switch (deviceType) {
          case DeviceScreenType.desktop:
            if (desktop != null) return desktop!(context);
            if (tablet != null) return tablet!(context);
            return mobile(context);
          case DeviceScreenType.tablet:
            if (tablet != null) return tablet!(context);
            return mobile(context);
          case DeviceScreenType.mobile:
            return mobile(context);
        }
      },
    );
  }
}

/// Centered content container applying responsive max-width constraints.
///
/// Prevents ultra-wide stretching on desktop/web while preserving full width on mobile.
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

/// Renders its children in a [Row] on desktop/tablet and in a [Column] on mobile.
///
/// Ideal for responsive forms, filter bars, and side-by-side dashboard sections.
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: _withSpacing(children, SizedBox(height: spacing)),
      );
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: _withSpacing(children, SizedBox(width: spacing)),
    );
  }

  static List<Widget> _withSpacing(List<Widget> widgets, Widget spacer) {
    if (widgets.isEmpty) return const [];
    final List<Widget> spaced = [];
    for (int i = 0; i < widgets.length; i++) {
      spaced.add(widgets[i]);
      if (i < widgets.length - 1) {
        spaced.add(spacer);
      }
    }
    return spaced;
  }
}

/// Convenience extension on [BuildContext] for responsive layout inspection.
extension ResponsiveContext on BuildContext {
  DeviceScreenType get deviceScreenType => ResponsiveLayout.of(this);
  bool get isMobile => ResponsiveLayout.isMobile(this);
  bool get isTablet => ResponsiveLayout.isTablet(this);
  bool get isDesktop => ResponsiveLayout.isDesktop(this);

  /// Selects a value based on the current screen size.
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final type = deviceScreenType;
    switch (type) {
      case DeviceScreenType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceScreenType.tablet:
        return tablet ?? mobile;
      case DeviceScreenType.mobile:
        return mobile;
    }
  }
}

