import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy_staff/domain/entities/academy_staff_entities.dart';

/// Repository contract for the shared Academy Admin & Staff module.
///
/// Strictly scoped to academy-owned branches, batches, coach connections,
/// students, enrollments, and staff governance. Never exposes coach personal
/// coaching records.
abstract class AcademyRepository {
  Future<Result<AcademyWorkspaceData>> getWorkspaceData({
    required String academyId,
  });

  Future<Result<AcademyWorkspaceData>> createBranch({
    required String academyId,
    required String name,
    String contactPerson = '',
    String city = '',
    required String address,
    String operatingHours = '',
    int courtCount = 0,
    String contactPhone = '',
  });

  Future<Result<AcademyWorkspaceData>> updateBranch({
    required String academyId,
    required String branchId,
    required String name,
    String contactPerson = '',
    String city = '',
    required String address,
    String operatingHours = '',
    int courtCount = 0,
    String contactPhone = '',
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
    String programId = '',
    String? branchId,
    required String name,
    BatchSkillLevel skillLevel = BatchSkillLevel.beginner,
    List<String> daysOfWeek = const ['Mon', 'Wed', 'Fri'],
    String startTime = '06:00 PM',
    String endTime = '07:30 PM',
    String? scheduleLabel,
    required int capacity,
    String? assignedCoachId,
  });

  Future<Result<AcademyWorkspaceData>> updateBatch({
    required String academyId,
    required String batchId,
    required String branchId,
    required String name,
    required BatchSkillLevel skillLevel,
    required List<String> daysOfWeek,
    required String startTime,
    required String endTime,
    required int capacity,
    String? assignedCoachId,
  });

  Future<Result<AcademyWorkspaceData>> assignCoachToBatch({
    required String academyId,
    required String batchId,
    String? coachId,
  });

  Future<Result<AcademyWorkspaceData>> sendCoachConnectionRequest({
    required String academyId,
    required String coachId,
    required List<String> branchIds,
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

  Future<Result<AcademyWorkspaceData>> addStaffMember({
    required String academyId,
    required String name,
    required String email,
    required String phone,
    required String roleTitle,
    required List<String> assignedBranchIds,
    required Set<AcademyStaffPermission> permissions,
  });

  Future<Result<AcademyWorkspaceData>> updateStaffMember({
    required String academyId,
    required String staffId,
    required String roleTitle,
    required List<String> assignedBranchIds,
    required Set<AcademyStaffPermission> permissions,
    required bool isActive,
  });

  Future<Result<AcademyWorkspaceData>> recordStudentAssessment({
    required String academyId,
    required String studentId,
    required String coachId,
    required String coachName,
    required String focusArea,
    required Map<String, int> aspectRatings,
    required String feedback,
  });
}
