import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_profile.dart';

/// Displays and manages coach certifications (add, edit, remove).
/// Verification/approval workflows are omitted per PRD.
class CoachProfileCertificationsSection extends StatelessWidget {
  final List<CoachCertification> certifications;
  final Future<bool> Function(CoachCertification certification) onAdd;
  final Future<bool> Function(CoachCertification certification) onUpdate;
  final Future<bool> Function(String certificationId) onRemove;

  const CoachProfileCertificationsSection({
    super.key,
    required this.certifications,
    required this.onAdd,
    required this.onUpdate,
    required this.onRemove,
  });

  void _openCertificationDialog(
    BuildContext context, {
    CoachCertification? existing,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => _CertificationFormDialog(
        existing: existing,
        onSubmit: (cert) => existing == null ? onAdd(cert) : onUpdate(cert),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      key: const Key('coach_profile_certifications_card'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Certifications',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                key: const Key('coach_add_certification_button'),
                onPressed: () => _openCertificationDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (certifications.isEmpty)
            Padding(
              key: const Key('coach_certifications_empty'),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: Text(
                  'No certifications added yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < certifications.length; i++) ...[
                  _CertificationTile(
                    certification: certifications[i],
                    onEdit: () => _openCertificationDialog(
                      context,
                      existing: certifications[i],
                    ),
                    onDelete: () => onRemove(certifications[i].id),
                  ),
                  if (i < certifications.length - 1)
                    const Divider(height: AppSpacing.md),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _CertificationTile extends StatelessWidget {
  final CoachCertification certification;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CertificationTile({
    required this.certification,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      key: Key('coach_certification_item_${certification.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                certification.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${certification.issuingBody}${certification.yearObtained.isNotEmpty ? ' • ${certification.yearObtained}' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (certification.details != null &&
                  certification.details!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  certification.details!,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        IconButton(
          key: Key('coach_edit_cert_${certification.id}'),
          tooltip: 'Edit certification',
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 18),
        ),
        IconButton(
          key: Key('coach_delete_cert_${certification.id}'),
          tooltip: 'Remove certification',
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

class _CertificationFormDialog extends StatefulWidget {
  final CoachCertification? existing;
  final Future<bool> Function(CoachCertification certification) onSubmit;

  const _CertificationFormDialog({
    this.existing,
    required this.onSubmit,
  });

  @override
  State<_CertificationFormDialog> createState() =>
      _CertificationFormDialogState();
}

class _CertificationFormDialogState extends State<_CertificationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _issuerController;
  late final TextEditingController _yearController;
  late final TextEditingController _detailsController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _issuerController =
        TextEditingController(text: widget.existing?.issuingBody ?? '');
    _yearController =
        TextEditingController(text: widget.existing?.yearObtained ?? '');
    _detailsController =
        TextEditingController(text: widget.existing?.details ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _yearController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cert = CoachCertification(
      id: widget.existing?.id ?? '',
      name: _nameController.text,
      issuingBody: _issuerController.text,
      yearObtained: _yearController.text,
      details: _detailsController.text,
    );
    final ok = await widget.onSubmit(cert);
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit Certification' : 'Add Certification'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('coach_cert_name_field'),
                controller: _nameController,
                decoration:
                    const InputDecoration(labelText: 'Certification Name'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Certification name is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('coach_cert_issuer_field'),
                controller: _issuerController,
                decoration: const InputDecoration(labelText: 'Issuing Body'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Issuing body is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('coach_cert_year_field'),
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Year Obtained'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('coach_cert_details_field'),
                controller: _detailsController,
                decoration:
                    const InputDecoration(labelText: 'Details (optional)'),
                maxLines: 2,
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
          key: const Key('coach_cert_save_button'),
          onPressed: _submit,
          child: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
