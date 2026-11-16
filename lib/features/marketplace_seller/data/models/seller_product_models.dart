import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_product_entities.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

class SellerProductImageModel extends SellerProductImage {
  const SellerProductImageModel({
    required super.id,
    required super.fileName,
    required super.mimeType,
    required super.fileSizeBytes,
    super.localFileRef,
    super.hostedUrl,
    super.fileBytes,
    super.isLocalMockOnly,
    super.isPrimary,
    required super.addedAt,
  });

  factory SellerProductImageModel.fromEntity(SellerProductImage entity) {
    return SellerProductImageModel(
      id: entity.id,
      fileName: entity.fileName,
      mimeType: entity.mimeType,
      fileSizeBytes: entity.fileSizeBytes,
      localFileRef: entity.localFileRef,
      hostedUrl: entity.hostedUrl,
      fileBytes: entity.fileBytes,
      isLocalMockOnly: entity.isLocalMockOnly,
      isPrimary: entity.isPrimary,
      addedAt: entity.addedAt,
    );
  }

  factory SellerProductImageModel.fromJson(Map<String, dynamic> json) {
    final hosted = json['hostedUrl'] as String?;
    final hasHosted = hosted != null && hosted.trim().isNotEmpty;
    return SellerProductImageModel(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'image/jpeg',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      localFileRef: json['localFileRef'] as String? ?? '',
      hostedUrl: hosted,
      isLocalMockOnly: json['isLocalMockOnly'] as bool? ?? !hasHosted,
      isPrimary: json['isPrimary'] as bool? ?? false,
      addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'mimeType': mimeType,
        'fileSizeBytes': fileSizeBytes,
        'localFileRef': localFileRef,
        'hostedUrl': hostedUrl,
        'isLocalMockOnly': isLocalMockOnly,
        'isPrimary': isPrimary,
        'addedAt': addedAt.toIso8601String(),
      };
}

class SellerProductVariantModel extends SellerProductVariant {
  const SellerProductVariantModel({
    required super.id,
    required super.sku,
    super.size,
    super.color,
    super.weight,
    required super.sellingPrice,
    super.originalPrice,
    required super.stockCount,
    super.isActive,
  });

  factory SellerProductVariantModel.fromEntity(SellerProductVariant entity) {
    return SellerProductVariantModel(
      id: entity.id,
      sku: entity.sku,
      size: entity.size,
      color: entity.color,
      weight: entity.weight,
      sellingPrice: entity.sellingPrice,
      originalPrice: entity.originalPrice,
      stockCount: entity.stockCount,
      isActive: entity.isActive,
    );
  }

  factory SellerProductVariantModel.fromJson(Map<String, dynamic> json) {
    return SellerProductVariantModel(
      id: json['id'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      size: json['size'] as String?,
      color: json['color'] as String?,
      weight: json['weight'] as String?,
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      stockCount: (json['stockCount'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sku': sku,
        'size': size,
        'color': color,
        'weight': weight,
        'sellingPrice': sellingPrice,
        'originalPrice': originalPrice,
        'stockCount': stockCount,
        'isActive': isActive,
      };
}

class SellerProductReviewRecordModel extends SellerProductReviewRecord {
  const SellerProductReviewRecordModel({
    required super.timestamp,
    required super.status,
    required super.actorRole,
    required super.note,
  });

  factory SellerProductReviewRecordModel.fromEntity(
    SellerProductReviewRecord entity,
  ) {
    return SellerProductReviewRecordModel(
      timestamp: entity.timestamp,
      status: entity.status,
      actorRole: entity.actorRole,
      note: entity.note,
    );
  }

  factory SellerProductReviewRecordModel.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? 'draft';
    final status = SellerProductStatus.values.firstWhere(
      (s) => s.name == rawStatus,
      orElse: () => SellerProductStatus.draft,
    );
    return SellerProductReviewRecordModel(
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      status: status,
      actorRole: json['actorRole'] as String? ?? 'Seller',
      note: json['note'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'status': status.name,
        'actorRole': actorRole,
        'note': note,
      };
}

class SellerProductModel extends SellerProduct {
  const SellerProductModel({
    required super.productId,
    required super.sellerId,
    required super.sellerName,
    required super.name,
    required super.description,
    required super.category,
    required super.subcategory,
    required super.brand,
    super.isPickleballOnlyConfirmed,
    super.specifications,
    super.images,
    super.variants,
    required super.baseSku,
    required super.sellingPrice,
    super.originalPrice,
    required super.stockCount,
    super.returnPolicyDays,
    super.status,
    super.isPublished,
    super.reviewFeedback,
    super.reviewHistory,
    required super.createdAt,
    required super.updatedAt,
    super.approvedAt,
    super.publishedAt,
  });

  factory SellerProductModel.fromEntity(SellerProduct entity) {
    return SellerProductModel(
      productId: entity.productId,
      sellerId: entity.sellerId,
      sellerName: entity.sellerName,
      name: entity.name,
      description: entity.description,
      category: entity.category,
      subcategory: entity.subcategory,
      brand: entity.brand,
      isPickleballOnlyConfirmed: entity.isPickleballOnlyConfirmed,
      specifications: Map<String, String>.from(entity.specifications),
      images: entity.images,
      variants: entity.variants,
      baseSku: entity.baseSku,
      sellingPrice: entity.sellingPrice,
      originalPrice: entity.originalPrice,
      stockCount: entity.stockCount,
      returnPolicyDays: entity.returnPolicyDays,
      status: entity.status,
      isPublished: entity.isPublished,
      reviewFeedback: entity.reviewFeedback,
      reviewHistory: entity.reviewHistory,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      approvedAt: entity.approvedAt,
      publishedAt: entity.publishedAt,
    );
  }

  factory SellerProductModel.fromJson(Map<String, dynamic> json) {
    final rawCategory = json['category'] as String? ?? 'paddles';
    final category = ProductCategory.values.firstWhere(
      (c) => c.name == rawCategory && c != ProductCategory.all,
      orElse: () => ProductCategory.paddles,
    );
    final rawStatus = json['status'] as String? ?? 'draft';
    final status = SellerProductStatus.values.firstWhere(
      (s) => s.name == rawStatus,
      orElse: () => SellerProductStatus.draft,
    );
    final parsedStatus = status;
    // Platform rule: unapproved products can never be published.
    final isPublished = parsedStatus == SellerProductStatus.approved &&
        (json['isPublished'] as bool? ?? false);

    return SellerProductModel(
      productId: json['productId'] as String? ?? '',
      sellerId: json['sellerId'] as String? ?? '',
      sellerName: json['sellerName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: category,
      subcategory: json['subcategory'] as String? ??
          PickleballCatalogCategories.subcategoriesFor(category).first,
      brand: json['brand'] as String? ?? '',
      isPickleballOnlyConfirmed:
          json['isPickleballOnlyConfirmed'] as bool? ?? false,
      specifications: Map<String, String>.from(
        (json['specifications'] as Map?) ?? const {},
      ),
      images: (json['images'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SellerProductImageModel.fromJson)
          .toList(),
      variants: (json['variants'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SellerProductVariantModel.fromJson)
          .toList(),
      baseSku: json['baseSku'] as String? ?? '',
      sellingPrice: (json['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      stockCount: (json['stockCount'] as num?)?.toInt() ?? 0,
      returnPolicyDays: (json['returnPolicyDays'] as num?)?.toInt() ?? 7,
      status: parsedStatus,
      isPublished: isPublished,
      reviewFeedback: json['reviewFeedback'] as String?,
      reviewHistory: (json['reviewHistory'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(SellerProductReviewRecordModel.fromJson)
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      approvedAt: DateTime.tryParse(json['approvedAt'] as String? ?? ''),
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'name': name,
        'description': description,
        'category': category.name,
        'subcategory': subcategory,
        'brand': brand,
        'isPickleballOnlyConfirmed': isPickleballOnlyConfirmed,
        'specifications': specifications,
        'images':
            images.map((i) => SellerProductImageModel.fromEntity(i).toJson()).toList(),
        'variants': variants
            .map((v) => SellerProductVariantModel.fromEntity(v).toJson())
            .toList(),
        'baseSku': baseSku,
        'sellingPrice': sellingPrice,
        'originalPrice': originalPrice,
        'stockCount': stockCount,
        'returnPolicyDays': returnPolicyDays,
        'status': status.name,
        'isPublished': isPublished,
        'reviewFeedback': reviewFeedback,
        'reviewHistory': reviewHistory
            .map((r) => SellerProductReviewRecordModel.fromEntity(r).toJson())
            .toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'approvedAt': approvedAt?.toIso8601String(),
        'publishedAt': publishedAt?.toIso8601String(),
      };
}
