import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

/// Card displaying an individual cart item with quantity increment/decrement and removal controls.
class CartItemCard extends StatelessWidget {
  final MarketplaceCartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  const CartItemCard({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    this.onTap,
  });

  Widget _buildThumbnail(BuildContext context) {
    final theme = Theme.of(context);
    if (item.product.imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          item.product.imageUrl,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallbackThumbnail(theme),
        ),
      );
    }
    return _buildFallbackThumbnail(theme);
  }

  Widget _buildFallbackThumbnail(ThemeData theme) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.shopping_bag_outlined,
        size: 32,
        color: theme.colorScheme.primary.withValues(alpha: 0.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumbnail(context),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.brand.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            item.product.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: theme.colorScheme.error,
                      tooltip: 'Remove',
                      visualDensity: VisualDensity.compact,
                      onPressed: onRemove,
                    ),
                  ],
                ),
                if (item.selectedSize != null || item.selectedColor != null) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (item.selectedSize != null)
                        Text(
                          'Size: ${item.selectedSize}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (item.selectedColor != null)
                        Text(
                          'Color: ${item.selectedColor}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currency.format(item.totalPrice),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    // Quantity counter
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: item.quantity > 1
                                ? () => onQuantityChanged(item.quantity - 1)
                                : onRemove,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Icon(
                                item.quantity > 1 ? Icons.remove : Icons.delete,
                                size: 16,
                                color: item.quantity > 1
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.error,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${item.quantity}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: item.quantity < item.product.stockCount
                                ? () => onQuantityChanged(item.quantity + 1)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Icon(
                                Icons.add,
                                size: 16,
                                color: item.quantity < item.product.stockCount
                                    ? theme.colorScheme.onSurface
                                    : theme.colorScheme.outline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
