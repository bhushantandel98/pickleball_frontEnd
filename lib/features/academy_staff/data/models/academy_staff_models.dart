import 'package:pickleball_platform/features/academy_staff/domain/entities/academy_staff_entities.dart';

/// DTO for [AcademyStaffProfile] API serialization.
class AcademyStaffProfileModel {
  final String staffId;
  final String academyId;
  final String academyName;
  final String staffName;
  final String staffEmail;
  final String roleTitle;
  final List<String> assignedBranchIds;
  final List<String> assignedBranchNames;
  final List<String> permissionCodes;
  final bool isActive;

  const AcademyStaffProfileModel({
    required this.staffId,
    required this.academyId,
    required this.academyName,
    required this.staffName,
    required this.staffEmail,
    required this.roleTitle,
    required this.assignedBranchIds,
    required this.assignedBranchNames,
    required this.permissionCodes,
    required this.isActive,
  });

  factory AcademyStaffProfileModel.fromJson(Map<String, dynamic> json) {
    return AcademyStaffProfileModel(
      staffId: json['staffId'] as String? ?? '',
      academyId: json['academyId'] as String? ?? '',
      academyName: json['academyName'] as String? ?? '',
      staffName: json['staffName'] as String? ?? '',
      staffEmail: json['staffEmail'] as String? ?? '',
      roleTitle: json['roleTitle'] as String? ?? 'Academy Staff',
      assignedBranchIds:
          (json['assignedBranchIds'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      assignedBranchNames:
          (json['assignedBranchNames'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      permissionCodes:
          (json['permissions'] as List<dynamic>? ?? const [])
              .map((e) => e.toString())
              .toList(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  AcademyStaffProfile toEntity() {
    final mappedPermissions = <AcademyStaffPermission>{
      AcademyStaffPermission.viewDashboard,
    };
    for (final code in permissionCodes) {
      for (final perm in AcademyStaffPermission.values) {
        if (perm.name.toLowerCase() == code.toLowerCase()) {
          mappedPermissions.add(perm);
        }
      }
    }
    return AcademyStaffProfile(
      staffId: staffId,
      academyId: academyId,
      academyName: academyName,
      staffName: staffName,
      staffEmail: staffEmail,
      roleTitle: roleTitle,
      assignedBranchIds: assignedBranchIds,
      assignedBranchNames: assignedBranchNames,
      permissions: mappedPermissions,
      isActive: isActive,
    );
  }
}

/// DTO for [StaffSessionAttendance] API serialization.
class StaffSessionAttendanceModel {
  final String id;
  final String academyId;
  final String branchId;
  final String branchName;
  final String batchId;
  final String batchName;
  final String studentId;
  final String studentName;
  final DateTime sessionDate;
  final String status;
  final String? notes;
  final String markedByStaffId;
  final DateTime updatedAt;

  const StaffSessionAttendanceModel({
    required this.id,
    required this.academyId,
    required this.branchId,
    required this.branchName,
    required this.batchId,
    required this.batchName,
    required this.studentId,
    required this.studentName,
    required this.sessionDate,
    required this.status,
    this.notes,
    required this.markedByStaffId,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'academyId': academyId,
        'branchId': branchId,
        'branchName': branchName,
        'batchId': batchId,
        'batchName': batchName,
        'studentId': studentId,
        'studentName': studentName,
        'sessionDate': sessionDate.toIso8601String(),
        'status': status,
        'notes': notes,
        'markedByStaffId': markedByStaffId,
        'updatedAt': updatedAt.toIso8601String(),
      };
}
