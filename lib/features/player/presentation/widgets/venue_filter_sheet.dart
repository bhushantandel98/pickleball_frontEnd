import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';

/// Modal bottom sheet for configuring venue discovery filters.
class VenueFilterSheet extends StatefulWidget {
  final VenueFilter initialFilter;
  final ValueChanged<VenueFilter> onApply;

  const VenueFilterSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required VenueFilter initialFilter,
    required ValueChanged<VenueFilter> onApply,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => VenueFilterSheet(
        initialFilter: initialFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<VenueFilterSheet> createState() => _VenueFilterSheetState();
}

class _VenueFilterSheetState extends State<VenueFilterSheet> {
  late double? _maxDistanceKm;
  late double? _minRating;
  late VenuePriceTier _priceTier;
  late Set<String> _requiredAmenities;
  late bool _indoorOnly;

  static const List<double?> _distanceOptions = [null, 5.0, 10.0, 25.0];
  static const List<double?> _ratingOptions = [null, 4.0, 4.5];
  static const List<String> _availableAmenities = [
    'Night Lights',
    'Equipment Rental',
    'Pro Shop',
    'Locker Rooms',
    'Parking',
    'Cafeteria',
    'Coaching Available',
  ];

  @override
  void initState() {
    super.initState();
    _maxDistanceKm = widget.initialFilter.maxDistanceKm;
    _minRating = widget.initialFilter.minRating;
    _priceTier = widget.initialFilter.priceTier;
    _requiredAmenities = Set.from(widget.initialFilter.requiredAmenities);
    _indoorOnly = widget.initialFilter.indoorOnly;
  }

  void _handleReset() {
    setState(() {
      _maxDistanceKm = null;
      _minRating = null;
      _priceTier = VenuePriceTier.any;
      _requiredAmenities.clear();
      _indoorOnly = false;
    });
  }

  void _handleApply() {
    final updated = widget.initialFilter.copyWith(
      maxDistanceKm: _maxDistanceKm,
      clearMaxDistance: _maxDistanceKm == null,
      minRating: _minRating,
      clearMinRating: _minRating == null,
      priceTier: _priceTier,
      requiredAmenities: _requiredAmenities,
      indoorOnly: _indoorOnly,
    );
    widget.onApply(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Text(
                      'Filter Venues',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _handleReset,
                      child: const Text('Reset All'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // 1. Distance filter
                    Text(
                      'Maximum Distance',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: _distanceOptions.map((dist) {
                        final isSelected = _maxDistanceKm == dist;
                        final label = dist == null ? 'Any Distance' : '< ${dist.toStringAsFixed(0)} km';
                        return FilterChip(
                          selected: isSelected,
                          label: Text(label),
                          onSelected: (_) {
                            setState(() => _maxDistanceKm = dist);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 2. Minimum rating filter
                    Text(
                      'Minimum Rating',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: _ratingOptions.map((rate) {
                        final isSelected = _minRating == rate;
                        final label = rate == null ? 'Any Rating' : '★ ${rate.toStringAsFixed(1)}+';
                        return FilterChip(
                          selected: isSelected,
                          label: Text(label),
                          onSelected: (_) {
                            setState(() => _minRating = rate);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 3. Price tier filter
                    Text(
                      'Price Range',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: VenuePriceTier.values.map((tier) {
                        final isSelected = _priceTier == tier;
                        return FilterChip(
                          selected: isSelected,
                          label: Text(tier.displayName),
                          onSelected: (_) {
                            setState(() => _priceTier = tier);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // 4. Indoor Courts Only Switch
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Indoor Courts Only',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text('Only show all-weather covered venues'),
                      value: _indoorOnly,
                      onChanged: (val) {
                        setState(() => _indoorOnly = val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // 5. Facilities & Amenities
                    Text(
                      'Facilities & Amenities',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: _availableAmenities.map((amenity) {
                        final isSelected = _requiredAmenities.contains(amenity);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(amenity),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _requiredAmenities.add(amenity);
                              } else {
                                _requiredAmenities.remove(amenity);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
              // Footer Actions
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: AppButton.primary(
                    label: 'Apply Filters',
                    onPressed: _handleApply,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
