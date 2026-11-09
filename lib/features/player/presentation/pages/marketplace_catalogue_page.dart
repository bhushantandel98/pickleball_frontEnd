import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_catalogue_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_catalogue_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/product_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/product_filter_sheet.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/product_search_bar.dart';

/// Player Marketplace Catalogue Page featuring category tabs, search, filtering,
/// quick wishlist/cart actions, and product cards.
class MarketplaceCataloguePage extends StatelessWidget {
  final MarketplaceCatalogueCubit? cubit;

  const MarketplaceCataloguePage({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (cubit ?? sl<MarketplaceCatalogueCubit>())..loadCatalogue(),
      child: const _MarketplaceCatalogueView(),
    );
  }
}

class _MarketplaceCatalogueView extends StatelessWidget {
  const _MarketplaceCatalogueView();

  void _openFilterSheet(BuildContext context, MarketplaceCatalogueLoaded state) {
    ProductFilterSheet.show(
      context,
      initialFilter: state.filter,
      onApply: (newFilter) {
        context.read<MarketplaceCatalogueCubit>().updateFilter(newFilter);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MarketplaceCatalogueCubit, MarketplaceCatalogueState>(
      listener: (context, state) {},
      builder: (context, state) {
        int cartCount = 0;
        if (state is MarketplaceCatalogueLoaded) {
          cartCount = state.cartItemCount;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Pickleball Shop'),
            actions: [
              IconButton(
                tooltip: 'Wishlist',
                icon: const Icon(Icons.favorite_border),
                onPressed: () {
                  context.push(AppRoutes.playerMarketplaceWishlist).then((_) {
                    if (context.mounted) {
                      context.read<MarketplaceCatalogueCubit>().refresh();
                    }
                  });
                },
              ),
              IconButton(
                tooltip: 'My Orders',
                icon: const Icon(Icons.receipt_long_outlined),
                onPressed: () {
                  context.push(AppRoutes.playerMarketplaceOrders);
                },
              ),
              Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: IconButton(
                  tooltip: 'Cart',
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () {
                    context.push(AppRoutes.playerMarketplaceCart).then((_) {
                      if (context.mounted) {
                        context.read<MarketplaceCatalogueCubit>().refresh();
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => context.read<MarketplaceCatalogueCubit>().refresh(),
              child: _buildContent(context, state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, MarketplaceCatalogueState state) {
    if (state is MarketplaceCatalogueLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (state is MarketplaceCatalogueFailure) {
      return ErrorStateView(
        message: state.message,
        onRetry: () => context.read<MarketplaceCatalogueCubit>().loadCatalogue(),
      );
    }

    if (state is MarketplaceCatalogueLoaded) {
      final products = state.products;

      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: ProductSearchBar(
                initialQuery: state.query,
                onQueryChanged: (query) {
                  context.read<MarketplaceCatalogueCubit>().updateSearchQuery(query);
                },
                onOpenFilter: () => _openFilterSheet(context, state),
                currentSort: state.filter.sortOption,
                onSortSelected: (sort) {
                  context.read<MarketplaceCatalogueCubit>().updateSortOption(sort);
                },
                activeFilterCount: state.filter.activeFilterCount,
                currentCategory: state.filter.category ?? ProductCategory.all,
                onCategorySelected: (category) {
                  context.read<MarketplaceCatalogueCubit>().updateCategory(category);
                },
              ),
            ),
          ),
          if (products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No products found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Try tweaking your search keywords or adjusting active filters.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: 'Reset Filters',
                      onPressed: () {
                        context.read<MarketplaceCatalogueCubit>().resetFilter();
                      },
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${products.length} product${products.length > 1 ? 's' : ''} available',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (state.filter.isFiltered)
                      TextButton(
                        onPressed: () {
                          context.read<MarketplaceCatalogueCubit>().resetFilter();
                        },
                        child: const Text('Clear Filters'),
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = products[index];
                    final isWishlisted = state.wishlistProductIds.contains(product.id);

                    return ProductCard(
                      product: product,
                      isWishlisted: isWishlisted,
                      onTap: () {
                        context.push(AppRoutes.playerProductDetailsPath(product.id)).then((_) {
                          if (context.mounted) {
                            context.read<MarketplaceCatalogueCubit>().refresh();
                          }
                        });
                      },
                      onToggleWishlist: () {
                        context.read<MarketplaceCatalogueCubit>().toggleWishlist(product.id);
                      },
                      onAddToCart: () {
                        context.read<MarketplaceCatalogueCubit>().quickAddToCart(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "${product.name}" to cart'),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'View Cart',
                              onPressed: () {
                                context.push(AppRoutes.playerMarketplaceCart).then((_) {
                                  if (context.mounted) {
                                    context.read<MarketplaceCatalogueCubit>().refresh();
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  childCount: products.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxl),
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
