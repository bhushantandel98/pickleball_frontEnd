import 'package:equatable/equatable.dart';

/// Verification lifecycle for a Marketplace Seller.
///
/// Application Staff may review and recommend (`staffRecommended`) or request
/// more details (`needsInformation`), while only Application Admin grants final
/// `approved` or `rejected` status.
enum SellerVerificationStatus {
  draft(
    'Draft',
    'Complete your business profile and upload all mandatory KYC documents.',
  ),
  pendingReview(
    'Pending Staff Review',
    'Submitted for Application Staff review. Editing is locked until review completes.',
  ),
  staffRecommended(
    'Recommended by Staff',
    'Application Staff recommended approval. Awaiting final Application Admin decision; editing remains locked.',
  ),
  needsInformation(
    'Needs Information',
    'Additional details or documents were requested. Update your profile and resubmit.',
  ),
  rejected(
    'Rejected',
    'Application was rejected. Review the feedback, update details/documents, and resubmit.',
  ),
  approved(
    'Verified Seller',
    'Approved by Application Admin. Profile & KYC details are locked; proceed to product catalog (Feature 6.2).',
  ),
  suspended(
    'Suspended',
    'Seller account is suspended. Contact platform support.',
  );

  final String label;
  final String description;

  const SellerVerificationStatus(this.label, this.description);

  bool get isEditable =>
      this == SellerVerificationStatus.draft ||
      this == SellerVerificationStatus.needsInformation ||
      this == SellerVerificationStatus.rejected;

  bool get isLocked => !isEditable;
}

/// Legal entity type determining mandatory business document requirements.
enum SellerEntityType {
  individualSoleProprietor('Individual / Sole Proprietor', false),
  partnershipLlp('Partnership / LLP', true),
  privateLimited('Private Limited Company', true),
  registeredBusiness('Registered Proprietorship / Shop Act', true);

  final String label;
  final bool requiresBusinessDocuments;

  const SellerEntityType(this.label, this.requiresBusinessDocuments);
}

/// Allowed pickleball-specific business focus categories.
///
/// Platform rule: only pickleball-related sellers and products are permitted.
enum SellerPickleballFocus {
  paddlesAndGear('Pickleball Paddles & Balls'),
  apparelAndFootwear('Pickleball Apparel & Court Footwear'),
  courtEquipmentAndNets('Pickleball Nets & Court Equipment'),
  multiCategoryPickleball('Full-Line Pickleball Store');

  final String label;

  const SellerPickleballFocus(this.label);
}

/// Supported KYC / business verification document types for Seller onboarding.
enum SellerDocumentType {
  addressProof('Address Proof (Utility Bill / Rent Agreement / Bank Statement)'),
  panCard('PAN Card (Individual / Business)'),
  businessRegistration('Business Registration / Incorporation / Shop Act'),
  gstCertificate('GST Registration Certificate'),
  identityProof('Authorized Signatory ID Proof');

  final String label;

  const SellerDocumentType(this.label);
}

/// Uploaded/attached KYC document metadata attached to a [SellerProfile].
///
/// In mock mode, [isLocalMockOnly] is `true` and [localFileRef] holds a local
/// reference pending secure multipart upload to the backend.
class SellerKycDocument extends Equatable {
  final String id;
  final SellerDocumentType type;
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;
  final String localFileRef;
  final bool isLocalMockOnly;
  final DateTime uploadedAt;
  final bool isVerifiedByStaff;
  final String? note;

  const SellerKycDocument({
    required this.id,
    required this.type,
    required this.fileName,
    this.mimeType = 'application/pdf',
    this.fileSizeBytes = 0,
    this.localFileRef = '',
    this.isLocalMockOnly = true,
    required this.uploadedAt,
    this.isVerifiedByStaff = false,
    this.note,
  });

  String get formattedSize {
    if (fileSizeBytes <= 0) return 'Unknown size';
    final kb = (fileSizeBytes / 1024).ceil();
    return '$kb KB';
  }

  @override
  List<Object?> get props => [
        id,
        type,
        fileName,
        mimeType,
        fileSizeBytes,
        localFileRef,
        isLocalMockOnly,
        uploadedAt,
        isVerifiedByStaff,
        note,
      ];
}

/// Historical record of a seller verification submission & review outcome.
class SellerSubmissionRecord extends Equatable {
  final DateTime submittedAt;
  final SellerVerificationStatus statusAtSubmission;
  final String? reviewNote;

  const SellerSubmissionRecord({
    required this.submittedAt,
    required this.statusAtSubmission,
    this.reviewNote,
  });

  @override
  List<Object?> get props => [submittedAt, statusAtSubmission, reviewNote];
}

/// Marketplace Seller business profile & verification record (Feature 6.1).
class SellerProfile extends Equatable {
  final String sellerId;
  final String ownerUserId;
  final String businessName;
  final String legalEntityName;
  final SellerEntityType entityType;
  final SellerPickleballFocus pickleballFocus;
  final bool isPickleballOnlyConfirmed;
  final String contactEmail;
  final bool isEmailVerified;
  final String contactPhone;
  final bool isMobileVerified;
  final String businessAddress;
  final String city;
  final String state;
  final String postalCode;
  final String gstNumber;
  final String panNumber;
  final String bankAccountHolder;
  final String bankAccountLast4;
  final String ifscCode;
  final List<SellerKycDocument> documents;
  final List<SellerSubmissionRecord> submissionHistory;
  final SellerVerificationStatus verificationStatus;
  final String? staffRecommendationNote;
  final String? adminDecisionReason;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final bool isActive;

  const SellerProfile({
    required this.sellerId,
    required this.ownerUserId,
    required this.businessName,
    required this.legalEntityName,
    this.entityType = SellerEntityType.registeredBusiness,
    this.pickleballFocus = SellerPickleballFocus.paddlesAndGear,
    this.isPickleballOnlyConfirmed = true,
    required this.contactEmail,
    this.isEmailVerified = false,
    required this.contactPhone,
    this.isMobileVerified = false,
    required this.businessAddress,
    required this.city,
    required this.state,
    required this.postalCode,
    this.gstNumber = '',
    this.panNumber = '',
    this.bankAccountHolder = '',
    this.bankAccountLast4 = '',
    this.ifscCode = '',
    this.documents = const [],
    this.submissionHistory = const [],
    this.verificationStatus = SellerVerificationStatus.draft,
    this.staffRecommendationNote,
    this.adminDecisionReason,
    this.submittedAt,
    this.approvedAt,
    this.isActive = true,
  });

  bool get canEditProfile => verificationStatus.isEditable;
  bool get canSubmitForVerification => verificationStatus.isEditable;

  bool get isVerified =>
      verificationStatus == SellerVerificationStatus.approved && isActive;

  /// Returns the mandatory [SellerDocumentType]s required for this seller's
  /// [entityType] and tax registration.
  List<SellerDocumentType> get requiredDocumentTypes {
    final requiredTypes = <SellerDocumentType>[
      SellerDocumentType.addressProof,
      SellerDocumentType.panCard,
    ];
    if (entityType.requiresBusinessDocuments) {
      requiredTypes.add(SellerDocumentType.businessRegistration);
    }
    if (gstNumber.trim().isNotEmpty) {
      requiredTypes.add(SellerDocumentType.gstCertificate);
    }
    return requiredTypes;
  }

  /// Returns the mandatory document types not yet attached to [documents].
  List<SellerDocumentType> get missingRequiredDocumentTypes {
    final attachedTypes = documents.map((d) => d.type).toSet();
    return requiredDocumentTypes
        .where((type) => !attachedTypes.contains(type))
        .toList(growable: false);
  }

  SellerProfile copyWith({
    String? businessName,
    String? legalEntityName,
    SellerEntityType? entityType,
    SellerPickleballFocus? pickleballFocus,
    bool? isPickleballOnlyConfirmed,
    String? contactEmail,
    bool? isEmailVerified,
    String? contactPhone,
    bool? isMobileVerified,
    String? businessAddress,
    String? city,
    String? state,
    String? postalCode,
    String? gstNumber,
    String? panNumber,
    String? bankAccountHolder,
    String? bankAccountLast4,
    String? ifscCode,
    List<SellerKycDocument>? documents,
    List<SellerSubmissionRecord>? submissionHistory,
    SellerVerificationStatus? verificationStatus,
    String? staffRecommendationNote,
    String? adminDecisionReason,
    DateTime? submittedAt,
    DateTime? approvedAt,
    bool? isActive,
  }) {
    return SellerProfile(
      sellerId: sellerId,
      ownerUserId: ownerUserId,
      businessName: businessName ?? this.businessName,
      legalEntityName: legalEntityName ?? this.legalEntityName,
      entityType: entityType ?? this.entityType,
      pickleballFocus: pickleballFocus ?? this.pickleballFocus,
      isPickleballOnlyConfirmed:
          isPickleballOnlyConfirmed ?? this.isPickleballOnlyConfirmed,
      contactEmail: contactEmail ?? this.contactEmail,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      contactPhone: contactPhone ?? this.contactPhone,
      isMobileVerified: isMobileVerified ?? this.isMobileVerified,
      businessAddress: businessAddress ?? this.businessAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      bankAccountHolder: bankAccountHolder ?? this.bankAccountHolder,
      bankAccountLast4: bankAccountLast4 ?? this.bankAccountLast4,
      ifscCode: ifscCode ?? this.ifscCode,
      documents: documents ?? this.documents,
      submissionHistory: submissionHistory ?? this.submissionHistory,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      staffRecommendationNote:
          staffRecommendationNote ?? this.staffRecommendationNote,
      adminDecisionReason: adminDecisionReason ?? this.adminDecisionReason,
      submittedAt: submittedAt ?? this.submittedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        sellerId,
        ownerUserId,
        businessName,
        legalEntityName,
        entityType,
        pickleballFocus,
        isPickleballOnlyConfirmed,
        contactEmail,
        isEmailVerified,
        contactPhone,
        isMobileVerified,
        businessAddress,
        city,
        state,
        postalCode,
        gstNumber,
        panNumber,
        bankAccountHolder,
        bankAccountLast4,
        ifscCode,
        documents,
        submissionHistory,
        verificationStatus,
        staffRecommendationNote,
        adminDecisionReason,
        submittedAt,
        approvedAt,
        isActive,
      ];
}
