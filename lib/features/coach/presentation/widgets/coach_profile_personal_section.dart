import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_profile.dart';
import 'package:pickleball_platform/features/profile/presentation/widgets/avatar_picker_dialog.dart';
import 'package:pickleball_platform/features/profile/presentation/widgets/profile_avatar_view.dart';

/// Displays Coach Personal Details (photo, name, contact info, bio) and Experience
/// with local mock edit dialogs.
class CoachProfilePersonalSection extends StatelessWidget {
  final CoachProfile profile;
  final ValueChanged<String?> onAvatarChanged;
  final Future<bool> Function({
    required String fullName,
    required String phone,
    required String email,
    required String city,
    required String bio,
  }) onSavePersonalDetails;
  final Future<bool> Function({
    required int yearsOfExperience,
    required String coachingExperienceSummary,
    required String professionalBackground,
  }) onSaveExperience;

  const CoachProfilePersonalSection({
    super.key,
    required this.profile,
    required this.onAvatarChanged,
    required this.onSavePersonalDetails,
    required this.onSaveExperience,
  });

  void _openAvatarPicker(BuildContext context) {
    AvatarPickerDialog.show(
      context: context,
      currentAvatarUrl: profile.avatarUrl,
      onAvatarSelected: onAvatarChanged,
    );
  }

  void _openEditPersonalDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _EditPersonalDetailsDialog(
        profile: profile,
        onSave: onSavePersonalDetails,
      ),
    );
  }

  void _openEditExperienceDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _EditExperienceDialog(
        profile: profile,
        onSave: onSaveExperience,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Personal Details Card
        AppCard(
          key: const Key('coach_profile_personal_card'),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileAvatarView(
                    name: profile.fullName,
                    avatarUrl: profile.avatarUrl,
                    radius: 34,
                    isEditable: true,
                    onEdit: () => _openAvatarPicker(context),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Coach Profile',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          profile.fullName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          profile.city,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('coach_edit_personal_button'),
                    tooltip: 'Edit Personal Details',
                    onPressed: () => _openEditPersonalDialog(context),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('coach_change_photo_button'),
                  onPressed: () => _openAvatarPicker(context),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Change Profile Photo'),
                ),
              ),
              const Divider(height: AppSpacing.md),
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: profile.phone,
              ),
              const SizedBox(height: AppSpacing.xs),
              _DetailRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: profile.email,
              ),
              if (profile.bio.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  profile.bio,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 2. Experience Card
        AppCard(
          key: const Key('coach_profile_experience_card'),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.work_history_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Experience',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('coach_edit_experience_button'),
                    tooltip: 'Edit Experience',
                    onPressed: () => _openEditExperienceDialog(context),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${profile.yearsOfExperience} ${profile.yearsOfExperience == 1 ? 'Year' : 'Years'} of Coaching Experience',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Coaching Experience',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                profile.coachingExperienceSummary,
                style: theme.textTheme.bodyMedium,
              ),
              if (profile.professionalBackground.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Professional Background',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  profile.professionalBackground,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EditPersonalDetailsDialog extends StatefulWidget {
  final CoachProfile profile;
  final Future<bool> Function({
    required String fullName,
    required String phone,
    required String email,
    required String city,
    required String bio,
  }) onSave;

  const _EditPersonalDetailsDialog({
    required this.profile,
    required this.onSave,
  });

  @override
  State<_EditPersonalDetailsDialog> createState() =>
      _EditPersonalDetailsDialogState();
}

class _EditPersonalDetailsDialogState
    extends State<_EditPersonalDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _cityController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.fullName);
    _phoneController = TextEditingController(text: widget.profile.phone);
    _emailController = TextEditingController(text: widget.profile.email);
    _cityController = TextEditingController(text: widget.profile.city);
    _bioController = TextEditingController(text: widget.profile.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await widget.onSave(
      fullName: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      city: _cityController.text,
      bio: _bioController.text,
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Personal Details'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('coach_edit_name_field'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('coach_edit_phone_field'),
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (v) => (v == null || v.trim().length < 8)
                    ? 'Enter a valid phone number'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('coach_edit_email_field'),
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                validator: (v) =>
                    (v == null || !v.contains('@') || !v.contains('.'))
                        ? 'Enter a valid email'
                        : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('coach_edit_city_field'),
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'City is required' : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('coach_edit_bio_field'),
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Short Bio'),
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
          key: const Key('coach_save_personal_button'),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _EditExperienceDialog extends StatefulWidget {
  final CoachProfile profile;
  final Future<bool> Function({
    required int yearsOfExperience,
    required String coachingExperienceSummary,
    required String professionalBackground,
  }) onSave;

  const _EditExperienceDialog({
    required this.profile,
    required this.onSave,
  });

  @override
  State<_EditExperienceDialog> createState() => _EditExperienceDialogState();
}

class _EditExperienceDialogState extends State<_EditExperienceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _yearsController;
  late final TextEditingController _summaryController;
  late final TextEditingController _backgroundController;

  @override
  void initState() {
    super.initState();
    _yearsController = TextEditingController(
      text: widget.profile.yearsOfExperience.toString(),
    );
    _summaryController = TextEditingController(
      text: widget.profile.coachingExperienceSummary,
    );
    _backgroundController = TextEditingController(
      text: widget.profile.professionalBackground,
    );
  }

  @override
  void dispose() {
    _yearsController.dispose();
    _summaryController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final years = int.tryParse(_yearsController.text.trim()) ?? 0;
    final ok = await widget.onSave(
      yearsOfExperience: years,
      coachingExperienceSummary: _summaryController.text,
      professionalBackground: _backgroundController.text,
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Experience'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('coach_edit_years_field'),
                controller: _yearsController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Years of Experience'),
                validator: (v) {
                  final parsed = int.tryParse(v?.trim() ?? '');
                  if (parsed == null || parsed < 0 || parsed > 60) {
                    return 'Enter valid years (0–60)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('coach_edit_exp_summary_field'),
                controller: _summaryController,
                decoration:
                    const InputDecoration(labelText: 'Coaching Experience'),
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Experience summary is required'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                key: const Key('coach_edit_background_field'),
                controller: _backgroundController,
                decoration:
                    const InputDecoration(labelText: 'Professional Background'),
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
          key: const Key('coach_save_experience_button'),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
