import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

/// Card summarizing a player's marketplace order with status, item previews, and amount.
class OrderCard extends StatelessWidget {
  final MarketplaceOrder order;
  final VoidCallback onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
  });

  Widget _buildStatusChip() {
    switch (order.status) {
      case MarketplaceOrderStatus.placed:
        return const AppChip.info(label: 'Order Placed');
      case MarketplaceOrderStatus.processing:
        return const AppChip.info(label: 'Processing');
      case MarketplaceOrderStatus.inTransit:
        return const AppChip.warning(label: 'In Transit');
      case MarketplaceOrderStatus.outForDelivery:
        return const AppChip.warning(label: 'Out for Delivery');
      case MarketplaceOrderStatus.delivered:
        return const AppChip.success(label: 'Delivered');
      case MarketplaceOrderStatus.cancelled:
        return const AppChip.error(label: 'Cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and Status Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.referenceId,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormat.format(order.placedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(),
            ],
          ),
          const Divider(height: 24),
          // Items summary & thumbnails
          Row(
            children: [
              // Overlapping thumbnail avatars
              SizedBox(
                height: 48,
                child: Row(
                  children: [
                    for (int i = 0; i < order.items.take(3).length; i++)
                      Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.outlineVariant),
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: order.items[i].product.imageUrl.isNotEmpty
                            ? Image.asset(
                                order.items[i].product.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(Icons.sports_tennis, size: 24),
                              )
                            : const Icon(Icons.sports_tennis, size: 24),
                      ),
                    if (order.items.length > 3)
                      Container(
                        width: 36,
                        height: 48,
                        alignment: Alignment.center,
                        child: Text(
                          '+${order.items.length - 3}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              // Total amount & item count
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${order.totalItemCount} item${order.totalItemCount > 1 ? 's' : ''}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    currency.format(order.totalAmount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Estimated delivery or tracking hint
          if (order.status != MarketplaceOrderStatus.cancelled &&
              order.status != MarketplaceOrderStatus.delivered &&
              order.estimatedDeliveryDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.local_shipping_outlined, size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Estimated Delivery: ${DateFormat('dd MMM yyyy').format(order.estimatedDeliveryDate!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
