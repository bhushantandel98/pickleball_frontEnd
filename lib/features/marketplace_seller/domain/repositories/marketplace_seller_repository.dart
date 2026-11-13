import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';

/// Repository contract for Feature 6.1 — Marketplace Seller Registration & Profile.
///
/// Supports independent seller registration for authenticated users (even
/// before an `activeOrganizationId` exists) as well as strict seller-scoped
/// profile and KYC operations.
abstract class MarketplaceSellerRepository {
  /// Fetches the seller profile linked to [userId] (and optional [sellerId]).
  /// Returns `Success(null)` when the user has not registered a seller account yet.
  Future<Result<SellerProfile?>> getSellerProfileForUser({
    required String userId,
    String? sellerId,
  });

  /// Requests verification OTPs for mandatory [mobileNumber] and [email]
  /// before creating a new seller organization.
  Future<Result<void>> requestContactVerificationOtp({
    required String userId,
    required String mobileNumber,
    required String email,
  });

  /// Registers a new independent Marketplace Seller organization/profile
  /// after validating mobile & email OTPs and preventing duplicate accounts.
  Future<Result<SellerProfile>> registerSellerAccount({
    required String userId,
    required String mobileNumber,
    required String mobileOtp,
    required String email,
    required String emailOtp,
    required String businessName,
    required String legalEntityName,
    required SellerEntityType entityType,
    required SellerPickleballFocus pickleballFocus,
    required bool isPickleballOnlyConfirmed,
  });

  Future<Result<SellerProfile>> saveBusinessProfile({
    required String sellerId,
    required String userId,
    required SellerProfile updatedProfile,
  });

  /// Attaches a selected PDF/image document (ready for multipart upload in
  /// remote implementation; stored locally in mock mode).
  Future<Result<SellerProfile>> attachKycDocument({
    required String sellerId,
    required String userId,
    required SellerDocumentType type,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
    required String localFileRef,
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
