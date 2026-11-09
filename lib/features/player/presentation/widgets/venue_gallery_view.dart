import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';

/// Interactive gallery widget for venue photographs with hero preview and thumbnail strip.
class VenueGalleryView extends StatelessWidget {
  final List<String> images;
  final int selectedIndex;
  final ValueChanged<int> onSelectImage;

  const VenueGalleryView({
    super.key,
    required this.images,
    required this.selectedIndex,
    required this.onSelectImage,
  });

  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.sports_tennis,
        color: theme.colorScheme.onPrimaryContainer,
        size: 56,
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context) {
    if (images.isEmpty) {
      return _buildPlaceholder(context);
    }

    final safeIndex = selectedIndex.clamp(0, images.length - 1);
    final imagePath = images[safeIndex];

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(context),
    );
  }

  Widget _buildThumbnail(BuildContext context, String path, int index) {
    final theme = Theme.of(context);
    final isSelected = index == selectedIndex;

    return Semantics(
      button: true,
      label: 'Select photo ${index + 1} of ${images.length}',
      child: GestureDetector(
        key: Key('venue_gallery_thumb_$index'),
        onTap: () => onSelectImage(index),
        child: Container(
          width: 72,
          height: 52,
          margin: const EdgeInsets.only(right: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: AppSpacing.borderRadiusSm,
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: isSelected ? 2.5 : 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm - 1),
            child: Image.asset(
              path,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                alignment: Alignment.center,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCount = images.length;
    final currentDisplayNumber = (selectedIndex + 1).clamp(1, totalCount > 0 ? totalCount : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main hero photograph preview
        ClipRRect(
          borderRadius: AppSpacing.borderRadiusMd,
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: SizedBox(
                  width: double.infinity,
                  child: _buildHeroImage(context),
                ),
              ),
              // Photo counter badge overlay
              if (totalCount > 1)
                Positioned(
                  bottom: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxxs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: AppSpacing.borderRadiusSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_library_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '$currentDisplayNumber / $totalCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Interactive thumbnail strip if multiple images exist
        if (totalCount > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: totalCount,
              itemBuilder: (context, index) {
                return _buildThumbnail(context, images[index], index);
              },
            ),
          ),
        ],
      ],
    );
  }
}
