import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_text_field.dart';
import 'package:pickleball_platform/features/player/domain/entities/community_post.dart';
import 'package:pickleball_platform/features/player/domain/repositories/community_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/post_comments_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/post_comments_state.dart';

/// Modal bottom sheet displaying community post comments with interactive
/// comment submission capabilities.
class PostCommentsModal extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserAvatarUrl;
  final VoidCallback? onCommentAdded;

  const PostCommentsModal({
    super.key,
    required this.postId,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatarUrl,
    this.onCommentAdded,
  });

  static Future<void> show(
    BuildContext context, {
    required String postId,
    required String currentUserId,
    required String currentUserName,
    String? currentUserAvatarUrl,
    VoidCallback? onCommentAdded,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider(
        create: (_) => PostCommentsCubit(
          repository: sl<CommunityRepository>(),
        )..loadComments(postId),
        child: PostCommentsModal(
          postId: postId,
          currentUserId: currentUserId,
          currentUserName: currentUserName,
          currentUserAvatarUrl: currentUserAvatarUrl,
          onCommentAdded: onCommentAdded,
        ),
      ),
    );
  }

  @override
  State<PostCommentsModal> createState() => _PostCommentsModalState();
}

class _PostCommentsModalState extends State<PostCommentsModal> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmitComment(BuildContext blocContext) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final cubit = blocContext.read<PostCommentsCubit>();
    final success = await cubit.addComment(
      postId: widget.postId,
      authorId: widget.currentUserId,
      authorName: widget.currentUserName,
      authorAvatarUrl: widget.currentUserAvatarUrl,
      content: text,
    );

    if (success && mounted) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
      widget.onCommentAdded?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final theme = Theme.of(context);
    final secondaryTextColor = theme.colorScheme.onSurfaceVariant;

    return Container(
      height: mediaQuery.size.height * 0.75,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Column(
        children: [
          // Drag handle & title
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
                  'Comments',
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

          // Comments body
          Expanded(
            child: BlocBuilder<PostCommentsCubit, PostCommentsState>(
              builder: (context, state) {
                if (state is PostCommentsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PostCommentsError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  );
                }

                if (state is PostCommentsLoaded) {
                  if (state.comments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'No comments yet',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: secondaryTextColor,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Be the first to join the conversation!',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: state.comments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final comment = state.comments[index];
                      return _CommentItem(comment: comment);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),

          // Bottom comment input field
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(
                  top: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _commentController,
                      hint: 'Add a comment...',
                      textInputAction: TextInputAction.send,
                      onEditingComplete: () => _handleSubmitComment(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  BlocBuilder<PostCommentsCubit, PostCommentsState>(
                    builder: (context, state) {
                      final isSubmitting =
                          state is PostCommentsLoaded && state.isSubmitting;
                      return IconButton(
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send, color: AppColors.primary),
                        onPressed: isSubmitting
                            ? null
                            : () => _handleSubmitComment(context),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final PostComment comment;

  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryTextColor = theme.colorScheme.onSurfaceVariant;
    final initial = comment.authorName.isNotEmpty
        ? comment.authorName[0].toUpperCase()
        : 'P';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    comment.authorName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '• ${_formatTimeAgo(comment.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                comment.content,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}
