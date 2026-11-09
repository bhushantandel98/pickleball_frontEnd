import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

/// Modal bottom sheet allowing players to refine marketplace catalogue listings.
class ProductFilterSheet extends StatefulWidget {
  final ProductFilter initialFilter;
  final ValueChanged<ProductFilter> onApply;

  const ProductFilterSheet({
    super.key,
    required this.initialFilter,
    required this.onApply,
  });

  static Future<void> show(
    BuildContext context, {
    required ProductFilter initialFilter,
    required ValueChanged<ProductFilter> onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ProductFilterSheet(
        initialFilter: initialFilter,
        onApply: onApply,
      ),
    );
  }

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late ProductCategory _selectedCategory;
  late RangeValues _priceRange;
  late bool _inStockOnly;
  late double? _minRating;
  late String? _selectedBrand;

  static const double _minPossiblePrice = 0;
  static const double _maxPossiblePrice = 15000;

  final List<String> _brands = const [
    'All Brands',
    'Selkirk Sport',
    'JOOLA',
    'Franklin Sports',
    'Head',
    'Skechers',
    'Babolat',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialFilter.category ?? ProductCategory.all;
    _priceRange = RangeValues(
      widget.initialFilter.minPrice ?? _minPossiblePrice,
      widget.initialFilter.maxPrice ?? _maxPossiblePrice,
    );
    _inStockOnly = widget.initialFilter.inStockOnly;
    _minRating = widget.initialFilter.minRating;
    _selectedBrand = widget.initialFilter.brand;
  }

  void _reset() {
    setState(() {
      _selectedCategory = ProductCategory.all;
      _priceRange = const RangeValues(_minPossiblePrice, _maxPossiblePrice);
      _inStockOnly = false;
      _minRating = null;
      _selectedBrand = null;
    });
  }

  void _apply() {
    final updated = widget.initialFilter.copyWith(
      category: _selectedCategory,
      minPrice: _priceRange.start > _minPossiblePrice ? _priceRange.start : null,
      maxPrice: _priceRange.end < _maxPossiblePrice ? _priceRange.end : null,
      inStockOnly: _inStockOnly,
      minRating: _minRating,
      brand: (_selectedBrand == null || _selectedBrand == 'All Brands')
          ? null
          : _selectedBrand,
    );
    widget.onApply(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar & Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Products',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _reset,
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Filter options list
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Category Section
                  Text(
                    'Category',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final cat in ProductCategory.values)
                        ChoiceChip(
                          label: Text(cat.displayName),
                          selected: _selectedCategory == cat,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Price Range Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Price Range',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${currency.format(_priceRange.start)} - ${currency.format(_priceRange.end)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: _minPossiblePrice,
                    max: _maxPossiblePrice,
                    divisions: 30,
                    labels: RangeLabels(
                      currency.format(_priceRange.start),
                      currency.format(_priceRange.end),
                    ),
                    onChanged: (values) {
                      setState(() => _priceRange = values);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // In-Stock Only Toggle
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('In-Stock Items Only'),
                    subtitle: const Text('Hide items that are currently sold out'),
                    value: _inStockOnly,
                    onChanged: (val) {
                      setState(() => _inStockOnly = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Brand Selector
                  Text(
                    'Brand',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBrand ?? 'All Brands',
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _brands.map((b) {
                      return DropdownMenuItem<String>(
                        value: b,
                        child: Text(b),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedBrand = (val == null || val == 'All Brands') ? null : val;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Customer Rating Section
                  Text(
                    'Minimum Rating',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Any'),
                        selected: _minRating == null,
                        onSelected: (selected) {
                          if (selected) setState(() => _minRating = null);
                        },
                      ),
                      ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('4.0+ '),
                            Icon(Icons.star, size: 14),
                          ],
                        ),
                        selected: _minRating == 4.0,
                        onSelected: (selected) {
                          setState(() => _minRating = selected ? 4.0 : null);
                        },
                      ),
                      ChoiceChip(
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('4.5+ '),
                            Icon(Icons.star, size: 14),
                          ],
                        ),
                        selected: _minRating == 4.5,
                        onSelected: (selected) {
                          setState(() => _minRating = selected ? 4.5 : null);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
            // Bottom Action Button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Apply Filters',
                  onPressed: _apply,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
