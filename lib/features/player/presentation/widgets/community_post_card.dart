import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/features/player/domain/entities/community_post.dart';

/// Card component presenting a community feed item (Photo post or Game-Request poll)
/// with author details, interaction controls, poll participation, and strict ownership checks.
class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final String currentUserId;
  final VoidCallback onToggleLike;
  final VoidCallback onOpenComments;
  final void Function(String optionId)? onVotePoll;
  final VoidCallback? onToggleFollow;
  final VoidCallback? onEditPost;
  final VoidCallback? onDeletePost;
  final VoidCallback? onReportPost;

  const CommunityPostCard({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onToggleLike,
    required this.onOpenComments,
    this.onVotePoll,
    this.onToggleFollow,
    this.onEditPost,
    this.onDeletePost,
    this.onReportPost,
  });

  bool get isOwnPost => post.authorId == currentUserId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header Row
          _buildAuthorRow(context),
          const SizedBox(height: AppSpacing.sm),

          // Post Text Caption
          Text(
            post.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Optional Photo Image
          if (post.type == PostType.image && post.mediaUrl != null) ...[
            _buildPhotoSection(context),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Game Request Poll Section
          if (post.type == PostType.gamePoll && post.pollDetails != null) ...[
            _buildPollSection(context, post.pollDetails!),
            const SizedBox(height: AppSpacing.sm),
          ],

          // Post Tag (if any)
          if (post.mediaTag != null && post.mediaTag!.isNotEmpty) ...[
            AppChip.neutral(
              label: post.mediaTag!.startsWith('#')
                  ? post.mediaTag!
                  : '#${post.mediaTag}',
            ),
            const SizedBox(height: AppSpacing.xs),
          ],

          const Divider(height: 16),

          // Engagement Footer
          _buildEngagementFooter(context),
        ],
      ),
    );
  }

  Widget _buildAuthorRow(BuildContext context) {
    final theme = Theme.of(context);
    final secondaryTextColor = theme.colorScheme.onSurfaceVariant;
    final initial = post.authorName.isNotEmpty
        ? post.authorName[0].toUpperCase()
        : 'P';

    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 16,
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
                  Flexible(
                    child: Text(
                      post.authorName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (post.authorRating != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${post.authorRating!.toStringAsFixed(1)} DUPR',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Text(
                    post.authorHandle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '• ${_formatTimeAgo(post.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Follow button if not own post
        if (!isOwnPost && onToggleFollow != null) ...[
          TextButton(
            onPressed: onToggleFollow,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              post.isAuthorFollowed ? 'Following' : '+ Follow',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: post.isAuthorFollowed
                    ? secondaryTextColor
                    : AppColors.primary,
              ),
            ),
          ),
        ],

        // Post Menu Options (Separates owner actions from moderation/report)
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: 20, color: secondaryTextColor),
          tooltip: 'Post options',
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEditPost?.call();
                break;
              case 'delete':
                onDeletePost?.call();
                break;
              case 'report':
                onReportPost?.call();
                break;
            }
          },
          itemBuilder: (context) {
            if (isOwnPost) {
              return [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: AppSpacing.sm),
                      Text('Edit Post'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      SizedBox(width: AppSpacing.sm),
                      Text('Delete Post', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ];
            } else {
              return [
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined, size: 18, color: AppColors.warning),
                      SizedBox(width: AppSpacing.sm),
                      Text('Report Post'),
                    ],
                  ),
                ),
              ];
            }
          },
        ),
      ],
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          post.mediaUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: Colors.grey,
            ),
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(strokeWidth: 2),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPollSection(BuildContext context, GamePollDetails poll) {
    final theme = Theme.of(context);
    final secondaryTextColor = theme.colorScheme.onSurfaceVariant;
    final dateStr = DateFormat.yMMMd().format(poll.playDate);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Venue Badge Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poll.venueName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      poll.venueAddress,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryTextColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Match Attributes Wrap
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildBadge(context, Icons.calendar_today, dateStr),
              _buildBadge(context, Icons.access_time, poll.timeSlot),
              _buildBadge(context, Icons.sports_tennis, poll.gameFormat),
              _buildBadge(context, Icons.speed, poll.targetSkillLevel),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Poll Options with vote counts and visual bar
          ...poll.options.map((option) {
            final isVoted = poll.myVotedOptionId == option.id;
            final percentage = poll.totalVotes > 0
                ? (option.voteCount / poll.totalVotes)
                : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: InkWell(
                onTap: onVotePoll != null ? () => onVotePoll!(option.id) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isVoted
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isVoted
                          ? AppColors.primary
                          : theme.dividerColor,
                      width: isVoted ? 1.5 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (isVoted) ...[
                                  const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Flexible(
                                  child: Text(
                                    option.text,
                                    style: TextStyle(
                                      fontWeight: isVoted
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${option.voteCount} (${(percentage * 100).toInt()}%)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isVoted
                                  ? AppColors.primary
                                  : secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: percentage,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isVoted ? AppColors.primary : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Total Votes Counter
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${poll.totalVotes} total ${poll.totalVotes == 1 ? "vote" : "votes"}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: secondaryTextColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementFooter(BuildContext context) {
    final secondaryTextColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      children: [
        // Like Button
        InkWell(
          onTap: onToggleLike,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(
                  post.isLikedByMe
                      ? Icons.favorite
                      : Icons.favorite_border,
                  size: 20,
                  color: post.isLikedByMe ? AppColors.error : secondaryTextColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '${post.likesCount}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: post.isLikedByMe ? AppColors.error : secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Comments Button
        InkWell(
          onTap: onOpenComments,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 20,
                  color: secondaryTextColor,
                ),
                const SizedBox(width: 6),
                Text(
                  '${post.commentsCount}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),

        // Post Type Badge
        if (post.type == PostType.gamePoll)
          const AppChip.info(label: 'Game Poll')
        else
          const AppChip.neutral(label: 'Photo Update'),
      ],
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
