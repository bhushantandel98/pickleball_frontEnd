import 'package:pickleball_platform/features/venue_staff/domain/entities/venue_staff_entities.dart';

/// DTO for [VenueStaffProfile] API serialization.
class VenueStaffProfileModel {
  final String staffId;
  final String partnerId;
  final String partnerName;
  final String staffName;
  final String staffEmail;
  final String roleTitle;
  final List<String> assignedLocationIds;
  final List<String> assignedLocationNames;
  final List<String> permissionCodes;
  final bool isActive;

  const VenueStaffProfileModel({
    required this.staffId,
    required this.partnerId,
    required this.partnerName,
    required this.staffName,
    required this.staffEmail,
    required this.roleTitle,
    required this.assignedLocationIds,
    required this.assignedLocationNames,
    required this.permissionCodes,
    required this.isActive,
  });

  factory VenueStaffProfileModel.fromJson(Map<String, dynamic> json) {
    return VenueStaffProfileModel(
      staffId: json['staffId'] as String? ?? '',
      partnerId: json['partnerId'] as String? ?? '',
      partnerName: json['partnerName'] as String? ?? '',
      staffName: json['staffName'] as String? ?? '',
      staffEmail: json['staffEmail'] as String? ?? '',
      roleTitle: json['roleTitle'] as String? ?? 'Venue Staff',
      assignedLocationIds:
          (json['assignedLocationIds'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      assignedLocationNames:
          (json['assignedLocationNames'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      permissionCodes:
          (json['permissions'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static String _normalizePermissionCode(String code) {
    return code.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  VenueStaffProfile toEntity() {
    final mappedPermissions = <VenueStaffPermission>{};
    for (final code in permissionCodes) {
      final normalizedCode = _normalizePermissionCode(code);
      if (normalizedCode.isEmpty) continue;
      for (final perm in VenueStaffPermission.values) {
        if (_normalizePermissionCode(perm.name) == normalizedCode) {
          mappedPermissions.add(perm);
        }
      }
    }

    return VenueStaffProfile(
      staffId: staffId,
      partnerId: partnerId,
      partnerName: partnerName,
      staffName: staffName,
      staffEmail: staffEmail,
      roleTitle: roleTitle,
      assignedLocationIds: assignedLocationIds,
      assignedLocationNames: assignedLocationNames,
      permissions: mappedPermissions,
      isActive: isActive,
    );
  }
}

/// DTO for [VenuePurchaseSubmission] API serialization.
class VenuePurchaseSubmissionModel {
  final String id;
  final String partnerId;
  final String locationId;
  final String title;
  final String category;
  final double amountInr;
  final String receiptReference;
  final String submittedByStaffId;
  final DateTime submittedAt;

  const VenuePurchaseSubmissionModel({
    required this.id,
    required this.partnerId,
    required this.locationId,
    required this.title,
    required this.category,
    required this.amountInr,
    required this.receiptReference,
    required this.submittedByStaffId,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'partnerId': partnerId,
        'locationId': locationId,
        'title': title,
        'category': category,
        'amountInr': amountInr,
        'receiptReference': receiptReference,
        'submittedByStaffId': submittedByStaffId,
        'submittedAt': submittedAt.toIso8601String(),
      };
}
