import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';

/// Repository contract for the Academy role module (Phase 3 — Feature 3.5).
///
/// Strictly scoped to academy-owned branches, programs, batches, coach
/// affiliations, and student enrollments/tuition. Never exposes coach personal
/// coaching records.
abstract class AcademyRepository {
  Future<Result<AcademyWorkspaceData>> getWorkspaceData({
    required String academyId,
  });

  Future<Result<AcademyWorkspaceData>> createBranch({
    required String academyId,
    required String name,
    required String city,
    required String address,
    required String operatingHours,
    required int courtCount,
    required String contactPhone,
  });

  Future<Result<AcademyWorkspaceData>> updateBranch({
    required String academyId,
    required String branchId,
    required String name,
    required String city,
    required String address,
    required String operatingHours,
    required int courtCount,
    required String contactPhone,
  });

  Future<Result<AcademyWorkspaceData>> toggleBranchStatus({
    required String academyId,
    required String branchId,
    required bool isActive,
  });

  Future<Result<AcademyWorkspaceData>> createProgram({
    required String academyId,
    required String branchId,
    required String title,
    required String skillLevel,
    required String ageGroup,
    required String description,
    required double monthlyTuitionInr,
  });

  Future<Result<AcademyWorkspaceData>> toggleProgramStatus({
    required String academyId,
    required String programId,
    required bool isActive,
  });

  Future<Result<AcademyWorkspaceData>> createBatch({
    required String academyId,
    required String programId,
    required String name,
    required String scheduleLabel,
    required int capacity,
    String? assignedCoachId,
  });

  Future<Result<AcademyWorkspaceData>> inviteCoach({
    required String academyId,
    required String coachName,
    required String coachContact,
    required String specialization,
    required List<String> branchIds,
    required bool canModifyOfficialSchedule,
  });

  Future<Result<AcademyWorkspaceData>> updateCoachAssignment({
    required String academyId,
    required String affiliationId,
    required List<String> branchIds,
    required bool canModifyOfficialSchedule,
  });

  Future<Result<AcademyWorkspaceData>> revokeCoachAffiliation({
    required String academyId,
    required String affiliationId,
  });

  Future<Result<AcademyWorkspaceData>> updateEnrollmentStatus({
    required String academyId,
    required String enrollmentId,
    required EnrollmentRequestStatus newStatus,
  });

  Future<Result<AcademyWorkspaceData>> recordTuitionPayment({
    required String academyId,
    required String enrollmentId,
    required TuitionFeeStatus feeStatus,
  });
}
