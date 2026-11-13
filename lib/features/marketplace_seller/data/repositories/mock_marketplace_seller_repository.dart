import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/marketplace_seller/data/models/seller_profile_models.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/repositories/marketplace_seller_repository.dart';

/// Mock implementation of [MarketplaceSellerRepository] for Feature 6.1.
///
/// Enforces:
/// - Strict [sellerId] and [userId] ownership validation.
/// - Pickleball-only seller confirmation.
/// - Server-owned verification status transitions (sellers cannot self-approve;
///   Application Staff recommends and Application Admin grants final approval).
class MockMarketplaceSellerRepository implements MarketplaceSellerRepository {
  final Map<String, SellerProfileModel> _sellers = {
    'org_seller_001': SellerProfileModel(
      sellerId: 'org_seller_001',
      ownerUserId: 'user_seller_001',
      businessName: 'Apex Pickleball Gear Co.',
      legalEntityName: 'Apex Sports Retail Pvt. Ltd.',
      pickleballFocus: SellerPickleballFocus.paddlesAndGear,
      isPickleballOnlyConfirmed: true,
      contactEmail: 'ops@apexpickleball.in',
      contactPhone: '+91 98201 44510',
      businessAddress: 'Plot 14, Sports Hub Industrial Estate, Andheri East',
      city: 'Mumbai',
      state: 'Maharashtra',
      postalCode: '400069',
      gstNumber: '27AABCA1234F1Z5',
      panNumber: 'AABCA1234F',
      bankAccountHolder: 'Apex Sports Retail Pvt. Ltd.',
      bankAccountLast4: '4821',
      ifscCode: 'HDFC0001234',
      documents: [
        SellerKycDocument(
          id: 'doc_seller_001',
          type: SellerDocumentType.gstCertificate,
          fileName: 'apex_gst_certificate_2026.pdf',
          uploadedAt: DateTime(2026, 11, 10, 11, 15),
        ),
      ],
      verificationStatus: SellerVerificationStatus.draft,
      isActive: true,
    ),
    // Isolated second seller to enforce multi-tenant data separation.
    'org_seller_002': SellerProfileModel(
      sellerId: 'org_seller_002',
      ownerUserId: 'user_seller_002',
      businessName: 'Dink & Smash Pro Shop',
      legalEntityName: 'Dink & Smash LLP',
      pickleballFocus: SellerPickleballFocus.multiCategoryPickleball,
      isPickleballOnlyConfirmed: true,
      contactEmail: 'hello@dinksmash.in',
      contactPhone: '+91 98450 22311',
      businessAddress: '22 Indiranagar 100ft Road',
      city: 'Bengaluru',
      state: 'Karnataka',
      postalCode: '560038',
      gstNumber: '29AABCD5678G1Z9',
      panNumber: 'AABCD5678G',
      documents: [
        SellerKycDocument(
          id: 'doc_seller_002',
          type: SellerDocumentType.businessRegistration,
          fileName: 'dink_smash_shop_act.pdf',
          uploadedAt: DateTime(2026, 11, 5, 9, 30),
          isVerifiedByStaff: true,
        ),
        SellerKycDocument(
          id: 'doc_seller_003',
          type: SellerDocumentType.panCard,
          fileName: 'dink_smash_pan.pdf',
          uploadedAt: DateTime(2026, 11, 5, 9, 35),
          isVerifiedByStaff: true,
        ),
      ],
      verificationStatus: SellerVerificationStatus.approved,
      staffRecommendationNote: 'All pickleball catalog & GST documents verified.',
      approvedAt: DateTime(2026, 11, 6, 16, 0),
      isActive: true,
    ),
  };

  int _docSeq = 10;

  (SellerProfileModel?, Failure?) _resolveAuthorizedSeller(
    String sellerId,
    String userId,
  ) {
    final seller = _sellers[sellerId];
    if (seller == null || seller.ownerUserId != userId) {
      return (
        null,
        const ForbiddenFailure(
          message:
              'Access denied: Seller profile does not belong to this authenticated session.',
        ),
      );
    }
    if (!seller.isActive) {
      return (
        null,
        const ForbiddenFailure(
          message: 'Access denied: Seller account is inactive.',
        ),
      );
    }
    if (seller.verificationStatus == SellerVerificationStatus.suspended) {
      return (
        null,
        const ForbiddenFailure(
          message: 'Access denied: Seller account is suspended.',
        ),
      );
    }
    return (seller, null);
  }

  @override
  Future<Result<SellerProfile>> getSellerProfile({
    required String sellerId,
    required String userId,
  }) async {
    final (seller, failure) = _resolveAuthorizedSeller(sellerId, userId);
    if (failure != null) return FailureResult(failure);
    return Success(seller!);
  }

  @override
  Future<Result<SellerProfile>> saveBusinessProfile({
    required String sellerId,
    required String userId,
    required SellerProfile updatedProfile,
  }) async {
    final (existing, failure) = _resolveAuthorizedSeller(sellerId, userId);
    if (failure != null) return FailureResult(failure);

    if (updatedProfile.sellerId != sellerId ||
        updatedProfile.ownerUserId != userId) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Cannot modify seller ownership identifiers.',
        ),
      );
    }
    if (!updatedProfile.isPickleballOnlyConfirmed) {
      return const FailureResult(
        ValidationFailure(
          message:
              'Only pickleball-related sellers and merchandise are permitted on this platform.',
        ),
      );
    }
    if (updatedProfile.businessName.trim().isEmpty ||
        updatedProfile.legalEntityName.trim().isEmpty ||
        updatedProfile.contactEmail.trim().isEmpty ||
        updatedProfile.contactPhone.trim().isEmpty ||
        updatedProfile.businessAddress.trim().isEmpty ||
        updatedProfile.city.trim().isEmpty ||
        updatedProfile.state.trim().isEmpty ||
        updatedProfile.postalCode.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'All required business and address fields must be completed.',
        ),
      );
    }

    // Preserve server-owned verification status and audit fields.
    final next = SellerProfileModel(
      sellerId: existing!.sellerId,
      ownerUserId: existing.ownerUserId,
      businessName: updatedProfile.businessName.trim(),
      legalEntityName: updatedProfile.legalEntityName.trim(),
      pickleballFocus: updatedProfile.pickleballFocus,
      isPickleballOnlyConfirmed: updatedProfile.isPickleballOnlyConfirmed,
      contactEmail: updatedProfile.contactEmail.trim(),
      contactPhone: updatedProfile.contactPhone.trim(),
      businessAddress: updatedProfile.businessAddress.trim(),
      city: updatedProfile.city.trim(),
      state: updatedProfile.state.trim(),
      postalCode: updatedProfile.postalCode.trim(),
      gstNumber: updatedProfile.gstNumber.trim().toUpperCase(),
      panNumber: updatedProfile.panNumber.trim().toUpperCase(),
      bankAccountHolder: updatedProfile.bankAccountHolder.trim(),
      bankAccountLast4: updatedProfile.bankAccountLast4.trim(),
      ifscCode: updatedProfile.ifscCode.trim().toUpperCase(),
      documents: existing.documents,
      verificationStatus: existing.verificationStatus,
      staffRecommendationNote: existing.staffRecommendationNote,
      adminDecisionReason: existing.adminDecisionReason,
      submittedAt: existing.submittedAt,
      approvedAt: existing.approvedAt,
      isActive: existing.isActive,
    );

    _sellers[sellerId] = next;
    return Success(next);
  }

  @override
  Future<Result<SellerProfile>> uploadKycDocument({
    required String sellerId,
    required String userId,
    required SellerDocumentType type,
    required String fileName,
  }) async {
    final (existing, failure) = _resolveAuthorizedSeller(sellerId, userId);
    if (failure != null) return FailureResult(failure);

    final trimmed = fileName.trim();
    if (trimmed.isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Select a document file name to upload.'),
      );
    }

    _docSeq += 1;
    final updatedDocs = List<SellerKycDocument>.from(existing!.documents)
      ..removeWhere((d) => d.type == type)
      ..add(
        SellerKycDocument(
          id: 'doc_seller_$_docSeq',
          type: type,
          fileName: trimmed,
          uploadedAt: DateTime.now(),
        ),
      );

    final next = SellerProfileModel(
      sellerId: existing.sellerId,
      ownerUserId: existing.ownerUserId,
      businessName: existing.businessName,
      legalEntityName: existing.legalEntityName,
      pickleballFocus: existing.pickleballFocus,
      isPickleballOnlyConfirmed: existing.isPickleballOnlyConfirmed,
      contactEmail: existing.contactEmail,
      contactPhone: existing.contactPhone,
      businessAddress: existing.businessAddress,
      city: existing.city,
      state: existing.state,
      postalCode: existing.postalCode,
      gstNumber: existing.gstNumber,
      panNumber: existing.panNumber,
      bankAccountHolder: existing.bankAccountHolder,
      bankAccountLast4: existing.bankAccountLast4,
      ifscCode: existing.ifscCode,
      documents: updatedDocs,
      verificationStatus: existing.verificationStatus,
      staffRecommendationNote: existing.staffRecommendationNote,
      adminDecisionReason: existing.adminDecisionReason,
      submittedAt: existing.submittedAt,
      approvedAt: existing.approvedAt,
      isActive: existing.isActive,
    );

    _sellers[sellerId] = next;
    return Success(next);
  }

  @override
  Future<Result<SellerProfile>> removeKycDocument({
    required String sellerId,
    required String userId,
    required String documentId,
  }) async {
    final (existing, failure) = _resolveAuthorizedSeller(sellerId, userId);
    if (failure != null) return FailureResult(failure);

    if (!existing!.canSubmitForVerification) {
      return const FailureResult(
        ForbiddenFailure(
          message:
              'Documents cannot be removed while verification is pending or approved.',
        ),
      );
    }

    final updatedDocs = existing.documents
        .where((d) => d.id != documentId)
        .toList(growable: false);

    final next = SellerProfileModel(
      sellerId: existing.sellerId,
      ownerUserId: existing.ownerUserId,
      businessName: existing.businessName,
      legalEntityName: existing.legalEntityName,
      pickleballFocus: existing.pickleballFocus,
      isPickleballOnlyConfirmed: existing.isPickleballOnlyConfirmed,
      contactEmail: existing.contactEmail,
      contactPhone: existing.contactPhone,
      businessAddress: existing.businessAddress,
      city: existing.city,
      state: existing.state,
      postalCode: existing.postalCode,
      gstNumber: existing.gstNumber,
      panNumber: existing.panNumber,
      bankAccountHolder: existing.bankAccountHolder,
      bankAccountLast4: existing.bankAccountLast4,
      ifscCode: existing.ifscCode,
      documents: updatedDocs,
      verificationStatus: existing.verificationStatus,
      staffRecommendationNote: existing.staffRecommendationNote,
      adminDecisionReason: existing.adminDecisionReason,
      submittedAt: existing.submittedAt,
      approvedAt: existing.approvedAt,
      isActive: existing.isActive,
    );

    _sellers[sellerId] = next;
    return Success(next);
  }

  @override
  Future<Result<SellerProfile>> submitForVerification({
    required String sellerId,
    required String userId,
  }) async {
    final (existing, failure) = _resolveAuthorizedSeller(sellerId, userId);
    if (failure != null) return FailureResult(failure);

    if (!existing!.canSubmitForVerification) {
      return const FailureResult(
        ValidationFailure(
          message: 'Seller verification has already been submitted or approved.',
        ),
      );
    }
    if (!existing.isPickleballOnlyConfirmed) {
      return const FailureResult(
        ValidationFailure(
          message:
              'Confirm that your store sells only pickleball-related merchandise.',
        ),
      );
    }
    if (existing.panNumber.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'PAN number is required before submitting for verification.',
        ),
      );
    }
    if (existing.documents.length < 2) {
      return const FailureResult(
        ValidationFailure(
          message:
              'Upload at least 2 KYC documents (e.g., Business/GST & PAN/ID) before submitting.',
        ),
      );
    }

    final next = SellerProfileModel(
      sellerId: existing.sellerId,
      ownerUserId: existing.ownerUserId,
      businessName: existing.businessName,
      legalEntityName: existing.legalEntityName,
      pickleballFocus: existing.pickleballFocus,
      isPickleballOnlyConfirmed: existing.isPickleballOnlyConfirmed,
      contactEmail: existing.contactEmail,
      contactPhone: existing.contactPhone,
      businessAddress: existing.businessAddress,
      city: existing.city,
      state: existing.state,
      postalCode: existing.postalCode,
      gstNumber: existing.gstNumber,
      panNumber: existing.panNumber,
      bankAccountHolder: existing.bankAccountHolder,
      bankAccountLast4: existing.bankAccountLast4,
      ifscCode: existing.ifscCode,
      documents: existing.documents,
      verificationStatus: SellerVerificationStatus.pendingReview,
      staffRecommendationNote: existing.staffRecommendationNote,
      adminDecisionReason: null,
      submittedAt: DateTime.now(),
      approvedAt: existing.approvedAt,
      isActive: existing.isActive,
    );

    _sellers[sellerId] = next;
    return Success(next);
  }
}
