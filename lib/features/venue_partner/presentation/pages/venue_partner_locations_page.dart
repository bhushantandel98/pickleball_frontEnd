import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/venue_partner/domain/entities/venue_partner_entities.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/bloc/venue_partner_cubit.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/bloc/venue_partner_state.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/widgets/venue_location_filter_bar.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/widgets/venue_partner_page_scaffold.dart';

/// Venue Partner Locations, Courts, Pricing, Booking Rules, Staff & Expenses page (Feature 3.7).
class VenuePartnerLocationsPage extends StatefulWidget {
  final VenuePartnerCubit? cubit;
  final String partnerId;

  const VenuePartnerLocationsPage({
    super.key,
    this.cubit,
    this.partnerId = 'org_venue_001',
  });

  @override
  State<VenuePartnerLocationsPage> createState() =>
      _VenuePartnerLocationsPageState();
}

class _VenuePartnerLocationsPageState extends State<VenuePartnerLocationsPage> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return VenuePartnerPageScaffold(
      cubit: widget.cubit,
      partnerId: widget.partnerId,
      title: 'Locations, Courts & Rules',
      subtitle:
          'Configure venue locations, booking rules, court pricing, staff access, and expenses.',
      headerActionBuilder: (context, state) {
        final cubit = context.read<VenuePartnerCubit>();
        return Wrap(
          spacing: AppSpacing.xs,
          children: [
            FilledButton.icon(
              onPressed: () => _showLocationDialog(context, cubit),
              icon: const Icon(Icons.add_location_alt_outlined, size: 18),
              label: const Text('Add Location'),
            ),
            if (state.data.locations.isNotEmpty)
              OutlinedButton.icon(
                onPressed: () => _showCourtDialog(context, cubit, state),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Court'),
              ),
          ],
        );
      },
      bodyBuilder: (context, state) {
        final cubit = context.read<VenuePartnerCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VenueLocationFilterBar(
              locations: state.data.locations,
              selectedLocationId: state.selectedLocationId,
              onLocationSelected: cubit.selectLocation,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                ChoiceChip(
                  label: Text('Locations & Rules (${state.data.locations.length})'),
                  selected: _tabIndex == 0,
                  onSelected: (_) => setState(() => _tabIndex = 0),
                ),
                ChoiceChip(
                  label: Text('Courts & Pricing (${state.scopedCourts.length})'),
                  selected: _tabIndex == 1,
                  onSelected: (_) => setState(() => _tabIndex = 1),
                ),
                ChoiceChip(
                  label: Text('Staff & Expenses (${state.scopedStaff.length}/${state.scopedExpenses.length})'),
                  selected: _tabIndex == 2,
                  onSelected: (_) => setState(() => _tabIndex = 2),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            switch (_tabIndex) {
              0 => _LocationsTab(
                  state: state,
                  cubit: cubit,
                  onEdit: (loc) =>
                      _showLocationDialog(context, cubit, existing: loc),
                ),
              1 => _CourtsTab(
                  state: state,
                  cubit: cubit,
                  onEditPricing: (court) =>
                      _showCourtPricingDialog(context, cubit, court),
                ),
              _ => _StaffAndExpensesTab(
                  state: state,
                  cubit: cubit,
                  onAddExpense: () => _showExpenseDialog(context, cubit, state),
                ),
            },
          ],
        );
      },
    );
  }

  Future<void> _showLocationDialog(
    BuildContext context,
    VenuePartnerCubit cubit, {
    VenueLocation? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final cityCtrl = TextEditingController(text: existing?.city ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final hoursCtrl = TextEditingController(
        text: existing?.operatingHours ?? '06:00 AM – 10:00 PM');
    final slotCtrl = TextEditingController(
        text: '${existing?.slotDurationMinutes ?? 60}');
    final windowCtrl = TextEditingController(
        text: '${existing?.advanceBookingWindowDays ?? 14}');
    final cutoffCtrl = TextEditingController(
        text: '${existing?.cancellationCutoffHours ?? 6}');
    var mode = existing?.confirmationMode ??
        VenueBookingRuleConfirmationMode.autoConfirm;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null
              ? 'Add Venue Location'
              : 'Edit Location & Booking Rules'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Location Name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: cityCtrl,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: hoursCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Operating Hours'),
                  ),
                  TextFormField(
                    controller: slotCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Slot Duration (minutes)'),
                    validator: (v) =>
                        (int.tryParse(v ?? '') ?? 0) <= 0 ? '> 0 required' : null,
                  ),
                  TextFormField(
                    controller: windowCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Advance Booking Window (days)'),
                    validator: (v) =>
                        (int.tryParse(v ?? '') ?? 0) <= 0 ? '> 0 required' : null,
                  ),
                  TextFormField(
                    controller: cutoffCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Cancellation Cutoff (hours)'),
                    validator: (v) =>
                        (int.tryParse(v ?? '') ?? -1) < 0 ? '>= 0 required' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<VenueBookingRuleConfirmationMode>(
                    initialValue: mode,
                    decoration:
                        const InputDecoration(labelText: 'Confirmation Mode'),
                    items: VenueBookingRuleConfirmationMode.values
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text(m.label),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => mode = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      if (existing == null) {
        await cubit.createLocation(
          name: nameCtrl.text,
          city: cityCtrl.text,
          address: addressCtrl.text,
          operatingHours: hoursCtrl.text,
          slotDurationMinutes: int.parse(slotCtrl.text),
          advanceBookingWindowDays: int.parse(windowCtrl.text),
          cancellationCutoffHours: int.parse(cutoffCtrl.text),
          confirmationMode: mode,
        );
      } else {
        await cubit.updateLocationAndRules(
          locationId: existing.id,
          name: nameCtrl.text,
          city: cityCtrl.text,
          address: addressCtrl.text,
          operatingHours: hoursCtrl.text,
          slotDurationMinutes: int.parse(slotCtrl.text),
          advanceBookingWindowDays: int.parse(windowCtrl.text),
          cancellationCutoffHours: int.parse(cutoffCtrl.text),
          confirmationMode: mode,
        );
      }
    }

    nameCtrl.dispose();
    cityCtrl.dispose();
    addressCtrl.dispose();
    hoursCtrl.dispose();
    slotCtrl.dispose();
    windowCtrl.dispose();
    cutoffCtrl.dispose();
  }

  Future<void> _showCourtDialog(
    BuildContext context,
    VenuePartnerCubit cubit,
    VenuePartnerLoaded state,
  ) async {
    var locationId =
        state.selectedLocationId ?? state.data.locations.first.id;
    final nameCtrl = TextEditingController();
    final surfaceCtrl = TextEditingController(text: 'Cushioned Acrylic');
    final rateCtrl = TextEditingController(text: '800');
    final peakCtrl = TextEditingController(text: '1100');
    var isIndoor = true;
    var hasLighting = true;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Court'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: locationId,
                    decoration: const InputDecoration(labelText: 'Location'),
                    items: state.data.locations
                        .map((l) => DropdownMenuItem(
                              value: l.id,
                              child: Text(l.name),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setDialogState(() => locationId = v);
                    },
                  ),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Court Name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: surfaceCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Surface Type'),
                  ),
                  TextFormField(
                    controller: rateCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Standard Hourly Rate (INR)'),
                    validator: (v) =>
                        (double.tryParse(v ?? '') ?? -1) < 0 ? '>= 0' : null,
                  ),
                  TextFormField(
                    controller: peakCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Peak Hourly Rate (INR)'),
                    validator: (v) =>
                        (double.tryParse(v ?? '') ?? -1) < 0 ? '>= 0' : null,
                  ),
                  SwitchListTile(
                    title: const Text('Indoor Court'),
                    value: isIndoor,
                    onChanged: (v) => setDialogState(() => isIndoor = v),
                  ),
                  SwitchListTile(
                    title: const Text('Floodlights Available'),
                    value: hasLighting,
                    onChanged: (v) => setDialogState(() => hasLighting = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await cubit.createCourt(
        locationId: locationId,
        name: nameCtrl.text,
        surfaceType: surfaceCtrl.text,
        isIndoor: isIndoor,
        hasLighting: hasLighting,
        hourlyRateInr: double.parse(rateCtrl.text),
        peakHourlyRateInr: double.parse(peakCtrl.text),
      );
    }

    nameCtrl.dispose();
    surfaceCtrl.dispose();
    rateCtrl.dispose();
    peakCtrl.dispose();
  }

  Future<void> _showCourtPricingDialog(
    BuildContext context,
    VenuePartnerCubit cubit,
    VenueCourt court,
  ) async {
    final rateCtrl =
        TextEditingController(text: court.hourlyRateInr.toStringAsFixed(0));
    final peakCtrl = TextEditingController(
        text: court.peakHourlyRateInr.toStringAsFixed(0));
    var isActive = court.isActive;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Pricing & Status — ${court.name}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Standard Hourly Rate (INR)'),
                  validator: (v) =>
                      (double.tryParse(v ?? '') ?? -1) < 0 ? '>= 0' : null,
                ),
                TextFormField(
                  controller: peakCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Peak Hourly Rate (INR)'),
                  validator: (v) =>
                      (double.tryParse(v ?? '') ?? -1) < 0 ? '>= 0' : null,
                ),
                SwitchListTile(
                  title: const Text('Court Active for Bookings'),
                  value: isActive,
                  onChanged: (v) => setDialogState(() => isActive = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await cubit.updateCourtPricing(
        courtId: court.id,
        hourlyRateInr: double.parse(rateCtrl.text),
        peakHourlyRateInr: double.parse(peakCtrl.text),
        isActive: isActive,
      );
    }

    rateCtrl.dispose();
    peakCtrl.dispose();
  }

  Future<void> _showExpenseDialog(
    BuildContext context,
    VenuePartnerCubit cubit,
    VenuePartnerLoaded state,
  ) async {
    var locationId =
        state.selectedLocationId ?? state.data.locations.first.id;
    final titleCtrl = TextEditingController();
    final catCtrl = TextEditingController(text: 'Equipment');
    final amtCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Record Venue Expense'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: locationId,
                  decoration: const InputDecoration(labelText: 'Location'),
                  items: state.data.locations
                      .map((l) =>
                          DropdownMenuItem(value: l.id, child: Text(l.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => locationId = v);
                  },
                ),
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Expense Title'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: catCtrl,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextFormField(
                  controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (INR)'),
                  validator: (v) =>
                      (double.tryParse(v ?? '') ?? 0) <= 0 ? '> 0 required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() == true) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await cubit.addExpense(
        locationId: locationId,
        title: titleCtrl.text,
        category: catCtrl.text,
        amountInr: double.parse(amtCtrl.text),
      );
    }

    titleCtrl.dispose();
    catCtrl.dispose();
    amtCtrl.dispose();
  }
}

class _LocationsTab extends StatelessWidget {
  final VenuePartnerLoaded state;
  final VenuePartnerCubit cubit;
  final ValueChanged<VenueLocation> onEdit;

  const _LocationsTab({
    required this.state,
    required this.cubit,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locations = state.selectedLocationId == null
        ? state.data.locations
        : state.data.locations
            .where((l) => l.id == state.selectedLocationId)
            .toList();

    if (locations.isEmpty) {
      return const EmptyStateView(
        icon: Icon(Icons.place_outlined),
        title: 'No Locations',
        message: 'Add a venue location to configure courts and booking rules.',
      );
    }

    return Column(
      children: locations.map((loc) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${loc.name} (${loc.city})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${loc.address} • ${loc.operatingHours}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: loc.isActive,
                      onChanged: (val) => cubit.toggleLocationStatus(
                        locationId: loc.id,
                        isActive: val,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Booking Rules: ${loc.slotDurationMinutes} min slots • '
                  '${loc.advanceBookingWindowDays}-day advance window • '
                  '${loc.cancellationCutoffHours}h cancel cutoff • '
                  '${loc.confirmationMode.label}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => onEdit(loc),
                  icon: const Icon(Icons.tune_outlined, size: 16),
                  label: const Text('Edit Profile & Booking Rules'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CourtsTab extends StatelessWidget {
  final VenuePartnerLoaded state;
  final VenuePartnerCubit cubit;
  final ValueChanged<VenueCourt> onEditPricing;

  const _CourtsTab({
    required this.state,
    required this.cubit,
    required this.onEditPricing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (state.scopedCourts.isEmpty) {
      return const EmptyStateView(
        icon: Icon(Icons.sports_tennis_outlined),
        title: 'No Courts',
        message: 'No courts configured for the selected location.',
      );
    }

    return Column(
      children: state.scopedCourts.map((court) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${court.name} • ${court.locationName}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${court.surfaceType} • ${court.isIndoor ? 'Indoor' : 'Outdoor'}'
                        '${court.hasLighting ? ' • Floodlights' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Standard: ₹${court.hourlyRateInr.toStringAsFixed(0)}/hr • '
                        'Peak: ₹${court.peakHourlyRateInr.toStringAsFixed(0)}/hr • '
                        '${court.isActive ? 'Active' : 'Inactive'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: court.isActive
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => onEditPricing(court),
                  child: const Text('Pricing & Status'),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StaffAndExpensesTab extends StatelessWidget {
  final VenuePartnerLoaded state;
  final VenuePartnerCubit cubit;
  final VoidCallback onAddExpense;

  const _StaffAndExpensesTab({
    required this.state,
    required this.cubit,
    required this.onAddExpense,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Delegated Venue Staff (Partner-Only Access Control)',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (state.scopedStaff.isEmpty)
          const EmptyStateView(
            icon: Icon(Icons.badge_outlined),
            title: 'No Assigned Venue Staff',
            message: 'No venue staff assigned to the selected location.',
          )
        else
          ...state.scopedStaff.map(
            (staff) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${staff.staffName} • ${staff.roleTitle}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${staff.locationName} • ${staff.permissions.join(', ')}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: staff.isActive,
                      onChanged: (val) => cubit.toggleStaffActive(
                        staffAssignmentId: staff.id,
                        isActive: val,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Venue Expenses & Purchases',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (state.data.locations.isNotEmpty)
              FilledButton.tonalIcon(
                onPressed: onAddExpense,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Log Expense'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (state.scopedExpenses.isEmpty)
          const EmptyStateView(
            icon: Icon(Icons.receipt_long_outlined),
            title: 'No Expenses Recorded',
            message: 'No venue operational expenses logged for this location.',
          )
        else
          ...state.scopedExpenses.map(
            (exp) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exp.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${exp.locationName} • ${exp.category} • By ${exp.submittedBy}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${exp.amountInr.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
