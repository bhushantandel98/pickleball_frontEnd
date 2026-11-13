import 'package:equatable/equatable.dart';

/// Verification lifecycle for a Marketplace Seller.
///
/// Application Staff may review and recommend (`staffRecommended`), while only
/// Application Admin grants final `approved` or `rejected` status.
enum SellerVerificationStatus {
  draft('Draft', 'Complete your business profile and upload required KYC documents.'),
  pendingReview(
    'Pending Staff Review',
    'Submitted for Application Staff review. Sellers cannot self-approve.',
  ),
  staffRecommended(
    'Recommended by Staff',
    'Application Staff recommended approval. Awaiting final Application Admin decision.',
  ),
  approved(
    'Verified Seller',
    'Approved by Application Admin. You can proceed to product catalog creation (Feature 6.2).',
  ),
  rejected(
    'Changes Requested / Rejected',
    'Update your business details or documents and resubmit for verification.',
  ),
  suspended(
    'Suspended',
    'Seller account is suspended. Contact platform support.',
  );

  final String label;
  final String description;

  const SellerVerificationStatus(this.label, this.description);
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
  businessRegistration('Business Registration / Shop Act'),
  gstCertificate('GST Registration Certificate'),
  panCard('Business / Proprietor PAN Card'),
  identityProof('Authorized Signatory ID Proof');

  final String label;

  const SellerDocumentType(this.label);
}

/// Uploaded KYC / business document metadata attached to a [SellerProfile].
class SellerKycDocument extends Equatable {
  final String id;
  final SellerDocumentType type;
  final String fileName;
  final DateTime uploadedAt;
  final bool isVerifiedByStaff;
  final String? note;

  const SellerKycDocument({
    required this.id,
    required this.type,
    required this.fileName,
    required this.uploadedAt,
    this.isVerifiedByStaff = false,
    this.note,
  });

  SellerKycDocument copyWith({
    String? id,
    SellerDocumentType? type,
    String? fileName,
    DateTime? uploadedAt,
    bool? isVerifiedByStaff,
    String? note,
  }) {
    return SellerKycDocument(
      id: id ?? this.id,
      type: type ?? this.type,
      fileName: fileName ?? this.fileName,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      isVerifiedByStaff: isVerifiedByStaff ?? this.isVerifiedByStaff,
      note: note ?? this.note,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        fileName,
        uploadedAt,
        isVerifiedByStaff,
        note,
      ];
}

/// Marketplace Seller business profile & verification record (Feature 6.1).
class SellerProfile extends Equatable {
  final String sellerId;
  final String ownerUserId;
  final String businessName;
  final String legalEntityName;
  final SellerPickleballFocus pickleballFocus;
  final bool isPickleballOnlyConfirmed;
  final String contactEmail;
  final String contactPhone;
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
    this.pickleballFocus = SellerPickleballFocus.paddlesAndGear,
    this.isPickleballOnlyConfirmed = true,
    required this.contactEmail,
    required this.contactPhone,
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
    this.verificationStatus = SellerVerificationStatus.draft,
    this.staffRecommendationNote,
    this.adminDecisionReason,
    this.submittedAt,
    this.approvedAt,
    this.isActive = true,
  });

  bool get canSubmitForVerification =>
      verificationStatus == SellerVerificationStatus.draft ||
      verificationStatus == SellerVerificationStatus.rejected;

  bool get isVerified =>
      verificationStatus == SellerVerificationStatus.approved && isActive;

  SellerProfile copyWith({
    String? businessName,
    String? legalEntityName,
    SellerPickleballFocus? pickleballFocus,
    bool? isPickleballOnlyConfirmed,
    String? contactEmail,
    String? contactPhone,
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
      pickleballFocus: pickleballFocus ?? this.pickleballFocus,
      isPickleballOnlyConfirmed:
          isPickleballOnlyConfirmed ?? this.isPickleballOnlyConfirmed,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
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
        pickleballFocus,
        isPickleballOnlyConfirmed,
        contactEmail,
        contactPhone,
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
        verificationStatus,
        staffRecommendationNote,
        adminDecisionReason,
        submittedAt,
        approvedAt,
        isActive,
      ];
}
