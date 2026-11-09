import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_text_field.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

/// Search input bar with category chip strip, filter sheet trigger, and sort dropdown.
class ProductSearchBar extends StatefulWidget {
  final String initialQuery;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onOpenFilter;
  final ValueChanged<ProductSortOption> onSortSelected;
  final ProductSortOption currentSort;
  final int activeFilterCount;
  final ProductCategory currentCategory;
  final ValueChanged<ProductCategory> onCategorySelected;

  const ProductSearchBar({
    super.key,
    required this.initialQuery,
    required this.onQueryChanged,
    required this.onOpenFilter,
    required this.onSortSelected,
    required this.currentSort,
    required this.activeFilterCount,
    required this.currentCategory,
    required this.onCategorySelected,
  });

  @override
  State<ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<ProductSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(ProductSearchBar oldWidget) {
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

  String _getSortLabel(ProductSortOption sort) {
    switch (sort) {
      case ProductSortOption.featured:
        return 'Featured';
      case ProductSortOption.priceLow:
      case ProductSortOption.priceLowToHigh:
        return 'Price: Low to High';
      case ProductSortOption.priceHigh:
      case ProductSortOption.priceHighToLow:
        return 'Price: High to Low';
      case ProductSortOption.ratingHigh:
      case ProductSortOption.ratingHighToLow:
        return 'Highest Rated';
      case ProductSortOption.newest:
        return 'Newest Arrivals';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Row: Input + Filter Button + Sort Button
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _controller,
                hint: 'Search paddles, balls, shoes, bags...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
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
            // Filter Button with Badge
            Badge(
              isLabelVisible: widget.activeFilterCount > 0,
              label: Text('${widget.activeFilterCount}'),
              child: IconButton.outlined(
                tooltip: 'Filter Products',
                icon: const Icon(Icons.tune),
                onPressed: widget.onOpenFilter,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Sort Button
            PopupMenuButton<ProductSortOption>(
              tooltip: 'Sort Products',
              icon: const Icon(Icons.sort),
              initialValue: widget.currentSort,
              onSelected: widget.onSortSelected,
              itemBuilder: (context) => [
                for (final sort in ProductSortOption.values)
                  PopupMenuItem(
                    value: sort,
                    child: Row(
                      children: [
                        if (widget.currentSort == sort)
                          Icon(Icons.check, size: 16, color: theme.colorScheme.primary)
                        else
                          const SizedBox(width: 16),
                        const SizedBox(width: 8),
                        Text(_getSortLabel(sort)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Category Horizontal Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final cat in ProductCategory.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat.displayName),
                    selected: widget.currentCategory == cat,
                    onSelected: (selected) {
                      if (selected) {
                        widget.onCategorySelected(cat);
                      }
                    },
                    avatar: Icon(
                      _getCategoryIcon(cat),
                      size: 16,
                      color: widget.currentCategory == cat
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(ProductCategory cat) {
    switch (cat) {
      case ProductCategory.all:
        return Icons.grid_view;
      case ProductCategory.paddles:
        return Icons.sports_tennis;
      case ProductCategory.balls:
        return Icons.sports_baseball;
      case ProductCategory.shoes:
      case ProductCategory.footwear:
        return Icons.roller_skating;
      case ProductCategory.equipment:
        return Icons.sports_tennis;
      case ProductCategory.bags:
        return Icons.backpack;
      case ProductCategory.apparel:
        return Icons.checkroom;
      case ProductCategory.accessories:
        return Icons.fitness_center;
    }
  }
}
