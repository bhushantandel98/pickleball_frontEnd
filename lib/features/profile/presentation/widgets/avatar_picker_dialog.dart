import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';

class AvatarPresetItem {
  final String key;
  final String label;
  final IconData icon;

  const AvatarPresetItem({
    required this.key,
    required this.label,
    required this.icon,
  });
}

/// Modal selector for choosing local mock profile avatar motifs.
class AvatarPickerDialog extends StatelessWidget {
  final String? currentAvatarUrl;
  final ValueChanged<String?> onAvatarSelected;

  static const List<AvatarPresetItem> presets = [
    AvatarPresetItem(
      key: 'initials',
      label: 'Initials',
      icon: Icons.text_fields,
    ),
    AvatarPresetItem(
      key: 'avatar:champion',
      label: 'Champion',
      icon: Icons.emoji_events,
    ),
    AvatarPresetItem(
      key: 'avatar:pro',
      label: 'Pro Star',
      icon: Icons.star,
    ),
    AvatarPresetItem(
      key: 'avatar:shield',
      label: 'Defender',
      icon: Icons.shield,
    ),
    AvatarPresetItem(
      key: 'avatar:speed',
      label: 'Speedster',
      icon: Icons.bolt,
    ),
    AvatarPresetItem(
      key: 'avatar:trophy',
      label: 'Tournament',
      icon: Icons.military_tech,
    ),
  ];

  const AvatarPickerDialog({
    super.key,
    required this.currentAvatarUrl,
    required this.onAvatarSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required String? currentAvatarUrl,
    required ValueChanged<String?> onAvatarSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => AvatarPickerDialog(
        currentAvatarUrl: currentAvatarUrl,
        onAvatarSelected: (selected) {
          onAvatarSelected(selected);
          Navigator.of(sheetContext).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Profile Badge',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Choose an avatar motif to represent your account across the platform.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: presets.map((preset) {
                final isSelected = (preset.key == 'initials' &&
                        (currentAvatarUrl == null ||
                            currentAvatarUrl!.isEmpty)) ||
                    currentAvatarUrl == preset.key;

                return InkWell(
                  onTap: () {
                    final value =
                        preset.key == 'initials' ? null : preset.key;
                    onAvatarSelected(value);
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.sm,
                      horizontal: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: isSelected
                              ? theme.colorScheme.primary
                              : AppColors.primary,
                          child: Icon(
                            preset.icon,
                            color: AppColors.onPrimary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          preset.label,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.secondary(
              label: 'Cancel',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
