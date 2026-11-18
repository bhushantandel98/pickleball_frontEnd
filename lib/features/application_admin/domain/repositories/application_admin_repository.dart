import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/application_admin/domain/entities/application_admin_entities.dart';
import 'package:pickleball_platform/features/application_staff/domain/entities/application_staff_entities.dart';

/// Repository contract for Feature 7.2 — Application Admin Dashboard &
/// Governance.
///
/// Enforces single Application Admin authorization (ADR-007) at the
/// repository level. Application Staff and non-admin users are rejected.
abstract class ApplicationAdminRepository {
  Future<Result<ApplicationAdminDashboardSummary>> getAdminDashboard({
    required String adminUserId,
  });

  Future<Result<List<AdminApprovalItem>>> getApprovalQueue({
    required String adminUserId,
    AdminApprovalTargetType? targetType,
    AdminApprovalStatus? status,
  });

  /// Grants final `approved`, `rejected`, or `needsInformation` decision for a
  /// pending seller or product item. Requires a non-empty audit [reason].
  Future<Result<AdminApprovalItem>> decideApprovalItem({
    required String adminUserId,
    required String itemId,
    required AdminApprovalStatus decision,
    required String reason,
  });

  Future<Result<List<ApplicationStaffProfile>>> getManagedStaff({
    required String adminUserId,
  });

  /// Updates an existing Application Staff member's delegated permissions,
  /// authorized organization scope, and active status. Cannot create or
  /// elevate Application Admin accounts (ADR-007).
  Future<Result<ApplicationStaffProfile>> updateStaffAccess({
    required String adminUserId,
    required String staffId,
    required Set<ApplicationStaffPermission> permissions,
    required Set<String> authorizedOrganizationIds,
    required bool isActive,
  });

  Future<Result<AdminCommissionPolicy>> getCommissionPolicy({
    required String adminUserId,
  });

  Future<Result<AdminCommissionPolicy>> updateCommissionPolicy({
    required String adminUserId,
    required double? defaultCommissionRatePercent,
    required int minReturnWindowDays,
    required int maxReturnWindowDays,
  });

  Future<Result<List<AdminAuditLogEntry>>> getAuditLogs({
    required String adminUserId,
    String? query,
  });
}
