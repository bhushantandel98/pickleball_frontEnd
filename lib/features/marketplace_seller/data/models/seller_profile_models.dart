import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';

/// Data model for [SellerKycDocument] with JSON serialization.
class SellerKycDocumentModel extends SellerKycDocument {
  const SellerKycDocumentModel({
    required super.id,
    required super.type,
    required super.fileName,
    required super.uploadedAt,
    super.isVerifiedByStaff,
    super.note,
  });

  factory SellerKycDocumentModel.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json['type'] as String? ?? '').trim();
    final matchedType = SellerDocumentType.values.firstWhere(
      (e) => e.name == typeRaw,
      orElse: () => SellerDocumentType.businessRegistration,
    );

    return SellerKycDocumentModel(
      id: json['id'] as String? ?? '',
      type: matchedType,
      fileName: json['fileName'] as String? ?? '',
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
        'uploadedAt': uploadedAt.toIso8601String(),
        'isVerifiedByStaff': isVerifiedByStaff,
        'note': note,
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
    super.pickleballFocus,
    super.isPickleballOnlyConfirmed,
    required super.contactEmail,
    required super.contactPhone,
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
    super.verificationStatus,
    super.staffRecommendationNote,
    super.adminDecisionReason,
    super.submittedAt,
    super.approvedAt,
    super.isActive = false,
  });

  factory SellerProfileModel.fromJson(Map<String, dynamic> json) {
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

    return SellerProfileModel(
      sellerId: json['sellerId'] as String? ?? '',
      ownerUserId: json['ownerUserId'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      legalEntityName: json['legalEntityName'] as String? ?? '',
      pickleballFocus: focus,
      isPickleballOnlyConfirmed:
          json['isPickleballOnlyConfirmed'] as bool? ?? false,
      contactEmail: json['contactEmail'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
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
      verificationStatus: status,
      staffRecommendationNote: json['staffRecommendationNote'] as String?,
      adminDecisionReason: json['adminDecisionReason'] as String?,
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? ''),
      approvedAt: DateTime.tryParse(json['approvedAt'] as String? ?? ''),
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'sellerId': sellerId,
        'ownerUserId': ownerUserId,
        'businessName': businessName,
        'legalEntityName': legalEntityName,
        'pickleballFocus': pickleballFocus.name,
        'isPickleballOnlyConfirmed': isPickleballOnlyConfirmed,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'businessAddress': businessAddress,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'gstNumber': gstNumber,
        'panNumber': panNumber,
        'bankAccountHolder': bankAccountHolder,
        'bankAccountLast4': bankAccountLast4,
        'ifscCode': ifscCode,
        'documents': documents
            .map(
              (d) => SellerKycDocumentModel(
                id: d.id,
                type: d.type,
                fileName: d.fileName,
                uploadedAt: d.uploadedAt,
                isVerifiedByStaff: d.isVerifiedByStaff,
                note: d.note,
              ).toJson(),
            )
            .toList(growable: false),
        'verificationStatus': verificationStatus.name,
        'staffRecommendationNote': staffRecommendationNote,
        'adminDecisionReason': adminDecisionReason,
        'submittedAt': submittedAt?.toIso8601String(),
        'approvedAt': approvedAt?.toIso8601String(),
        'isActive': isActive,
      };
}
