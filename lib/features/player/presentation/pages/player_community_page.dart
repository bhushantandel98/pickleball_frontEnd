import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/mock/data/mock_data.dart';
import 'package:pickleball_platform/features/player/domain/repositories/community_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/community_feed_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/community_feed_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/community_post_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/create_game_poll_sheet.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/create_post_sheet.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/edit_post_dialog.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/post_comments_modal.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/report_post_dialog.dart';

/// Main Player Community & Matchmaking Page (/player/community).
///
/// Features:
/// 1. Community feed with photo posts and venue-referenced game-request polls.
/// 2. Category tab filtering (All, Game Polls, Photos, My Posts).
/// 3. Like/unlike and comment interactions.
/// 4. Author follow/unfollow capability.
/// 5. Poll participation with dynamic vote updates.
/// 6. Strict ownership checks: edit & delete restricted to owned posts.
/// 7. Content reporting dialog separated from author actions.
class PlayerCommunityPage extends StatelessWidget {
  const PlayerCommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    String currentUserId = MockData.playerUser.id;
    if (sl.isRegistered<SessionCubit>()) {
      final sessionState = sl<SessionCubit>().state;
      if (sessionState.userId != null) {
        currentUserId = sessionState.userId!;
      }
    }

    return BlocProvider(
      create: (_) => CommunityFeedCubit(
        repository: sl<CommunityRepository>(),
        currentUserId: currentUserId,
      )..loadFeed(),
      child: const _PlayerCommunityView(),
    );
  }
}

class _PlayerCommunityView extends StatelessWidget {
  const _PlayerCommunityView();

  void _showDeleteConfirmation(
    BuildContext context,
    String postId,
    VoidCallback onConfirm,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              onConfirm();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openCreatePost(BuildContext context, CommunityFeedCubit cubit) {
    CreatePostSheet.show(
      context,
      authorId: cubit.currentUserId,
      authorName: MockData.playerUser.name,
      authorHandle: '@alex_pickleball',
      authorAvatarUrl: MockData.playerUser.avatarUrl,
      authorRating: MockData.playerUser.rating,
      onPostCreated: (_) {
        cubit.loadFeed();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Post published successfully!')),
          );
      },
    );
  }

  void _openCreateGamePoll(BuildContext context, CommunityFeedCubit cubit) {
    CreateGamePollSheet.show(
      context,
      authorId: cubit.currentUserId,
      authorName: MockData.playerUser.name,
      authorHandle: '@alex_pickleball',
      authorAvatarUrl: MockData.playerUser.avatarUrl,
      authorRating: MockData.playerUser.rating,
      onPollCreated: (_) {
        cubit.loadFeed();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Game request poll broadcast successfully!'),
            ),
          );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommunityFeedCubit>();
    final theme = Theme.of(context);
    final secondaryTextColor = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community & Matchmaking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Feed',
            onPressed: () => cubit.loadFeed(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'fab_request_game',
            icon: const Icon(Icons.sports_tennis),
            label: const Text('Request Game'),
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            onPressed: () => _openCreateGamePoll(context, cubit),
          ),
          const SizedBox(height: AppSpacing.sm),
          FloatingActionButton.extended(
            heroTag: 'fab_create_post',
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('New Post'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            onPressed: () => _openCreatePost(context, cubit),
          ),
        ],
      ),
      body: BlocConsumer<CommunityFeedCubit, CommunityFeedState>(
        listener: (context, state) {
          if (state is CommunityFeedLoaded) {
            if (state.feedbackMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(state.feedbackMessage!)),
                );
              cubit.clearFeedback();
            } else if (state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: AppColors.error,
                  ),
                );
              cubit.clearFeedback();
            }
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Filter tabs
              _FilterTabsBar(
                currentTab: state is CommunityFeedLoaded
                    ? state.activeTab
                    : CommunityFilterTab.all,
                onTabSelected: (tab) => cubit.setFilterTab(tab),
              ),
              const Divider(height: 1),

              // Content Body
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (state is CommunityFeedLoading ||
                        state is CommunityFeedInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is CommunityFeedError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: AppColors.error,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.error),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ElevatedButton(
                                onPressed: () => cubit.loadFeed(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is CommunityFeedLoaded) {
                      if (state.posts.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: () => cubit.loadFeed(),
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.45,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.forum_outlined,
                                        size: 56,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        'No posts found',
                                        style:
                                            theme.textTheme.titleMedium?.copyWith(
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Be the first player to start the conversation!',
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () => cubit.loadFeed(),
                        child: ListView.separated(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.md,
                            right: AppSpacing.md,
                            top: AppSpacing.md,
                            bottom: 96, // clearance for dual FABs
                          ),
                          itemCount: state.posts.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final post = state.posts[index];

                            return CommunityPostCard(
                              post: post,
                              currentUserId: cubit.currentUserId,
                              onToggleLike: () => cubit.toggleLike(post.id),
                              onOpenComments: () {
                                PostCommentsModal.show(
                                  context,
                                  postId: post.id,
                                  currentUserId: cubit.currentUserId,
                                  currentUserName: MockData.playerUser.name,
                                  currentUserAvatarUrl:
                                      MockData.playerUser.avatarUrl,
                                  onCommentAdded: () => cubit.loadFeed(),
                                );
                              },
                              onVotePoll: (optionId) =>
                                  cubit.votePoll(post.id, optionId),
                              onToggleFollow: () =>
                                  cubit.toggleFollow(post.authorId),
                              onEditPost: () {
                                EditPostDialog.show(
                                  context,
                                  postId: post.id,
                                  initialContent: post.content,
                                  onSave: (newContent) =>
                                      cubit.updatePost(post.id, newContent),
                                );
                              },
                              onDeletePost: () {
                                _showDeleteConfirmation(
                                  context,
                                  post.id,
                                  () => cubit.deletePost(post.id),
                                );
                              },
                              onReportPost: () {
                                ReportPostDialog.show(
                                  context,
                                  postId: post.id,
                                  onReport: (reason, notes) {
                                    cubit.reportPost(
                                      postId: post.id,
                                      reason: reason,
                                      notes: notes,
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterTabsBar extends StatelessWidget {
  final CommunityFilterTab currentTab;
  final ValueChanged<CommunityFilterTab> onTabSelected;

  const _FilterTabsBar({
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: CommunityFilterTab.values.map((tab) {
          final isSelected = currentTab == tab;

          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(tab.label),
              selected: isSelected,
              onSelected: (_) => onTabSelected(tab),
            ),
          );
        }).toList(),
      ),
    );
  }
}
