import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/venue_filter_sheet.dart';

/// Search input bar with filter trigger, sort selector, and active filter indicator.
class VenueSearchBar extends StatefulWidget {
  final VenueFilter filter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<VenueFilter> onFilterChanged;
  final ValueChanged<VenueSortOption> onSortChanged;
  final VoidCallback onClearFilters;

  const VenueSearchBar({
    super.key,
    required this.filter,
    required this.onSearchChanged,
    required this.onFilterChanged,
    required this.onSortChanged,
    required this.onClearFilters,
  });

  @override
  State<VenueSearchBar> createState() => _VenueSearchBarState();
}

class _VenueSearchBarState extends State<VenueSearchBar> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.filter.searchQuery);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant VenueSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter.searchQuery != _controller.text) {
      final newText = widget.filter.searchQuery;
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeFilters = widget.filter.activeFilterCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Search Input
            Expanded(
              child: TextField(
                key: const Key('venue_search_text_field'),
                controller: _controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onChanged: widget.onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search by venue name or location...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _controller.clear();
                            widget.onSearchChanged('');
                            _focusNode.requestFocus();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppSpacing.borderRadiusMd,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Filter Button
            Badge(
              isLabelVisible: activeFilters > 0,
              label: Text(activeFilters.toString()),
              child: IconButton.outlined(
                tooltip: 'Filter Venues',
                icon: const Icon(Icons.tune),
                onPressed: () {
                  VenueFilterSheet.show(
                    context: context,
                    initialFilter: widget.filter,
                    onApply: widget.onFilterChanged,
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Sort Menu
            PopupMenuButton<VenueSortOption>(
              tooltip: 'Sort Listings',
              icon: const Icon(Icons.sort),
              initialValue: widget.filter.sortBy,
              onSelected: widget.onSortChanged,
              itemBuilder: (context) {
                return VenueSortOption.values.map((option) {
                  return PopupMenuItem<VenueSortOption>(
                    value: option,
                    child: Row(
                      children: [
                        if (widget.filter.sortBy == option)
                          Icon(Icons.check, size: 16, color: theme.colorScheme.primary)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Text(option.displayName),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
          ],
        ),
        // Active Filter Indicators Row
        if (widget.filter.hasActiveFilters) ...[
          const SizedBox(height: AppSpacing.xs),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (widget.filter.searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xxs),
                    child: InputChip(
                      label: Text('Query: "${widget.filter.searchQuery}"'),
                      onDeleted: () {
                        _controller.clear();
                        widget.onSearchChanged('');
                      },
                    ),
                  ),
                if (widget.filter.maxDistanceKm != null)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xxs),
                    child: InputChip(
                      label: Text('< ${widget.filter.maxDistanceKm!.toStringAsFixed(0)} km'),
                      onDeleted: () {
                        widget.onFilterChanged(
                          widget.filter.copyWith(clearMaxDistance: true),
                        );
                      },
                    ),
                  ),
                if (widget.filter.minRating != null)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xxs),
                    child: InputChip(
                      label: Text('★ ${widget.filter.minRating!.toStringAsFixed(1)}+'),
                      onDeleted: () {
                        widget.onFilterChanged(
                          widget.filter.copyWith(clearMinRating: true),
                        );
                      },
                    ),
                  ),
                if (widget.filter.priceTier != VenuePriceTier.any)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xxs),
                    child: InputChip(
                      label: Text(widget.filter.priceTier.displayName),
                      onDeleted: () {
                        widget.onFilterChanged(
                          widget.filter.copyWith(priceTier: VenuePriceTier.any),
                        );
                      },
                    ),
                  ),
                if (widget.filter.indoorOnly)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xxs),
                    child: InputChip(
                      label: const Text('Indoor Only'),
                      onDeleted: () {
                        widget.onFilterChanged(
                          widget.filter.copyWith(indoorOnly: false),
                        );
                      },
                    ),
                  ),
                ...widget.filter.requiredAmenities.map(
                  (amenity) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xxs),
                    child: InputChip(
                      label: Text(amenity),
                      onDeleted: () {
                        final updated = Set<String>.from(widget.filter.requiredAmenities)
                          ..remove(amenity);
                        widget.onFilterChanged(
                          widget.filter.copyWith(requiredAmenities: updated),
                        );
                      },
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onClearFilters,
                  child: const Text('Clear all'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
