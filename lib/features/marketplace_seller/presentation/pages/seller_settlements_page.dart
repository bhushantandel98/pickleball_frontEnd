import 'package:flutter/material.dart';
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

/// Feature 6.6 — Read-only Order-Level Settlement, Commission & Return Window
/// Visibility screen.
class SellerSettlementsPage extends StatelessWidget {
  final SellerOrderCubit? cubit;
  final String? sellerId;
  final String? userId;

  const SellerSettlementsPage({
    super.key,
    this.cubit,
    this.sellerId,
    this.userId,
  });

  static String _fmt(double amount) => NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 0,
        locale: 'en_IN',
      ).format(amount);

  @override
  Widget build(BuildContext context) {
    return SellerOrderScaffold(
      cubit: cubit,
      sellerId: sellerId,
      userId: userId,
      title: 'Settlements & Commission Statements',
      subtitle:
          'Read-only order-level gross value, snapshotted commission, return holds & estimated net settlement.',
      actionsBuilder: (context, _) => [
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.marketplaceSellerOrders),
          icon: const Icon(Icons.local_shipping_outlined),
          label: const Text('Manage Orders'),
        ),
      ],
      bodyBuilder: (context, state) {
        final theme = Theme.of(context);
        final orders = state.orders;
        final activeSnapshots = orders
            .where((o) => o.status != MarketplaceOrderStatus.cancelled)
            .map((o) => o.settlementSnapshot)
            .whereType<SellerOrderSettlementSnapshot>()
            .toList();

        final totalGross = activeSnapshots.fold<double>(
          0.0,
          (sum, s) => sum + s.grossAmount,
        );
        final totalCommission = activeSnapshots.fold<double>(
          0.0,
          (sum, s) => sum + s.commissionAmount,
        );
        final totalDeductions = activeSnapshots.fold<double>(
          0.0,
          (sum, s) => sum + s.otherDeductionsAmount,
        );
        final totalEstimatedNet = activeSnapshots.fold<double>(
          0.0,
          (sum, s) => sum + s.estimatedNetSettlement,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.info),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Read-Only Settlement & Payout Visibility',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Commission terms and product return windows are snapshotted per order at placement. Estimated net settlement is NOT an executed payout; actual transfers and settlement dates require verified backend & payment-provider confirmation.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _SummaryBox(
                        label: 'Gross Order Value',
                        value: _fmt(totalGross),
                      ),
                      _SummaryBox(
                        label: 'Snapshotted Commission',
                        value: '-${_fmt(totalCommission)}',
                      ),
                      _SummaryBox(
                        label: 'Other Deductions',
                        value: '-${_fmt(totalDeductions)}',
                      ),
                      _SummaryBox(
                        label: 'Estimated Net Settlement',
                        value: _fmt(totalEstimatedNet),
                        highlight: AppColors.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Order-Level Statements (${orders.length})',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (orders.isEmpty)
              const EmptyStateView(
                title: 'No Settlement Statements Yet',
                message:
                    'Order-level commission and settlement snapshots will appear once orders containing your products are placed.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: orders.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  final settlement = order.settlementSnapshot;
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              order.orderId,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Chip(label: Text(order.status.displayName)),
                            if (settlement != null)
                              Chip(
                                label: Text(settlement.payoutStatus.label),
                              ),
                            if (order.isMultiSellerOrder)
                              const Chip(
                                label: Text('Multi-Seller (Your Slice Only)'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Order Date: ${order.formattedOrderDate} • Payment (Read-Only): ${order.paymentStatus}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (settlement != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.lg,
                            runSpacing: 4,
                            children: [
                              Text(
                                'Gross: ${settlement.formattedGrossAmount}',
                              ),
                              Text(
                                'Commission (${settlement.snapshottedCommissionRatePercent.toStringAsFixed(0)}%): -${settlement.formattedCommissionAmount}',
                              ),
                              Text(
                                'Deductions: -${settlement.formattedOtherDeductions}',
                              ),
                              Text(
                                'Est. Net: ${settlement.formattedEstimatedNetSettlement}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rule Snapshot: ${settlement.commissionRuleLabel}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (order.itemReturnSnapshots.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          ...order.itemReturnSnapshots.map(
                            (ret) => Text(
                              '• ${ret.productTitle}: ${ret.policyLabel} — ${ret.eligibilityStatus.label}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.xs),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => context.go(
                              AppRoutes.marketplaceSellerOrderDetailsPath(
                                order.orderId,
                              ),
                            ),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: const Text('View Order Breakdown'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? highlight;

  const _SummaryBox({
    required this.label,
    required this.value,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 210,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: highlight,
            ),
          ),
        ],
      ),
    );
  }
}
