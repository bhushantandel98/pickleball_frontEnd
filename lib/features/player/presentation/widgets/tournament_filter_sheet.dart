import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';

/// Modal bottom sheet for configuring advanced tournament discovery filters.
class TournamentFilterSheet extends StatefulWidget {
  final TournamentFilter currentFilter;
  final ValueChanged<TournamentFilter> onApply;

  const TournamentFilterSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<TournamentFilterSheet> createState() => _TournamentFilterSheetState();
}

class _TournamentFilterSheetState extends State<TournamentFilterSheet> {
  late TournamentStatus? _selectedStatus;
  late String? _selectedCategory;
  late bool _onlyOpen;
  late bool _onlyMyEntries;

  static const List<String> availableCategories = [
    'All Categories',
    'Men\'s Singles',
    'Women\'s Singles',
    'Mixed Doubles',
    'Men\'s Doubles',
    'Women\'s Doubles',
    'Senior',
    'Junior',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentFilter.status;
    _selectedCategory = widget.currentFilter.category;
    _onlyOpen = widget.currentFilter.onlyOpenForRegistration;
    _onlyMyEntries = widget.currentFilter.onlyMyEntries;
  }

  void _reset() {
    setState(() {
      _selectedStatus = null;
      _selectedCategory = null;
      _onlyOpen = false;
      _onlyMyEntries = false;
    });
  }

  void _apply() {
    final updated = widget.currentFilter.copyWith(
      status: _selectedStatus,
      clearStatus: _selectedStatus == null,
      category: _selectedCategory,
      clearCategory: _selectedCategory == null,
      onlyOpenForRegistration: _onlyOpen,
      onlyMyEntries: _onlyMyEntries,
    );
    widget.onApply(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sheet Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Tournaments',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  key: const Key('tournament_filter_reset_button'),
                  onPressed: _reset,
                  child: const Text('Reset All'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),

            // Tournament Status
            Text(
              'Tournament Status',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedStatus == null,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedStatus = null);
                  },
                ),
                ...TournamentStatus.values.map((status) {
                  return ChoiceChip(
                    label: Text(status.displayName),
                    selected: _selectedStatus == status,
                    onSelected: (selected) {
                      setState(() {
                        _selectedStatus = selected ? status : null;
                      });
                    },
                  );
                }),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Category Division
            Text(
              'Division / Event Category',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableCategories.map((cat) {
                final isAll = cat == 'All Categories';
                final isSelected = isAll
                    ? _selectedCategory == null
                    : _selectedCategory == cat;

                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (isAll) {
                        _selectedCategory = null;
                      } else {
                        _selectedCategory = selected ? cat : null;
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: AppSpacing.md),

            // Quick Toggles
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Registration Open Only'),
              subtitle: const Text('Show tournaments currently accepting entries'),
              value: _onlyOpen,
              onChanged: (val) => setState(() => _onlyOpen = val),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('My Registered Tournaments'),
              subtitle: const Text('Show events you have already entered'),
              value: _onlyMyEntries,
              onChanged: (val) => setState(() => _onlyMyEntries = val),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Apply Button
            AppButton.primary(
              key: const Key('tournament_filter_apply_button'),
              label: 'Apply Filters',
              width: double.infinity,
              onPressed: _apply,
            ),
          ],
        ),
      ),
    );
  }
}
