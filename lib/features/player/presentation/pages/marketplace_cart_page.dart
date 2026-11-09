import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_cart_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_cart_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/cart_item_card.dart';

/// Shopping Cart Page for Player Marketplace.
class MarketplaceCartPage extends StatelessWidget {
  final MarketplaceCartCubit? cubit;

  const MarketplaceCartPage({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (cubit ?? sl<MarketplaceCartCubit>())..loadCart(),
      child: const _MarketplaceCartView(),
    );
  }
}

class _MarketplaceCartView extends StatelessWidget {
  const _MarketplaceCartView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return BlocConsumer<MarketplaceCartCubit, MarketplaceCartState>(
      listener: (context, state) {
        if (state is MarketplaceCartLoaded && state.userNotice != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.userNotice!),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Shopping Cart'),
            actions: [
              if (state is MarketplaceCartLoaded && state.items.isNotEmpty)
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear Cart'),
                        content: const Text('Are you sure you want to remove all items from your cart?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              context.read<MarketplaceCartCubit>().clearCart();
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Clear Cart'),
                ),
            ],
          ),
          body: SafeArea(
            child: _buildBody(context, state, theme, currency),
          ),
          bottomNavigationBar: (state is MarketplaceCartLoaded && state.items.isNotEmpty)
              ? Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Amount',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              currency.format(state.totalAmount),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        AppButton(
                          label: 'Checkout (${state.totalItemCount})',
                          onPressed: () {
                            context.push(AppRoutes.playerMarketplaceCheckout).then((_) {
                              if (context.mounted) {
                                context.read<MarketplaceCartCubit>().loadCart();
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    MarketplaceCartState state,
    ThemeData theme,
    NumberFormat currency,
  ) {
    if (state is MarketplaceCartLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (state is MarketplaceCartFailure) {
      return ErrorStateView(
        message: state.message,
        onRetry: () => context.read<MarketplaceCartCubit>().loadCart(),
      );
    }

    if (state is MarketplaceCartLoaded) {
      if (state.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.remove_shopping_cart_outlined,
                  size: 72,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Your cart is empty',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Explore our wide range of pickleball paddles, balls, shoes and gear.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Start Shopping',
                  onPressed: () {
                    context.go(AppRoutes.playerMarketplace);
                  },
                ),
              ],
            ),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => context.read<MarketplaceCartCubit>().loadCart(showLoading: false),
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            // Delivery Free threshold progress card
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.sm),
              color: state.qualifiesForFreeDelivery
                  ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
                  : theme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  Icon(
                    state.qualifiesForFreeDelivery
                        ? Icons.check_circle_outline
                        : Icons.local_shipping_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      state.qualifiesForFreeDelivery
                          ? 'Congratulations! You unlocked FREE Delivery!'
                          : 'Add ${currency.format(state.amountNeededForFreeDelivery)} more to qualify for FREE Delivery.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Cart Items List
            for (final item in state.items) ...[
              CartItemCard(
                item: item,
                onQuantityChanged: (newQty) {
                  context.read<MarketplaceCartCubit>().updateQuantity(item.id, newQty);
                },
                onRemove: () {
                  context.read<MarketplaceCartCubit>().removeItem(item.id);
                },
                onTap: () {
                  context.push(AppRoutes.playerProductDetailsPath(item.product.id));
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.md),

            // Order Price Summary Card
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal (${state.totalItemCount} items)',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        currency.format(state.subtotal),
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
                      Text(
                        'Delivery Fee',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        state.deliveryFee == 0 ? 'FREE' : currency.format(state.deliveryFee),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: state.deliveryFee == 0 ? theme.colorScheme.primary : null,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        currency.format(state.totalAmount),
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
            const SizedBox(height: 80),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
