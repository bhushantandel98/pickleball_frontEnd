import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/product_details_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/product_details_state.dart';

/// Product Details Page displaying high-res gallery, specs, seller info, return policy, and purchase options.
class ProductDetailsPage extends StatelessWidget {
  final String productId;
  final ProductDetailsCubit? cubit;

  const ProductDetailsPage({
    super.key,
    required this.productId,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (cubit ?? ProductDetailsCubit(
        repository: sl(),
        productId: productId,
      ))..loadProduct(),
      child: const _ProductDetailsView(),
    );
  }
}

class _ProductDetailsView extends StatefulWidget {
  const _ProductDetailsView();

  @override
  State<_ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<_ProductDetailsView> {
  int _activeGalleryIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return BlocConsumer<ProductDetailsCubit, ProductDetailsState>(
      listener: (context, state) {
        if (state is ProductDetailsLoaded && state.actionMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.actionMessage!),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ProductDetailsLoading) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        if (state is ProductDetailsFailure) {
          return Scaffold(
            appBar: AppBar(title: const Text('Product Details')),
            body: ErrorStateView(
              message: state.message,
              onRetry: () => context.read<ProductDetailsCubit>().loadProduct(),
            ),
          );
        }

        if (state is ProductDetailsLoaded) {
          final product = state.product;
          final images = product.galleryImages.isNotEmpty
              ? product.galleryImages
              : [product.imageUrl];

          return Scaffold(
            appBar: AppBar(
              title: Text(product.name),
              actions: [
                IconButton(
                  tooltip: state.isWishlisted ? 'Remove from wishlist' : 'Add to wishlist',
                  icon: Icon(
                    state.isWishlisted ? Icons.favorite : Icons.favorite_border,
                    color: state.isWishlisted ? theme.colorScheme.error : null,
                  ),
                  onPressed: () {
                    context.read<ProductDetailsCubit>().toggleWishlist();
                  },
                ),
                Badge(
                  isLabelVisible: state.cartItemCount > 0,
                  label: Text('${state.cartItemCount}'),
                  child: IconButton(
                    tooltip: 'Cart',
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      context.push(AppRoutes.playerMarketplaceCart).then((_) {
                        if (context.mounted) {
                          context.read<ProductDetailsCubit>().loadProduct();
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gallery Carousel / Preview
                  AspectRatio(
                    aspectRatio: 1.25,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        PageView.builder(
                          itemCount: images.length,
                          onPageChanged: (index) {
                            setState(() => _activeGalleryIndex = index);
                          },
                          itemBuilder: (context, index) {
                            final imgUrl = images[index];
                            if (imgUrl.isNotEmpty) {
                              return Image.asset(
                                imgUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _buildFallbackImage(theme),
                              );
                            }
                            return _buildFallbackImage(theme);
                          },
                        ),
                        if (images.length > 1)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(images.length, (idx) {
                                return Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _activeGalleryIndex == idx
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outlineVariant,
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Product Details Container
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category & Brand row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              product.brand.toUpperCase(),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            AppChip.info(label: product.category.displayName),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        // Title
                        Text(
                          product.name,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // Rating & Reviews Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    product.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.star, size: 14, color: Colors.white),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${product.reviewCount} customer reviews',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),

                        // Price and Discount
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              currency.format(product.price),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            if (product.hasDiscount) ...[
                              const SizedBox(width: 12),
                              Text(
                                currency.format(product.originalPrice),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${product.discountPercentage}% OFF',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Inclusive of all taxes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Stock Availability badge
                        if (!product.isInStock)
                          const AppChip.error(label: 'Currently Out of Stock')
                        else if (product.isLowStock)
                          AppChip.warning(label: 'Hurry! Only ${product.stockCount} items left in stock')
                        else
                          AppChip.success(label: 'In Stock (${product.stockCount} available)'),

                        const SizedBox(height: AppSpacing.lg),

                        // Size Selection (if applicable)
                        if (product.availableSizes.isNotEmpty) ...[
                          Text(
                            'Select Size',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: product.availableSizes.map((size) {
                              final isSelected = state.selectedSize == size;
                              return ChoiceChip(
                                label: Text(size),
                                selected: isSelected,
                                onSelected: (_) {
                                  context.read<ProductDetailsCubit>().selectSize(size);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Color Selection (if applicable)
                        if (product.availableColors.isNotEmpty) ...[
                          Text(
                            'Select Color / Style',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: product.availableColors.map((color) {
                              final isSelected = state.selectedColor == color;
                              return ChoiceChip(
                                label: Text(color),
                                selected: isSelected,
                                onSelected: (_) {
                                  context.read<ProductDetailsCubit>().selectColor(color);
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // Product Description
                        Text(
                          'Description',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Specifications Card
                        if (product.specifications.isNotEmpty) ...[
                          Text(
                            'Specifications',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          AppCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              children: product.specifications.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 130,
                                        child: Text(
                                          entry.key,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],

                        // Seller & Return Policy Card
                        AppCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.storefront, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sold by ${product.sellerName}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                children: [
                                  Icon(Icons.assignment_return_outlined,
                                      size: 20, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${product.returnPolicyDays} Days Replacement / Return Policy',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.local_shipping_outlined,
                                      size: 20, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Free delivery on orders over ₹999. Pay on delivery available.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Sticky Bar with Quantity and CTAs
            bottomSheet: Container(
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
                    // Quantity selector
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: state.selectedQuantity > 1
                                ? () => context.read<ProductDetailsCubit>().decrementQuantity()
                                : null,
                          ),
                          Text(
                            '${state.selectedQuantity}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: state.selectedQuantity < product.stockCount
                                ? () => context.read<ProductDetailsCubit>().incrementQuantity()
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Add to Cart
                    Expanded(
                      child: AppButton(
                        label: 'Add to Cart',
                        variant: AppButtonVariant.secondary,
                        isLoading: state.isAddingToCart,
                        onPressed: product.isInStock
                            ? () {
                                context.read<ProductDetailsCubit>().addToCart();
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // Buy Now
                    Expanded(
                      child: AppButton(
                        label: 'Buy Now',
                        onPressed: product.isInStock
                            ? () async {
                                final added = await context.read<ProductDetailsCubit>().addToCart();
                                if (added && context.mounted) {
                                  context.push(AppRoutes.playerMarketplaceCheckout);
                                }
                              }
                            : null,
                      ),
                    ),
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

  Widget _buildFallbackImage(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.sports_tennis,
        size: 64,
        color: theme.colorScheme.primary.withValues(alpha: 0.6),
      ),
    );
  }
}
