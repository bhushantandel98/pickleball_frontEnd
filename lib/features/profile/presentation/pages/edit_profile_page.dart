import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_dialog.dart';
import 'package:pickleball_platform/core/widgets/app_text_field.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pickleball_platform/features/profile/presentation/cubit/profile_state.dart';
import 'package:pickleball_platform/features/profile/presentation/validators/profile_validators.dart';
import 'package:pickleball_platform/features/profile/presentation/widgets/avatar_picker_dialog.dart';
import 'package:pickleball_platform/features/profile/presentation/widgets/profile_avatar_view.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

/// Screen allowing users to update their shared personal details (name, email, avatar).
class EditProfilePage extends StatelessWidget {
  final UserProfile? initialProfile;
  final ProfileCubit? cubit;
  final ValueChanged<UserProfile>? onSaveSuccess;
  final VoidCallback? onCancel;

  const EditProfilePage({
    super.key,
    this.initialProfile,
    this.cubit,
    this.onSaveSuccess,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<ProfileCubit>.value(
        value: cubit!,
        child: _EditProfileView(
          initialProfile: initialProfile,
          onSaveSuccess: onSaveSuccess,
          onCancel: onCancel,
        ),
      );
    }

    try {
      final existing = context.read<ProfileCubit>();
      return BlocProvider<ProfileCubit>.value(
        value: existing,
        child: _EditProfileView(
          initialProfile: initialProfile,
          onSaveSuccess: onSaveSuccess,
          onCancel: onCancel,
        ),
      );
    } catch (_) {
      return BlocProvider<ProfileCubit>(
        create: (_) => sl<ProfileCubit>(),
        child: _EditProfileView(
          initialProfile: initialProfile,
          onSaveSuccess: onSaveSuccess,
          onCancel: onCancel,
        ),
      );
    }
  }
}

class _EditProfileView extends StatefulWidget {
  final UserProfile? initialProfile;
  final ValueChanged<UserProfile>? onSaveSuccess;
  final VoidCallback? onCancel;

  const _EditProfileView({
    this.initialProfile,
    this.onSaveSuccess,
    this.onCancel,
  });

  @override
  State<_EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<_EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late String? _selectedAvatarUrl;
  UserProfile? _resolvedProfile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _resolvedProfile = widget.initialProfile;
    _nameController = TextEditingController(text: _resolvedProfile?.name ?? '');
    _emailController = TextEditingController(text: _resolvedProfile?.email ?? '');
    _selectedAvatarUrl = _resolvedProfile?.avatarUrl;

    if (_resolvedProfile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = context.read<ProfileCubit>().state;
        if (state is ProfileLoaded) {
          _populateFromProfile(state.profile);
        } else {
          context.read<ProfileCubit>().loadProfile();
        }
      });
    }
  }

  void _populateFromProfile(UserProfile profile) {
    setState(() {
      _resolvedProfile = profile;
      _nameController.text = profile.name;
      _emailController.text = profile.email;
      _selectedAvatarUrl = profile.avatarUrl;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _isDirty {
    if (_resolvedProfile == null) return false;
    final nameChanged = _nameController.text.trim() != _resolvedProfile!.name;
    final emailChanged =
        _emailController.text.trim() != _resolvedProfile!.email;
    final avatarChanged = _selectedAvatarUrl != _resolvedProfile!.avatarUrl;
    return nameChanged || emailChanged || avatarChanged;
  }

  Future<bool> _confirmDiscard() async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Discard Changes?',
      message:
          'You have unsaved changes. Are you sure you want to discard them?',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep Editing',
      isDestructive: true,
    );
    return confirmed ?? false;
  }

  Future<void> _handleCancel() async {
    if (_isDirty) {
      final shouldDiscard = await _confirmDiscard();
      if (!shouldDiscard || !mounted) return;
    }

    if (widget.onCancel != null) {
      widget.onCancel!();
      return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.profile);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _resolvedProfile == null) {
      return;
    }

    setState(() => _isSaving = true);

    final updated = _resolvedProfile!.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      avatarUrl: _selectedAvatarUrl,
    );

    final success =
        await context.read<ProfileCubit>().updateProfile(updated);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      if (widget.onSaveSuccess != null) {
        widget.onSaveSuccess!(updated);
        return;
      }

      if (context.canPop()) {
        context.pop(updated);
      } else {
        context.go(AppRoutes.profile);
      }
    }
  }

  void _openAvatarPicker() {
    AvatarPickerDialog.show(
      context: context,
      currentAvatarUrl: _selectedAvatarUrl,
      onAvatarSelected: (selected) {
        setState(() {
          _selectedAvatarUrl = selected;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isDirty && !_isSaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldDiscard = await _confirmDiscard();
        if (shouldDiscard && context.mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AppRoutes.profile);
          }
        }
      },
      child: Scaffold(
        appBar: CommonAppBar(
          title: 'Edit Profile',
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed: _handleCancel,
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _handleSave,
              child: const Text('Save'),
            ),
          ],
        ),
        body: BlocConsumer<ProfileCubit, ProfileState>(
          listener: (context, state) {
            if (state is ProfileLoaded && _resolvedProfile == null) {
              _populateFromProfile(state.profile);
            }
            if (state is ProfileFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ProfileLoading && _resolvedProfile == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final profile = _resolvedProfile;
            if (profile == null) {
              return const Center(
                child: Text('Unable to load profile data for editing.'),
              );
            }

            return Center(
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: AppSpacing.maxFormWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Avatar Edit Card
                        AppCard(
                          padding: AppSpacing.cardPadding,
                          child: Column(
                            children: [
                              ProfileAvatarView(
                                name: _nameController.text.isNotEmpty
                                    ? _nameController.text
                                    : profile.name,
                                avatarUrl: _selectedAvatarUrl,
                                radius: 48,
                                isEditable: true,
                                onEdit: _openAvatarPicker,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextButton.icon(
                                icon: const Icon(Icons.photo_library_outlined,
                                    size: 18),
                                label: const Text('Change Badge / Photo'),
                                onPressed: _openAvatarPicker,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Form Fields Card
                        AppCard(
                          padding: AppSpacing.cardPadding,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personal Details',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              AppTextField(
                                controller: _nameController,
                                label: 'Full Name *',
                                hint: 'Enter your full name',
                                prefixIcon:
                                    const Icon(Icons.person_outline),
                                validator: ProfileValidators.validateName,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                controller: _emailController,
                                label: 'Email Address (Optional)',
                                hint: 'name@example.com',
                                prefixIcon:
                                    const Icon(Icons.email_outlined),
                                keyboardType: TextInputType.emailAddress,
                                validator: ProfileValidators.validateEmail,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              AppTextField(
                                initialValue: profile.phone,
                                label: 'Registered Mobile Number',
                                readOnly: true,
                                prefixIcon: const Icon(Icons.lock_outline),
                                prefixText: '',
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs),
                                child: Text(
                                  'Mobile number is your primary verified identifier and cannot be changed directly.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Actions
                        AppButton.primary(
                          label: 'Save Changes',
                          isLoading: _isSaving,
                          onPressed: _handleSave,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton.secondary(
                          label: 'Cancel',
                          onPressed: _handleCancel,
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
    );
  }
}
