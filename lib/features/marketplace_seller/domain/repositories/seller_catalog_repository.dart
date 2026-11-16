import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_product_entities.dart';

/// Repository contract for Feature 6.2 — Marketplace Seller Product Creation &
/// Catalog Management.
///
/// Enforces strict seller-scoped ownership (`sellerId` + `userId`),
/// pickleball-only category rules, verified-seller gating before submission,
/// and strict separation between Application Admin approval and Seller
/// publish/unpublish control.
abstract class SellerCatalogRepository {
  /// Returns all products belonging to [sellerId] (filtered optionally).
  Future<Result<List<SellerProduct>>> getSellerProducts({
    required String sellerId,
    required String userId,
    SellerProductFilter? filter,
  });

  /// Returns a single product owned by [sellerId].
  Future<Result<SellerProduct>> getSellerProductById({
    required String sellerId,
    required String userId,
    required String productId,
  });

  /// Creates or updates a product in `draft`, `needsInformation`, or `rejected`.
  ///
  /// Throws a validation failure if the product is currently `submittedForReview`
  /// or `approved` (inventory updates use [updateProductInventory] instead).
  Future<Result<SellerProduct>> saveProductDraft({
    required String sellerId,
    required String userId,
    required SellerProduct product,
  });

  /// Updates product-level stock and/or per-variant stock counts for an owned
  /// product without altering approval status.
  Future<Result<SellerProduct>> updateProductInventory({
    required String sellerId,
    required String userId,
    required String productId,
    int? stockCount,
    Map<String, int>? variantStockCounts,
  });

  /// Submits an owned product for Application Staff review & Application Admin
  /// final approval.
  ///
  /// Requires:
  /// - Seller verification status == `SellerVerificationStatus.approved`.
  /// - `isPickleballOnlyConfirmed == true` and allowed pickleball category.
  /// - All mandatory fields, at least one image, valid SKU/price, and valid variants.
  Future<Result<SellerProduct>> submitProductForReview({
    required String sellerId,
    required String userId,
    required String productId,
    String? submissionNote,
  });

  /// Explicitly publishes or unpublishes an `approved` product.
  ///
  /// Enforces that `product.status == SellerProductStatus.approved` and
  /// seller verification is `approved`. Approval never auto-publishes.
  Future<Result<SellerProduct>> setProductPublished({
    required String sellerId,
    required String userId,
    required String productId,
    required bool isPublished,
  });

  /// Deletes a product that is still in `draft` status and owned by [sellerId].
  Future<Result<void>> deleteDraftProduct({
    required String sellerId,
    required String userId,
    required String productId,
  });
}
