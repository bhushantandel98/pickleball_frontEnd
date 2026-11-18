import 'package:pickleball_platform/features/application_admin/domain/entities/application_admin_entities.dart';

class AdminApprovalItemModel extends AdminApprovalItem {
  const AdminApprovalItemModel({
    required super.id,
    required super.targetType,
    required super.targetId,
    required super.organizationId,
    required super.organizationName,
    required super.subjectTitle,
    required super.summary,
    super.staffRecommendationNote,
    super.recommendedByStaffId,
    required super.submittedAt,
    required super.status,
    super.decisionReason,
    super.decidedAt,
  });

  factory AdminApprovalItemModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['targetType'] as String? ?? 'sellerVerification';
    final targetType = AdminApprovalTargetType.values.firstWhere(
      (t) => t.name == rawType,
      orElse: () => AdminApprovalTargetType.sellerVerification,
    );
    final rawStatus = json['status'] as String? ?? 'pendingAdminDecision';
    final status = AdminApprovalStatus.values.firstWhere(
      (s) => s.name == rawStatus,
      orElse: () => AdminApprovalStatus.pendingAdminDecision,
    );

    return AdminApprovalItemModel(
      id: json['id'] as String? ?? '',
      targetType: targetType,
      targetId: json['targetId'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? '',
      organizationName: json['organizationName'] as String? ?? '',
      subjectTitle: json['subjectTitle'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      staffRecommendationNote: json['staffRecommendationNote'] as String?,
      recommendedByStaffId: json['recommendedByStaffId'] as String?,
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? '') ??
          DateTime.now(),
      status: status,
      decisionReason: json['decisionReason'] as String?,
      decidedAt: DateTime.tryParse(json['decidedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'targetType': targetType.name,
        'targetId': targetId,
        'organizationId': organizationId,
        'organizationName': organizationName,
        'subjectTitle': subjectTitle,
        'summary': summary,
        'staffRecommendationNote': staffRecommendationNote,
        'recommendedByStaffId': recommendedByStaffId,
        'submittedAt': submittedAt.toIso8601String(),
        'status': status.name,
        'decisionReason': decisionReason,
        'decidedAt': decidedAt?.toIso8601String(),
      };
}

class AdminCommissionPolicyModel extends AdminCommissionPolicy {
  const AdminCommissionPolicyModel({
    required super.policyId,
    super.defaultCommissionRatePercent,
    required super.minReturnWindowDays,
    required super.maxReturnWindowDays,
    super.pickleballOnlyEnforced,
    required super.version,
    required super.updatedByAdminId,
    required super.updatedAt,
  });

  factory AdminCommissionPolicyModel.fromJson(Map<String, dynamic> json) {
    return AdminCommissionPolicyModel(
      policyId: json['policyId'] as String? ?? 'policy_default',
      defaultCommissionRatePercent:
          (json['defaultCommissionRatePercent'] as num?)?.toDouble(),
      minReturnWindowDays:
          (json['minReturnWindowDays'] as num?)?.toInt() ?? 0,
      maxReturnWindowDays:
          (json['maxReturnWindowDays'] as num?)?.toInt() ?? 30,
      pickleballOnlyEnforced:
          json['pickleballOnlyEnforced'] as bool? ?? true,
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedByAdminId: json['updatedByAdminId'] as String? ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'policyId': policyId,
        'defaultCommissionRatePercent': defaultCommissionRatePercent,
        'minReturnWindowDays': minReturnWindowDays,
        'maxReturnWindowDays': maxReturnWindowDays,
        'pickleballOnlyEnforced': pickleballOnlyEnforced,
        'version': version,
        'updatedByAdminId': updatedByAdminId,
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class AdminAuditLogEntryModel extends AdminAuditLogEntry {
  const AdminAuditLogEntryModel({
    required super.id,
    required super.timestamp,
    required super.actorUserId,
    required super.actorRole,
    required super.action,
    required super.targetType,
    required super.targetId,
    required super.organizationId,
    required super.detail,
  });

  factory AdminAuditLogEntryModel.fromJson(Map<String, dynamic> json) {
    return AdminAuditLogEntryModel(
      id: json['id'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      actorUserId: json['actorUserId'] as String? ?? '',
      actorRole: json['actorRole'] as String? ?? 'Application Admin',
      action: json['action'] as String? ?? '',
      targetType: json['targetType'] as String? ?? '',
      targetId: json['targetId'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? '',
      detail: json['detail'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'actorUserId': actorUserId,
        'actorRole': actorRole,
        'action': action,
        'targetType': targetType,
        'targetId': targetId,
        'organizationId': organizationId,
        'detail': detail,
      };
}
