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
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_wishlist_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_wishlist_state.dart';

/// Wishlist Page for Player Marketplace.
class MarketplaceWishlistPage extends StatelessWidget {
  final MarketplaceWishlistCubit? cubit;

  const MarketplaceWishlistPage({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (cubit ?? sl<MarketplaceWishlistCubit>())..loadWishlist(),
      child: const _MarketplaceWishlistView(),
    );
  }
}

class _MarketplaceWishlistView extends StatelessWidget {
  const _MarketplaceWishlistView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return BlocConsumer<MarketplaceWishlistCubit, MarketplaceWishlistState>(
      listener: (context, state) {
        if (state is MarketplaceWishlistLoaded && state.notice != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.notice!),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Wishlist'),
            actions: [
              IconButton(
                tooltip: 'Go to Cart',
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () {
                  context.push(AppRoutes.playerMarketplaceCart).then((_) {
                    if (context.mounted) {
                      context.read<MarketplaceWishlistCubit>().loadWishlist(showLoading: false);
                    }
                  });
                },
              ),
            ],
          ),
          body: SafeArea(
            child: _buildBody(context, state, theme, currency),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    MarketplaceWishlistState state,
    ThemeData theme,
    NumberFormat currency,
  ) {
    if (state is MarketplaceWishlistLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (state is MarketplaceWishlistFailure) {
      return ErrorStateView(
        message: state.message,
        onRetry: () => context.read<MarketplaceWishlistCubit>().loadWishlist(),
      );
    }

    if (state is MarketplaceWishlistLoaded) {
      if (state.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_outline,
                  size: 72,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Your wishlist is empty',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Save items you love here to easily purchase them later.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'Browse Gear',
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
        onRefresh: () => context.read<MarketplaceWishlistCubit>().loadWishlist(showLoading: false),
        child: ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: state.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final product = state.items[index];
            return _buildWishlistItem(context, product, theme, currency);
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildWishlistItem(
    BuildContext context,
    MarketplaceProduct product,
    ThemeData theme,
    NumberFormat currency,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: () {
        context.push(AppRoutes.playerProductDetailsPath(product.id)).then((_) {
          if (context.mounted) {
            context.read<MarketplaceWishlistCubit>().loadWishlist(showLoading: false);
          }
        });
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              color: theme.colorScheme.surfaceContainerHighest,
              child: product.imageUrl.isNotEmpty
                  ? Image.asset(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.sports_tennis, size: 36),
                    )
                  : const Icon(Icons.sports_tennis, size: 36),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  product.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  currency.format(product.price),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    AppButton(
                      label: 'Move to Cart',
                      variant: AppButtonVariant.secondary,
                      onPressed: product.isInStock
                          ? () {
                              context.read<MarketplaceWishlistCubit>().moveToCart(product);
                            }
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: theme.colorScheme.error,
                      tooltip: 'Remove',
                      onPressed: () {
                        context.read<MarketplaceWishlistCubit>().removeFromWishlist(product.id);
                      },
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
