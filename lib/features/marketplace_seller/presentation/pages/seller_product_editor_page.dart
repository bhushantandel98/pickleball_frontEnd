import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_product_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/seller_catalog_cubit.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/seller_catalog_state.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/widgets/product_image_device_picker.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/widgets/seller_catalog_scaffold.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

/// Feature 6.2 — Create / Edit Seller Product screen.
class SellerProductEditorPage extends StatelessWidget {
  final String? productId;
  final SellerCatalogCubit? cubit;
  final String? sellerId;
  final String? userId;

  const SellerProductEditorPage({
    super.key,
    this.productId,
    this.cubit,
    this.sellerId,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final isCreate = productId == null || productId!.trim().isEmpty;

    return SellerCatalogScaffold(
      cubit: cubit,
      sellerId: sellerId,
      userId: userId,
      title: isCreate ? 'Create Pickleball Product' : 'Edit Product',
      subtitle:
          'Configure pickleball catalog metadata, device images, variants & stock.',
      actionsBuilder: (context, _) => [
        if (!isCreate)
          OutlinedButton.icon(
            onPressed: () => context.go(
              AppRoutes.marketplaceSellerProductReviewPath(productId!),
            ),
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Review & History'),
          ),
        if (!isCreate) const SizedBox(width: AppSpacing.xs),
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.marketplaceSellerProducts),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Catalog'),
        ),
      ],
      bodyBuilder: (context, state) {
        SellerProduct? existing;
        if (!isCreate) {
          for (final p in state.products) {
            if (p.productId == productId) {
              existing = p;
              break;
            }
          }
          if (existing == null) {
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Product not found in your seller catalog.'),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton(
                    onPressed: () =>
                        context.go(AppRoutes.marketplaceSellerProducts),
                    child: const Text('Return to Product Catalog'),
                  ),
                ],
              ),
            );
          }
        }

        return _ProductEditorForm(
          state: state,
          existing: existing,
        );
      },
    );
  }
}

class _ProductEditorForm extends StatefulWidget {
  final SellerCatalogLoaded state;
  final SellerProduct? existing;

  const _ProductEditorForm({
    required this.state,
    this.existing,
  });

  @override
  State<_ProductEditorForm> createState() => _ProductEditorFormState();
}

class _ProductEditorFormState extends State<_ProductEditorForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _mrpCtrl;
  late final TextEditingController _stockCtrl;

  late ProductCategory _category;
  late String _subcategory;
  late int _returnDays;
  late bool _isPickleballOnly;
  late List<SellerProductImage> _images;
  late List<SellerProductVariant> _variants;
  late Map<String, String> _specifications;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _nameCtrl = TextEditingController(text: existing?.name ?? '');
    _descCtrl = TextEditingController(text: existing?.description ?? '');
    _brandCtrl = TextEditingController(
      text: existing?.brand ?? widget.state.sellerProfile.businessName,
    );
    _skuCtrl = TextEditingController(text: existing?.baseSku ?? '');
    _priceCtrl = TextEditingController(
      text: existing != null ? existing.sellingPrice.toStringAsFixed(0) : '',
    );
    _mrpCtrl = TextEditingController(
      text: existing?.originalPrice != null
          ? existing!.originalPrice!.toStringAsFixed(0)
          : '',
    );
    _stockCtrl = TextEditingController(
      text: existing != null ? existing.stockCount.toString() : '10',
    );

    _category = existing?.category ?? ProductCategory.paddles;
    final allowedSubs = PickleballCatalogCategories.subcategoriesFor(_category);
    _subcategory = (existing != null && allowedSubs.contains(existing.subcategory))
        ? existing.subcategory
        : allowedSubs.first;
    _returnDays = existing?.returnPolicyDays ?? 7;
    _isPickleballOnly = existing?.isPickleballOnlyConfirmed ?? true;
    _images = List<SellerProductImage>.from(existing?.images ?? const []);
    _variants = List<SellerProductVariant>.from(existing?.variants ?? const []);
    _specifications =
        Map<String, String>.from(existing?.specifications ?? const {});
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _brandCtrl.dispose();
    _skuCtrl.dispose();
    _priceCtrl.dispose();
    _mrpCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  bool get _isEditable =>
      widget.existing == null || widget.existing!.status.canEditDetails;

  Future<void> _pickProductImage() async {
    final result = await ProductImageDevicePicker.pickImage();
    if (!mounted) return;

    switch (result) {
      case ProductImagePickCancelled():
        return;
      case ProductImagePickError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      case ProductImagePickSuccess(
          :final fileName,
          :final mimeType,
          :final fileSizeBytes,
          :final localFileRef,
          :final fileBytes,
        ):
        setState(() {
          _images = [
            ..._images,
            SellerProductImage(
              id: 'img_${DateTime.now().microsecondsSinceEpoch}',
              fileName: fileName,
              mimeType: mimeType,
              fileSizeBytes: fileSizeBytes,
              localFileRef: localFileRef,
              fileBytes: fileBytes,
              isLocalMockOnly: true,
              isPrimary: _images.isEmpty,
              addedAt: DateTime.now(),
            ),
          ];
        });
    }
  }

  Future<void> _addSpecificationDialog() async {
    final keyCtrl = TextEditingController();
    final valCtrl = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Product Specification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: keyCtrl,
              decoration: const InputDecoration(
                labelText: 'Attribute (e.g. Core Thickness)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: valCtrl,
              decoration: const InputDecoration(
                labelText: 'Value (e.g. 16 mm)',
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
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (added == true &&
        keyCtrl.text.trim().isNotEmpty &&
        valCtrl.text.trim().isNotEmpty) {
      setState(() {
        _specifications = {
          ..._specifications,
          keyCtrl.text.trim(): valCtrl.text.trim(),
        };
      });
    }
    keyCtrl.dispose();
    valCtrl.dispose();
  }

  Future<void> _addOrEditVariantDialog([SellerProductVariant? existing]) async {
    final skuCtrl = TextEditingController(text: existing?.sku ?? '');
    final sizeCtrl = TextEditingController(text: existing?.size ?? '');
    final colorCtrl = TextEditingController(text: existing?.color ?? '');
    final weightCtrl = TextEditingController(text: existing?.weight ?? '');
    final priceCtrl = TextEditingController(
      text: existing != null
          ? existing.sellingPrice.toStringAsFixed(0)
          : _priceCtrl.text,
    );
    final stockCtrl = TextEditingController(
      text: existing != null ? existing.stockCount.toString() : '10',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add Variant' : 'Edit Variant'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: skuCtrl,
                decoration: const InputDecoration(
                  labelText: 'Variant SKU *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: sizeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Size / Grip (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(
                  labelText: 'Color (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: weightCtrl,
                decoration: const InputDecoration(
                  labelText: 'Weight (e.g. 7.9 oz, optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Selling Price (₹) *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock Units *',
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
            child: const Text('Save Variant'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final sku = skuCtrl.text.trim();
      final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
      final stock = int.tryParse(stockCtrl.text.trim()) ?? -1;

      if (sku.isEmpty || price <= 0 || stock < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Enter a valid SKU, positive price, and non-negative stock.',
              ),
            ),
          );
        }
      } else {
        final nextVariant = SellerProductVariant(
          id: existing?.id ?? 'var_${DateTime.now().microsecondsSinceEpoch}',
          sku: sku,
          size: sizeCtrl.text.trim().isEmpty ? null : sizeCtrl.text.trim(),
          color: colorCtrl.text.trim().isEmpty ? null : colorCtrl.text.trim(),
          weight:
              weightCtrl.text.trim().isEmpty ? null : weightCtrl.text.trim(),
          sellingPrice: price,
          stockCount: stock,
        );
        setState(() {
          if (existing == null) {
            _variants = [..._variants, nextVariant];
          } else {
            _variants = _variants
                .map((v) => v.id == existing.id ? nextVariant : v)
                .toList();
          }
        });
      }
    }

    skuCtrl.dispose();
    sizeCtrl.dispose();
    colorCtrl.dispose();
    weightCtrl.dispose();
    priceCtrl.dispose();
    stockCtrl.dispose();
  }

  SellerProduct? _buildProductFromForm() {
    if (!(_formKey.currentState?.validate() ?? false)) return null;

    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0;
    final mrp = double.tryParse(_mrpCtrl.text.trim());
    final rawStock = int.tryParse(_stockCtrl.text.trim()) ?? 0;
    final computedStock = _variants.isNotEmpty
        ? _variants.fold<int>(0, (sum, v) => sum + v.stockCount)
        : rawStock;
    final now = DateTime.now();

    return SellerProduct(
      productId: widget.existing?.productId ?? '',
      sellerId: widget.state.sellerProfile.sellerId,
      sellerName: widget.state.sellerProfile.businessName,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      subcategory: _subcategory,
      brand: _brandCtrl.text.trim(),
      isPickleballOnlyConfirmed: _isPickleballOnly,
      specifications: _specifications,
      images: _images,
      variants: _variants,
      baseSku: _skuCtrl.text.trim(),
      sellingPrice: price,
      originalPrice: (mrp != null && mrp > price) ? mrp : null,
      stockCount: computedStock,
      returnPolicyDays: _returnDays,
      status: widget.existing?.status ?? SellerProductStatus.draft,
      isPublished: false,
      reviewFeedback: widget.existing?.reviewFeedback,
      reviewHistory: widget.existing?.reviewHistory ?? const [],
      createdAt: widget.existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Future<void> _saveDraft() async {
    final product = _buildProductFromForm();
    if (product == null) return;

    final cubit = context.read<SellerCatalogCubit>();
    final saved = await cubit.saveProductDraft(product);
    if (saved != null && mounted) {
      context.go(AppRoutes.marketplaceSellerProducts);
    }
  }

  Future<void> _saveAndReview() async {
    final product = _buildProductFromForm();
    if (product == null) return;

    final cubit = context.read<SellerCatalogCubit>();
    final saved = await cubit.saveProductDraft(product);
    if (saved != null && mounted) {
      context.go(
        AppRoutes.marketplaceSellerProductReviewPath(saved.productId),
      );
    }
  }

  Future<void> _saveAndSubmit() async {
    final product = _buildProductFromForm();
    if (product == null) return;

    final cubit = context.read<SellerCatalogCubit>();
    final saved = await cubit.saveProductDraft(product);
    if (saved == null || !mounted) return;

    final submitted = await cubit.submitProductForReview(saved.productId);
    if (submitted && mounted) {
      context.go(AppRoutes.marketplaceSellerProducts);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMutating = widget.state.isMutating;
    final isVerified = widget.state.isVerifiedSeller;
    final subcategories =
        PickleballCatalogCategories.subcategoriesFor(_category);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.existing != null) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product Status: ${widget.existing!.status.label}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(widget.existing!.status.description),
                  if (widget.existing!.reviewFeedback != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      widget.existing!.reviewFeedback!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. Pickleball Product Details',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isPickleballOnly,
                  onChanged: _isEditable
                      ? (v) => setState(() => _isPickleballOnly = v ?? false)
                      : null,
                  title: const Text(
                    'I confirm this product is 100% pickleball-related merchandise.',
                  ),
                  subtitle: const Text(
                    'Non-pickleball products are rejected per platform policy.',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _nameCtrl,
                  enabled: _isEditable,
                  decoration: const InputDecoration(
                    labelText: 'Product Name *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Enter a product name (at least 3 characters).'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _descCtrl,
                  enabled: _isEditable,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Product Description *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().length < 15)
                      ? 'Enter a description (at least 15 characters).'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<ProductCategory>(
                        initialValue: _category,
                        decoration: const InputDecoration(
                          labelText: 'Pickleball Category *',
                          border: OutlineInputBorder(),
                        ),
                        items: PickleballCatalogCategories.allowedCategories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.displayName),
                              ),
                            )
                            .toList(),
                        onChanged: _isEditable
                            ? (val) {
                                if (val == null) return;
                                final subs = PickleballCatalogCategories
                                    .subcategoriesFor(val);
                                setState(() {
                                  _category = val;
                                  _subcategory = subs.first;
                                });
                              }
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: subcategories.contains(_subcategory)
                            ? _subcategory
                            : subcategories.first,
                        decoration: const InputDecoration(
                          labelText: 'Subcategory *',
                          border: OutlineInputBorder(),
                        ),
                        items: subcategories
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s),
                              ),
                            )
                            .toList(),
                        onChanged: _isEditable
                            ? (val) {
                                if (val != null) {
                                  setState(() => _subcategory = val);
                                }
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _brandCtrl,
                        enabled: _isEditable,
                        decoration: const InputDecoration(
                          labelText: 'Brand *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Brand is required.'
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _returnDays,
                        decoration: const InputDecoration(
                          labelText: 'Return Window *',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 0,
                            child: Text('No Returns (0 days)'),
                          ),
                          DropdownMenuItem(value: 7, child: Text('7 Days')),
                          DropdownMenuItem(value: 14, child: Text('14 Days')),
                          DropdownMenuItem(value: 30, child: Text('30 Days')),
                        ],
                        onChanged: _isEditable
                            ? (val) {
                                if (val != null) {
                                  setState(() => _returnDays = val);
                                }
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '2. Product Images (Device File Selection)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Select JPG, PNG, or WEBP files (max 5 MB). Mock mode stores local references & bytes only — not uploaded to server.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (_isEditable)
                      OutlinedButton.icon(
                        onPressed: _pickProductImage,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Select Image'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_images.isEmpty)
                  const Text('No product images selected yet.')
                else
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _images.map((img) {
                      return Container(
                        width: 170,
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: img.isPrimary
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 10,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: img.fileBytes != null
                                    ? Image.memory(
                                        img.fileBytes!,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        color: theme
                                            .colorScheme.surfaceContainerHighest,
                                        child: const Icon(Icons.image_outlined),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              img.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium,
                            ),
                            Text(
                              '${(img.fileSizeBytes / 1024).toStringAsFixed(0)} KB • ${img.isHosted ? 'Hosted URL' : 'Local preview'}',
                              style: theme.textTheme.labelSmall,
                            ),
                            if (_isEditable)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: img.isPrimary
                                        ? null
                                        : () {
                                            setState(() {
                                              _images = _images
                                                  .map(
                                                    (i) => i.copyWith(
                                                      isPrimary: i.id == img.id,
                                                    ),
                                                  )
                                                  .toList();
                                            });
                                          },
                                    child: Text(
                                      img.isPrimary ? 'Primary' : 'Set Primary',
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        final remaining = _images
                                            .where((i) => i.id != img.id)
                                            .toList();
                                        if (remaining.isNotEmpty &&
                                            !remaining.any((i) => i.isPrimary)) {
                                          remaining[0] = remaining[0]
                                              .copyWith(isPrimary: true);
                                        }
                                        _images = remaining;
                                      });
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '3. Pricing, SKU & Inventory',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skuCtrl,
                        enabled: _isEditable,
                        decoration: const InputDecoration(
                          labelText: 'Base SKU *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'SKU is required.'
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _priceCtrl,
                        enabled: _isEditable,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Selling Price (₹) *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final parsed = double.tryParse(v?.trim() ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a valid price > 0.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _mrpCtrl,
                        enabled: _isEditable,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'MRP / Original Price (₹)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _stockCtrl,
                        enabled: _isEditable && _variants.isEmpty,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: _variants.isEmpty
                              ? 'Available Stock *'
                              : 'Stock (From Variants)',
                          border: const OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (_variants.isNotEmpty) return null;
                          final parsed = int.tryParse(v?.trim() ?? '');
                          if (parsed == null || parsed < 0) {
                            return 'Enter stock >= 0.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Product Variants (${_variants.length})',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_isEditable)
                      OutlinedButton.icon(
                        onPressed: () => _addOrEditVariantDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Variant'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (_variants.isEmpty)
                  Text(
                    'Optional: add size, color, or weight variants with individual SKUs and stock counts.',
                    style: theme.textTheme.bodySmall,
                  )
                else
                  Column(
                    children: _variants.map((v) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${v.displayLabel} • SKU: ${v.sku}'),
                        subtitle: Text(
                          '₹${v.sellingPrice.toStringAsFixed(0)} • Stock: ${v.stockCount}',
                        ),
                        trailing: _isEditable
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () =>
                                        _addOrEditVariantDialog(v),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => setState(() {
                                      _variants = _variants
                                          .where((item) => item.id != v.id)
                                          .toList();
                                    }),
                                  ),
                                ],
                              )
                            : null,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '4. Specifications (${_specifications.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_isEditable)
                      OutlinedButton.icon(
                        onPressed: _addSpecificationDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Spec'),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                if (_specifications.isEmpty)
                  const Text('No specifications added yet.')
                else
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: _specifications.entries.map((entry) {
                      return Chip(
                        label: Text('${entry.key}: ${entry.value}'),
                        onDeleted: _isEditable
                            ? () => setState(() {
                                  _specifications = Map.of(_specifications)
                                    ..remove(entry.key);
                                })
                            : null,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (_isEditable) ...[
                OutlinedButton.icon(
                  onPressed: isMutating ? null : _saveDraft,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Draft'),
                ),
                OutlinedButton.icon(
                  onPressed: isMutating ? null : _saveAndReview,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Save & Review'),
                ),
                FilledButton.icon(
                  onPressed:
                      isMutating || !isVerified ? null : _saveAndSubmit,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(
                    isVerified
                        ? 'Submit for Review'
                        : 'Verify Seller Account to Submit',
                  ),
                ),
              ] else
                Text(
                  'Product details are locked in "${widget.existing!.status.label}". Use the Stock action on the Catalog page to adjust inventory.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.info,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
