import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/features/player/domain/entities/player_dashboard_data.dart';
import 'package:pickleball_platform/features/profile/presentation/widgets/profile_avatar_view.dart';

/// Modern summary card displaying the player's welcome greeting and play context.
class PlayerHeaderCard extends StatelessWidget {
  final PlayerProfileSummary profile;
  final int unreadNotificationsCount;

  const PlayerHeaderCard({
    super.key,
    required this.profile,
    this.unreadNotificationsCount = 0,
  });

  String _extractFirstName(String fullName) {
    final parts = fullName.trim().split(' ');
    return parts.isNotEmpty ? parts.first : fullName;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final firstName = _extractFirstName(profile.fullName);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppSpacing.borderRadiusMd,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withValues(alpha: 0.45),
              colorScheme.surface,
            ],
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProfileAvatarView(
                  name: profile.fullName,
                  avatarUrl: profile.avatarUrl,
                  radius: 30.0,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, $firstName!',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxs),
                      Text(
                        profile.fullName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                AppChip.neutral(
                  label: profile.location,
                  icon: const Icon(Icons.location_on_outlined, size: 14),
                ),
                AppChip.info(
                  label: profile.playStyle,
                  icon: const Icon(Icons.sports_tennis_outlined, size: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
