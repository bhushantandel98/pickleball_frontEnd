import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/application_admin/data/models/application_admin_models.dart';
import 'package:pickleball_platform/features/application_admin/domain/entities/application_admin_entities.dart';
import 'package:pickleball_platform/features/application_admin/domain/repositories/application_admin_repository.dart';
import 'package:pickleball_platform/features/application_staff/data/models/application_staff_models.dart';
import 'package:pickleball_platform/features/application_staff/domain/entities/application_staff_entities.dart';

/// Mock implementation of [ApplicationAdminRepository] for Feature 7.2.
///
/// Enforces:
/// - Sole Application Admin authorization (`user_app_admin_001`, ADR-007).
/// - Strict separation from Application Staff (staff users are rejected).
/// - Valid final approval/rejection transitions (`pendingAdminDecision` ->
///   `approved` / `rejected` / `needsInformation`).
/// - Immutable governance audit logging for every Admin mutation.
class MockApplicationAdminRepository implements ApplicationAdminRepository {
  static const String _soleAdminUserId = 'user_app_admin_001';
  static const String _demoAllRolesUserId = 'user_all_12_roles';
  static const String _soleAdminName = 'Platform Administrator';
  static const String _soleAdminEmail = 'root-admin@platform.internal';

  int _nextAuditSeq = 10;

  final List<AdminApprovalItemModel> _approvalItems = [
    AdminApprovalItemModel(
      id: 'adm_appr_001',
      targetType: AdminApprovalTargetType.sellerVerification,
      targetId: 'org_seller_001',
      organizationId: 'org_seller_001',
      organizationName: 'Apex Pickleball Gear Co.',
      subjectTitle: 'Seller Verification — Apex Pickleball Gear Co.',
      summary:
          'Private Limited seller (Mumbai). GSTIN, PAN, and pickleball-only declaration attached for final Admin sign-off.',
      staffRecommendationNote:
          'Application Staff verified GST/PAN format and recommended conditional review once address proof is confirmed.',
      recommendedByStaffId: 'app_staff_001',
      submittedAt: DateTime(2026, 11, 14, 11, 0),
      status: AdminApprovalStatus.pendingAdminDecision,
    ),
    AdminApprovalItemModel(
      id: 'adm_appr_002',
      targetType: AdminApprovalTargetType.productCatalog,
      targetId: 'sp_006',
      organizationId: 'org_seller_002',
      organizationName: 'Dink & Smash Pro Shop',
      subjectTitle: 'Product Approval — CourtGrip Pro Non-Marking Pickleball Shoes',
      summary:
          'Staff-recommended pickleball court footwear (SKU: DS-SHOE-PRO). Admin approval keeps product Unpublished until seller publishes.',
      staffRecommendationNote:
          'Pickleball suitability and SKU metadata verified by Staff. Recommended to Application Admin.',
      recommendedByStaffId: 'app_staff_001',
      submittedAt: DateTime(2026, 11, 13, 10, 15),
      status: AdminApprovalStatus.pendingAdminDecision,
    ),
    AdminApprovalItemModel(
      id: 'adm_appr_003',
      targetType: AdminApprovalTargetType.productCatalog,
      targetId: 'sp_001',
      organizationId: 'org_seller_002',
      organizationName: 'Dink & Smash Pro Shop',
      subjectTitle: 'Product Approval — Vortex T700 Raw Carbon Paddle',
      summary: 'USAPA-approved T700 carbon fiber pickleball paddle.',
      staffRecommendationNote: 'Specs and imagery verified.',
      recommendedByStaffId: 'app_staff_001',
      submittedAt: DateTime(2026, 11, 6, 11, 0),
      status: AdminApprovalStatus.approved,
      decisionReason:
          'Approved for marketplace listing. Seller controls publish visibility.',
      decidedAt: DateTime(2026, 11, 7, 15, 30),
    ),
  ];

  final List<ApplicationStaffProfileModel> _managedStaff = [
    ApplicationStaffProfileModel(
      staffId: 'app_staff_001',
      userId: 'user_app_staff_001',
      organizationScopeId: 'platform_ops_in',
      authorizedOrganizationIds: const {
        'org_seller_001',
        'org_seller_002',
        'org_venue_001',
        'org_acad_001',
      },
      staffName: 'Elena Rostova',
      staffEmail: 'elena.rostova@platform-staff.com',
      roleTitle: 'Senior Marketplace & Operations Reviewer',
      permissions: const {
        ApplicationStaffPermission.viewDashboard,
        ApplicationStaffPermission.reviewSellers,
        ApplicationStaffPermission.reviewProducts,
        ApplicationStaffPermission.handleSupportTickets,
        ApplicationStaffPermission.monitorPlatformHealth,
      },
      isActive: true,
      assignedAt: DateTime(2024, 11, 1),
    ),
    ApplicationStaffProfileModel(
      staffId: 'app_staff_002',
      userId: 'user_app_staff_002',
      organizationScopeId: 'platform_ops_in',
      authorizedOrganizationIds: const {'org_venue_001'},
      staffName: 'Karan Mehta',
      staffEmail: 'karan.mehta@platform-staff.com',
      roleTitle: 'Support Triage Specialist',
      permissions: const {
        ApplicationStaffPermission.viewDashboard,
        ApplicationStaffPermission.handleSupportTickets,
      },
      isActive: true,
      assignedAt: DateTime(2025, 4, 15),
    ),
  ];

  AdminCommissionPolicyModel _policy = AdminCommissionPolicyModel(
    policyId: 'policy_marketplace_v1',
    defaultCommissionRatePercent: null,
    minReturnWindowDays: 0,
    maxReturnWindowDays: 30,
    pickleballOnlyEnforced: true,
    version: 1,
    updatedByAdminId: _soleAdminUserId,
    updatedAt: DateTime(2026, 11, 1, 9, 0),
  );

  final List<AdminAuditLogEntryModel> _auditLogs = [
    AdminAuditLogEntryModel(
      id: 'audit_001',
      timestamp: DateTime(2026, 11, 7, 15, 30),
      actorUserId: _soleAdminUserId,
      actorRole: 'Application Admin',
      action: 'APPROVE_PRODUCT',
      targetType: 'productCatalog',
      targetId: 'sp_001',
      organizationId: 'org_seller_002',
      detail:
          'Approved Vortex T700 Raw Carbon Paddle (seller controls publishing).',
    ),
    AdminAuditLogEntryModel(
      id: 'audit_002',
      timestamp: DateTime(2026, 11, 5, 14, 0),
      actorUserId: _soleAdminUserId,
      actorRole: 'Application Admin',
      action: 'APPROVE_SELLER',
      targetType: 'sellerVerification',
      targetId: 'org_seller_002',
      organizationId: 'org_seller_002',
      detail: 'Verified seller organization Dink & Smash Pro Shop.',
    ),
  ];

  Result<String> _requireSoleAdmin(String adminUserId) {
    final normalized = adminUserId.trim();
    if (normalized != _soleAdminUserId && normalized != _demoAllRolesUserId) {
      return const FailureResult(
        ForbiddenFailure(
          message:
              'Forbidden: Only the single Application Admin account is authorized for this governance action.',
        ),
      );
    }
    return Success(adminUserId.trim());
  }

  void _appendAudit({
    required String adminUserId,
    required String action,
    required String targetType,
    required String targetId,
    required String organizationId,
    required String detail,
  }) {
    _auditLogs.insert(
      0,
      AdminAuditLogEntryModel(
        id: 'audit_${++_nextAuditSeq}',
        timestamp: DateTime.now(),
        actorUserId: adminUserId,
        actorRole: 'Application Admin',
        action: action,
        targetType: targetType,
        targetId: targetId,
        organizationId: organizationId,
        detail: detail,
      ),
    );
  }

  @override
  Future<Result<ApplicationAdminDashboardSummary>> getAdminDashboard({
    required String adminUserId,
  }) async {
    final auth = _requireSoleAdmin(adminUserId);
    if (auth is FailureResult<String>) return FailureResult(auth.failure);

    final pendingSellers = _approvalItems
        .where(
          (i) =>
              i.targetType == AdminApprovalTargetType.sellerVerification &&
              i.status == AdminApprovalStatus.pendingAdminDecision,
        )
        .length;
    final pendingProducts = _approvalItems
        .where(
          (i) =>
              i.targetType == AdminApprovalTargetType.productCatalog &&
              i.status == AdminApprovalStatus.pendingAdminDecision,
        )
        .length;
    final activeStaff = _managedStaff.where((s) => s.isActive).length;

    return Success(
      ApplicationAdminDashboardSummary(
        adminUserId: _soleAdminUserId,
        adminName: _soleAdminName,
        adminEmail: _soleAdminEmail,
        pendingSellerApprovals: pendingSellers,
        pendingProductApprovals: pendingProducts,
        activeStaffCount: activeStaff,
        totalStaffCount: _managedStaff.length,
        auditLogCount: _auditLogs.length,
        policy: _policy,
        recentApprovals: List<AdminApprovalItem>.unmodifiable(_approvalItems),
        staffProfiles: List<ApplicationStaffProfile>.unmodifiable(_managedStaff),
      ),
    );
  }

  @override
  Future<Result<List<AdminApprovalItem>>> getApprovalQueue({
    required String adminUserId,
    AdminApprovalTargetType? targetType,
    AdminApprovalStatus? status,
  }) async {
    final auth = _requireSoleAdmin(adminUserId);
    if (auth is FailureResult<String>) return FailureResult(auth.failure);

    var list = _approvalItems.toList();
    if (targetType != null) {
      list = list.where((i) => i.targetType == targetType).toList();
    }
    if (status != null) {
      list = list.where((i) => i.status == status).toList();
    }
    list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return Success(List<AdminApprovalItem>.unmodifiable(list));
  }

  @override
  Future<Result<AdminApprovalItem>> decideApprovalItem({
    required String adminUserId,
    required String itemId,
    required AdminApprovalStatus decision,
    required String reason,
  }) async {
    final auth = _requireSoleAdmin(adminUserId);
    if (auth is FailureResult<String>) return FailureResult(auth.failure);

    if (decision == AdminApprovalStatus.pendingAdminDecision) {
      return const FailureResult(
        ValidationFailure(
          message: 'Select Approved, Rejected, or Needs Information.',
        ),
      );
    }

    final trimmedReason = reason.trim();
    if (trimmedReason.length < 5) {
      return const FailureResult(
        ValidationFailure(
          message: 'Provide a clear governance reason (at least 5 characters).',
        ),
      );
    }

    final idx = _approvalItems.indexWhere((i) => i.id == itemId);
    if (idx == -1) {
      return const FailureResult(
        NotFoundFailure(message: 'Approval item not found.'),
      );
    }

    final existing = _approvalItems[idx];
    if (!existing.status.isDecidable) {
      return FailureResult(
        ValidationFailure(
          message:
              'Item is already in status "${existing.status.label}" and cannot be re-decided.',
        ),
      );
    }

    final now = DateTime.now();
    final updated = AdminApprovalItemModel(
      id: existing.id,
      targetType: existing.targetType,
      targetId: existing.targetId,
      organizationId: existing.organizationId,
      organizationName: existing.organizationName,
      subjectTitle: existing.subjectTitle,
      summary: existing.summary,
      staffRecommendationNote: existing.staffRecommendationNote,
      recommendedByStaffId: existing.recommendedByStaffId,
      submittedAt: existing.submittedAt,
      status: decision,
      decisionReason: trimmedReason,
      decidedAt: now,
    );
    _approvalItems[idx] = updated;

    _appendAudit(
      adminUserId: adminUserId,
      action: '${decision.name.toUpperCase()}_${existing.targetType.name.toUpperCase()}',
      targetType: existing.targetType.name,
      targetId: existing.targetId,
      organizationId: existing.organizationId,
      detail: '${existing.subjectTitle}: $trimmedReason',
    );

    return Success(updated);
  }

  @override
  Future<Result<List<ApplicationStaffProfile>>> getManagedStaff({
    required String adminUserId,
  }) async {
    final auth = _requireSoleAdmin(adminUserId);
    if (auth is FailureResult<String>) return FailureResult(auth.failure);
    return Success(List<ApplicationStaffProfile>.unmodifiable(_managedStaff));
  }

  @override
  Future<Result<ApplicationStaffProfile>> updateStaffAccess({
    required String adminUserId,
    required String staffId,
    required Set<ApplicationStaffPermission> permissions,
    required Set<String> authorizedOrganizationIds,
    required bool isActive,
  }) async {
    final auth = _requireSoleAdmin(adminUserId);
    if (auth is FailureResult<String>) return FailureResult(auth.failure);

    final idx = _managedStaff.indexWhere((s) => s.staffId == staffId);
    if (idx == -1) {
      return const FailureResult(
        NotFoundFailure(message: 'Application Staff member not found.'),
      );
    }

    final cleanedOrgs = authorizedOrganizationIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (isActive && permissions.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Active Application Staff must retain at least one permission.',
        ),
      );
    }

    final existing = _managedStaff[idx];
    final updated = ApplicationStaffProfileModel(
      staffId: existing.staffId,
      userId: existing.userId,
      organizationScopeId: existing.organizationScopeId,
      authorizedOrganizationIds: cleanedOrgs,
      staffName: existing.staffName,
      staffEmail: existing.staffEmail,
      roleTitle: existing.roleTitle,
      permissions: Set<ApplicationStaffPermission>.unmodifiable(permissions),
      isActive: isActive,
      assignedAt: existing.assignedAt,
    );
    _managedStaff[idx] = updated;

    _appendAudit(
      adminUserId: adminUserId,
      action: 'UPDATE_STAFF_ACCESS',
      targetType: 'applicationStaff',
      targetId: existing.staffId,
      organizationId: existing.organizationScopeId,
      detail:
          'Updated ${existing.staffName}: active=$isActive, permissions=${permissions.length}, orgScopes=${cleanedOrgs.length}',
    );

    return Success(updated);
  }

  @override
  Future<Result<AdminCommissionPolicy>> getCommissionPolicy({
    required String adminUserId,
  }) async {
    final auth = _requireSoleAdmin(adminUserId);
    if (auth is FailureResult<String>) return FailureResult(auth.failure);
    return Success(_policy);
  }

  @override
  Future<Result<AdminCommissionPolicy>> updateCommissionPolicy({
    required String adminUserId,
    required double? defaultCommissionRatePercent,
    required int minReturnWindowDays,
    required int maxReturnWindowDays,
  }) async {
    final auth = _requireSoleAdmin(adminUserId);
    if (auth is FailureResult<String>) return FailureResult(auth.failure);

    if (defaultCommissionRatePercent != null &&
        (defaultCommissionRatePercent < 0 ||
            defaultCommissionRatePercent > 50)) {
      return const FailureResult(
        ValidationFailure(
          message: 'Commission rate must be between 0% and 50%.',
        ),
      );
    }
    if (minReturnWindowDays < 0 ||
        maxReturnWindowDays > 60 ||
        minReturnWindowDays > maxReturnWindowDays) {
      return const FailureResult(
        ValidationFailure(
          message:
              'Return window bounds must satisfy 0 <= min <= max <= 60 days.',
        ),
      );
    }

    final updated = AdminCommissionPolicyModel(
      policyId: _policy.policyId,
      defaultCommissionRatePercent: defaultCommissionRatePercent,
      minReturnWindowDays: minReturnWindowDays,
      maxReturnWindowDays: maxReturnWindowDays,
      pickleballOnlyEnforced: true,
      version: _policy.version + 1,
      updatedByAdminId: adminUserId,
      updatedAt: DateTime.now(),
    );
    _policy = updated;

    _appendAudit(
      adminUserId: adminUserId,
      action: 'UPDATE_COMMISSION_POLICY',
      targetType: 'platformPolicy',
      targetId: updated.policyId,
      organizationId: 'platform_global',
      detail:
          'Policy v${updated.version}: commission=${defaultCommissionRatePercent != null ? '${defaultCommissionRatePercent.toStringAsFixed(1)}%' : 'Not configured'}, returnWindow=$minReturnWindowDays-$maxReturnWindowDays days (applies to future orders only).',
    );

    return Success(updated);
  }

  @override
  Future<Result<List<AdminAuditLogEntry>>> getAuditLogs({
    required String adminUserId,
    String? query,
  }) async {
    final auth = _requireSoleAdmin(adminUserId);
    if (auth is FailureResult<String>) return FailureResult(auth.failure);

    var list = _auditLogs.toList();
    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      list = list.where((e) {
        return e.action.toLowerCase().contains(q) ||
            e.targetId.toLowerCase().contains(q) ||
            e.organizationId.toLowerCase().contains(q) ||
            e.detail.toLowerCase().contains(q);
      }).toList();
    }
    return Success(List<AdminAuditLogEntry>.unmodifiable(list));
  }
}
