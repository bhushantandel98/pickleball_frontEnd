import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_text_field.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';

/// Search input bar with filter trigger, sorting popup menu, and quick filter chips.
class TournamentSearchBar extends StatefulWidget {
  final String initialQuery;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onOpenFilter;
  final ValueChanged<TournamentSortOption> onSortSelected;
  final TournamentSortOption currentSort;
  final int activeFilterCount;
  final TournamentFilter activeFilter;
  final ValueChanged<TournamentFilter> onFilterQuickChanged;

  const TournamentSearchBar({
    super.key,
    required this.initialQuery,
    required this.onQueryChanged,
    required this.onOpenFilter,
    required this.onSortSelected,
    required this.currentSort,
    required this.activeFilterCount,
    required this.activeFilter,
    required this.onFilterQuickChanged,
  });

  @override
  State<TournamentSearchBar> createState() => _TournamentSearchBarState();
}

class _TournamentSearchBarState extends State<TournamentSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(TournamentSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery &&
        widget.initialQuery != _controller.text) {
      _controller.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input & Action Icons
        Row(
          children: [
            Expanded(
              child: AppTextField(
                key: const Key('tournament_search_input'),
                controller: _controller,
                hint: 'Search tournaments, cities, venues...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _controller.clear();
                          widget.onQueryChanged('');
                        },
                      )
                    : null,
                onChanged: widget.onQueryChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Filter Sheet Trigger Button
            Badge(
              isLabelVisible: widget.activeFilterCount > 0,
              label: Text('${widget.activeFilterCount}'),
              child: IconButton.filledTonal(
                key: const Key('tournament_filter_button'),
                icon: const Icon(Icons.tune),
                tooltip: 'Filter Tournaments',
                onPressed: widget.onOpenFilter,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),

            // Sort Menu Button
            PopupMenuButton<TournamentSortOption>(
              key: const Key('tournament_sort_button'),
              icon: const Icon(Icons.sort),
              tooltip: 'Sort Tournaments',
              initialValue: widget.currentSort,
              onSelected: widget.onSortSelected,
              itemBuilder: (context) {
                return TournamentSortOption.values.map((option) {
                  return PopupMenuItem(
                    value: option,
                    child: Row(
                      children: [
                        if (option == widget.currentSort)
                          Icon(Icons.check, size: 16, color: theme.colorScheme.primary)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 8),
                        Text(option.label),
                      ],
                    ),
                  );
                }).toList();
              },
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.sm),

        // Quick Category/Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                context,
                label: 'All Tournaments',
                isSelected: !widget.activeFilter.onlyOpenForRegistration &&
                    !widget.activeFilter.onlyMyEntries &&
                    widget.activeFilter.status == null,
                onTap: () {
                  widget.onFilterQuickChanged(
                    widget.activeFilter.copyWith(
                      clearStatus: true,
                      onlyOpenForRegistration: false,
                      onlyMyEntries: false,
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(
                context,
                label: 'Registration Open',
                isSelected: widget.activeFilter.onlyOpenForRegistration,
                onTap: () {
                  widget.onFilterQuickChanged(
                    widget.activeFilter.copyWith(
                      onlyOpenForRegistration: !widget.activeFilter.onlyOpenForRegistration,
                      onlyMyEntries: false,
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(
                context,
                label: 'Upcoming',
                isSelected: widget.activeFilter.status == TournamentStatus.upcoming,
                onTap: () {
                  final isCurrently = widget.activeFilter.status == TournamentStatus.upcoming;
                  widget.onFilterQuickChanged(
                    widget.activeFilter.copyWith(
                      status: isCurrently ? null : TournamentStatus.upcoming,
                      clearStatus: isCurrently,
                      onlyOpenForRegistration: false,
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildFilterChip(
                context,
                label: 'My Entries',
                isSelected: widget.activeFilter.onlyMyEntries,
                onTap: () {
                  widget.onFilterQuickChanged(
                    widget.activeFilter.copyWith(
                      onlyMyEntries: !widget.activeFilter.onlyMyEntries,
                      onlyOpenForRegistration: false,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
      ),
    );
  }
}
