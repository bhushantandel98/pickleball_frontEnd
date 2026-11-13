import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/marketplace_seller/data/models/seller_profile_models.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/repositories/marketplace_seller_repository.dart';

/// Mock implementation of [MarketplaceSellerRepository] for Feature 6.1.
///
/// Enforces:
/// - Independent seller registration with mobile + email OTP verification and
///   duplicate-account prevention.
/// - Strict [sellerId] and [ownerUserId] ownership validation.
/// - Individual mandatory KYC document validation (Address Proof, PAN Card,
///   and Business Registration / GST Certificate based on entity type).
/// - Repository-level edit/document lock after submission until status
///   transitions to `needsInformation` or `rejected`.
class MockMarketplaceSellerRepository implements MarketplaceSellerRepository {
  static const String _mockOtp = '123456';
  static const Set<String> _allowedMimeTypes = {
    'application/pdf',
    'image/jpeg',
    'image/png',
  };

  final Map<String, SellerProfileModel> _sellers = {
    'org_seller_001': SellerProfileModel(
      sellerId: 'org_seller_001',
      ownerUserId: 'user_seller_001',
      businessName: 'Apex Pickleball Gear Co.',
      legalEntityName: 'Apex Sports Retail Pvt. Ltd.',
      entityType: SellerEntityType.privateLimited,
      pickleballFocus: SellerPickleballFocus.paddlesAndGear,
      isPickleballOnlyConfirmed: true,
      contactEmail: 'ops@apexpickleball.in',
      isEmailVerified: true,
      contactPhone: '+91 98201 44510',
      isMobileVerified: true,
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
          mimeType: 'application/pdf',
          fileSizeBytes: 328400,
          localFileRef: 'local://kyc/org_seller_001/apex_gst_certificate_2026.pdf',
          isLocalMockOnly: true,
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
      entityType: SellerEntityType.partnershipLlp,
      pickleballFocus: SellerPickleballFocus.multiCategoryPickleball,
      isPickleballOnlyConfirmed: true,
      contactEmail: 'hello@dinksmash.in',
      isEmailVerified: true,
      contactPhone: '+91 98450 22311',
      isMobileVerified: true,
      businessAddress: '22 Indiranagar 100ft Road',
      city: 'Bengaluru',
      state: 'Karnataka',
      postalCode: '560038',
      gstNumber: '29AABCD5678G1Z9',
      panNumber: 'AABCD5678G',
      documents: [
        SellerKycDocument(
          id: 'doc_seller_002',
          type: SellerDocumentType.addressProof,
          fileName: 'dink_smash_lease_agreement.pdf',
          mimeType: 'application/pdf',
          fileSizeBytes: 412000,
          localFileRef: 'local://kyc/org_seller_002/dink_smash_lease_agreement.pdf',
          isLocalMockOnly: true,
          uploadedAt: DateTime(2026, 11, 5, 9, 25),
          isVerifiedByStaff: true,
        ),
        SellerKycDocument(
          id: 'doc_seller_003',
          type: SellerDocumentType.businessRegistration,
          fileName: 'dink_smash_llp_certificate.pdf',
          mimeType: 'application/pdf',
          fileSizeBytes: 510200,
          localFileRef: 'local://kyc/org_seller_002/dink_smash_llp_certificate.pdf',
          isLocalMockOnly: true,
          uploadedAt: DateTime(2026, 11, 5, 9, 30),
          isVerifiedByStaff: true,
        ),
        SellerKycDocument(
          id: 'doc_seller_004',
          type: SellerDocumentType.panCard,
          fileName: 'dink_smash_pan.jpg',
          mimeType: 'image/jpeg',
          fileSizeBytes: 198400,
          localFileRef: 'local://kyc/org_seller_002/dink_smash_pan.jpg',
          isLocalMockOnly: true,
          uploadedAt: DateTime(2026, 11, 5, 9, 35),
          isVerifiedByStaff: true,
        ),
      ],
      submissionHistory: [
        SellerSubmissionRecord(
          submittedAt: DateTime(2026, 11, 5, 10, 0),
          statusAtSubmission: SellerVerificationStatus.approved,
          reviewNote: 'All pickleball catalog & KYC documents verified.',
        ),
      ],
      verificationStatus: SellerVerificationStatus.approved,
      staffRecommendationNote: 'All pickleball catalog & KYC documents verified.',
      approvedAt: DateTime(2026, 11, 6, 16, 0),
      isActive: true,
    ),
  };

  final Map<String, ({String mobile, String email})> _pendingOtps = {};
  int _docSeq = 10;
  int _sellerSeq = 10;

  String _normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  String _normalizeEmail(String raw) => raw.trim().toLowerCase();

  bool _hasDuplicateIdentifiers({
    required String userId,
    required String mobileNumber,
    required String email,
  }) {
    final normPhone = _normalizePhone(mobileNumber);
    final normEmail = _normalizeEmail(email);

    for (final s in _sellers.values) {
      if (s.ownerUserId == userId) return true;
      if (normPhone.isNotEmpty && _normalizePhone(s.contactPhone) == normPhone) {
        return true;
      }
      if (normEmail.isNotEmpty && _normalizeEmail(s.contactEmail) == normEmail) {
        return true;
      }
    }
    return false;
  }

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
  Future<Result<SellerProfile?>> getSellerProfileForUser({
    required String userId,
    String? sellerId,
  }) async {
    if (sellerId != null && sellerId.trim().isNotEmpty) {
      final (seller, failure) = _resolveAuthorizedSeller(sellerId.trim(), userId);
      if (failure != null) return FailureResult(failure);
      return Success(seller);
    }

    for (final seller in _sellers.values) {
      if (seller.ownerUserId == userId) {
        if (!seller.isActive ||
            seller.verificationStatus == SellerVerificationStatus.suspended) {
          return const FailureResult(
            ForbiddenFailure(
              message: 'Access denied: Seller account is inactive or suspended.',
            ),
          );
        }
        return Success(seller);
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> requestContactVerificationOtp({
    required String userId,
    required String mobileNumber,
    required String email,
  }) async {
    final normPhone = _normalizePhone(mobileNumber);
    final normEmail = _normalizeEmail(email);

    if (normPhone.length != 10) {
      return const FailureResult(
        ValidationFailure(
          message: 'Enter a valid 10-digit mobile number for OTP verification.',
        ),
      );
    }
    if (!normEmail.contains('@') || !normEmail.contains('.')) {
      return const FailureResult(
        ValidationFailure(
          message: 'Enter a valid business email address for verification.',
        ),
      );
    }
    if (_hasDuplicateIdentifiers(
      userId: userId,
      mobileNumber: normPhone,
      email: normEmail,
    )) {
      return const FailureResult(
        ValidationFailure(
          message:
              'A Marketplace Seller account already exists for this user, mobile number, or email.',
        ),
      );
    }

    _pendingOtps[userId] = (mobile: normPhone, email: normEmail);
    return const Success(null);
  }

  @override
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
  }) async {
    final normPhone = _normalizePhone(mobileNumber);
    final normEmail = _normalizeEmail(email);

    if (normPhone.length != 10) {
      return const FailureResult(
        ValidationFailure(message: 'A valid 10-digit mobile number is required.'),
      );
    }
    if (!normEmail.contains('@') || !normEmail.contains('.')) {
      return const FailureResult(
        ValidationFailure(message: 'A valid business email address is required.'),
      );
    }
    if (!isPickleballOnlyConfirmed) {
      return const FailureResult(
        ValidationFailure(
          message:
              'Only pickleball-related sellers and merchandise are permitted on this platform.',
        ),
      );
    }
    if (businessName.trim().isEmpty || legalEntityName.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Store display name and legal entity name are required.',
        ),
      );
    }
    if (_hasDuplicateIdentifiers(
      userId: userId,
      mobileNumber: normPhone,
      email: normEmail,
    )) {
      return const FailureResult(
        ValidationFailure(
          message:
              'Duplicate seller registration blocked: an account already exists for this user, mobile, or email.',
        ),
      );
    }

    final pending = _pendingOtps[userId];
    if (pending == null ||
        pending.mobile != normPhone ||
        pending.email != normEmail) {
      return const FailureResult(
        ValidationFailure(
          message:
              'Request mobile and email verification OTPs before registering.',
        ),
      );
    }
    if (mobileOtp.trim() != _mockOtp || emailOtp.trim() != _mockOtp) {
      return const FailureResult(
        ValidationFailure(
          message:
              'Invalid mobile or email verification OTP (mock OTP: 123456).',
        ),
      );
    }

    _pendingOtps.remove(userId);
    _sellerSeq += 1;
    final newSellerId = 'org_seller_$_sellerSeq';

    final created = SellerProfileModel(
      sellerId: newSellerId,
      ownerUserId: userId,
      businessName: businessName.trim(),
      legalEntityName: legalEntityName.trim(),
      entityType: entityType,
      pickleballFocus: pickleballFocus,
      isPickleballOnlyConfirmed: true,
      contactEmail: normEmail,
      isEmailVerified: true,
      contactPhone: '+91 $normPhone',
      isMobileVerified: true,
      businessAddress: '',
      city: '',
      state: '',
      postalCode: '',
      verificationStatus: SellerVerificationStatus.draft,
      isActive: true,
    );

    _sellers[newSellerId] = created;
    return Success(created);
  }

  @override
  Future<Result<SellerProfile>> saveBusinessProfile({
    required String sellerId,
    required String userId,
    required SellerProfile updatedProfile,
  }) async {
    final (existing, failure) = _resolveAuthorizedSeller(sellerId, userId);
    if (failure != null) return FailureResult(failure);

    if (!existing!.canEditProfile) {
      return FailureResult(
        ForbiddenFailure(
          message:
              'Profile editing is locked while verification status is "${existing.verificationStatus.label}".',
        ),
      );
    }
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
        updatedProfile.businessAddress.trim().isEmpty ||
        updatedProfile.city.trim().isEmpty ||
        updatedProfile.state.trim().isEmpty ||
        updatedProfile.postalCode.trim().isEmpty ||
        updatedProfile.panNumber.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message:
              'Complete all required business, address, and PAN fields before saving.',
        ),
      );
    }

    // Preserve verified contact identifiers, documents, submission history,
    // and server-owned verification status.
    final next = SellerProfileModel(
      sellerId: existing.sellerId,
      ownerUserId: existing.ownerUserId,
      businessName: updatedProfile.businessName.trim(),
      legalEntityName: updatedProfile.legalEntityName.trim(),
      entityType: updatedProfile.entityType,
      pickleballFocus: updatedProfile.pickleballFocus,
      isPickleballOnlyConfirmed: updatedProfile.isPickleballOnlyConfirmed,
      contactEmail: existing.contactEmail,
      isEmailVerified: existing.isEmailVerified,
      contactPhone: existing.contactPhone,
      isMobileVerified: existing.isMobileVerified,
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
      submissionHistory: existing.submissionHistory,
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
  Future<Result<SellerProfile>> attachKycDocument({
    required String sellerId,
    required String userId,
    required SellerDocumentType type,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
    required String localFileRef,
  }) async {
    final (existing, failure) = _resolveAuthorizedSeller(sellerId, userId);
    if (failure != null) return FailureResult(failure);

    if (!existing!.canEditProfile) {
      return FailureResult(
        ForbiddenFailure(
          message:
              'KYC documents cannot be modified while verification status is "${existing.verificationStatus.label}".',
        ),
      );
    }

    final trimmed = fileName.trim();
    if (trimmed.isEmpty || localFileRef.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Select a valid PDF or image document.'),
      );
    }
    if (!_allowedMimeTypes.contains(mimeType)) {
      return const FailureResult(
        ValidationFailure(
          message: 'Unsupported file format. Only PDF, JPG, and PNG are allowed.',
        ),
      );
    }
    if (fileSizeBytes <= 0 || fileSizeBytes > 5 * 1024 * 1024) {
      return const FailureResult(
        ValidationFailure(
          message: 'Document size must be between 1 byte and 5 MB.',
        ),
      );
    }

    _docSeq += 1;
    final updatedDocs = List<SellerKycDocument>.from(existing.documents)
      ..removeWhere((d) => d.type == type)
      ..add(
        SellerKycDocument(
          id: 'doc_seller_$_docSeq',
          type: type,
          fileName: trimmed,
          mimeType: mimeType,
          fileSizeBytes: fileSizeBytes,
          localFileRef: localFileRef.trim(),
          isLocalMockOnly: true,
          uploadedAt: DateTime.now(),
        ),
      );

    final next = _copyWithDocuments(existing, updatedDocs);
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

    if (!existing!.canEditProfile) {
      return FailureResult(
        ForbiddenFailure(
          message:
              'Documents cannot be removed while verification status is "${existing.verificationStatus.label}".',
        ),
      );
    }

    final updatedDocs = existing.documents
        .where((d) => d.id != documentId)
        .toList(growable: false);

    final next = _copyWithDocuments(existing, updatedDocs);
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

    if (!existing!.canEditProfile) {
      return FailureResult(
        ForbiddenFailure(
          message:
              'Submission is locked while verification status is "${existing.verificationStatus.label}".',
        ),
      );
    }
    if (!existing.isMobileVerified || !existing.isEmailVerified) {
      return const FailureResult(
        ValidationFailure(
          message:
              'Both mobile number and email address must be verified before submitting.',
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
    if (existing.businessAddress.trim().isEmpty ||
        existing.city.trim().isEmpty ||
        existing.state.trim().isEmpty ||
        existing.postalCode.trim().isEmpty ||
        existing.panNumber.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message:
              'Complete and save your business address and PAN details before submitting.',
        ),
      );
    }

    final missingDocs = existing.missingRequiredDocumentTypes;
    if (missingDocs.isNotEmpty) {
      final missingLabels = missingDocs.map((d) => d.label).join(', ');
      return FailureResult(
        ValidationFailure(
          message: 'Missing mandatory KYC documents: $missingLabels.',
        ),
      );
    }

    final now = DateTime.now();
    final updatedHistory = [
      ...existing.submissionHistory,
      SellerSubmissionRecord(
        submittedAt: now,
        statusAtSubmission: SellerVerificationStatus.pendingReview,
      ),
    ];

    final next = SellerProfileModel(
      sellerId: existing.sellerId,
      ownerUserId: existing.ownerUserId,
      businessName: existing.businessName,
      legalEntityName: existing.legalEntityName,
      entityType: existing.entityType,
      pickleballFocus: existing.pickleballFocus,
      isPickleballOnlyConfirmed: existing.isPickleballOnlyConfirmed,
      contactEmail: existing.contactEmail,
      isEmailVerified: existing.isEmailVerified,
      contactPhone: existing.contactPhone,
      isMobileVerified: existing.isMobileVerified,
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
      submissionHistory: updatedHistory,
      verificationStatus: SellerVerificationStatus.pendingReview,
      staffRecommendationNote: existing.staffRecommendationNote,
      adminDecisionReason: existing.adminDecisionReason,
      submittedAt: now,
      approvedAt: existing.approvedAt,
      isActive: existing.isActive,
    );

    _sellers[sellerId] = next;
    return Success(next);
  }

  SellerProfileModel _copyWithDocuments(
    SellerProfileModel existing,
    List<SellerKycDocument> updatedDocs,
  ) {
    return SellerProfileModel(
      sellerId: existing.sellerId,
      ownerUserId: existing.ownerUserId,
      businessName: existing.businessName,
      legalEntityName: existing.legalEntityName,
      entityType: existing.entityType,
      pickleballFocus: existing.pickleballFocus,
      isPickleballOnlyConfirmed: existing.isPickleballOnlyConfirmed,
      contactEmail: existing.contactEmail,
      isEmailVerified: existing.isEmailVerified,
      contactPhone: existing.contactPhone,
      isMobileVerified: existing.isMobileVerified,
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
      submissionHistory: existing.submissionHistory,
      verificationStatus: existing.verificationStatus,
      staffRecommendationNote: existing.staffRecommendationNote,
      adminDecisionReason: existing.adminDecisionReason,
      submittedAt: existing.submittedAt,
      approvedAt: existing.approvedAt,
      isActive: existing.isActive,
    );
  }
}
