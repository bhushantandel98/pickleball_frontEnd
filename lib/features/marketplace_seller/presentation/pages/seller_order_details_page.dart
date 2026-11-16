import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_order_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/seller_order_cubit.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/widgets/seller_order_scaffold.dart';

/// Feature 6.4 — Seller Order Details screen (scoped strictly to the owning
/// seller's items, fulfilment address, read-only payment state, and permitted
/// Feature 6.4 actions).
class SellerOrderDetailsPage extends StatelessWidget {
  final String? orderId;
  final SellerOrderCubit? cubit;
  final String? sellerId;
  final String? userId;

  const SellerOrderDetailsPage({
    super.key,
    required this.orderId,
    this.cubit,
    this.sellerId,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return SellerOrderScaffold(
      cubit: cubit,
      sellerId: sellerId,
      userId: userId,
      title: 'Order Details',
      subtitle: 'Seller-scoped order items, fulfilment details & lifecycle.',
      actionsBuilder: (context, _) => [
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.marketplaceSellerOrders),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Orders'),
        ),
      ],
      bodyBuilder: (context, state) {
        SellerOrderView? order;
        for (final o in state.orders) {
          if (o.orderId == orderId) {
            order = o;
            break;
          }
        }

        if (order == null) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order not found or does not contain products belonging to your seller account.',
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: () =>
                      context.go(AppRoutes.marketplaceSellerOrders),
                  child: const Text('Return to Seller Orders'),
                ),
              ],
            ),
          );
        }

        return _OrderDetailContent(
          order: order,
          isMutating: state.isMutating,
        );
      },
    );
  }
}

class _OrderDetailContent extends StatelessWidget {
  final SellerOrderView order;
  final bool isMutating;

  const _OrderDetailContent({
    required this.order,
    required this.isMutating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<SellerOrderCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header & Actions
        AppCard(
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
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Chip(label: Text(order.status.displayName)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Placed on ${order.formattedOrderDate}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (order.isMultiSellerOrder) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Multi-seller order: Other sellers\' products and totals are hidden for tenant isolation.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (order.cancellationReason != null &&
                  order.cancellationReason!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Cancellation Reason: ${order.cancellationReason}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (order.canAcceptOrder)
                    FilledButton.icon(
                      onPressed:
                          isMutating ? null : () => cubit.acceptOrder(order.orderId),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Accept Order (Move to Processing)'),
                    ),
                  if (order.canMarkDispatched)
                    FilledButton.icon(
                      onPressed: isMutating
                          ? null
                          : () => _showDispatchDialog(context, cubit, order.orderId),
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Mark Dispatched (In Transit)'),
                    ),
                  if (order.canMarkOutForDelivery)
                    FilledButton.icon(
                      onPressed: isMutating
                          ? null
                          : () => _showFulfilmentNoteDialog(
                                context,
                                title: 'Mark Out for Delivery',
                                confirmLabel: 'Mark Out for Delivery',
                                onConfirm: (note) => cubit.markOutForDelivery(
                                  orderId: order.orderId,
                                  note: note,
                                ),
                              ),
                      icon: const Icon(Icons.delivery_dining_outlined),
                      label: const Text('Mark Out for Delivery'),
                    ),
                  if (order.canMarkDelivered)
                    FilledButton.icon(
                      onPressed: isMutating
                          ? null
                          : () => _showFulfilmentNoteDialog(
                                context,
                                title: 'Confirm Delivery',
                                confirmLabel: 'Confirm Delivered',
                                helperText:
                                    'Sensitive customer street/phone details will be masked once delivered.',
                                onConfirm: (note) => cubit.markDelivered(
                                  orderId: order.orderId,
                                  note: note,
                                ),
                              ),
                      icon: const Icon(Icons.verified_outlined),
                      label: const Text('Confirm Delivered'),
                    ),
                  if (order.canCancelOrder)
                    OutlinedButton.icon(
                      onPressed: isMutating
                          ? null
                          : () => _showCancelDialog(context, cubit, order.orderId),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel Order'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Settlement & commission statements (Feature 6.6) are managed separately. Payment records are read-only.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 1b. Fulfilment & Dispatch Details (Feature 6.5)
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fulfilment & Dispatch Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (order.fulfilment == null)
                Text(
                  'No dispatch details recorded yet. Once Processing, enter carrier & tracking reference to mark Dispatched.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else ...[
                if (order.fulfilment!.carrierName != null)
                  Text('Carrier: ${order.fulfilment!.carrierName}'),
                if (order.fulfilment!.trackingNumber != null)
                  Text('Tracking Ref: ${order.fulfilment!.trackingNumber}'),
                if (order.fulfilment!.trackingUrl != null)
                  Text('Tracking Link: ${order.fulfilment!.trackingUrl}'),
                if (order.fulfilment!.dispatchedAt != null)
                  Text(
                    'Dispatched At: ${DateFormat('dd MMM yyyy, HH:mm').format(order.fulfilment!.dispatchedAt!)}',
                  ),
                if (order.fulfilment!.deliveredAt != null)
                  Text(
                    'Delivered At: ${DateFormat('dd MMM yyyy, HH:mm').format(order.fulfilment!.deliveredAt!)}',
                  ),
                if (order.fulfilment!.fulfilmentNote != null)
                  Text('Note: ${order.fulfilment!.fulfilmentNote}'),
                const SizedBox(height: 4),
                Text(
                  'Seller-entered manual tracking details (no live courier API integration).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 2. Seller Ordered Items
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Ordered Products (${order.totalUnits} units)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...order.sellerItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Qty: ${item.quantity}'
                              '${item.selectedSize != null ? ' • Size: ${item.selectedSize}' : ''}'
                              '${item.selectedColor != null ? ' • Color: ${item.selectedColor}' : ''}'
                              ' • Return Window: ${item.product.returnPolicyDays} days',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item.formattedItemTotal,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Seller Order Value (Gross)',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    order.formattedSellerSubtotal,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 3. Fulfilment Delivery Address & Read-Only Payment Info
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Fulfilment Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('Recipient: ${order.deliveryAddress.recipientName}'),
              Text('Phone: ${order.deliveryAddress.phoneNumber}'),
              Text('Address: ${order.deliveryAddress.streetAddress}'),
              Text('Location: ${order.deliveryAddress.formattedLocation}'),
              if (order.deliveryAddress.landmark != null &&
                  order.deliveryAddress.landmark!.isNotEmpty)
                Text('Landmark: ${order.deliveryAddress.landmark}'),
              if (order.deliveryAddress.isMasked) ...[
                const SizedBox(height: 4),
                Text(
                  'Sensitive contact details are masked once the order is ${order.status.displayName.toLowerCase()}.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const Divider(height: AppSpacing.lg),
              Text(
                'Payment Summary (Read-Only)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('Method: ${order.paymentMethod}'),
              Text('Payment Status: ${order.paymentStatus}'),
              const SizedBox(height: 4),
              Text(
                'Order value is not a settled payout. Sellers cannot modify customer payment status.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 3b. Product-Specific Return Windows (Feature 6.6)
        if (order.itemReturnSnapshots.isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Return Windows (Order-Placement Snapshot)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Return windows are locked to the policy active when this order was placed.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...order.itemReturnSnapshots.map((ret) {
                  final df = DateFormat('dd MMM yyyy');
                  final endLabel = ret.returnWindowEndsAt != null
                      ? ' • Eligible until ${df.format(ret.returnWindowEndsAt!)}'
                      : '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${ret.productTitle} (${ret.quantity}x)',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${ret.policyLabel} • ${ret.eligibilityStatus.label}$endLabel',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 3c. Order-Level Settlement Breakdown (Feature 6.6, Read-Only)
        if (order.settlementSnapshot != null) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order-Level Settlement Breakdown (Read-Only)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                _SettlementRow(
                  label: 'Seller Order Value (Gross)',
                  value: order.settlementSnapshot!.formattedGrossAmount,
                ),
                _SettlementRow(
                  label: order.settlementSnapshot!.isCommissionConfigured
                      ? 'Platform Commission (${order.settlementSnapshot!.snapshottedCommissionRatePercent!.toStringAsFixed(0)}%)'
                      : 'Platform Commission',
                  value: order.settlementSnapshot!.isCommissionConfigured
                      ? '-${order.settlementSnapshot!.formattedCommissionAmount}'
                      : 'Not configured',
                ),
                _SettlementRow(
                  label: 'Other Deductions',
                  value: '-${order.settlementSnapshot!.formattedOtherDeductions}',
                ),
                const Divider(),
                _SettlementRow(
                  label: 'Estimated Net Settlement',
                  value: order.settlementSnapshot!.formattedEstimatedNetSettlement,
                  isBold: true,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Actual Payout Status: ${order.settlementSnapshot!.payoutStatus.label}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.info,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.settlementSnapshot!.commissionRuleLabel}. Actual payout dates & transfers require verified backend/payment-provider settlement.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 4. Order Status Timeline
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Timeline (${order.timeline.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (order.timeline.isEmpty)
                const Text('No timeline events recorded yet.')
              else
                ...order.timeline.map((step) {
                  final ts = step.timestamp != null
                      ? DateFormat('dd MMM yyyy, HH:mm').format(step.timestamp!)
                      : '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          step.isCurrent
                              ? Icons.radio_button_checked
                              : Icons.check_circle_outline,
                          size: 18,
                          color: step.isCurrent
                              ? AppColors.primary
                              : AppColors.success,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${step.title}${ts.isNotEmpty ? ' • $ts' : ''}',
                                style: theme.textTheme.labelLarge,
                              ),
                              Text(
                                step.description,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
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
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Cancellation Reason *',
            border: OutlineInputBorder(),
          ),
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
      await cubit.cancelOrder(orderId: orderId, reason: reasonCtrl.text);
    }
    reasonCtrl.dispose();
  }

  Future<void> _showDispatchDialog(
    BuildContext context,
    SellerOrderCubit cubit,
    String orderId,
  ) async {
    final carrierCtrl = TextEditingController();
    final trackingCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Dispatch Order $orderId'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: carrierCtrl,
                decoration: const InputDecoration(
                  labelText: 'Carrier / Courier Name *',
                  hintText: 'e.g. Delhivery, BlueDart, DTDC',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: trackingCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tracking Reference *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Tracking URL (optional https://...)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Dispatch Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Mark Dispatched'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.markDispatched(
        orderId: orderId,
        carrierName: carrierCtrl.text,
        trackingNumber: trackingCtrl.text,
        trackingUrl: urlCtrl.text,
        note: noteCtrl.text,
      );
    }
    carrierCtrl.dispose();
    trackingCtrl.dispose();
    urlCtrl.dispose();
    noteCtrl.dispose();
  }

  Future<void> _showFulfilmentNoteDialog(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String? helperText,
    required Future<void> Function(String? note) onConfirm,
  }) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (helperText != null) ...[
              Text(helperText),
              const SizedBox(height: AppSpacing.sm),
            ],
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Fulfilment Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onConfirm(noteCtrl.text);
    }
    noteCtrl.dispose();
  }
}

class _SettlementRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _SettlementRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}
