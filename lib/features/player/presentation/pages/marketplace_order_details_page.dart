import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_orders_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_orders_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/order_status_timeline.dart';

/// Player Marketplace Order Details and Tracking Page.
class MarketplaceOrderDetailsPage extends StatelessWidget {
  final String orderId;
  final MarketplaceOrderDetailsCubit? cubit;

  const MarketplaceOrderDetailsPage({
    super.key,
    required this.orderId,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (cubit ?? MarketplaceOrderDetailsCubit(
        repository: sl(),
        orderId: orderId,
      ))..loadOrderDetails(),
      child: const _MarketplaceOrderDetailsView(),
    );
  }
}

class _MarketplaceOrderDetailsView extends StatelessWidget {
  const _MarketplaceOrderDetailsView();

  Widget _buildStatusChip(MarketplaceOrderStatus status) {
    switch (status) {
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

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this order? This action cannot be undone.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                hintText: 'e.g. Changed my mind, found better price',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              final reason = reasonController.text.trim().isEmpty
                  ? 'Buyer cancelled the order'
                  : reasonController.text.trim();
              context.read<MarketplaceOrderDetailsCubit>().cancelOrder(reason);
            },
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return BlocConsumer<MarketplaceOrderDetailsCubit, MarketplaceOrderDetailsState>(
      listener: (context, state) {
        if (state is MarketplaceOrderDetailsLoaded && state.userNotice != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.userNotice!),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is MarketplaceOrderDetailsLoading) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order Details')),
            body: const Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        if (state is MarketplaceOrderDetailsFailure) {
          return Scaffold(
            appBar: AppBar(title: const Text('Order Details')),
            body: ErrorStateView(
              message: state.message,
              onRetry: () => context.read<MarketplaceOrderDetailsCubit>().loadOrderDetails(),
            ),
          );
        }

        if (state is MarketplaceOrderDetailsLoaded) {
          final order = state.order;

          return Scaffold(
            appBar: AppBar(
              title: Text(order.referenceId),
              actions: [
                _buildStatusChip(order.status),
                const SizedBox(width: AppSpacing.md),
              ],
            ),
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: () =>
                    context.read<MarketplaceOrderDetailsCubit>().loadOrderDetails(),
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    // Order Meta Card
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Order Placed',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                dateFormat.format(order.placedAt),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (order.estimatedDeliveryDate != null &&
                              order.status != MarketplaceOrderStatus.cancelled &&
                              order.status != MarketplaceOrderStatus.delivered) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Estimated Delivery',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy').format(order.estimatedDeliveryDate!),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (order.cancellationReason != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 16, color: theme.colorScheme.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Cancellation Reason: ${order.cancellationReason}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Tracking Stepper Timeline Card
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Status & Tracking',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 24),
                          OrderStatusTimeline(steps: order.trackingSteps),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Delivery Address Card
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 20, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Shipping Address',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            order.deliveryAddress.fullName,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Phone: ${order.deliveryAddress.phoneNumber}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.deliveryAddress.formattedAddress,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Items List Card
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ordered Items (${order.totalItemCount})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 20),
                          for (final item in order.items)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: item.product.imageUrl.isNotEmpty
                                        ? Image.asset(
                                            item.product.imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) =>
                                                const Icon(Icons.sports_tennis, size: 24),
                                          )
                                        : const Icon(Icons.sports_tennis, size: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Qty: ${item.quantity} • ${currency.format(item.product.price)} each',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        if (item.selectedSize != null || item.selectedColor != null)
                                          Text(
                                            [
                                              if (item.selectedSize != null) 'Size: ${item.selectedSize}',
                                              if (item.selectedColor != null) 'Color: ${item.selectedColor}',
                                            ].join(' | '),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    currency.format(item.totalPrice),
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Payment & Pricing Breakdown Card
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment & Summary',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Payment Method', style: theme.textTheme.bodyMedium),
                              Text(
                                order.paymentMethod,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Payment Status', style: theme.textTheme.bodyMedium),
                              Text(
                                order.paymentStatus,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: order.paymentStatus == 'Paid'
                                      ? Colors.green
                                      : Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Subtotal', style: theme.textTheme.bodyMedium),
                              Text(currency.format(order.subtotal), style: theme.textTheme.bodyMedium),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Delivery Fee', style: theme.textTheme.bodyMedium),
                              Text(
                                order.deliveryFee == 0 ? 'FREE' : currency.format(order.deliveryFee),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: order.deliveryFee == 0 ? theme.colorScheme.primary : null,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Cancel Order Action (if eligible)
                    if (order.canBeCancelled) ...[
                      AppButton(
                        label: 'Cancel Order',
                        variant: AppButtonVariant.secondary,
                        isLoading: state.isCancelling,
                        onPressed: () => _showCancelDialog(context),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: Text(
                          'You can cancel your order anytime before it leaves the fulfillment facility.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
