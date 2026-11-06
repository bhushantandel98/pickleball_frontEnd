import 'package:flutter/material.dart';

/// Horizontal scroll wrapper for data tables and operational grids.
///
/// Prevents layout overflow on mobile screens while maintaining clean desktop presentation.
class ResponsiveTableContainer extends StatelessWidget {
  final Widget child;
  final double minWidth;

  const ResponsiveTableContainer({
    super.key,
    required this.child,
    this.minWidth = 600.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth > minWidth
                  ? constraints.maxWidth
                  : minWidth,
            ),
            child: child,
          ),
        );
      },
    );
  }
}
