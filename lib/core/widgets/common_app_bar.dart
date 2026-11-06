import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';

/// Reusable application bar with role context, title, and action entries.
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;

  const CommonAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBar(
      leading: leading,
      centerTitle: centerTitle,
      title: Column(
        crossAxisAlignment:
            centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xxxs),
            Text(
              subtitle!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppSpacing.appBarHeight);
}
