import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

/// Product approval lifecycle for Marketplace Seller catalog items.
///
/// Platform rules:
/// - Application Staff may review and recommend; only Application Admin gives
///   final `approved` or `rejected` decision.
/// - Approval does NOT automatically publish a product; the seller explicitly
///   controls [SellerProduct.isPublished] once `status == approved`.
enum SellerProductStatus {
  draft(
    'Draft',
    'Saved locally as a draft. Complete all required fields and submit for review.',
  ),
  submittedForReview(
    'Submitted for Review',
    'Under Application Staff / Admin review. Product details are locked; inventory can still be adjusted.',
  ),
  needsInformation(
    'Needs Information',
    'Additional details or images were requested. Update the product and resubmit.',
  ),
  approved(
    'Approved',
    'Approved by Application Admin. Toggle Publish when ready to list in the Player Marketplace.',
  ),
  rejected(
    'Rejected',
    'Rejected during review. Address the feedback and resubmit.',
  );

  final String label;
  final String description;

  const SellerProductStatus(this.label, this.description);

  bool get canEditDetails =>
      this == SellerProductStatus.draft ||
      this == SellerProductStatus.needsInformation ||
      this == SellerProductStatus.rejected;

  bool get canSubmitForReview =>
      this == SellerProductStatus.draft ||
      this == SellerProductStatus.needsInformation ||
      this == SellerProductStatus.rejected;

  bool get canTogglePublish => this == SellerProductStatus.approved;

  bool get canDelete => this == SellerProductStatus.draft;
}

/// Pickleball-specific subcategories mapped to [ProductCategory].
class PickleballCatalogCategories {
  PickleballCatalogCategories._();

  static const List<ProductCategory> allowedCategories = [
    ProductCategory.paddles,
    ProductCategory.balls,
    ProductCategory.equipment,
    ProductCategory.footwear,
    ProductCategory.bags,
    ProductCategory.apparel,
    ProductCategory.accessories,
  ];

  static const Map<ProductCategory, List<String>> subcategoriesByCategory = {
    ProductCategory.paddles: [
      'Control Paddles',
      'Power Paddles',
      'All-Court Paddles',
      'Elongated Paddles',
      'Beginner & Junior Paddles',
    ],
    ProductCategory.balls: [
      'Outdoor 40-Hole Tournament Balls',
      'Indoor 26-Hole Balls',
      'Practice & Hopper Balls',
    ],
    ProductCategory.equipment: [
      'Portable Nets & Systems',
      'Court Markers & Tape',
      'Ball Hoppers & Pickups',
      'Ball Machines & Rebounders',
    ],
    ProductCategory.footwear: [
      'Outdoor Court Shoes',
      'Indoor Non-Marking Court Shoes',
      'Performance Insoles & Socks',
    ],
    ProductCategory.shoes: [
      'Outdoor Court Shoes',
      'Indoor Non-Marking Court Shoes',
    ],
    ProductCategory.bags: [
      'Tournament Backpacks',
      'Paddle Sling Bags',
      'Duffel & Pro Tour Bags',
    ],
    ProductCategory.apparel: [
      'Performance Polos & Tees',
      'Court Shorts & Skorts',
      'Caps, Visors & Sweatbands',
    ],
    ProductCategory.accessories: [
      'Overgrips & Replacement Grips',
      'Edge Guard Tape & Lead Tape',
      'Paddle Covers & Erasers',
      'Water Bottles & Towels',
    ],
  };

  static List<String> subcategoriesFor(ProductCategory category) {
    return subcategoriesByCategory[category] ?? const ['General Pickleball Gear'];
  }
}

/// Product image selected from the seller's device or hosted on the backend.
///
/// Distinguishes between:
/// - Local preview images ([isLocalMockOnly] == `true`, [localFileRef] +
///   [fileBytes] for preview and future multipart upload).
/// - Backend-hosted image URLs ([hostedUrl] with `http`/`https` scheme and
///   [isLocalMockOnly] == `false`).
///
/// Local device references are never treated as remote image URLs.
class SellerProductImage extends Equatable {
  final String id;
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final String localFileRef;
  final String? hostedUrl;
  final Uint8List? fileBytes;
  final bool isLocalMockOnly;
  final bool isPrimary;
  final DateTime addedAt;

  const SellerProductImage({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
    this.localFileRef = '',
    this.hostedUrl,
    this.fileBytes,
    this.isLocalMockOnly = true,
    this.isPrimary = false,
    required this.addedAt,
  });

  /// Returns [hostedUrl] only when this image is backend-hosted (not local mock)
  /// and uses a valid `http` or `https` URL.
  String? get validHostedUrl {
    if (isLocalMockOnly) return null;
    final raw = hostedUrl?.trim();
    if (raw == null || raw.isEmpty) return null;
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return raw;
  }

  bool get isHosted => validHostedUrl != null;

  SellerProductImage copyWith({
    String? id,
    String? fileName,
    String? mimeType,
    int? fileSizeBytes,
    String? localFileRef,
    String? hostedUrl,
    Uint8List? fileBytes,
    bool? isLocalMockOnly,
    bool? isPrimary,
    DateTime? addedAt,
  }) {
    return SellerProductImage(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      localFileRef: localFileRef ?? this.localFileRef,
      hostedUrl: hostedUrl ?? this.hostedUrl,
      fileBytes: fileBytes ?? this.fileBytes,
      isLocalMockOnly: isLocalMockOnly ?? this.isLocalMockOnly,
      isPrimary: isPrimary ?? this.isPrimary,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fileName,
        mimeType,
        fileSizeBytes,
        localFileRef,
        hostedUrl,
        fileBytes,
        isLocalMockOnly,
        isPrimary,
        addedAt,
      ];
}

/// Variant (size / color / weight) with independent SKU, price, and inventory.
class SellerProductVariant extends Equatable {
  final String id;
  final String sku;
  final String? size;
  final String? color;
  final String? weight;
  final double sellingPrice;
  final double? originalPrice;
  final int stockCount;
  final bool isActive;

  const SellerProductVariant({
    required this.id,
    required this.sku,
    this.size,
    this.color,
    this.weight,
    required this.sellingPrice,
    this.originalPrice,
    required this.stockCount,
    this.isActive = true,
  });

  String get displayLabel {
    final parts = [
      if (size != null && size!.trim().isNotEmpty) size!.trim(),
      if (color != null && color!.trim().isNotEmpty) color!.trim(),
      if (weight != null && weight!.trim().isNotEmpty) weight!.trim(),
    ];
    return parts.isEmpty ? sku : parts.join(' • ');
  }

  SellerProductVariant copyWith({
    String? id,
    String? sku,
    String? size,
    String? color,
    String? weight,
    double? sellingPrice,
    double? originalPrice,
    int? stockCount,
    bool? isActive,
  }) {
    return SellerProductVariant(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      size: size ?? this.size,
      color: color ?? this.color,
      weight: weight ?? this.weight,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      stockCount: stockCount ?? this.stockCount,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sku,
        size,
        color,
        weight,
        sellingPrice,
        originalPrice,
        stockCount,
        isActive,
      ];
}

/// Audit trail entry for product submission, review, approval, and publish events.
class SellerProductReviewRecord extends Equatable {
  final DateTime timestamp;
  final SellerProductStatus status;
  final String actorRole;
  final String note;

  const SellerProductReviewRecord({
    required this.timestamp,
    required this.status,
    required this.actorRole,
    required this.note,
  });

  @override
  List<Object?> get props => [timestamp, status, actorRole, note];
}

/// Marketplace Seller product entity supporting lifecycle, variants, inventory,
/// and buyer-catalog compatibility via [toMarketplaceProduct].
class SellerProduct extends Equatable {
  final String productId;
  final String sellerId;
  final String sellerName;
  final String name;
  final String description;
  final ProductCategory category;
  final String subcategory;
  final String brand;
  final bool isPickleballOnlyConfirmed;
  final Map<String, String> specifications;
  final List<SellerProductImage> images;
  final List<SellerProductVariant> variants;
  final String baseSku;
  final double sellingPrice;
  final double? originalPrice;
  final int stockCount;
  final int returnPolicyDays;
  final SellerProductStatus status;
  final bool isPublished;
  final String? reviewFeedback;
  final List<SellerProductReviewRecord> reviewHistory;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? approvedAt;
  final DateTime? publishedAt;

  const SellerProduct({
    required this.productId,
    required this.sellerId,
    required this.sellerName,
    required this.name,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.brand,
    this.isPickleballOnlyConfirmed = true,
    this.specifications = const {},
    this.images = const [],
    this.variants = const [],
    required this.baseSku,
    required this.sellingPrice,
    this.originalPrice,
    required this.stockCount,
    this.returnPolicyDays = 7,
    this.status = SellerProductStatus.draft,
    this.isPublished = false,
    this.reviewFeedback,
    this.reviewHistory = const [],
    required this.createdAt,
    required this.updatedAt,
    this.approvedAt,
    this.publishedAt,
  });

  int get totalStock {
    final activeVariants = variants.where((v) => v.isActive).toList();
    if (activeVariants.isEmpty) return stockCount;
    return activeVariants.fold<int>(0, (sum, v) => sum + v.stockCount);
  }

  double get effectiveStartingPrice {
    final activeVariants = variants.where((v) => v.isActive).toList();
    if (activeVariants.isEmpty) return sellingPrice;
    return activeVariants
        .map((v) => v.sellingPrice)
        .reduce((a, b) => a < b ? a : b);
  }

  String get formattedPrice => NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 0,
        locale: 'en_IN',
      ).format(effectiveStartingPrice);

  SellerProductImage? get primaryImage {
    if (images.isEmpty) return null;
    for (final img in images) {
      if (img.isPrimary) return img;
    }
    return images.first;
  }

  bool get isLiveInBuyerCatalog =>
      status == SellerProductStatus.approved && isPublished;

  /// Converts an approved, published product into a [MarketplaceProduct]
  /// compatible with the existing Player Marketplace catalog, cart & checkout.
  ///
  /// Only valid backend-hosted `http`/`https` URLs are exposed in [imageUrl]
  /// and [galleryImages]; local mock/device file references are never treated
  /// as remote URLs, allowing the buyer catalog to render its existing
  /// fallback when no hosted URL exists.
  MarketplaceProduct toMarketplaceProduct() {
    final primary = primaryImage;
    final hostedGallery =
        images.map((i) => i.validHostedUrl).whereType<String>().toList();
    final primaryHostedUrl = primary?.validHostedUrl ??
        (hostedGallery.isNotEmpty ? hostedGallery.first : '');
    final sizes = variants
        .where((v) => v.isActive && v.size != null && v.size!.trim().isNotEmpty)
        .map((v) => v.size!.trim())
        .toSet()
        .toList();
    final colors = variants
        .where(
          (v) => v.isActive && v.color != null && v.color!.trim().isNotEmpty,
        )
        .map((v) => v.color!.trim())
        .toSet()
        .toList();
    final mergedSpecs = <String, String>{
      'Subcategory': subcategory,
      ...specifications,
    };

    return MarketplaceProduct(
      id: productId,
      title: name,
      brand: brand,
      sellerName: sellerName,
      description: description,
      price: effectiveStartingPrice,
      originalPrice: originalPrice,
      rating: 0.0,
      reviewCount: 0,
      category: category,
      imageUrl: primaryHostedUrl,
      galleryImages: hostedGallery,
      inStock: totalStock > 0,
      stockCount: totalStock,
      returnPolicyDays: returnPolicyDays,
      specifications: mergedSpecs,
      availableSizes: sizes,
      availableColors: colors,
    );
  }

  SellerProduct copyWith({
    String? productId,
    String? sellerId,
    String? sellerName,
    String? name,
    String? description,
    ProductCategory? category,
    String? subcategory,
    String? brand,
    bool? isPickleballOnlyConfirmed,
    Map<String, String>? specifications,
    List<SellerProductImage>? images,
    List<SellerProductVariant>? variants,
    String? baseSku,
    double? sellingPrice,
    double? originalPrice,
    int? stockCount,
    int? returnPolicyDays,
    SellerProductStatus? status,
    bool? isPublished,
    String? reviewFeedback,
    bool clearReviewFeedback = false,
    List<SellerProductReviewRecord>? reviewHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
  }) {
    return SellerProduct(
      productId: productId ?? this.productId,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      brand: brand ?? this.brand,
      isPickleballOnlyConfirmed:
          isPickleballOnlyConfirmed ?? this.isPickleballOnlyConfirmed,
      specifications: specifications ?? this.specifications,
      images: images ?? this.images,
      variants: variants ?? this.variants,
      baseSku: baseSku ?? this.baseSku,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      stockCount: stockCount ?? this.stockCount,
      returnPolicyDays: returnPolicyDays ?? this.returnPolicyDays,
      status: status ?? this.status,
      isPublished: isPublished ?? this.isPublished,
      reviewFeedback:
          clearReviewFeedback ? null : (reviewFeedback ?? this.reviewFeedback),
      reviewHistory: reviewHistory ?? this.reviewHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      publishedAt:
          clearPublishedAt ? null : (publishedAt ?? this.publishedAt),
    );
  }

  @override
  List<Object?> get props => [
        productId,
        sellerId,
        sellerName,
        name,
        description,
        category,
        subcategory,
        brand,
        isPickleballOnlyConfirmed,
        specifications,
        images,
        variants,
        baseSku,
        sellingPrice,
        originalPrice,
        stockCount,
        returnPolicyDays,
        status,
        isPublished,
        reviewFeedback,
        reviewHistory,
        createdAt,
        updatedAt,
        approvedAt,
        publishedAt,
      ];
}

/// Filter parameters for the Seller Product Listing screen.
class SellerProductFilter extends Equatable {
  final String query;
  final ProductCategory? category;
  final SellerProductStatus? status;
  final bool? publishedOnly;

  const SellerProductFilter({
    this.query = '',
    this.category,
    this.status,
    this.publishedOnly,
  });

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      category != null ||
      status != null ||
      publishedOnly != null;

  SellerProductFilter copyWith({
    String? query,
    ProductCategory? category,
    bool clearCategory = false,
    SellerProductStatus? status,
    bool clearStatus = false,
    bool? publishedOnly,
    bool clearPublishedOnly = false,
  }) {
    return SellerProductFilter(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      status: clearStatus ? null : (status ?? this.status),
      publishedOnly:
          clearPublishedOnly ? null : (publishedOnly ?? this.publishedOnly),
    );
  }

  @override
  List<Object?> get props => [query, category, status, publishedOnly];
}
