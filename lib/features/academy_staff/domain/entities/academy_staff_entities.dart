import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';

/// Delegated permissions assignable to Academy Staff by an Academy Owner/Admin.
///
/// Staff cannot self-escalate permissions and never receive owner-only
/// privileges (branch creation/deletion, coach revocation, or staff role editing).
enum AcademyStaffPermission {
  viewDashboard('View Dashboard'),
  manageAttendance('Mark Attendance'),
  manageBatches('Manage Batch Schedules'),
  manageEnrollments('Review Enrollments'),
  viewStudents('View Students'),
  viewCoaches('View Academy Coaches'),
  recordTuition('Record Tuition Payments');

  final String label;
  const AcademyStaffPermission(this.label);
}

/// Attendance status recorded by Academy Staff for a batch session.
enum StaffAttendanceStatus {
  present('Present'),
  absent('Absent'),
  late('Late'),
  excused('Excused');

  final String label;
  const StaffAttendanceStatus(this.label);
}

/// Academy Staff member profile and delegated scope within a single Academy.
class AcademyStaffProfile extends Equatable {
  final String staffId;
  final String academyId;
  final String academyName;
  final String staffName;
  final String staffEmail;
  final String roleTitle;
  final List<String> assignedBranchIds;
  final List<String> assignedBranchNames;
  final Set<AcademyStaffPermission> permissions;
  final bool isActive;

  const AcademyStaffProfile({
    required this.staffId,
    required this.academyId,
    required this.academyName,
    required this.staffName,
    required this.staffEmail,
    required this.roleTitle,
    required this.assignedBranchIds,
    required this.assignedBranchNames,
    required this.permissions,
    this.isActive = true,
  });

  bool hasPermission(AcademyStaffPermission permission) =>
      isActive && permissions.contains(permission);

  bool canAccessBranch(String branchId) =>
      isActive && assignedBranchIds.contains(branchId);

  @override
  List<Object?> get props => [
        staffId,
        academyId,
        academyName,
        staffName,
        staffEmail,
        roleTitle,
        assignedBranchIds,
        assignedBranchNames,
        permissions,
        isActive,
      ];
}

/// Student attendance record for a specific Academy batch session.
class StaffSessionAttendance extends Equatable {
  final String id;
  final String academyId;
  final String branchId;
  final String branchName;
  final String batchId;
  final String batchName;
  final String studentId;
  final String studentName;
  final DateTime sessionDate;
  final StaffAttendanceStatus status;
  final String? notes;
  final String markedByStaffId;
  final DateTime updatedAt;

  const StaffSessionAttendance({
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

  StaffSessionAttendance copyWith({
    StaffAttendanceStatus? status,
    String? notes,
    String? markedByStaffId,
    DateTime? updatedAt,
  }) {
    return StaffSessionAttendance(
      id: id,
      academyId: academyId,
      branchId: branchId,
      branchName: branchName,
      batchId: batchId,
      batchName: batchName,
      studentId: studentId,
      studentName: studentName,
      sessionDate: sessionDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      markedByStaffId: markedByStaffId ?? this.markedByStaffId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        academyId,
        branchId,
        branchName,
        batchId,
        batchName,
        studentId,
        studentName,
        sessionDate,
        status,
        notes,
        markedByStaffId,
        updatedAt,
      ];
}

/// Daily scheduled batch session visible to assigned Academy Staff.
class StaffBatchScheduleItem extends Equatable {
  final String batchId;
  final String academyId;
  final String branchId;
  final String branchName;
  final String programId;
  final String programTitle;
  final String batchName;
  final String scheduleLabel;
  final String? assignedCoachName;
  final int capacity;
  final int enrolledCount;

  const StaffBatchScheduleItem({
    required this.batchId,
    required this.academyId,
    required this.branchId,
    required this.branchName,
    required this.programId,
    required this.programTitle,
    required this.batchName,
    required this.scheduleLabel,
    this.assignedCoachName,
    required this.capacity,
    required this.enrolledCount,
  });

  @override
  List<Object?> get props => [
        batchId,
        academyId,
        branchId,
        branchName,
        programId,
        programTitle,
        batchName,
        scheduleLabel,
        assignedCoachName,
        capacity,
        enrolledCount,
      ];
}

/// Aggregated Academy Staff workspace payload strictly scoped to the staff
/// member's authorized Academy, assigned branches, and delegated permissions.
class AcademyStaffWorkspaceData extends Equatable {
  final AcademyStaffProfile staffProfile;
  final List<AcademyBranch> assignedBranches;
  final List<AcademyProgram> programs;
  final List<AcademyBatch> batches;
  final List<AcademyCoachAffiliation> coaches;
  final List<AcademyEnrollmentRecord> enrollments;
  final List<StaffSessionAttendance> attendanceRecords;
  final List<StaffBatchScheduleItem> todaySessions;

  const AcademyStaffWorkspaceData({
    required this.staffProfile,
    required this.assignedBranches,
    required this.programs,
    required this.batches,
    required this.coaches,
    required this.enrollments,
    required this.attendanceRecords,
    required this.todaySessions,
  });

  @override
  List<Object?> get props => [
        staffProfile,
        assignedBranches,
        programs,
        batches,
        coaches,
        enrollments,
        attendanceRecords,
        todaySessions,
      ];
}
