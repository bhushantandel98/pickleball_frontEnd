import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_calendar.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_calendar_state.dart';

/// Combined calendar schedule widget supporting Day, Week, and Month views,
/// context filtering (All/Personal/Academy/Blocked), and read-only academy indicators.
class CoachCalendarScheduleView extends StatelessWidget {
  final CoachCalendarLoaded state;
  final ValueChanged<CoachCalendarViewMode> onViewModeChanged;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<int> onStepDate;
  final ValueChanged<CalendarEntryContext?> onContextFilterChanged;
  final ValueChanged<String> onRemoveBlockedTime;

  const CoachCalendarScheduleView({
    super.key,
    required this.state,
    required this.onViewModeChanged,
    required this.onSelectDate,
    required this.onStepDate,
    required this.onContextFilterChanged,
    required this.onRemoveBlockedTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sessions = state.filteredSessions;
    final blocked = state.filteredBlockedTimes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // View mode & Date navigation
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SegmentedButton<CoachCalendarViewMode>(
                    segments: const [
                      ButtonSegment(
                        value: CoachCalendarViewMode.day,
                        label: Text('Day'),
                      ),
                      ButtonSegment(
                        value: CoachCalendarViewMode.week,
                        label: Text('Week'),
                      ),
                      ButtonSegment(
                        value: CoachCalendarViewMode.month,
                        label: Text('Month'),
                      ),
                    ],
                    selected: {state.viewMode},
                    onSelectionChanged: (selected) {
                      if (selected.isNotEmpty) {
                        onViewModeChanged(selected.first);
                      }
                    },
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Previous',
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => onStepDate(-1),
                      ),
                      Text(
                        _rangeLabel(state),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Next',
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => onStepDate(1),
                      ),
                      TextButton(
                        onPressed: () => onSelectDate(DateTime.now()),
                        child: const Text('Today'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Context filter chips
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  ChoiceChip(
                    label: const Text('All Contexts'),
                    selected: state.contextFilter == null,
                    onSelected: (_) => onContextFilterChanged(null),
                  ),
                  ChoiceChip(
                    label: const Text('Personal'),
                    selected:
                        state.contextFilter == CalendarEntryContext.personal,
                    onSelected: (_) =>
                        onContextFilterChanged(CalendarEntryContext.personal),
                  ),
                  ChoiceChip(
                    label: const Text('Academy'),
                    selected:
                        state.contextFilter == CalendarEntryContext.academy,
                    onSelected: (_) =>
                        onContextFilterChanged(CalendarEntryContext.academy),
                  ),
                  ChoiceChip(
                    label: const Text('Blocked'),
                    selected:
                        state.contextFilter == CalendarEntryContext.blocked,
                    onSelected: (_) =>
                        onContextFilterChanged(CalendarEntryContext.blocked),
                  ),
                ],
              ),
              if (state.viewMode == CoachCalendarViewMode.week) ...[
                const SizedBox(height: AppSpacing.md),
                _WeekStrip(
                  state: state,
                  onSelectDate: onSelectDate,
                ),
              ],
              if (state.viewMode == CoachCalendarViewMode.month) ...[
                const SizedBox(height: AppSpacing.md),
                _MonthGrid(
                  state: state,
                  onSelectDate: onSelectDate,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Chronological agenda list for the selected range
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _agendaTitle(state),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (sessions.isEmpty && blocked.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: Text(
                      'No sessions or blocked periods in this range.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                ..._buildChronologicalEntries(context, sessions, blocked),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildChronologicalEntries(
    BuildContext context,
    List<CoachCalendarSession> sessions,
    List<CoachBlockedTime> blocked,
  ) {
    final entries = <_TimelineEntry>[
      ...sessions.map((s) => _TimelineEntry(start: s.startTime, session: s)),
      ...blocked.map((b) => _TimelineEntry(start: b.startTime, blocked: b)),
    ]..sort((a, b) => a.start.compareTo(b.start));

    return entries.map((entry) {
      if (entry.session != null) {
        return _SessionCard(
          session: entry.session!,
          hasConflict: state.hasConflictForEntry(entry.session!.id),
        );
      }
      return _BlockedTimeCard(
        blockedTime: entry.blocked!,
        onRemove: () => onRemoveBlockedTime(entry.blocked!.id),
      );
    }).toList();
  }

  String _rangeLabel(CoachCalendarLoaded state) {
    final d = state.selectedDate;
    switch (state.viewMode) {
      case CoachCalendarViewMode.day:
        return '${_monthShort(d.month)} ${d.day}, ${d.year}';
      case CoachCalendarViewMode.week:
        final ws = state.weekStart;
        final we = state.weekEnd;
        return '${_monthShort(ws.month)} ${ws.day} – ${_monthShort(we.month)} ${we.day}';
      case CoachCalendarViewMode.month:
        return '${_monthFull(d.month)} ${d.year}';
    }
  }

  String _agendaTitle(CoachCalendarLoaded state) {
    switch (state.viewMode) {
      case CoachCalendarViewMode.day:
        return 'Day Schedule';
      case CoachCalendarViewMode.week:
        return 'Week Schedule';
      case CoachCalendarViewMode.month:
        return 'Month Schedule';
    }
  }
}

class _TimelineEntry {
  final DateTime start;
  final CoachCalendarSession? session;
  final CoachBlockedTime? blocked;

  _TimelineEntry({
    required this.start,
    this.session,
    this.blocked,
  });
}

class _WeekStrip extends StatelessWidget {
  final CoachCalendarLoaded state;
  final ValueChanged<DateTime> onSelectDate;

  const _WeekStrip({
    required this.state,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = List.generate(
      7,
      (i) => state.weekStart.add(Duration(days: i)),
    );
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      children: days.map((day) {
        final isSelected = _isSameDay(day, state.selectedDate);
        final count = state.sessionsOnDay(day).length +
            state.blockedTimesOnDay(day).length;

        return Expanded(
          child: InkWell(
            onTap: () => onSelectDate(day),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(color: theme.colorScheme.primary)
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weekdayLabels[day.weekday - 1],
                    style: theme.textTheme.labelSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count > 0 ? '$count' : '·',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: count > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final CoachCalendarLoaded state;
  final ValueChanged<DateTime> onSelectDate;

  const _MonthGrid({
    required this.state,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstOfMonth =
        DateTime(state.selectedDate.year, state.selectedDate.month, 1);
    final daysInMonth =
        DateTime(state.selectedDate.year, state.selectedDate.month + 1, 0).day;
    final leadingEmpty = firstOfMonth.weekday - 1;
    final totalCells = ((leadingEmpty + daysInMonth + 6) ~/ 7) * 7;
    const headers = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      children: [
        Row(
          children: headers
              .map(
                (h) => Expanded(
                  child: Center(
                    child: Text(
                      h,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalCells,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final dayNum = index - leadingEmpty + 1;
            if (dayNum < 1 || dayNum > daysInMonth) {
              return const SizedBox.shrink();
            }
            final day = DateTime(
              state.selectedDate.year,
              state.selectedDate.month,
              dayNum,
            );
            final isSelected = _isSameDay(day, state.selectedDate);
            final hasEntries = state.sessionsOnDay(day).isNotEmpty ||
                state.blockedTimesOnDay(day).isNotEmpty;

            return InkWell(
              onTap: () => onSelectDate(day),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNum',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (hasEntries)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final CoachCalendarSession session;
  final bool hasConflict;

  const _SessionCard({
    required this.session,
    required this.hasConflict,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPersonal = session.contextType == CalendarEntryContext.personal;
    final accentColor = isPersonal
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasConflict
              ? AppColors.warning
              : accentColor.withValues(alpha: 0.35),
        ),
        color: accentColor.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _ContextBadge(
                label: isPersonal ? 'Personal Coaching' : 'Academy',
                color: accentColor,
              ),
              if (!isPersonal && !session.canModifySchedule)
                _ContextBadge(
                  label: 'Academy Official Schedule (Read-only)',
                  color: theme.colorScheme.onSurfaceVariant,
                  icon: Icons.lock_outline,
                ),
              if (hasConflict)
                _ContextBadge(
                  label: 'Overlap Warning',
                  color: AppColors.warning,
                  icon: Icons.warning_amber_rounded,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            session.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_formatDayTimeRange(session.startTime, session.endTime)} • ${session.sessionType}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isPersonal
                ? '${session.venueOrBranchName} • ${session.participantCount} player(s) • ${session.statusLabel}'
                : '${session.academyName ?? ''} • ${session.branchName ?? session.venueOrBranchName}'
                    '${session.batchName != null ? ' • ${session.batchName}' : ''}'
                    ' • ${session.participantCount} players',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _BlockedTimeCard extends StatelessWidget {
  final CoachBlockedTime blockedTime;
  final VoidCallback onRemove;

  const _BlockedTimeCard({
    required this.blockedTime,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockedColor = AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: blockedColor.withValues(alpha: 0.35)),
        color: blockedColor.withValues(alpha: 0.05),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ContextBadge(
                  label: 'Personal Blocked Time',
                  color: blockedColor,
                  icon: Icons.block_outlined,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  blockedTime.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDayTimeRange(
                    blockedTime.startTime,
                    blockedTime.endTime,
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (blockedTime.reason != null &&
                    blockedTime.reason!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    blockedTime.reason!,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove blocked time',
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _ContextBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _ContextBadge({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _monthShort(int m) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return months[m - 1];
}

String _monthFull(int m) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return months[m - 1];
}

String _formatTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

String _formatDayTimeRange(DateTime start, DateTime end) =>
    '${_monthShort(start.month)} ${start.day}, ${_formatTime(start)} – ${_formatTime(end)}';
