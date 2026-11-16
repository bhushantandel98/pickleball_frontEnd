import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_order_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/seller_order_cubit.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/widgets/seller_order_scaffold.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

/// Feature 6.4 — Seller Order Management listing screen.
class SellerOrdersPage extends StatefulWidget {
  final SellerOrderCubit? cubit;
  final String? sellerId;
  final String? userId;

  const SellerOrdersPage({
    super.key,
    this.cubit,
    this.sellerId,
    this.userId,
  });

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SellerOrderScaffold(
      cubit: widget.cubit,
      sellerId: widget.sellerId,
      userId: widget.userId,
      title: 'Seller Orders',
      subtitle:
          'Manage orders containing your pickleball products. Multi-seller orders are scoped to your items only.',
      actionsBuilder: (context, _) => [
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.marketplaceSellerDashboard),
          icon: const Icon(Icons.dashboard_outlined),
          label: const Text('Dashboard'),
        ),
      ],
      bodyBuilder: (context, state) {
        final cubit = context.read<SellerOrderCubit>();
        final filter = state.filter;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OrderFilterCard(
              searchController: _searchCtrl,
              filter: filter,
              onFilterChanged: cubit.applyFilter,
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.orders.isEmpty)
              EmptyStateView(
                title: filter.hasActiveFilters
                    ? 'No Matching Orders'
                    : 'No Seller Orders Yet',
                message: filter.hasActiveFilters
                    ? 'Try clearing your search, status, or date filters.'
                    : 'Orders containing your approved & published products will appear here.',
                actionLabel: filter.hasActiveFilters ? 'Clear Filters' : null,
                onAction: filter.hasActiveFilters
                    ? () {
                        _searchCtrl.clear();
                        cubit.applyFilter(const SellerOrderFilter());
                      }
                    : null,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.orders.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final order = state.orders[index];
                  return _SellerOrderCard(
                    order: order,
                    isMutating: state.isMutating,
                    onViewDetails: () => context.go(
                      AppRoutes.marketplaceSellerOrderDetailsPath(
                        order.orderId,
                      ),
                    ),
                    onAccept: () => cubit.acceptOrder(order.orderId),
                    onCancel: () =>
                        _showCancelDialog(context, cubit, order.orderId),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    SellerOrderCubit cubit,
    String orderId,
  ) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cancel Order $orderId?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Provide a clear cancellation reason. Payment records and refund execution are not modified by this action.',
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason *',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.cancelOrder(
        orderId: orderId,
        reason: reasonCtrl.text,
      );
    }
    reasonCtrl.dispose();
  }
}

class _OrderFilterCard extends StatelessWidget {
  final TextEditingController searchController;
  final SellerOrderFilter filter;
  final ValueChanged<SellerOrderFilter> onFilterChanged;

  const _OrderFilterCard({
    required this.searchController,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy');
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 340,
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Order ID, product, customer or city...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: filter.query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              onFilterChanged(filter.copyWith(query: ''));
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) =>
                      onFilterChanged(filter.copyWith(query: value)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: filter.fromDate ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    onFilterChanged(filter.copyWith(fromDate: picked));
                  }
                },
                icon: const Icon(Icons.date_range_outlined, size: 18),
                label: Text(
                  filter.fromDate == null
                      ? 'From Date'
                      : 'From: ${df.format(filter.fromDate!)}',
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: filter.toDate ?? DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    onFilterChanged(filter.copyWith(toDate: picked));
                  }
                },
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text(
                  filter.toDate == null
                      ? 'To Date'
                      : 'To: ${df.format(filter.toDate!)}',
                ),
              ),
              if (filter.hasActiveFilters)
                TextButton(
                  onPressed: () {
                    searchController.clear();
                    onFilterChanged(const SellerOrderFilter());
                  },
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: filter.status == null,
                  onSelected: (_) =>
                      onFilterChanged(filter.copyWith(clearStatus: true)),
                ),
                const SizedBox(width: AppSpacing.xs),
                ...MarketplaceOrderStatus.values.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: FilterChip(
                      label: Text(status.displayName),
                      selected: filter.status == status,
                      onSelected: (_) =>
                          onFilterChanged(filter.copyWith(status: status)),
                    ),
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

class _SellerOrderCard extends StatelessWidget {
  final SellerOrderView order;
  final bool isMutating;
  final VoidCallback onViewDetails;
  final VoidCallback onAccept;
  final VoidCallback onCancel;

  const _SellerOrderCard({
    required this.order,
    required this.isMutating,
    required this.onViewDetails,
    required this.onAccept,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _orderStatusColor(order.status);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                order.orderId,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              _OrderStatusBadge(
                label: order.status.displayName,
                color: statusColor,
              ),
              if (order.isMultiSellerOrder)
                const _OrderStatusBadge(
                  label: 'Multi-Seller (Scoped)',
                  color: AppColors.info,
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${order.formattedOrderDate} • Customer: ${order.deliveryAddress.recipientName} (${order.deliveryAddress.formattedLocation})',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          ...order.sellerItems.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '• ${item.quantity}x ${item.product.title}'
                '${item.selectedSize != null ? ' (${item.selectedSize})' : ''}'
                '${item.selectedColor != null ? ' • ${item.selectedColor}' : ''}'
                ' — ${item.formattedItemTotal}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: 4,
            children: [
              Text(
                'Your Order Value: ${order.formattedSellerSubtotal}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Payment: ${order.paymentStatus} (${order.paymentMethod})',
                style: theme.textTheme.bodySmall,
              ),
              if (order.fulfilment?.trackingNumber != null)
                Text(
                  'Tracking: ${order.fulfilment!.carrierName ?? 'Carrier'} (${order.fulfilment!.trackingNumber})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.info,
                  ),
                ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OutlinedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Order Details'),
              ),
              if (order.canAcceptOrder)
                FilledButton.icon(
                  onPressed: isMutating ? null : onAccept,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Accept Order'),
                ),
              if (order.canCancelOrder)
                TextButton.icon(
                  onPressed: isMutating ? null : onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel Order'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _orderStatusColor(MarketplaceOrderStatus status) {
    switch (status) {
      case MarketplaceOrderStatus.placed:
        return AppColors.warning;
      case MarketplaceOrderStatus.processing:
        return AppColors.info;
      case MarketplaceOrderStatus.inTransit:
      case MarketplaceOrderStatus.outForDelivery:
        return AppColors.secondary;
      case MarketplaceOrderStatus.delivered:
        return AppColors.success;
      case MarketplaceOrderStatus.cancelled:
        return AppColors.error;
    }
  }
}

class _OrderStatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _OrderStatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
