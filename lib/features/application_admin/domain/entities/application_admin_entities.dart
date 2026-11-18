import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/application_staff/domain/entities/application_staff_entities.dart';

/// Target domain of a final Application Admin governance decision.
enum AdminApprovalTargetType {
  sellerVerification('Seller Verification'),
  productCatalog('Product Catalog');

  final String label;
  const AdminApprovalTargetType(this.label);
}

/// Final governance decision statuses controlled exclusively by the single
/// Application Admin.
enum AdminApprovalStatus {
  pendingAdminDecision('Pending Admin Decision'),
  needsInformation('Needs Information'),
  approved('Approved'),
  rejected('Rejected');

  final String label;
  const AdminApprovalStatus(this.label);

  bool get isDecidable => this == AdminApprovalStatus.pendingAdminDecision;
}

/// Seller or Product item awaiting final Application Admin decision.
class AdminApprovalItem extends Equatable {
  final String id;
  final AdminApprovalTargetType targetType;
  final String targetId;
  final String organizationId;
  final String organizationName;
  final String subjectTitle;
  final String summary;
  final String? staffRecommendationNote;
  final String? recommendedByStaffId;
  final DateTime submittedAt;
  final AdminApprovalStatus status;
  final String? decisionReason;
  final DateTime? decidedAt;

  const AdminApprovalItem({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.organizationId,
    required this.organizationName,
    required this.subjectTitle,
    required this.summary,
    this.staffRecommendationNote,
    this.recommendedByStaffId,
    required this.submittedAt,
    required this.status,
    this.decisionReason,
    this.decidedAt,
  });

  AdminApprovalItem copyWith({
    AdminApprovalStatus? status,
    String? decisionReason,
    DateTime? decidedAt,
  }) {
    return AdminApprovalItem(
      id: id,
      targetType: targetType,
      targetId: targetId,
      organizationId: organizationId,
      organizationName: organizationName,
      subjectTitle: subjectTitle,
      summary: summary,
      staffRecommendationNote: staffRecommendationNote,
      recommendedByStaffId: recommendedByStaffId,
      submittedAt: submittedAt,
      status: status ?? this.status,
      decisionReason: decisionReason ?? this.decisionReason,
      decidedAt: decidedAt ?? this.decidedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        targetType,
        targetId,
        organizationId,
        organizationName,
        subjectTitle,
        summary,
        staffRecommendationNote,
        recommendedByStaffId,
        submittedAt,
        status,
        decisionReason,
        decidedAt,
      ];
}

/// Platform-wide marketplace commission & return-window policy controlled
/// exclusively by the single Application Admin.
class AdminCommissionPolicy extends Equatable {
  final String policyId;
  final double? defaultCommissionRatePercent;
  final int minReturnWindowDays;
  final int maxReturnWindowDays;
  final bool pickleballOnlyEnforced;
  final int version;
  final String updatedByAdminId;
  final DateTime updatedAt;

  const AdminCommissionPolicy({
    required this.policyId,
    this.defaultCommissionRatePercent,
    required this.minReturnWindowDays,
    required this.maxReturnWindowDays,
    this.pickleballOnlyEnforced = true,
    required this.version,
    required this.updatedByAdminId,
    required this.updatedAt,
  });

  bool get isCommissionConfigured => defaultCommissionRatePercent != null;

  @override
  List<Object?> get props => [
        policyId,
        defaultCommissionRatePercent,
        minReturnWindowDays,
        maxReturnWindowDays,
        pickleballOnlyEnforced,
        version,
        updatedByAdminId,
        updatedAt,
      ];
}

/// Immutable audit log entry for Application Admin governance actions.
class AdminAuditLogEntry extends Equatable {
  final String id;
  final DateTime timestamp;
  final String actorUserId;
  final String actorRole;
  final String action;
  final String targetType;
  final String targetId;
  final String organizationId;
  final String detail;

  const AdminAuditLogEntry({
    required this.id,
    required this.timestamp,
    required this.actorUserId,
    required this.actorRole,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.organizationId,
    required this.detail,
  });

  @override
  List<Object?> get props => [
        id,
        timestamp,
        actorUserId,
        actorRole,
        action,
        targetType,
        targetId,
        organizationId,
        detail,
      ];
}

/// Aggregated summary for the Application Admin Macro Dashboard.
class ApplicationAdminDashboardSummary extends Equatable {
  final String adminUserId;
  final String adminName;
  final String adminEmail;
  final int pendingSellerApprovals;
  final int pendingProductApprovals;
  final int activeStaffCount;
  final int totalStaffCount;
  final int auditLogCount;
  final AdminCommissionPolicy policy;
  final List<AdminApprovalItem> recentApprovals;
  final List<ApplicationStaffProfile> staffProfiles;

  const ApplicationAdminDashboardSummary({
    required this.adminUserId,
    required this.adminName,
    required this.adminEmail,
    required this.pendingSellerApprovals,
    required this.pendingProductApprovals,
    required this.activeStaffCount,
    required this.totalStaffCount,
    required this.auditLogCount,
    required this.policy,
    required this.recentApprovals,
    required this.staffProfiles,
  });

  @override
  List<Object?> get props => [
        adminUserId,
        adminName,
        adminEmail,
        pendingSellerApprovals,
        pendingProductApprovals,
        activeStaffCount,
        totalStaffCount,
        auditLogCount,
        policy,
        recentApprovals,
        staffProfiles,
      ];
}
