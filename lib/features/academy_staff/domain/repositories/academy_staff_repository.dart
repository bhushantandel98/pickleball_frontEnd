import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy_staff/domain/entities/academy_staff_entities.dart';

/// Repository contract for the Academy Staff role module (Phase 3 — Feature 3.6).
///
/// Strictly enforces:
/// 1. Academy ownership (`academyId` must match the staff member's academy).
/// 2. Assigned branch scoping (operations outside `assignedBranchIds` are rejected).
/// 3. Delegated permission checks at the repository boundary.
/// 4. No owner-only operations and no access to coach personal coaching data.
abstract class AcademyStaffRepository {
  Future<Result<AcademyStaffWorkspaceData>> getWorkspaceData({
    required String academyId,
    required String staffId,
  });

  Future<Result<AcademyStaffWorkspaceData>> markAttendance({
    required String academyId,
    required String staffId,
    required String attendanceId,
    required StaffAttendanceStatus status,
    String? notes,
  });

  Future<Result<AcademyStaffWorkspaceData>> updateBatchScheduleLabel({
    required String academyId,
    required String staffId,
    required String batchId,
    required String scheduleLabel,
  });

  Future<Result<AcademyStaffWorkspaceData>> updateEnrollmentStatus({
    required String academyId,
    required String staffId,
    required String enrollmentId,
    required EnrollmentRequestStatus newStatus,
  });

  Future<Result<AcademyStaffWorkspaceData>> recordTuitionPayment({
    required String academyId,
    required String staffId,
    required String enrollmentId,
    required TuitionFeeStatus feeStatus,
  });
}
