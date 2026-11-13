import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/features/coach/domain/entities/personal_coaching_booking.dart';

class PersonalBookingFormResult {
  final String playerName;
  final String playerContact;
  final String sessionTitle;
  final String sessionType;
  final String venueName;
  final DateTime startTime;
  final DateTime endTime;
  final String? notes;

  const PersonalBookingFormResult({
    required this.playerName,
    required this.playerContact,
    required this.sessionTitle,
    required this.sessionType,
    required this.venueName,
    required this.startTime,
    required this.endTime,
    this.notes,
  });
}

/// Modal dialog for creating or editing a coach's personal coaching booking.
class PersonalBookingFormDialog extends StatefulWidget {
  final PersonalCoachingBooking? existing;

  const PersonalBookingFormDialog({
    super.key,
    this.existing,
  });

  static Future<PersonalBookingFormResult?> show(
    BuildContext context, {
    PersonalCoachingBooking? existing,
  }) {
    return showDialog<PersonalBookingFormResult>(
      context: context,
      builder: (_) => PersonalBookingFormDialog(existing: existing),
    );
  }

  @override
  State<PersonalBookingFormDialog> createState() =>
      _PersonalBookingFormDialogState();
}

class _PersonalBookingFormDialogState extends State<PersonalBookingFormDialog> {
  static const _sessionTypes = [
    '1-on-1 Coaching',
    'Semi-Private',
    'Assessment',
    'Small Group',
  ];

  late final TextEditingController _playerNameController;
  late final TextEditingController _playerContactController;
  late final TextEditingController _titleController;
  late final TextEditingController _venueController;
  late final TextEditingController _startController;
  late final TextEditingController _endController;
  late final TextEditingController _notesController;
  late String _sessionType;
  late DateTime _pickedDate;
  String? _errorText;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _playerNameController = TextEditingController(text: b?.playerName ?? '');
    _playerContactController =
        TextEditingController(text: b?.playerContact ?? '');
    _titleController = TextEditingController(text: b?.sessionTitle ?? '');
    _venueController = TextEditingController(text: b?.venueName ?? '');
    _notesController = TextEditingController(text: b?.notes ?? '');
    _sessionType = (b != null && _sessionTypes.contains(b.sessionType))
        ? b.sessionType
        : _sessionTypes.first;

    final baseStart = b?.startTime ?? DateTime.now().add(const Duration(days: 1));
    _pickedDate = DateTime(baseStart.year, baseStart.month, baseStart.day);
    _startController = TextEditingController(
      text: b != null ? _hhmm(b.startTime) : '08:00',
    );
    _endController = TextEditingController(
      text: b != null ? _hhmm(b.endTime) : '09:00',
    );
  }

  @override
  void dispose() {
    _playerNameController.dispose();
    _playerContactController.dispose();
    _titleController.dispose();
    _venueController.dispose();
    _startController.dispose();
    _endController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConfirmedEdit =
        widget.existing?.status == PersonalBookingStatus.confirmed;

    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit Personal Booking' : 'Create Personal Booking',
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isEditing)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'New bookings start as Pending Player Approval until the player approves or declines.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              if (isConfirmedEdit)
                Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Editing a confirmed booking invalidates previous player approval and returns it to Pending Player Approval.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              TextField(
                controller: _playerNameController,
                enabled: !_isEditing,
                decoration: const InputDecoration(
                  labelText: 'Player Name',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _playerContactController,
                enabled: !_isEditing,
                decoration: const InputDecoration(
                  labelText: 'Player Contact (optional)',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Session Title',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _sessionType,
                decoration: const InputDecoration(labelText: 'Session Type'),
                items: _sessionTypes
                    .map(
                      (t) => DropdownMenuItem<String>(
                        value: t,
                        child: Text(t),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _sessionType = val);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _venueController,
                decoration: const InputDecoration(
                  labelText: 'Venue',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: ${_pickedDate.year}-${_pickedDate.month.toString().padLeft(2, '0')}-${_pickedDate.day.toString().padLeft(2, '0')}',
                  ),
                  TextButton(
                    onPressed: () async {
                      final chosen = await showDatePicker(
                        context: context,
                        initialDate: _pickedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2030),
                      );
                      if (chosen != null) {
                        setState(() => _pickedDate = chosen);
                      }
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _startController,
                      decoration: const InputDecoration(
                        labelText: 'Start (HH:MM)',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: _endController,
                      decoration: const InputDecoration(
                        labelText: 'End (HH:MM)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Session Notes (optional)',
                ),
              ),
              if (_errorText != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _errorText!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(_isEditing ? 'Save Changes' : 'Create Booking'),
        ),
      ],
    );
  }

  void _submit() {
    final playerName = _playerNameController.text.trim();
    final title = _titleController.text.trim();
    final venue = _venueController.text.trim();
    final startDt = _parseTimeOnDate(_pickedDate, _startController.text.trim());
    final endDt = _parseTimeOnDate(_pickedDate, _endController.text.trim());

    if (playerName.isEmpty || title.isEmpty || venue.isEmpty) {
      setState(
        () => _errorText = 'Player name, session title, and venue are required.',
      );
      return;
    }
    if (startDt == null || endDt == null || !endDt.isAfter(startDt)) {
      setState(
        () => _errorText = 'Enter valid HH:MM times with end after start.',
      );
      return;
    }

    Navigator.of(context).pop(
      PersonalBookingFormResult(
        playerName: playerName,
        playerContact: _playerContactController.text.trim(),
        sessionTitle: title,
        sessionType: _sessionType,
        venueName: venue,
        startTime: startDt,
        endTime: endDt,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
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

  String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
