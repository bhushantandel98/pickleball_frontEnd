import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_text_field.dart';
import 'package:pickleball_platform/features/player/domain/entities/community_post.dart';
import 'package:pickleball_platform/features/player/domain/repositories/community_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/create_post_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/create_post_state.dart';

/// Modal bottom sheet for composing and publishing community image posts.
class CreatePostSheet extends StatefulWidget {
  final String authorId;
  final String authorName;
  final String authorHandle;
  final String? authorAvatarUrl;
  final double? authorRating;
  final void Function(CommunityPost newPost)? onPostCreated;

  const CreatePostSheet({
    super.key,
    required this.authorId,
    required this.authorName,
    required this.authorHandle,
    this.authorAvatarUrl,
    this.authorRating,
    this.onPostCreated,
  });

  static Future<void> show(
    BuildContext context, {
    required String authorId,
    required String authorName,
    required String authorHandle,
    String? authorAvatarUrl,
    double? authorRating,
    void Function(CommunityPost newPost)? onPostCreated,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => CreatePostCubit(
          repository: sl<CommunityRepository>(),
        ),
        child: CreatePostSheet(
          authorId: authorId,
          authorName: authorName,
          authorHandle: authorHandle,
          authorAvatarUrl: authorAvatarUrl,
          authorRating: authorRating,
          onPostCreated: onPostCreated,
        ),
      ),
    );
  }

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _captionController = TextEditingController();
  String? _selectedPhotoUrl;
  String? _selectedTag = 'MatchDay';

  static const _mockPhotos = [
    {
      'label': 'Court Action',
      'url': 'https://images.unsplash.com/photo-1599586120429-48281b6f0ece?w=800',
    },
    {
      'label': 'Gear & Paddle',
      'url': 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
    },
    {
      'label': 'Training Rally',
      'url': 'https://images.unsplash.com/photo-1517649763962-0c623266ddc0?w=800',
    },
    {
      'label': 'Tournament',
      'url': 'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=800',
    },
  ];

  static const _popularTags = [
    'MatchDay',
    'PickleballLife',
    'TournamentPrep',
    'GearTalk',
    'DinkPractice',
  ];

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  void _handleSubmit(BuildContext context) {
    context.read<CreatePostCubit>().submitPost(
          authorId: widget.authorId,
          authorName: widget.authorName,
          authorHandle: widget.authorHandle,
          authorAvatarUrl: widget.authorAvatarUrl,
          authorRating: widget.authorRating,
          content: _captionController.text,
          mediaUrl: _selectedPhotoUrl,
          mediaTag: _selectedTag,
        );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);

    return BlocConsumer<CreatePostCubit, CreatePostState>(
      listener: (context, state) {
        if (state is CreatePostSuccess) {
          widget.onPostCreated?.call(state.post);
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final isSubmitting = state is CreatePostSubmitting;

        return Container(
          height: mediaQuery.size.height * 0.85,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
          child: Column(
            children: [
              // Header
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Create Post',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Form Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (state is CreatePostFailure) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            state.error,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],

                      // Caption field
                      AppTextField(
                        controller: _captionController,
                        label: 'Caption',
                        hint: 'Share match highlights, tips, or announcements...',
                        maxLines: 4,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Photo attachment picker (presets)
                      Text(
                        'Attach a Photo (Optional):',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SizedBox(
                        height: 90,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _mockPhotos.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final photo = _mockPhotos[index];
                            final isSelected =
                                _selectedPhotoUrl == photo['url'];

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedPhotoUrl = isSelected
                                      ? null
                                      : photo['url'];
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 90,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : theme.dividerColor,
                                    width: isSelected ? 2.5 : 1.0,
                                  ),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        photo['url']!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Container(
                                          color: Colors.grey.shade300,
                                          child: const Icon(
                                            Icons.image,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.3),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Hashtag selector
                      Text(
                        'Topic Tag (Optional):',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: 8,
                        children: _popularTags.map((tag) {
                          final isSelected = _selectedTag == tag;
                          return ChoiceChip(
                            label: Text('#$tag'),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedTag = selected ? tag : null;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom submit button
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppButton.primary(
                    label: isSubmitting ? 'Publishing...' : 'Publish Post',
                    isLoading: isSubmitting,
                    onPressed: isSubmitting ? null : () => _handleSubmit(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
