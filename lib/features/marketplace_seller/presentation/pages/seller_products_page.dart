import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_product_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/seller_catalog_cubit.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/widgets/seller_catalog_scaffold.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

/// Feature 6.2 — Seller Product Listing & Catalog Management screen.
class SellerProductsPage extends StatefulWidget {
  final SellerCatalogCubit? cubit;
  final String? sellerId;
  final String? userId;

  const SellerProductsPage({
    super.key,
    this.cubit,
    this.sellerId,
    this.userId,
  });

  @override
  State<SellerProductsPage> createState() => _SellerProductsPageState();
}

class _SellerProductsPageState extends State<SellerProductsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SellerCatalogScaffold(
      cubit: widget.cubit,
      sellerId: widget.sellerId,
      userId: widget.userId,
      title: 'Seller Product Catalog',
      subtitle:
          'Manage pickleball merchandise, variants, inventory & publishing.',
      actionsBuilder: (context, state) => [
        FilledButton.icon(
          onPressed: () =>
              context.go(AppRoutes.marketplaceSellerProductCreate),
          icon: const Icon(Icons.add),
          label: const Text('Add Product'),
        ),
      ],
      bodyBuilder: (context, state) {
        final cubit = context.read<SellerCatalogCubit>();
        final filter = state.filter;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SellerVerificationBanner(profile: state.sellerProfile),
            const SizedBox(height: AppSpacing.md),
            _CatalogFiltersBar(
              searchController: _searchCtrl,
              filter: filter,
              onFilterChanged: cubit.applyFilter,
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.products.isEmpty)
              EmptyStateView(
                title: filter.hasActiveFilters
                    ? 'No Matching Products'
                    : 'No Products Created Yet',
                message: filter.hasActiveFilters
                    ? 'Try clearing your search or status/category filters.'
                    : 'Create your first pickleball product draft to get started.',
                actionLabel:
                    filter.hasActiveFilters ? 'Clear Filters' : 'Create Product',
                onAction: filter.hasActiveFilters
                    ? () {
                        _searchCtrl.clear();
                        cubit.applyFilter(const SellerProductFilter());
                      }
                    : () =>
                        context.go(AppRoutes.marketplaceSellerProductCreate),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.products.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final product = state.products[index];
                  return _SellerProductCard(
                    product: product,
                    isVerifiedSeller: state.isVerifiedSeller,
                    isMutating: state.isMutating,
                    onEdit: () => context.go(
                      AppRoutes.marketplaceSellerProductEditPath(
                        product.productId,
                      ),
                    ),
                    onUpdateInventory: () =>
                        _showInventoryDialog(context, cubit, product),
                    onSubmitForReview: () =>
                        cubit.submitProductForReview(product.productId),
                    onTogglePublish: (next) => cubit.togglePublish(
                      productId: product.productId,
                      isPublished: next,
                    ),
                    onDeleteDraft: () => _confirmDelete(
                      context,
                      cubit,
                      product,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _showInventoryDialog(
    BuildContext context,
    SellerCatalogCubit cubit,
    SellerProduct product,
  ) async {
    final stockCtrl =
        TextEditingController(text: product.stockCount.toString());
    final variantCtrls = <String, TextEditingController>{
      for (final v in product.variants)
        v.id: TextEditingController(text: v.stockCount.toString()),
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update Inventory — ${product.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.variants.isEmpty)
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Available Stock Units',
                    border: OutlineInputBorder(),
                  ),
                )
              else ...[
                const Text(
                  'Update stock per variant (total stock is calculated automatically):',
                ),
                const SizedBox(height: AppSpacing.sm),
                ...product.variants.map(
                  (v) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: TextField(
                      controller: variantCtrls[v.id],
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: '${v.displayLabel} (${v.sku})',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
              ],
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
            child: const Text('Save Stock'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (product.variants.isEmpty) {
        final parsed = int.tryParse(stockCtrl.text.trim()) ?? -1;
        await cubit.updateInventory(
          productId: product.productId,
          stockCount: parsed,
        );
      } else {
        final map = <String, int>{};
        for (final entry in variantCtrls.entries) {
          map[entry.key] = int.tryParse(entry.value.text.trim()) ?? -1;
        }
        await cubit.updateInventory(
          productId: product.productId,
          variantStockCounts: map,
        );
      }
    }

    stockCtrl.dispose();
    for (final c in variantCtrls.values) {
      c.dispose();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SellerCatalogCubit cubit,
    SellerProduct product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Draft Product?'),
        content: Text(
          'Delete "${product.name}"? Only draft products can be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.deleteDraft(product.productId);
    }
  }
}

class _SellerVerificationBanner extends StatelessWidget {
  final SellerProfile profile;

  const _SellerVerificationBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVerified =
        profile.verificationStatus == SellerVerificationStatus.approved;
    final color = isVerified ? AppColors.success : AppColors.warning;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isVerified ? Icons.verified_outlined : Icons.info_outline,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVerified
                      ? 'Verified Seller (${profile.businessName})'
                      : 'Seller Verification: ${profile.verificationStatus.label}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isVerified
                      ? 'Only pickleball-related products are permitted. Admin-approved products remain Unpublished until you publish them.'
                      : 'You can prepare product drafts now, but only Verified/Approved sellers can submit products for review or publish them.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (!isVerified)
            TextButton(
              onPressed: () =>
                  context.go(AppRoutes.marketplaceSellerOnboarding),
              child: const Text('Onboarding'),
            ),
        ],
      ),
    );
  }
}

class _CatalogFiltersBar extends StatelessWidget {
  final TextEditingController searchController;
  final SellerProductFilter filter;
  final ValueChanged<SellerProductFilter> onFilterChanged;

  const _CatalogFiltersBar({
    required this.searchController,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by product name, SKU, brand, subcategory...',
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
              const SizedBox(width: AppSpacing.sm),
              DropdownButton<ProductCategory?>(
                value: filter.category,
                hint: const Text('All Categories'),
                items: [
                  const DropdownMenuItem<ProductCategory?>(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...PickleballCatalogCategories.allowedCategories.map(
                    (c) => DropdownMenuItem<ProductCategory?>(
                      value: c,
                      child: Text(c.displayName),
                    ),
                  ),
                ],
                onChanged: (cat) => onFilterChanged(
                  cat == null
                      ? filter.copyWith(clearCategory: true)
                      : filter.copyWith(category: cat),
                ),
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
                  selected:
                      filter.status == null && filter.publishedOnly == null,
                  onSelected: (_) => onFilterChanged(
                    filter.copyWith(
                      clearStatus: true,
                      clearPublishedOnly: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                ...SellerProductStatus.values.map(
                  (status) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: FilterChip(
                      label: Text(status.label),
                      selected: filter.status == status,
                      onSelected: (_) => onFilterChanged(
                        filter.copyWith(
                          status: status,
                          clearPublishedOnly: true,
                        ),
                      ),
                    ),
                  ),
                ),
                FilterChip(
                  label: const Text('Published Only'),
                  selected: filter.publishedOnly == true,
                  onSelected: (selected) => onFilterChanged(
                    selected
                        ? filter.copyWith(
                            publishedOnly: true,
                            clearStatus: true,
                          )
                        : filter.copyWith(clearPublishedOnly: true),
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

class _SellerProductCard extends StatelessWidget {
  final SellerProduct product;
  final bool isVerifiedSeller;
  final bool isMutating;
  final VoidCallback onEdit;
  final VoidCallback onUpdateInventory;
  final VoidCallback onSubmitForReview;
  final ValueChanged<bool> onTogglePublish;
  final VoidCallback onDeleteDraft;

  const _SellerProductCard({
    required this.product,
    required this.isVerifiedSeller,
    required this.isMutating,
    required this.onEdit,
    required this.onUpdateInventory,
    required this.onSubmitForReview,
    required this.onTogglePublish,
    required this.onDeleteDraft,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = product.primaryImage;
    final statusColor = _statusColor(product.status);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProductThumbnail(image: primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          product.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        _BadgeChip(
                          label: product.status.label,
                          color: statusColor,
                        ),
                        if (product.status == SellerProductStatus.approved)
                          _BadgeChip(
                            label: product.isPublished
                                ? 'Published'
                                : 'Unpublished',
                            color: product.isPublished
                                ? AppColors.success
                                : AppColors.textSecondaryLight,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.category.displayName} • ${product.subcategory} • Brand: ${product.brand} • SKU: ${product.baseSku}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Price: ${product.formattedPrice}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Stock: ${product.totalStock} units'
                          '${product.variants.isNotEmpty ? ' (${product.variants.length} variants)' : ''}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: product.totalStock == 0
                                ? AppColors.error
                                : null,
                          ),
                        ),
                        Text(
                          'Return Window: ${product.returnPolicyDays} days',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (product.reviewFeedback != null &&
                        product.reviewFeedback!.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        product.reviewFeedback!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: Icon(
                      product.status.canEditDetails
                          ? Icons.edit_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    label: Text(
                      product.status.canEditDetails ? 'Edit' : 'View Details',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: isMutating ? null : onUpdateInventory,
                    icon: const Icon(Icons.inventory_2_outlined, size: 18),
                    label: const Text('Stock'),
                  ),
                  if (product.status.canSubmitForReview)
                    FilledButton.icon(
                      onPressed: isMutating || !isVerifiedSeller
                          ? null
                          : onSubmitForReview,
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: Text(
                        isVerifiedSeller
                            ? 'Submit for Review'
                            : 'Verify Seller to Submit',
                      ),
                    ),
                  if (product.status.canDelete)
                    TextButton.icon(
                      onPressed: isMutating ? null : onDeleteDraft,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete Draft'),
                    ),
                ],
              ),
              if (product.status == SellerProductStatus.approved)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.isPublished ? 'Published' : 'Unpublished',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Switch(
                      value: product.isPublished,
                      onChanged: isMutating ? null : onTogglePublish,
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(SellerProductStatus status) {
    switch (status) {
      case SellerProductStatus.draft:
        return AppColors.textSecondaryLight;
      case SellerProductStatus.submittedForReview:
        return AppColors.info;
      case SellerProductStatus.needsInformation:
        return AppColors.warning;
      case SellerProductStatus.approved:
        return AppColors.success;
      case SellerProductStatus.rejected:
        return AppColors.error;
    }
  }
}

class _ProductThumbnail extends StatelessWidget {
  final SellerProductImage? image;

  const _ProductThumbnail({this.image});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: image?.fileBytes != null
          ? Image.memory(image!.fileBytes!, fit: BoxFit.cover)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  image == null
                      ? Icons.image_not_supported_outlined
                      : Icons.sports_tennis,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                if (image != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      image!.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _BadgeChip({required this.label, required this.color});

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
