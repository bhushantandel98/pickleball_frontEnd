import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';

/// Repository contract for Feature 6.1 — Marketplace Seller Registration & Profile.
///
/// Every method requires validated [sellerId] and [userId] from the
/// authenticated session context and enforces strict seller ownership.
abstract class MarketplaceSellerRepository {
  Future<Result<SellerProfile>> getSellerProfile({
    required String sellerId,
    required String userId,
  });

  Future<Result<SellerProfile>> saveBusinessProfile({
    required String sellerId,
    required String userId,
    required SellerProfile updatedProfile,
  });

  Future<Result<SellerProfile>> uploadKycDocument({
    required String sellerId,
    required String userId,
    required SellerDocumentType type,
    required String fileName,
  });

  Future<Result<SellerProfile>> removeKycDocument({
    required String sellerId,
    required String userId,
    required String documentId,
  });

  Future<Result<SellerProfile>> submitForVerification({
    required String sellerId,
    required String userId,
  });
}
