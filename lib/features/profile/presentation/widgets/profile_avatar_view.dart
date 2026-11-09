import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';

/// Reusable circular avatar widget rendering photo, preset icon badge, or initials.
class ProfileAvatarView extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final double radius;
  final bool isEditable;
  final VoidCallback? onEdit;

  const ProfileAvatarView({
    super.key,
    required this.name,
    this.avatarUrl,
    this.radius = 48.0,
    this.isEditable = false,
    this.onEdit,
  });

  String _extractInitials(String input) {
    final parts = input.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _buildAvatarContent(BuildContext context) {
    final theme = Theme.of(context);

    // Support mock avatar presets (e.g., 'avatar:champion', 'avatar:pro', etc.)
    if (avatarUrl != null && avatarUrl!.startsWith('avatar:')) {
      final presetKey = avatarUrl!.replaceFirst('avatar:', '');
      IconData iconData = Icons.sports_tennis;
      switch (presetKey) {
        case 'champion':
          iconData = Icons.emoji_events;
        case 'pro':
          iconData = Icons.star;
        case 'trophy':
          iconData = Icons.military_tech;
        case 'shield':
          iconData = Icons.shield;
        case 'speed':
          iconData = Icons.bolt;
        default:
          iconData = Icons.person;
      }
      return Icon(
        iconData,
        size: radius * 0.9,
        color: AppColors.onPrimary,
      );
    }

    // Default to initials
    final initials = _extractInitials(name);
    return Text(
      initials,
      style: theme.textTheme.headlineMedium?.copyWith(
        color: AppColors.onPrimary,
        fontWeight: FontWeight.bold,
        fontSize: radius * 0.7,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Semantics(
            label: 'Profile avatar for $name',
            child: CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.primary,
              child: _buildAvatarContent(context),
            ),
          ),
          if (isEditable)
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: theme.colorScheme.primary,
                shape: const CircleBorder(),
                elevation: 3,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Icon(
                      Icons.camera_alt,
                      size: radius * 0.38,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
