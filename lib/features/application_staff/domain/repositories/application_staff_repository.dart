import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/application_staff/domain/entities/application_staff_entities.dart';

/// Repository contract for Feature 7.1 — Application Staff Dashboard &
/// Operations.
///
/// Enforces active staff membership, delegated [ApplicationStaffPermission]
/// checks, organization-level data boundaries, and strict separation from
/// Application Admin-only final approval, policy, and payout operations.
abstract class ApplicationStaffRepository {
  /// Fetches the authenticated staff member's profile and permission-scoped
  /// dashboard summary.
  Future<Result<ApplicationStaffDashboardSummary>> getStaffDashboard({
    required String userId,
    String? staffId,
  });

  /// Lists operational queue items visible under the staff member's delegated
  /// permissions, optionally filtered by [category], [status], or [query].
  Future<Result<List<StaffOperationalQueueItem>>> getOperationalQueue({
    required String userId,
    StaffQueueCategory? category,
    StaffQueueItemStatus? status,
    String? query,
  });

  /// Records a staff triage/review action (`needsInformation`,
  /// `recommendedToAdmin`, `escalatedToAdmin`, or `resolved` for support).
  ///
  /// Enforces delegated permissions and prevents Application Staff from
  /// performing Application Admin-only final approvals.
  Future<Result<StaffOperationalQueueItem>> updateQueueItemStatus({
    required String userId,
    required String itemId,
    required StaffQueueItemStatus nextStatus,
    required String note,
  });
}
