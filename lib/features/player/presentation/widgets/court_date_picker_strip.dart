import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';

/// Horizontal scrollable date picker strip with past-date restrictions and calendar picker action.
class CourtDatePickerStrip extends StatelessWidget {
  final List<DateTime> dates;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const CourtDatePickerStrip({
    super.key,
    required this.dates,
    required this.selectedDate,
    required this.onDateSelected,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return _isSameDay(date, now);
  }

  Future<void> _openCalendarPicker(BuildContext context) async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final lastDate = dates.isNotEmpty
        ? dates.last.add(const Duration(days: 30))
        : firstDate.add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.isBefore(firstDate) ? firstDate : selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'SELECT COURT DATE',
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedFormat = DateFormat('EEEE, d MMMM yyyy').format(selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with current selected date label and calendar picker trigger
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Date',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedFormat,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.outlined(
              icon: const Icon(Icons.calendar_month_outlined, size: 20),
              tooltip: 'Choose date from calendar',
              onPressed: () => _openCalendarPicker(context),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Horizontal Date Card Carousel
        SizedBox(
          height: 82,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = _isSameDay(date, selectedDate);
              final isTodayDate = _isToday(date);
              final weekdayStr = isTodayDate ? 'TODAY' : DateFormat('EEE').format(date).toUpperCase();
              final dayNumStr = DateFormat('d').format(date);
              final monthStr = DateFormat('MMM').format(date).toUpperCase();

              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: Semantics(
                  button: true,
                  selected: isSelected,
                  label: '${isTodayDate ? "Today, " : ""}${DateFormat("EEEE, d MMMM").format(date)}',
                  child: InkWell(
                    key: Key('court_date_card_${date.year}_${date.month}_${date.day}'),
                    onTap: () => onDateSelected(date),
                    borderRadius: AppSpacing.borderRadiusSm,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 66,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                        horizontal: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: AppSpacing.borderRadiusSm,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          width: isSelected ? 2.0 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            weekdayStr,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : isTodayDate
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dayNumStr,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            monthStr,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary.withValues(alpha: 0.9)
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
