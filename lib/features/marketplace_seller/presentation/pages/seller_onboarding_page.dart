import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/marketplace_seller_cubit.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/marketplace_seller_state.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/widgets/kyc_document_picker_dialog.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/widgets/seller_page_scaffold.dart';

/// Marketplace Seller Registration, Business Profile & KYC Onboarding page
/// (Feature 6.1).
///
/// - When the authenticated user has no seller organization yet, renders the
///   independent Seller Registration & Mobile/Email OTP verification flow.
/// - Once registered, renders the Business Profile & Mandatory KYC Document
///   selection flow, locking edits after submission unless status becomes
///   `needsInformation` or `rejected`.
class SellerOnboardingPage extends StatelessWidget {
  final MarketplaceSellerCubit? cubit;
  final String? sellerId;
  final String? userId;

  const SellerOnboardingPage({
    super.key,
    this.cubit,
    this.sellerId,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return SellerPageScaffold(
      cubit: cubit,
      sellerId: sellerId,
      userId: userId,
      allowUnregistered: true,
      title: 'Seller Registration & KYC',
      subtitle:
          'Independent seller registration, pickleball declaration & mandatory KYC documents.',
      unregisteredBuilder: (context, state) =>
          _IndependentRegistrationForm(state: state),
      bodyBuilder: (context, state) => _OnboardingForm(state: state),
    );
  }
}

class _IndependentRegistrationForm extends StatefulWidget {
  final MarketplaceSellerUnregistered state;

  const _IndependentRegistrationForm({required this.state});

  @override
  State<_IndependentRegistrationForm> createState() =>
      _IndependentRegistrationFormState();
}

class _IndependentRegistrationFormState
    extends State<_IndependentRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _mobileCtrl = TextEditingController();
  final _mobileOtpCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _emailOtpCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _legalEntityCtrl = TextEditingController();

  SellerEntityType _entityType = SellerEntityType.registeredBusiness;
  SellerPickleballFocus _pickleballFocus = SellerPickleballFocus.paddlesAndGear;
  bool _pickleballOnlyConfirmed = true;

  @override
  void initState() {
    super.initState();
    final session = context.read<SessionCubit>().state;
    if (session.email != null && session.email!.isNotEmpty) {
      _emailCtrl.text = session.email!;
    }
  }

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _mobileOtpCtrl.dispose();
    _emailCtrl.dispose();
    _emailOtpCtrl.dispose();
    _businessNameCtrl.dispose();
    _legalEntityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBusy = widget.state.isMutating;

    return Form(
      key: _formKey,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Register as a Marketplace Seller',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Verify your mandatory mobile number and business email to create your seller organization.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _businessNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Store / Display Name *',
              ),
              validator: _required,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _legalEntityCtrl,
              decoration: const InputDecoration(
                labelText: 'Legal Entity Name *',
              ),
              validator: _required,
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<SellerEntityType>(
              initialValue: _entityType,
              decoration: const InputDecoration(labelText: 'Entity Type *'),
              items: SellerEntityType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _entityType = val);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<SellerPickleballFocus>(
              initialValue: _pickleballFocus,
              decoration: const InputDecoration(
                labelText: 'Pickleball Merchandise Focus *',
              ),
              items: SellerPickleballFocus.values
                  .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _pickleballFocus = val);
              },
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _pickleballOnlyConfirmed,
              onChanged: (val) =>
                  setState(() => _pickleballOnlyConfirmed = val ?? false),
              title: const Text(
                'I confirm this seller account will offer only pickleball-related products.',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _mobileCtrl,
              decoration: const InputDecoration(
                labelText: 'Mandatory Mobile Number (10 digits) *',
              ),
              validator: _required,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Mandatory Business Email *',
              ),
              validator: _required,
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: isBusy
                  ? null
                  : () => context
                      .read<MarketplaceSellerCubit>()
                      .requestContactVerificationOtp(
                        mobileNumber: _mobileCtrl.text,
                        email: _emailCtrl.text,
                      ),
              icon: const Icon(Icons.sms_outlined),
              label: Text(
                widget.state.otpSent
                    ? 'Resend Mobile & Email OTPs'
                    : 'Send Mobile & Email OTPs',
              ),
            ),
            if (widget.state.otpSent) ...[
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _mobileOtpCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Mobile OTP (123456) *',
                      ),
                      validator: _required,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _emailOtpCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email OTP (123456) *',
                      ),
                      validator: _required,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: isBusy ? null : _submitRegistration,
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Verify & Create Seller Account'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  Future<void> _submitRegistration() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final cubit = context.read<MarketplaceSellerCubit>();
    final sessionCubit = context.read<SessionCubit>();
    final created = await cubit.registerSellerAccount(
      mobileNumber: _mobileCtrl.text,
      mobileOtp: _mobileOtpCtrl.text,
      email: _emailCtrl.text,
      emailOtp: _emailOtpCtrl.text,
      businessName: _businessNameCtrl.text,
      legalEntityName: _legalEntityCtrl.text,
      entityType: _entityType,
      pickleballFocus: _pickleballFocus,
      isPickleballOnlyConfirmed: _pickleballOnlyConfirmed,
    );

    if (created != null && mounted) {
      await sessionCubit.linkSellerOrganization(
        sellerId: created.sellerId,
        businessName: created.businessName,
      );
    }
  }
}

class _OnboardingForm extends StatefulWidget {
  final MarketplaceSellerLoaded state;

  const _OnboardingForm({required this.state});

  @override
  State<_OnboardingForm> createState() => _OnboardingFormState();
}

class _OnboardingFormState extends State<_OnboardingForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _businessNameCtrl;
  late final TextEditingController _legalEntityCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _postalCtrl;
  late final TextEditingController _gstCtrl;
  late final TextEditingController _panCtrl;
  late final TextEditingController _bankHolderCtrl;
  late final TextEditingController _bankLast4Ctrl;
  late final TextEditingController _ifscCtrl;

  late SellerEntityType _entityType;
  late SellerPickleballFocus _pickleballFocus;
  late bool _pickleballOnlyConfirmed;
  SellerDocumentType _selectedDocType = SellerDocumentType.addressProof;

  @override
  void initState() {
    super.initState();
    final p = widget.state.profile;
    _businessNameCtrl = TextEditingController(text: p.businessName);
    _legalEntityCtrl = TextEditingController(text: p.legalEntityName);
    _addressCtrl = TextEditingController(text: p.businessAddress);
    _cityCtrl = TextEditingController(text: p.city);
    _stateCtrl = TextEditingController(text: p.state);
    _postalCtrl = TextEditingController(text: p.postalCode);
    _gstCtrl = TextEditingController(text: p.gstNumber);
    _panCtrl = TextEditingController(text: p.panNumber);
    _bankHolderCtrl = TextEditingController(text: p.bankAccountHolder);
    _bankLast4Ctrl = TextEditingController(text: p.bankAccountLast4);
    _ifscCtrl = TextEditingController(text: p.ifscCode);
    _entityType = p.entityType;
    _pickleballFocus = p.pickleballFocus;
    _pickleballOnlyConfirmed = p.isPickleballOnlyConfirmed;
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _legalEntityCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _postalCtrl.dispose();
    _gstCtrl.dispose();
    _panCtrl.dispose();
    _bankHolderCtrl.dispose();
    _bankLast4Ctrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.state.profile;
    final isBusy = widget.state.isMutating;
    final canEdit = profile.canEditProfile && !isBusy;
    final missingDocs = profile.missingRequiredDocumentTypes;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    context.go(AppRoutes.marketplaceSellerDashboard),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Seller Dashboard'),
              ),
              const Spacer(),
              Chip(label: Text(profile.verificationStatus.label)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (!profile.canEditProfile) ...[
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.lock_outline),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Profile & KYC editing is locked (${profile.verificationStatus.label}). '
                      'Editing re-opens only if Application Staff/Admin marks your application as Needs Information or Rejected.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. Business & Verified Contact Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Verified Mobile: ${profile.contactPhone} • Verified Email: ${profile.contactEmail}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _businessNameCtrl,
                  enabled: canEdit,
                  decoration: const InputDecoration(
                    labelText: 'Store / Display Name *',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _legalEntityCtrl,
                  enabled: canEdit,
                  decoration: const InputDecoration(
                    labelText: 'Legal Entity Name *',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<SellerEntityType>(
                  initialValue: _entityType,
                  decoration: const InputDecoration(labelText: 'Entity Type *'),
                  items: SellerEntityType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: canEdit
                      ? (val) {
                          if (val != null) setState(() => _entityType = val);
                        }
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<SellerPickleballFocus>(
                  initialValue: _pickleballFocus,
                  decoration: const InputDecoration(
                    labelText: 'Pickleball Merchandise Focus *',
                  ),
                  items: SellerPickleballFocus.values
                      .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                      .toList(),
                  onChanged: canEdit
                      ? (val) {
                          if (val != null) {
                            setState(() => _pickleballFocus = val);
                          }
                        }
                      : null,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _pickleballOnlyConfirmed,
                  onChanged: canEdit
                      ? (val) => setState(
                            () => _pickleballOnlyConfirmed = val ?? false,
                          )
                      : null,
                  title: const Text(
                    'I confirm this store sells exclusively pickleball-related merchandise.',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _addressCtrl,
                  enabled: canEdit,
                  decoration: const InputDecoration(
                    labelText: 'Registered Business Address *',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityCtrl,
                        enabled: canEdit,
                        decoration: const InputDecoration(labelText: 'City *'),
                        validator: _required,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _stateCtrl,
                        enabled: canEdit,
                        decoration: const InputDecoration(labelText: 'State *'),
                        validator: _required,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _postalCtrl,
                        enabled: canEdit,
                        decoration: const InputDecoration(
                          labelText: 'PIN Code *',
                        ),
                        validator: _required,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _gstCtrl,
                        enabled: canEdit,
                        decoration: const InputDecoration(
                          labelText: 'GSTIN (if applicable)',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _panCtrl,
                        enabled: canEdit,
                        decoration: const InputDecoration(
                          labelText: 'PAN Number *',
                        ),
                        validator: _required,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bankHolderCtrl,
                        enabled: canEdit,
                        decoration: const InputDecoration(
                          labelText: 'Bank Account Holder',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _bankLast4Ctrl,
                        enabled: canEdit,
                        decoration: const InputDecoration(
                          labelText: 'Account Last 4 Digits',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _ifscCtrl,
                        enabled: canEdit,
                        decoration: const InputDecoration(labelText: 'IFSC'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: canEdit ? () => _saveProfile(profile) : null,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Business Profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '2. Mandatory KYC Document Selection (PDF / Image)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: profile.requiredDocumentTypes.map((reqType) {
                    final isDone = !missingDocs.contains(reqType);
                    return Chip(
                      avatar: Icon(
                        isDone ? Icons.check_circle : Icons.error_outline,
                        size: 18,
                      ),
                      label: Text(reqType.label),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<SellerDocumentType>(
                        initialValue: _selectedDocType,
                        decoration: const InputDecoration(
                          labelText: 'Document Type',
                        ),
                        items: SellerDocumentType.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.label),
                              ),
                            )
                            .toList(),
                        onChanged: canEdit
                            ? (val) {
                                if (val != null) {
                                  setState(() => _selectedDocType = val);
                                }
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: canEdit ? _pickDocument : null,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Select PDF / Image'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (profile.documents.isEmpty)
                  const EmptyStateView(
                    title: 'No Documents Selected',
                    message:
                        'Select PDF or image files for Address Proof, PAN Card, and Business documents.',
                  )
                else
                  ...profile.documents.map(
                    (doc) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        doc.mimeType == 'application/pdf'
                            ? Icons.picture_as_pdf_outlined
                            : Icons.image_outlined,
                      ),
                      title: Text(doc.type.label),
                      subtitle: Text(
                        '${doc.fileName} (${doc.formattedSize}) • '
                        '${doc.isLocalMockOnly ? 'Local preview (mock — not uploaded to server)' : 'Uploaded'}',
                      ),
                      trailing: canEdit
                          ? IconButton(
                              tooltip: 'Remove document',
                              onPressed: () => context
                                  .read<MarketplaceSellerCubit>()
                                  .removeKycDocument(doc.id),
                              icon: const Icon(Icons.delete_outline),
                            )
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3. Verification Submission',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Status: ${profile.verificationStatus.label}. ${profile.verificationStatus.description}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (missingDocs.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Missing mandatory documents: ${missingDocs.map((d) => d.label).join(', ')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: canEdit && missingDocs.isEmpty
                      ? _confirmSubmit
                      : null,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: Text(
                    profile.canSubmitForVerification
                        ? 'Submit for Verification'
                        : 'Locked (${profile.verificationStatus.label})',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  Future<void> _pickDocument() async {
    final picked = await KycDocumentPickerDialog.show(
      context,
      documentType: _selectedDocType,
    );
    if (picked != null && mounted) {
      await context.read<MarketplaceSellerCubit>().attachKycDocument(
            type: _selectedDocType,
            fileName: picked.fileName,
            mimeType: picked.mimeType,
            fileSizeBytes: picked.fileSizeBytes,
            localFileRef: picked.localFileRef,
          );
    }
  }

  Future<void> _saveProfile(SellerProfile existing) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = existing.copyWith(
      businessName: _businessNameCtrl.text,
      legalEntityName: _legalEntityCtrl.text,
      entityType: _entityType,
      pickleballFocus: _pickleballFocus,
      isPickleballOnlyConfirmed: _pickleballOnlyConfirmed,
      businessAddress: _addressCtrl.text,
      city: _cityCtrl.text,
      state: _stateCtrl.text,
      postalCode: _postalCtrl.text,
      gstNumber: _gstCtrl.text,
      panNumber: _panCtrl.text,
      bankAccountHolder: _bankHolderCtrl.text,
      bankAccountLast4: _bankLast4Ctrl.text,
      ifscCode: _ifscCtrl.text,
    );
    await context.read<MarketplaceSellerCubit>().saveBusinessProfile(updated);
  }

  Future<void> _confirmSubmit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Submit Seller Profile for Verification?'),
        content: const Text(
          'Your business profile and KYC documents will be locked for editing while Application Staff reviews and Application Admin makes the final decision.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Submit & Lock'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<MarketplaceSellerCubit>().submitForVerification();
    }
  }
}
