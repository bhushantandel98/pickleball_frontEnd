import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/application_admin/domain/entities/application_admin_entities.dart';
import 'package:pickleball_platform/features/application_staff/domain/entities/application_staff_entities.dart';

abstract class ApplicationAdminState extends Equatable {
  const ApplicationAdminState();

  @override
  List<Object?> get props => [];
}

class ApplicationAdminInitial extends ApplicationAdminState {
  const ApplicationAdminInitial();
}

class ApplicationAdminLoading extends ApplicationAdminState {
  const ApplicationAdminLoading();
}

class ApplicationAdminLoaded extends ApplicationAdminState {
  final ApplicationAdminDashboardSummary summary;
  final List<AdminApprovalItem> approvals;
  final List<ApplicationStaffProfile> staffProfiles;
  final List<AdminAuditLogEntry> auditLogs;
  final AdminApprovalTargetType? filterTargetType;
  final AdminApprovalStatus? filterStatus;
  final String auditQuery;
  final bool isMutating;
  final String? feedbackMessage;
  final String? errorMessage;

  const ApplicationAdminLoaded({
    required this.summary,
    required this.approvals,
    required this.staffProfiles,
    required this.auditLogs,
    this.filterTargetType,
    this.filterStatus,
    this.auditQuery = '',
    this.isMutating = false,
    this.feedbackMessage,
    this.errorMessage,
  });

  ApplicationAdminLoaded copyWith({
    ApplicationAdminDashboardSummary? summary,
    List<AdminApprovalItem>? approvals,
    List<ApplicationStaffProfile>? staffProfiles,
    List<AdminAuditLogEntry>? auditLogs,
    AdminApprovalTargetType? filterTargetType,
    bool clearTargetType = false,
    AdminApprovalStatus? filterStatus,
    bool clearStatus = false,
    String? auditQuery,
    bool? isMutating,
    String? feedbackMessage,
    bool clearFeedback = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ApplicationAdminLoaded(
      summary: summary ?? this.summary,
      approvals: approvals ?? this.approvals,
      staffProfiles: staffProfiles ?? this.staffProfiles,
      auditLogs: auditLogs ?? this.auditLogs,
      filterTargetType:
          clearTargetType ? null : (filterTargetType ?? this.filterTargetType),
      filterStatus: clearStatus ? null : (filterStatus ?? this.filterStatus),
      auditQuery: auditQuery ?? this.auditQuery,
      isMutating: isMutating ?? this.isMutating,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        summary,
        approvals,
        staffProfiles,
        auditLogs,
        filterTargetType,
        filterStatus,
        auditQuery,
        isMutating,
        feedbackMessage,
        errorMessage,
      ];
}

class ApplicationAdminFailure extends ApplicationAdminState {
  final String message;

  const ApplicationAdminFailure(this.message);

  @override
  List<Object?> get props => [message];
}
