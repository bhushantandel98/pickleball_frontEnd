import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_calendar.dart';

typedef AddBlockedTimeCallback = Future<bool> Function({
  required String title,
  required DateTime startTime,
  required DateTime endTime,
  String? reason,
});

/// Manages the coach's personal coaching availability windows and personal
/// blocked-time periods. Does not alter official academy schedules.
class CoachAvailabilityManagementSection extends StatelessWidget {
  final List<PersonalAvailabilityWindow> availabilityWindows;
  final List<CoachBlockedTime> blockedTimes;
  final DateTime selectedDate;
  final Future<bool> Function(PersonalAvailabilityWindow window)
      onAddAvailability;
  final Future<bool> Function(String windowId, bool isActive)
      onToggleAvailability;
  final Future<bool> Function(String windowId) onRemoveAvailability;
  final AddBlockedTimeCallback onAddBlockedTime;
  final Future<bool> Function(String blockedTimeId) onRemoveBlockedTime;

  const CoachAvailabilityManagementSection({
    super.key,
    required this.availabilityWindows,
    required this.blockedTimes,
    required this.selectedDate,
    required this.onAddAvailability,
    required this.onToggleAvailability,
    required this.onRemoveAvailability,
    required this.onAddBlockedTime,
    required this.onRemoveBlockedTime,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Personal Availability Windows
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Personal Availability',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _showAddAvailabilityDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Availability'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Applies to personal coaching only. Academy schedules remain separate.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (availabilityWindows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    'No personal availability windows configured.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...availabilityWindows.map(
                  (window) => Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${window.dayLabel} • ${window.startTimeLabel} – ${window.endTimeLabel}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (window.locationNote.isNotEmpty)
                                Text(
                                  window.locationNote,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Switch(
                          value: window.isActive,
                          onChanged: (val) =>
                              onToggleAvailability(window.id, val),
                        ),
                        IconButton(
                          tooltip: 'Remove availability',
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => onRemoveAvailability(window.id),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Personal Blocked Time
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Blocked Time',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _showAddBlockedTimeDialog(context),
                    icon: const Icon(Icons.block_outlined, size: 18),
                    label: const Text('Block Time'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Mark personal unavailable periods on your calendar.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (blockedTimes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Text(
                    'No blocked periods added.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...blockedTimes.map(
                  (blocked) => Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                blocked.title,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatRange(
                                  blocked.startTime,
                                  blocked.endTime,
                                ),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove blocked period',
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => onRemoveBlockedTime(blocked.id),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showAddAvailabilityDialog(BuildContext context) async {
    const dayNames = <int, String>{
      DateTime.monday: 'Monday',
      DateTime.tuesday: 'Tuesday',
      DateTime.wednesday: 'Wednesday',
      DateTime.thursday: 'Thursday',
      DateTime.friday: 'Friday',
      DateTime.saturday: 'Saturday',
      DateTime.sunday: 'Sunday',
    };
    int selectedDay = DateTime.monday;
    final startController = TextEditingController(text: '07:00');
    final endController = TextEditingController(text: '09:00');
    final locationController =
        TextEditingController(text: 'Personal Coaching Venue');
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Add Personal Availability'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedDay,
                      decoration: const InputDecoration(labelText: 'Day'),
                      items: dayNames.entries
                          .map(
                            (e) => DropdownMenuItem<int>(
                              value: e.key,
                              child: Text(e.value),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => selectedDay = val);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: startController,
                      decoration: const InputDecoration(
                        labelText: 'Start Time (HH:MM)',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: endController,
                      decoration: const InputDecoration(
                        labelText: 'End Time (HH:MM)',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location Note',
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        errorText!,
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final start = startController.text.trim();
                    final end = endController.text.trim();
                    if (start.isEmpty || end.isEmpty) {
                      setState(
                        () => errorText = 'Start and end times are required.',
                      );
                      return;
                    }
                    final window = PersonalAvailabilityWindow(
                      id: 'avl_${DateTime.now().microsecondsSinceEpoch}',
                      dayOfWeek: selectedDay,
                      dayLabel: dayNames[selectedDay] ?? 'Monday',
                      startTimeLabel: start,
                      endTimeLabel: end,
                      locationNote: locationController.text.trim(),
                      isActive: true,
                    );
                    Navigator.of(dialogContext).pop();
                    await onAddAvailability(window);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddBlockedTimeDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final reasonController = TextEditingController();
    final startHourController = TextEditingController(text: '13:00');
    final endHourController = TextEditingController(text: '15:00');
    DateTime pickedDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Add Blocked Time'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g. Travel / Recovery',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Date: ${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}',
                        ),
                        TextButton(
                          onPressed: () async {
                            final chosen = await showDatePicker(
                              context: ctx,
                              initialDate: pickedDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (chosen != null) {
                              setState(() => pickedDate = chosen);
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextField(
                      controller: startHourController,
                      decoration: const InputDecoration(
                        labelText: 'Start Time (HH:MM)',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: endHourController,
                      decoration: const InputDecoration(
                        labelText: 'End Time (HH:MM)',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: reasonController,
                      decoration: const InputDecoration(
                        labelText: 'Reason (optional)',
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        errorText!,
                        style: TextStyle(
                          color: Theme.of(ctx).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final startDt = _parseTimeOnDate(
                      pickedDate,
                      startHourController.text.trim(),
                    );
                    final endDt = _parseTimeOnDate(
                      pickedDate,
                      endHourController.text.trim(),
                    );

                    if (title.isEmpty) {
                      setState(() => errorText = 'Title is required.');
                      return;
                    }
                    if (startDt == null ||
                        endDt == null ||
                        !endDt.isAfter(startDt)) {
                      setState(
                        () => errorText =
                            'Enter valid HH:MM times with end after start.',
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop();
                    await onAddBlockedTime(
                      title: title,
                      startTime: startDt,
                      endTime: endDt,
                      reason: reasonController.text.trim().isEmpty
                          ? null
                          : reasonController.text.trim(),
                    );
                  },
                  child: const Text('Block Time'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  DateTime? _parseTimeOnDate(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return null;
    }
    return DateTime(date.year, date.month, date.day, h, m);
  }

  String _formatRange(DateTime start, DateTime end) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final sH = start.hour.toString().padLeft(2, '0');
    final sM = start.minute.toString().padLeft(2, '0');
    final eH = end.hour.toString().padLeft(2, '0');
    final eM = end.minute.toString().padLeft(2, '0');
    return '${months[start.month - 1]} ${start.day}, $sH:$sM – $eH:$eM';
  }
}
