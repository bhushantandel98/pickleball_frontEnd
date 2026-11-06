import 'package:flutter/material.dart';

/// Representation of a single navigation destination in the platform shell.
class NavDestinationItem {
  final String label;
  final String routePath;
  final IconData icon;
  final IconData? selectedIcon;
  final int? badgeCount;

  const NavDestinationItem({
    required this.label,
    required this.routePath,
    required this.icon,
    this.selectedIcon,
    this.badgeCount,
  });
}
