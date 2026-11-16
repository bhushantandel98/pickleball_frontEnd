import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/marketplace_seller/data/models/seller_product_models.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_product_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/repositories/marketplace_seller_repository.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/repositories/seller_catalog_repository.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

/// Mock implementation of [SellerCatalogRepository] for Feature 6.2.
///
/// Enforces:
/// - Strict multi-tenant isolation (`sellerId` + `ownerUserId`).
/// - Verified-seller gate (`SellerVerificationStatus.approved`) before product
///   submission or publishing.
/// - Pickleball-only category & confirmation validation.
/// - Separation of Application Admin approval and Seller publish control
///   (approval never auto-publishes).
class MockSellerCatalogRepository implements SellerCatalogRepository {
  final MarketplaceSellerRepository _sellerRepository;
  int _nextProductSeq = 100;

  // ignore: prefer_initializing_formals
  MockSellerCatalogRepository({
    required MarketplaceSellerRepository sellerRepository,
  }) : _sellerRepository = sellerRepository; // ignore: prefer_initializing_formals

  final Map<String, SellerProductModel> _products = {
    'sp_001': SellerProductModel(
      productId: 'sp_001',
      sellerId: 'org_seller_002',
      sellerName: 'Dink & Smash Pro Shop',
      name: 'Vortex T700 Raw Carbon Paddle',
      description:
          'USAPA-approved T700 raw carbon fiber pickleball paddle with 16mm polypropylene honeycomb core and thermoformed edge foam.',
      category: ProductCategory.paddles,
      subcategory: 'Control Paddles',
      brand: 'Dink & Smash',
      isPickleballOnlyConfirmed: true,
      specifications: const {
        'Face Material': 'Toray T700 Carbon Fiber',
        'Core Thickness': '16 mm',
        'Grip Circumference': '4.25 in',
        'USAPA Approved': 'Yes',
      },
      images: [
        SellerProductImageModel(
          id: 'img_sp_001_1',
          fileName: 'vortex_t700_front.jpg',
          mimeType: 'image/jpeg',
          fileSizeBytes: 284120,
          localFileRef: 'local://catalog/org_seller_002/vortex_t700_front.jpg',
          isLocalMockOnly: true,
          isPrimary: true,
          addedAt: DateTime(2026, 11, 6, 10, 0),
        ),
      ],
      variants: const [
        SellerProductVariantModel(
          id: 'var_sp_001_1',
          sku: 'DS-VTX-BLK-79',
          size: 'Standard 16mm',
          color: 'Matte Carbon',
          weight: '7.9 oz',
          sellingPrice: 10999,
          originalPrice: 12499,
          stockCount: 18,
        ),
        SellerProductVariantModel(
          id: 'var_sp_001_2',
          sku: 'DS-VTX-BLU-82',
          size: 'Elongated 16mm',
          color: 'Court Blue',
          weight: '8.2 oz',
          sellingPrice: 11499,
          originalPrice: 12999,
          stockCount: 12,
        ),
      ],
      baseSku: 'DS-VTX-T700',
      sellingPrice: 10999,
      originalPrice: 12499,
      stockCount: 30,
      returnPolicyDays: 14,
      status: SellerProductStatus.approved,
      isPublished: true,
      reviewHistory: [
        SellerProductReviewRecordModel(
          timestamp: DateTime(2026, 11, 6, 11, 0),
          status: SellerProductStatus.submittedForReview,
          actorRole: 'Seller',
          note: 'Submitted for pickleball catalog review.',
        ),
        SellerProductReviewRecordModel(
          timestamp: DateTime(2026, 11, 7, 15, 30),
          status: SellerProductStatus.approved,
          actorRole: 'Application Admin',
          note: 'Approved for marketplace listing. Seller controls publish state.',
        ),
      ],
      createdAt: DateTime(2026, 11, 6, 9, 45),
      updatedAt: DateTime(2026, 11, 7, 16, 0),
      approvedAt: DateTime(2026, 11, 7, 15, 30),
      publishedAt: DateTime(2026, 11, 7, 16, 0),
    ),
    'sp_002': SellerProductModel(
      productId: 'sp_002',
      sellerId: 'org_seller_002',
      sellerName: 'Dink & Smash Pro Shop',
      name: 'Pro-Flight 40 Outdoor Pickleballs (12-Pack)',
      description:
          'Rotationally molded 40-hole outdoor tournament pickleballs engineered for consistent bounce in warm Indian court conditions.',
      category: ProductCategory.balls,
      subcategory: 'Outdoor 40-Hole Tournament Balls',
      brand: 'Dink & Smash',
      isPickleballOnlyConfirmed: true,
      specifications: const {
        'Hole Count': '40 Precision Holes',
        'Diameter': '74 mm',
        'Weight': '26 g',
      },
      images: [
        SellerProductImageModel(
          id: 'img_sp_002_1',
          fileName: 'pro_flight_40_pack.png',
          mimeType: 'image/png',
          fileSizeBytes: 192400,
          localFileRef: 'local://catalog/org_seller_002/pro_flight_40_pack.png',
          isLocalMockOnly: true,
          isPrimary: true,
          addedAt: DateTime(2026, 11, 8, 12, 0),
        ),
      ],
      variants: const [
        SellerProductVariantModel(
          id: 'var_sp_002_1',
          sku: 'DS-PF40-YLW-12',
          color: 'Optic Yellow',
          sellingPrice: 2499,
          originalPrice: 2999,
          stockCount: 45,
        ),
      ],
      baseSku: 'DS-PF40-12',
      sellingPrice: 2499,
      originalPrice: 2999,
      stockCount: 45,
      returnPolicyDays: 7,
      status: SellerProductStatus.approved,
      // Explicitly unpublished to demonstrate approval != auto-publish.
      isPublished: false,
      reviewHistory: [
        SellerProductReviewRecordModel(
          timestamp: DateTime(2026, 11, 8, 14, 0),
          status: SellerProductStatus.approved,
          actorRole: 'Application Admin',
          note: 'Approved by Admin. Awaiting seller publish action.',
        ),
      ],
      createdAt: DateTime(2026, 11, 8, 11, 30),
      updatedAt: DateTime(2026, 11, 8, 14, 0),
      approvedAt: DateTime(2026, 11, 8, 14, 0),
    ),
    'sp_003': SellerProductModel(
      productId: 'sp_003',
      sellerId: 'org_seller_002',
      sellerName: 'Dink & Smash Pro Shop',
      name: 'Portable USAPA Regulation Pickleball Net System',
      description:
          '22ft regulation width powder-coated steel frame portable pickleball net with wheeled carry bag.',
      category: ProductCategory.equipment,
      subcategory: 'Portable Nets & Systems',
      brand: 'CourtMaster',
      isPickleballOnlyConfirmed: true,
      specifications: const {
        'Width': '22 ft (Regulation)',
        'Center Height': '34 in',
        'Frame': 'Powder-Coated Steel',
      },
      images: [
        SellerProductImageModel(
          id: 'img_sp_003_1',
          fileName: 'courtmaster_net.jpg',
          mimeType: 'image/jpeg',
          fileSizeBytes: 342100,
          localFileRef: 'local://catalog/org_seller_002/courtmaster_net.jpg',
          isLocalMockOnly: true,
          isPrimary: true,
          addedAt: DateTime(2026, 11, 10, 9, 0),
        ),
      ],
      variants: const [],
      baseSku: 'CM-NET-22FT',
      sellingPrice: 13999,
      originalPrice: 15999,
      stockCount: 9,
      returnPolicyDays: 10,
      status: SellerProductStatus.submittedForReview,
      isPublished: false,
      reviewHistory: [
        SellerProductReviewRecordModel(
          timestamp: DateTime(2026, 11, 10, 9, 30),
          status: SellerProductStatus.submittedForReview,
          actorRole: 'Seller',
          note: 'Submitted for Application Staff recommendation & Admin approval.',
        ),
      ],
      createdAt: DateTime(2026, 11, 10, 8, 45),
      updatedAt: DateTime(2026, 11, 10, 9, 30),
    ),
    'sp_004': SellerProductModel(
      productId: 'sp_004',
      sellerId: 'org_seller_002',
      sellerName: 'Dink & Smash Pro Shop',
      name: 'Hex-Tacky Paddle Overgrip (Pack of 3)',
      description:
          'Moisture-wicking perforated pickleball paddle overgrip tape for humid outdoor play.',
      category: ProductCategory.accessories,
      subcategory: 'Overgrips & Replacement Grips',
      brand: 'Dink & Smash',
      isPickleballOnlyConfirmed: true,
      specifications: const {
        'Thickness': '0.6 mm',
        'Pack Count': '3 Grips',
      },
      images: [
        SellerProductImageModel(
          id: 'img_sp_004_1',
          fileName: 'overgrip_pack.jpg',
          mimeType: 'image/jpeg',
          fileSizeBytes: 154000,
          localFileRef: 'local://catalog/org_seller_002/overgrip_pack.jpg',
          isLocalMockOnly: true,
          isPrimary: true,
          addedAt: DateTime(2026, 11, 11, 10, 0),
        ),
      ],
      variants: const [
        SellerProductVariantModel(
          id: 'var_sp_004_1',
          sku: 'DS-GRIP-WHT-3',
          color: 'Arctic White',
          sellingPrice: 599,
          stockCount: 60,
        ),
      ],
      baseSku: 'DS-GRIP-3PK',
      sellingPrice: 599,
      stockCount: 60,
      returnPolicyDays: 7,
      status: SellerProductStatus.needsInformation,
      isPublished: false,
      reviewFeedback:
          'Application Staff Note: Please clarify grip length (in cm) in specifications before Admin review.',
      reviewHistory: [
        SellerProductReviewRecordModel(
          timestamp: DateTime(2026, 11, 11, 14, 15),
          status: SellerProductStatus.needsInformation,
          actorRole: 'Application Staff',
          note: 'Clarify grip length in specifications.',
        ),
      ],
      createdAt: DateTime(2026, 11, 11, 9, 45),
      updatedAt: DateTime(2026, 11, 11, 14, 15),
    ),
    // Draft product for unverified seller org_seller_001 to verify isolation & gating.
    'sp_005': SellerProductModel(
      productId: 'sp_005',
      sellerId: 'org_seller_001',
      sellerName: 'Apex Pickleball Gear Co.',
      name: 'Apex Tour 3-Paddle Sling Bag',
      description:
          'Thermal-lined pickleball sling bag with ventilated shoe compartment and fence hook.',
      category: ProductCategory.bags,
      subcategory: 'Paddle Sling Bags',
      brand: 'Apex',
      isPickleballOnlyConfirmed: true,
      specifications: const {
        'Capacity': '3 Paddles + 6 Balls',
        'Material': '600D Water-Resistant Ripstop',
      },
      images: const [],
      variants: const [],
      baseSku: 'APX-SLING-01',
      sellingPrice: 3499,
      originalPrice: 3999,
      stockCount: 15,
      returnPolicyDays: 14,
      status: SellerProductStatus.draft,
      isPublished: false,
      createdAt: DateTime(2026, 11, 12, 10, 0),
      updatedAt: DateTime(2026, 11, 12, 10, 0),
    ),
  };

  Future<Result<SellerProfile>> _requireOwnedSeller({
    required String sellerId,
    required String userId,
  }) async {
    final profileResult = await _sellerRepository.getSellerProfileForUser(
      userId: userId,
      sellerId: sellerId,
    );
    return profileResult.when(
      success: (profile) {
        if (profile == null) {
          return const FailureResult(
            ForbiddenFailure(
              message:
                  'Seller profile not found or does not belong to the authenticated user.',
            ),
          );
        }
        if (profile.sellerId != sellerId || profile.ownerUserId != userId) {
          return const FailureResult(
            ForbiddenFailure(
              message:
                  'Forbidden: Seller ownership verification failed for this catalog.',
            ),
          );
        }
        return Success(profile);
      },
      failure: (failure) => FailureResult(failure),
    );
  }

  SellerProductModel? _getOwnedProduct(String sellerId, String productId) {
    final product = _products[productId];
    if (product == null || product.sellerId != sellerId) return null;
    return product;
  }

  @override
  Future<Result<List<SellerProduct>>> getSellerProducts({
    required String sellerId,
    required String userId,
    SellerProductFilter? filter,
  }) async {
    final sellerCheck = await _requireOwnedSeller(
      sellerId: sellerId,
      userId: userId,
    );
    if (sellerCheck is FailureResult<SellerProfile>) {
      return FailureResult(sellerCheck.failure);
    }

    var list = _products.values
        .where((p) => p.sellerId == sellerId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (filter != null) {
      final q = filter.query.trim().toLowerCase();
      if (q.isNotEmpty) {
        list = list.where((p) {
          return p.name.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q) ||
              p.baseSku.toLowerCase().contains(q) ||
              p.subcategory.toLowerCase().contains(q);
        }).toList();
      }
      if (filter.category != null && filter.category != ProductCategory.all) {
        list = list.where((p) => p.category == filter.category).toList();
      }
      if (filter.status != null) {
        list = list.where((p) => p.status == filter.status).toList();
      }
      if (filter.publishedOnly == true) {
        list = list.where((p) => p.isPublished).toList();
      } else if (filter.publishedOnly == false) {
        list = list.where((p) => !p.isPublished).toList();
      }
    }

    return Success(List<SellerProduct>.unmodifiable(list));
  }

  @override
  Future<Result<SellerProduct>> getSellerProductById({
    required String sellerId,
    required String userId,
    required String productId,
  }) async {
    final sellerCheck = await _requireOwnedSeller(
      sellerId: sellerId,
      userId: userId,
    );
    if (sellerCheck is FailureResult<SellerProfile>) {
      return FailureResult(sellerCheck.failure);
    }

    final product = _getOwnedProduct(sellerId, productId);
    if (product == null) {
      return const FailureResult(
        NotFoundFailure(
          message: 'Product not found in this seller catalog.',
        ),
      );
    }
    return Success(product);
  }

  @override
  Future<Result<SellerProduct>> saveProductDraft({
    required String sellerId,
    required String userId,
    required SellerProduct product,
  }) async {
    final sellerCheck = await _requireOwnedSeller(
      sellerId: sellerId,
      userId: userId,
    );
    if (sellerCheck is FailureResult<SellerProfile>) {
      return FailureResult(sellerCheck.failure);
    }
    final seller = (sellerCheck as Success<SellerProfile>).data;

    if (!PickleballCatalogCategories.allowedCategories.contains(product.category)) {
      return const FailureResult(
        ValidationFailure(
          message:
              'Only approved pickleball categories are allowed in the marketplace.',
        ),
      );
    }
    if (product.name.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Product name is required.'),
      );
    }
    if (product.sellingPrice <= 0) {
      return const FailureResult(
        ValidationFailure(
          message: 'Selling price must be greater than zero.',
        ),
      );
    }
    if (product.stockCount < 0) {
      return const FailureResult(
        ValidationFailure(message: 'Stock count cannot be negative.'),
      );
    }
    if (product.returnPolicyDays < 0 || product.returnPolicyDays > 60) {
      return const FailureResult(
        ValidationFailure(
          message: 'Return window must be between 0 and 60 days.',
        ),
      );
    }

    final existing = product.productId.isEmpty
        ? null
        : _products[product.productId];
    if (existing != null && existing.sellerId != sellerId) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Forbidden: You cannot edit another seller\'s product.',
        ),
      );
    }
    if (existing != null && !existing.status.canEditDetails) {
      return FailureResult(
        ValidationFailure(
          message:
              'Product details cannot be edited while status is "${existing.status.label}". Use inventory update for stock changes.',
        ),
      );
    }

    final now = DateTime.now();
    final assignedId = existing?.productId ?? 'sp_${++_nextProductSeq}';
    final nextStatus = existing == null
        ? SellerProductStatus.draft
        : (existing.status == SellerProductStatus.needsInformation ||
                existing.status == SellerProductStatus.rejected)
            ? existing.status
            : SellerProductStatus.draft;

    final saved = SellerProductModel.fromEntity(
      product.copyWith(
        productId: assignedId,
        sellerId: seller.sellerId,
        sellerName: seller.businessName,
        status: nextStatus,
        // Never allow publishing during draft save.
        isPublished: false,
        clearPublishedAt: true,
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      ),
    );

    _products[assignedId] = saved;
    return Success(saved);
  }

  @override
  Future<Result<SellerProduct>> updateProductInventory({
    required String sellerId,
    required String userId,
    required String productId,
    int? stockCount,
    Map<String, int>? variantStockCounts,
  }) async {
    final sellerCheck = await _requireOwnedSeller(
      sellerId: sellerId,
      userId: userId,
    );
    if (sellerCheck is FailureResult<SellerProfile>) {
      return FailureResult(sellerCheck.failure);
    }

    final existing = _getOwnedProduct(sellerId, productId);
    if (existing == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Product not found for this seller.'),
      );
    }

    if (stockCount != null && stockCount < 0) {
      return const FailureResult(
        ValidationFailure(message: 'Stock count cannot be negative.'),
      );
    }

    var updatedVariants = existing.variants;
    if (variantStockCounts != null && variantStockCounts.isNotEmpty) {
      for (final entry in variantStockCounts.entries) {
        if (entry.value < 0) {
          return const FailureResult(
            ValidationFailure(
              message: 'Variant stock count cannot be negative.',
            ),
          );
        }
      }
      updatedVariants = existing.variants.map((variant) {
        final next = variantStockCounts[variant.id];
        return next == null ? variant : variant.copyWith(stockCount: next);
      }).toList();
    }

    final computedTotal = updatedVariants.isNotEmpty
        ? updatedVariants
            .where((v) => v.isActive)
            .fold<int>(0, (sum, v) => sum + v.stockCount)
        : (stockCount ?? existing.stockCount);

    final updated = SellerProductModel.fromEntity(
      existing.copyWith(
        variants: updatedVariants,
        stockCount: computedTotal,
        updatedAt: DateTime.now(),
      ),
    );
    _products[productId] = updated;
    return Success(updated);
  }

  @override
  Future<Result<SellerProduct>> submitProductForReview({
    required String sellerId,
    required String userId,
    required String productId,
  }) async {
    final sellerCheck = await _requireOwnedSeller(
      sellerId: sellerId,
      userId: userId,
    );
    if (sellerCheck is FailureResult<SellerProfile>) {
      return FailureResult(sellerCheck.failure);
    }
    final seller = (sellerCheck as Success<SellerProfile>).data;

    if (seller.verificationStatus != SellerVerificationStatus.approved) {
      return FailureResult(
        ValidationFailure(
          message:
              'Only Verified/Approved sellers can submit products for review. Current status: ${seller.verificationStatus.label}.',
        ),
      );
    }

    final existing = _getOwnedProduct(sellerId, productId);
    if (existing == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Product not found for this seller.'),
      );
    }
    if (!existing.status.canSubmitForReview) {
      return FailureResult(
        ValidationFailure(
          message:
              'Product cannot be submitted from status "${existing.status.label}".',
        ),
      );
    }

    final validationError = _validateForSubmission(existing);
    if (validationError != null) {
      return FailureResult(ValidationFailure(message: validationError));
    }

    final now = DateTime.now();
    final updated = SellerProductModel.fromEntity(
      existing.copyWith(
        status: SellerProductStatus.submittedForReview,
        isPublished: false,
        clearPublishedAt: true,
        clearReviewFeedback: true,
        updatedAt: now,
        reviewHistory: [
          ...existing.reviewHistory,
          SellerProductReviewRecord(
            timestamp: now,
            status: SellerProductStatus.submittedForReview,
            actorRole: 'Seller',
            note:
                'Submitted for Application Staff review & Application Admin approval.',
          ),
        ],
      ),
    );
    _products[productId] = updated;
    return Success(updated);
  }

  String? _validateForSubmission(SellerProduct product) {
    if (!product.isPickleballOnlyConfirmed) {
      return 'Confirm that this product is 100% pickleball-related before submitting.';
    }
    if (!PickleballCatalogCategories.allowedCategories.contains(product.category)) {
      return 'Select a valid pickleball product category.';
    }
    if (product.name.trim().length < 3) {
      return 'Product name must be at least 3 characters.';
    }
    if (product.description.trim().length < 15) {
      return 'Product description must be at least 15 characters.';
    }
    if (product.brand.trim().isEmpty) {
      return 'Brand name is required.';
    }
    if (product.subcategory.trim().isEmpty) {
      return 'Pickleball subcategory is required.';
    }
    if (product.baseSku.trim().isEmpty) {
      return 'Base SKU is required.';
    }
    if (product.images.isEmpty) {
      return 'Attach at least one product image from your device before submitting.';
    }
    if (product.sellingPrice <= 0) {
      return 'Selling price must be greater than zero.';
    }
    if (product.variants.isNotEmpty) {
      final seenSkus = <String>{};
      for (final variant in product.variants) {
        final sku = variant.sku.trim().toUpperCase();
        if (sku.isEmpty) {
          return 'Every product variant must have a SKU.';
        }
        if (!seenSkus.add(sku)) {
          return 'Duplicate variant SKU found: ${variant.sku}.';
        }
        if (variant.sellingPrice <= 0) {
          return 'Variant ${variant.sku} must have a price greater than zero.';
        }
        if (variant.stockCount < 0) {
          return 'Variant ${variant.sku} stock cannot be negative.';
        }
      }
    }
    return null;
  }

  @override
  Future<Result<SellerProduct>> setProductPublished({
    required String sellerId,
    required String userId,
    required String productId,
    required bool isPublished,
  }) async {
    final sellerCheck = await _requireOwnedSeller(
      sellerId: sellerId,
      userId: userId,
    );
    if (sellerCheck is FailureResult<SellerProfile>) {
      return FailureResult(sellerCheck.failure);
    }
    final seller = (sellerCheck as Success<SellerProfile>).data;

    if (seller.verificationStatus != SellerVerificationStatus.approved) {
      return const FailureResult(
        ValidationFailure(
          message: 'Only verified sellers can publish products.',
        ),
      );
    }

    final existing = _getOwnedProduct(sellerId, productId);
    if (existing == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Product not found for this seller.'),
      );
    }
    if (!existing.status.canTogglePublish) {
      return FailureResult(
        ValidationFailure(
          message:
              'Only Admin-approved products can be published or unpublished. Current status: ${existing.status.label}.',
        ),
      );
    }

    final now = DateTime.now();
    final updated = SellerProductModel.fromEntity(
      existing.copyWith(
        isPublished: isPublished,
        publishedAt: isPublished ? now : null,
        clearPublishedAt: !isPublished,
        updatedAt: now,
      ),
    );
    _products[productId] = updated;
    return Success(updated);
  }

  @override
  Future<Result<void>> deleteDraftProduct({
    required String sellerId,
    required String userId,
    required String productId,
  }) async {
    final sellerCheck = await _requireOwnedSeller(
      sellerId: sellerId,
      userId: userId,
    );
    if (sellerCheck is FailureResult<SellerProfile>) {
      return FailureResult(sellerCheck.failure);
    }

    final existing = _getOwnedProduct(sellerId, productId);
    if (existing == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Product not found for this seller.'),
      );
    }
    if (!existing.status.canDelete) {
      return FailureResult(
        ValidationFailure(
          message:
              'Only Draft products can be deleted. Current status: ${existing.status.label}.',
        ),
      );
    }

    _products.remove(productId);
    return const Success(null);
  }
}
