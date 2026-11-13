import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/features/venue_partner/domain/entities/venue_partner_entities.dart';

/// Shared location filter chips used across Venue Partner screens.
class VenueLocationFilterBar extends StatelessWidget {
  final List<VenueLocation> locations;
  final String? selectedLocationId;
  final ValueChanged<String?> onLocationSelected;

  const VenueLocationFilterBar({
    super.key,
    required this.locations,
    required this.selectedLocationId,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        ChoiceChip(
          label: const Text('All Locations'),
          selected: selectedLocationId == null,
          onSelected: (_) => onLocationSelected(null),
        ),
        ...locations.map(
          (loc) => ChoiceChip(
            label: Text(loc.name),
            selected: selectedLocationId == loc.id,
            onSelected: (_) => onLocationSelected(loc.id),
          ),
        ),
      ],
    );
  }
}
