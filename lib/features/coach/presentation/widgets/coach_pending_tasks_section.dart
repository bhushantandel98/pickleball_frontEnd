import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_dashboard_data.dart';

/// Displays pending booking approvals, reschedule updates, academy invitations, and coach action items.
class CoachPendingTasksSection extends StatelessWidget {
  final List<CoachPendingTask> tasks;

  const CoachPendingTasksSection({
    super.key,
    required this.tasks,
  });

  String _taskTypeLabel(CoachPendingTaskType type) {
    return switch (type) {
      CoachPendingTaskType.bookingApproval => 'Booking Approval',
      CoachPendingTaskType.academyInvitation => 'Academy Invitation',
      CoachPendingTaskType.rescheduleRequest => 'Reschedule Update',
      CoachPendingTaskType.sessionNotes => 'Session Notes',
    };
  }

  IconData _taskIcon(CoachPendingTaskType type) {
    return switch (type) {
      CoachPendingTaskType.bookingApproval => Icons.event_note_rounded,
      CoachPendingTaskType.academyInvitation => Icons.business_center_outlined,
      CoachPendingTaskType.rescheduleRequest => Icons.update_rounded,
      CoachPendingTaskType.sessionNotes => Icons.assignment_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Row(
            children: [
              Icon(
                Icons.pending_actions_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Pending Tasks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (tasks.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    '${tasks.length} pending',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (tasks.isEmpty)
          AppCard(
            key: const Key('coach_tasks_empty'),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.task_alt_rounded,
                    size: 36,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'No pending tasks for the selected context.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < tasks.length; i++) ...[
                _TaskCard(
                  task: tasks[i],
                  typeLabel: _taskTypeLabel(tasks[i].type),
                  icon: _taskIcon(tasks[i].type),
                ),
                if (i < tasks.length - 1) const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  final CoachPendingTask task;
  final String typeLabel;
  final IconData icon;

  const _TaskCard({
    required this.task,
    required this.typeLabel,
    required this.icon,
  });

  void _showTaskDetails(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(task.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.description),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Context: ${task.contextType == CoachSessionContext.personal ? 'Personal Coaching' : (task.academyName ?? 'Academy')}',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
              Text(
                'Timing: ${task.dueOrCreatedLabel}',
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAcademy = task.contextType == CoachSessionContext.academy;

    return AppCard(
      key: Key('coach_task_card_${task.id}'),
      onTap: () => _showTaskDetails(context),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: (task.isUrgent
                      ? AppColors.warning
                      : theme.colorScheme.primary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              icon,
              size: 20,
              color:
                  task.isUrgent ? AppColors.warning : theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      typeLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '•',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      isAcademy
                          ? (task.academyName ?? 'Academy')
                          : 'Personal Coaching',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (task.isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          'Action Needed',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  task.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  task.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  task.dueOrCreatedLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
