import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';

/// Standard adaptive page layout providing a consistent header, action bar,
/// and responsive content container for desktop and mobile management screens.
///
/// Tailored for the 8 web-priority operational roles (Academy, Tournament Organizer,
/// Venue Partner, Application Admin, and their respective staff roles).
class AdaptivePageLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget body;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool scrollable;

  const AdaptivePageLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    required this.body,
    this.maxWidth = AppSpacing.maxContentWidth,
    this.padding,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final header = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? AppSpacing.lg : AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: isDesktop
                      ? theme.textTheme.headlineMedium
                      : theme.textTheme.titleLarge,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.end,
              children: actions!,
            ),
          ],
        ],
      ),
    );

    final content = ResponsiveContainer(
      maxWidth: maxWidth,
      padding: padding ??
          EdgeInsets.all(isDesktop ? AppSpacing.lg : AppSpacing.md),
      child: body,
    );

    return Scaffold(
      body: scrollable
          ? SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const Divider(height: 1),
                  content,
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                const Divider(height: 1),
                Expanded(child: content),
              ],
            ),
    );
  }
}
