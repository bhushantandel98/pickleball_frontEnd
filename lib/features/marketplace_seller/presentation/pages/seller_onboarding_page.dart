import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/marketplace_seller_cubit.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/marketplace_seller_state.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/widgets/seller_page_scaffold.dart';

/// Marketplace Seller Onboarding, Business Profile & KYC Document Upload page
/// (Feature 6.1).
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
      title: 'Seller Onboarding & KYC',
      subtitle:
          'Business details, pickleball-only declaration & KYC document submission.',
      bodyBuilder: (context, state) => _OnboardingForm(state: state),
    );
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
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _postalCtrl;
  late final TextEditingController _gstCtrl;
  late final TextEditingController _panCtrl;
  late final TextEditingController _bankHolderCtrl;
  late final TextEditingController _bankLast4Ctrl;
  late final TextEditingController _ifscCtrl;
  late final TextEditingController _docFileCtrl;

  late SellerPickleballFocus _pickleballFocus;
  late bool _pickleballOnlyConfirmed;
  SellerDocumentType _selectedDocType = SellerDocumentType.panCard;

  @override
  void initState() {
    super.initState();
    final p = widget.state.profile;
    _businessNameCtrl = TextEditingController(text: p.businessName);
    _legalEntityCtrl = TextEditingController(text: p.legalEntityName);
    _emailCtrl = TextEditingController(text: p.contactEmail);
    _phoneCtrl = TextEditingController(text: p.contactPhone);
    _addressCtrl = TextEditingController(text: p.businessAddress);
    _cityCtrl = TextEditingController(text: p.city);
    _stateCtrl = TextEditingController(text: p.state);
    _postalCtrl = TextEditingController(text: p.postalCode);
    _gstCtrl = TextEditingController(text: p.gstNumber);
    _panCtrl = TextEditingController(text: p.panNumber);
    _bankHolderCtrl = TextEditingController(text: p.bankAccountHolder);
    _bankLast4Ctrl = TextEditingController(text: p.bankAccountLast4);
    _ifscCtrl = TextEditingController(text: p.ifscCode);
    _docFileCtrl = TextEditingController(text: 'seller_pan_document.pdf');
    _pickleballFocus = p.pickleballFocus;
    _pickleballOnlyConfirmed = p.isPickleballOnlyConfirmed;
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _legalEntityCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _postalCtrl.dispose();
    _gstCtrl.dispose();
    _panCtrl.dispose();
    _bankHolderCtrl.dispose();
    _bankLast4Ctrl.dispose();
    _ifscCtrl.dispose();
    _docFileCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = widget.state.profile;
    final isBusy = widget.state.isMutating;

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
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. Business & Pickleball Store Profile',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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
                DropdownButtonFormField<SellerPickleballFocus>(
                  initialValue: _pickleballFocus,
                  decoration: const InputDecoration(
                    labelText: 'Pickleball Merchandise Focus *',
                  ),
                  items: SellerPickleballFocus.values
                      .map(
                        (f) => DropdownMenuItem(value: f, child: Text(f.label)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _pickleballFocus = val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.xs),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _pickleballOnlyConfirmed,
                  onChanged: (val) =>
                      setState(() => _pickleballOnlyConfirmed = val ?? false),
                  title: const Text(
                    'I confirm this store sells exclusively pickleball-related merchandise.',
                  ),
                  subtitle: const Text(
                    'Non-pickleball sellers and products are not permitted.',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Business Contact Email *',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Business Contact Phone *',
                  ),
                  validator: _required,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _addressCtrl,
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
                        decoration: const InputDecoration(labelText: 'City *'),
                        validator: _required,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _stateCtrl,
                        decoration: const InputDecoration(labelText: 'State *'),
                        validator: _required,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _postalCtrl,
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
                        decoration: const InputDecoration(
                          labelText: 'GSTIN (if applicable)',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _panCtrl,
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
                        decoration: const InputDecoration(
                          labelText: 'Bank Account Holder',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _bankLast4Ctrl,
                        decoration: const InputDecoration(
                          labelText: 'Account Last 4 Digits',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _ifscCtrl,
                        decoration: const InputDecoration(labelText: 'IFSC'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: isBusy ? null : () => _saveProfile(profile),
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
                  '2. Business & KYC Document Upload',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<SellerDocumentType>(
                  initialValue: _selectedDocType,
                  decoration: const InputDecoration(labelText: 'Document Type'),
                  items: SellerDocumentType.values
                      .map(
                        (t) => DropdownMenuItem(value: t, child: Text(t.label)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedDocType = val);
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _docFileCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Selected Document File Name',
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => context
                              .read<MarketplaceSellerCubit>()
                              .uploadKycDocument(
                                type: _selectedDocType,
                                fileName: _docFileCtrl.text,
                              ),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (profile.documents.isEmpty)
                  const EmptyStateView(
                    title: 'No Documents Uploaded',
                    message:
                        'Upload at least 2 KYC documents before submitting for verification.',
                  )
                else
                  ...profile.documents.map(
                    (doc) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.picture_as_pdf_outlined),
                      title: Text(doc.type.label),
                      subtitle: Text(doc.fileName),
                      trailing: profile.canSubmitForVerification
                          ? IconButton(
                              tooltip: 'Remove document',
                              onPressed: isBusy
                                  ? null
                                  : () => context
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
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: isBusy || !profile.canSubmitForVerification
                      ? null
                      : _confirmSubmit,
                  icon: const Icon(Icons.verified_user_outlined),
                  label: Text(
                    profile.canSubmitForVerification
                        ? 'Submit for Verification'
                        : 'Submitted (${profile.verificationStatus.label})',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  Future<void> _saveProfile(SellerProfile existing) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final updated = existing.copyWith(
      businessName: _businessNameCtrl.text,
      legalEntityName: _legalEntityCtrl.text,
      pickleballFocus: _pickleballFocus,
      isPickleballOnlyConfirmed: _pickleballOnlyConfirmed,
      contactEmail: _emailCtrl.text,
      contactPhone: _phoneCtrl.text,
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
          'Your business profile and KYC documents will be reviewed by Application Staff and routed to Application Admin for final approval.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<MarketplaceSellerCubit>().submitForVerification();
    }
  }
}
