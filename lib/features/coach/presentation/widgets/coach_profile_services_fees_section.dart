import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_profile.dart';

/// Displays and manages personal coaching services and personal coaching fees,
/// kept strictly separate from academy-owned programs and finances.
class CoachProfileServicesFeesSection extends StatelessWidget {
  final CoachProfile profile;
  final Future<bool> Function(CoachServiceOffering service) onAddService;
  final Future<bool> Function(CoachServiceOffering service) onUpdateService;
  final Future<bool> Function(String serviceId) onRemoveService;
  final Future<bool> Function({
    required double defaultHourlyFee,
    required String feeNotes,
  }) onSaveFees;

  const CoachProfileServicesFeesSection({
    super.key,
    required this.profile,
    required this.onAddService,
    required this.onUpdateService,
    required this.onRemoveService,
    required this.onSaveFees,
  });

  void _openFeesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _EditFeesDialog(
        profile: profile,
        onSave: onSaveFees,
      ),
    );
  }

  void _openServiceDialog(
    BuildContext context, {
    CoachServiceOffering? existing,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => _ServiceFormDialog(
        existing: existing,
        onSubmit: (service) =>
            existing == null ? onAddService(service) : onUpdateService(service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fees Card
        AppCard(
          key: const Key('coach_profile_fees_card'),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Personal Coaching Fees',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('coach_edit_fees_button'),
                    tooltip: 'Edit Fees',
                    onPressed: () => _openFeesDialog(context),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              Text(
                'Personal coaching rates only • Separate from academy finances',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${profile.currencySymbol}${profile.defaultHourlyFee.toStringAsFixed(0)} / hour',
                key: const Key('coach_default_fee_text'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
              if (profile.feeNotes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  profile.feeNotes,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Coaching Services Card
        AppCard(
          key: const Key('coach_profile_services_card'),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.sports_tennis_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Coaching Services',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    key: const Key('coach_add_service_button'),
                    onPressed: () => _openServiceDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              if (profile.services.isEmpty)
                Padding(
                  key: const Key('coach_services_empty'),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(
                    child: Text(
                      'No personal coaching services added yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < profile.services.length; i++) ...[
                      _ServiceTile(
                        service: profile.services[i],
                        onEdit: () => _openServiceDialog(
                          context,
                          existing: profile.services[i],
                        ),
                        onDelete: () => onRemoveService(profile.services[i].id),
                      ),
                      if (i < profile.services.length - 1)
                        const Divider(height: AppSpacing.md),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final CoachServiceOffering service;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceTile({
    required this.service,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      key: Key('coach_service_item_${service.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                service.description,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '${service.durationMinutes} mins • ${service.currencySymbol}${service.fee.toStringAsFixed(0)}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: Key('coach_edit_service_${service.id}'),
          tooltip: 'Edit service',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
        ),
        IconButton(
          key: Key('coach_delete_service_${service.id}'),
          tooltip: 'Remove service',
          onPressed: onDelete,
          icon: Icon(
            Icons.delete_outline,
            size: 18,
            color: theme.colorScheme.error,
          ),
        ),
      ],
    );
  }
}

class _EditFeesDialog extends StatefulWidget {
  final CoachProfile profile;
  final Future<bool> Function({
    required double defaultHourlyFee,
    required String feeNotes,
  }) onSave;

  const _EditFeesDialog({
    required this.profile,
    required this.onSave,
  });

  @override
  State<_EditFeesDialog> createState() => _EditFeesDialogState();
}

class _EditFeesDialogState extends State<_EditFeesDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _feeController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _feeController = TextEditingController(
      text: widget.profile.defaultHourlyFee.toStringAsFixed(0),
    );
    _notesController = TextEditingController(text: widget.profile.feeNotes);
  }

  @override
  void dispose() {
    _feeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final fee = double.tryParse(_feeController.text.trim()) ?? 0;
    final ok = await widget.onSave(
      defaultHourlyFee: fee,
      feeNotes: _notesController.text,
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Personal Coaching Fees'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('coach_fee_amount_field'),
                controller: _feeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      'Default Hourly Fee (${widget.profile.currencySymbol})',
                ),
                validator: (v) {
                  final parsed = double.tryParse(v?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a fee greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('coach_fee_notes_field'),
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Fee Notes'),
                maxLines: 3,
              ),
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
          key: const Key('coach_fee_save_button'),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ServiceFormDialog extends StatefulWidget {
  final CoachServiceOffering? existing;
  final Future<bool> Function(CoachServiceOffering service) onSubmit;

  const _ServiceFormDialog({
    this.existing,
    required this.onSubmit,
  });

  @override
  State<_ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<_ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _durationController;
  late final TextEditingController _feeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _descController =
        TextEditingController(text: widget.existing?.description ?? '');
    _durationController = TextEditingController(
      text: (widget.existing?.durationMinutes ?? 60).toString(),
    );
    _feeController = TextEditingController(
      text: widget.existing != null
          ? widget.existing!.fee.toStringAsFixed(0)
          : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _durationController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final duration = int.tryParse(_durationController.text.trim()) ?? 60;
    final fee = double.tryParse(_feeController.text.trim()) ?? 0;
    final service = CoachServiceOffering(
      id: widget.existing?.id ?? '',
      name: _nameController.text,
      description: _descController.text,
      durationMinutes: duration,
      fee: fee,
    );
    final ok = await widget.onSubmit(service);
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Coaching Service' : 'Add Coaching Service'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('coach_service_name_field'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Service Name'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Service name is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('coach_service_desc_field'),
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Description is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('coach_service_duration_field'),
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Duration (minutes)'),
                validator: (v) {
                  final parsed = int.tryParse(v?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter valid duration';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('coach_service_fee_field'),
                controller: _feeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Fee (₹)'),
                validator: (v) {
                  final parsed = double.tryParse(v?.trim() ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Enter valid fee';
                  }
                  return null;
                },
              ),
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
          key: const Key('coach_service_save_button'),
          onPressed: _submit,
          child: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
