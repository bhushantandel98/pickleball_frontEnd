import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';

/// Data model for [SellerKycDocument] with JSON serialization.
class SellerKycDocumentModel extends SellerKycDocument {
  const SellerKycDocumentModel({
    required super.id,
    required super.type,
    required super.fileName,
    super.mimeType,
    super.fileSizeBytes,
    super.localFileRef,
    super.isLocalMockOnly,
    required super.uploadedAt,
    super.isVerifiedByStaff,
    super.note,
  });

  factory SellerKycDocumentModel.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json['type'] as String? ?? '').trim();
    final matchedType = SellerDocumentType.values.firstWhere(
      (e) => e.name == typeRaw,
      orElse: () => SellerDocumentType.addressProof,
    );

    return SellerKycDocumentModel(
      id: json['id'] as String? ?? '',
      type: matchedType,
      fileName: json['fileName'] as String? ?? '',
      mimeType: json['mimeType'] as String? ?? 'application/pdf',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      localFileRef: json['localFileRef'] as String? ?? '',
      isLocalMockOnly: json['isLocalMockOnly'] as bool? ?? true,
      uploadedAt: DateTime.tryParse(json['uploadedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      isVerifiedByStaff: json['isVerifiedByStaff'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'fileName': fileName,
        'mimeType': mimeType,
        'fileSizeBytes': fileSizeBytes,
        'localFileRef': localFileRef,
        'isLocalMockOnly': isLocalMockOnly,
        'uploadedAt': uploadedAt.toIso8601String(),
        'isVerifiedByStaff': isVerifiedByStaff,
        'note': note,
      };
}

/// Data model for [SellerSubmissionRecord] with JSON serialization.
class SellerSubmissionRecordModel extends SellerSubmissionRecord {
  const SellerSubmissionRecordModel({
    required super.submittedAt,
    required super.statusAtSubmission,
    super.reviewNote,
  });

  factory SellerSubmissionRecordModel.fromJson(Map<String, dynamic> json) {
    final statusRaw = (json['statusAtSubmission'] as String? ?? '').trim();
    final status = SellerVerificationStatus.values.firstWhere(
      (e) => e.name == statusRaw,
      orElse: () => SellerVerificationStatus.pendingReview,
    );

    return SellerSubmissionRecordModel(
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      statusAtSubmission: status,
      reviewNote: json['reviewNote'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'submittedAt': submittedAt.toIso8601String(),
        'statusAtSubmission': statusAtSubmission.name,
        'reviewNote': reviewNote,
      };
}

/// Data model for [SellerProfile] with JSON serialization.
///
/// Missing or null `isActive` defaults strictly to `false` (fail-closed).
class SellerProfileModel extends SellerProfile {
  const SellerProfileModel({
    required super.sellerId,
    required super.ownerUserId,
    required super.businessName,
    required super.legalEntityName,
    super.entityType,
    super.pickleballFocus,
    super.isPickleballOnlyConfirmed,
    required super.contactEmail,
    super.isEmailVerified,
    required super.contactPhone,
    super.isMobileVerified,
    required super.businessAddress,
    required super.city,
    required super.state,
    required super.postalCode,
    super.gstNumber,
    super.panNumber,
    super.bankAccountHolder,
    super.bankAccountLast4,
    super.ifscCode,
    super.documents,
    super.submissionHistory,
    super.verificationStatus,
    super.staffRecommendationNote,
    super.adminDecisionReason,
    super.submittedAt,
    super.approvedAt,
    super.isActive = false,
  });

  factory SellerProfileModel.fromJson(Map<String, dynamic> json) {
    final entityRaw = (json['entityType'] as String? ?? '').trim();
    final entityType = SellerEntityType.values.firstWhere(
      (e) => e.name == entityRaw,
      orElse: () => SellerEntityType.registeredBusiness,
    );

    final focusRaw = (json['pickleballFocus'] as String? ?? '').trim();
    final focus = SellerPickleballFocus.values.firstWhere(
      (e) => e.name == focusRaw,
      orElse: () => SellerPickleballFocus.paddlesAndGear,
    );

    final statusRaw = (json['verificationStatus'] as String? ?? '').trim();
    final status = SellerVerificationStatus.values.firstWhere(
      (e) => e.name == statusRaw,
      orElse: () => SellerVerificationStatus.draft,
    );

    final docsJson = json['documents'] as List<dynamic>? ?? const [];
    final docs = docsJson
        .whereType<Map<String, dynamic>>()
        .map(SellerKycDocumentModel.fromJson)
        .toList(growable: false);

    final historyJson =
        json['submissionHistory'] as List<dynamic>? ?? const [];
    final history = historyJson
        .whereType<Map<String, dynamic>>()
        .map(SellerSubmissionRecordModel.fromJson)
        .toList(growable: false);

    return SellerProfileModel(
      sellerId: json['sellerId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      legalEntityName: json['legalEntityName'] as String? ?? '',
      entityType: entityType,
      pickleballFocus: focus,
      isPickleballOnlyConfirmed:
          json['isPickleballOnlyConfirmed'] as bool? ?? false,
      contactEmail: json['contactEmail'] as String? ?? '',
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      contactPhone: json['contactPhone'] as String? ?? '',
      isMobileVerified: json['isMobileVerified'] as bool? ?? false,
      businessAddress: json['businessAddress'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? '',
      gstNumber: json['gstNumber'] as String? ?? '',
      panNumber: json['panNumber'] as String? ?? '',
      bankAccountHolder: json['bankAccountHolder'] as String? ?? '',
      bankAccountLast4: json['bankAccountLast4'] as String? ?? '',
      ifscCode: json['ifscCode'] as String? ?? '',
      documents: docs,
      submissionHistory: history,
      verificationStatus: status,
      staffRecommendationNote: json['staffRecommendationNote'] as String?,
      adminDecisionReason: json['adminDecisionReason'] as String?,
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? ''),
      approvedAt: DateTime.tryParse(json['approvedAt'] as String? ?? ''),
      isActive: json['isActive'] as bool? ?? false,
    );
  }
}
