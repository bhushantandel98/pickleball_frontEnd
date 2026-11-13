import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';

/// Displays and manages the coach's personal specializations.
class CoachProfileSpecializationsSection extends StatelessWidget {
  final List<String> specializations;
  final Future<bool> Function(String specialization) onAdd;
  final Future<bool> Function(String specialization) onRemove;

  const CoachProfileSpecializationsSection({
    super.key,
    required this.specializations,
    required this.onAdd,
    required this.onRemove,
  });

  void _openAddDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddSpecializationDialog(onAdd: onAdd),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      key: const Key('coach_profile_specializations_card'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_outline_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Specializations',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                key: const Key('coach_add_specialization_button'),
                onPressed: () => _openAddDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (specializations.isEmpty)
            Padding(
              key: const Key('coach_specializations_empty'),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No specializations added yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          else
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final spec in specializations)
                  InputChip(
                    key: Key('coach_spec_chip_$spec'),
                    label: Text(spec),
                    onDeleted: () => onRemove(spec),
                    deleteButtonTooltipMessage: 'Remove $spec',
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AddSpecializationDialog extends StatefulWidget {
  final Future<bool> Function(String specialization) onAdd;

  const _AddSpecializationDialog({required this.onAdd});

  @override
  State<_AddSpecializationDialog> createState() =>
      _AddSpecializationDialogState();
}

class _AddSpecializationDialogState extends State<_AddSpecializationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await widget.onAdd(_controller.text);
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Specialization'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          key: const Key('coach_spec_input_field'),
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Specialization',
            hintText: 'e.g., Footwork & Court Coverage',
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Specialization cannot be empty'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('coach_spec_save_button'),
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
