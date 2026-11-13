import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/bloc/venue_partner_cubit.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/bloc/venue_partner_state.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/widgets/venue_location_filter_bar.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/widgets/venue_partner_page_scaffold.dart';

/// Venue Partner Court Booking Calendar & Availability Blocks page (Feature 3.7).
class VenuePartnerCalendarPage extends StatelessWidget {
  final VenuePartnerCubit? cubit;
  final String partnerId;

  const VenuePartnerCalendarPage({
    super.key,
    this.cubit,
    this.partnerId = 'org_venue_001',
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('EEE, MMM d • hh:mm a');

    return VenuePartnerPageScaffold(
      cubit: cubit,
      partnerId: partnerId,
      title: 'Court Booking Calendar',
      subtitle:
          'Manage court availability blocks, maintenance holds, and scheduled court bookings.',
      headerActionBuilder: (context, state) {
        if (state.scopedCourts.isEmpty) return const SizedBox.shrink();
        return FilledButton.icon(
          onPressed: () => _showAddBlockDialog(
            context,
            context.read<VenuePartnerCubit>(),
            state,
          ),
          icon: const Icon(Icons.block_outlined, size: 18),
          label: const Text('Block Court Slot'),
        );
      },
      bodyBuilder: (context, state) {
        final cubit = context.read<VenuePartnerCubit>();
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VenueLocationFilterBar(
              locations: state.data.locations,
              selectedLocationId: state.selectedLocationId,
              onLocationSelected: cubit.selectLocation,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Availability & Maintenance Blocks',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (state.scopedBlocks.isEmpty)
              const EmptyStateView(
                icon: Icon(Icons.event_available_outlined),
                title: 'No Availability Blocks',
                message:
                    'No maintenance or private holds are blocking courts for this location.',
              )
            else
              ...state.scopedBlocks.map(
                (block) => Padding(
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
                                '${block.title} • ${block.courtName}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${timeFormat.format(block.startTime)} → ${DateFormat('hh:mm a').format(block.endTime)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                block.reason,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove block',
                          onPressed: () =>
                              cubit.removeAvailabilityBlock(block.id),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Scheduled Court Bookings',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (state.scopedBookings.isEmpty)
              const EmptyStateView(
                icon: Icon(Icons.calendar_today_outlined),
                title: 'No Scheduled Bookings',
                message: 'No court bookings match the selected location.',
              )
            else
              ...state.scopedBookings.map(
                (bkg) => Padding(
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
                                '${bkg.courtName} • ${bkg.playerName}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${bkg.locationName} • ${timeFormat.format(bkg.slotStart)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(bkg.status.label),
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.10),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showAddBlockDialog(
    BuildContext context,
    VenuePartnerCubit cubit,
    VenuePartnerLoaded state,
  ) async {
    var courtId = state.scopedCourts.first.id;
    final titleCtrl = TextEditingController();
    final reasonCtrl = TextEditingController(text: 'Scheduled maintenance');
    final startHourCtrl = TextEditingController(text: '14');
    final durationCtrl = TextEditingController(text: '2');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Block Court Availability'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: courtId,
                  decoration: const InputDecoration(labelText: 'Court'),
                  items: state.scopedCourts
                      .map((c) =>
                          DropdownMenuItem(value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => courtId = v);
                  },
                ),
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Block Title'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
                TextFormField(
                  controller: startHourCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Start Hour (0-23)'),
                  validator: (v) {
                    final h = int.tryParse(v ?? '');
                    return (h == null || h < 0 || h > 23) ? '0-23' : null;
                  },
                ),
                TextFormField(
                  controller: durationCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Duration (hours)'),
                  validator: (v) =>
                      (int.tryParse(v ?? '') ?? 0) <= 0 ? '> 0' : null,
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
              child: const Text('Add Block'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final now = DateTime.now();
      final startHour = int.parse(startHourCtrl.text);
      final duration = int.parse(durationCtrl.text);
      final start = DateTime(now.year, now.month, now.day, startHour);
      await cubit.createAvailabilityBlock(
        courtId: courtId,
        title: titleCtrl.text,
        reason: reasonCtrl.text,
        startTime: start,
        endTime: start.add(Duration(hours: duration)),
      );
    }

    titleCtrl.dispose();
    reasonCtrl.dispose();
    startHourCtrl.dispose();
    durationCtrl.dispose();
  }
}
