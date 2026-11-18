import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/application_admin/domain/entities/application_admin_entities.dart';
import 'package:pickleball_platform/features/application_admin/domain/repositories/application_admin_repository.dart';
import 'package:pickleball_platform/features/application_admin/presentation/bloc/application_admin_state.dart';
import 'package:pickleball_platform/features/application_staff/domain/entities/application_staff_entities.dart';

class ApplicationAdminCubit extends Cubit<ApplicationAdminState> {
  final ApplicationAdminRepository _repository;

  ApplicationAdminCubit({required ApplicationAdminRepository repository})
      : _repository = repository, // ignore: prefer_initializing_formals
        super(const ApplicationAdminInitial());

  String? _adminUserId;
  AdminApprovalTargetType? _targetType;
  AdminApprovalStatus? _status;
  String _auditQuery = '';

  Future<void> load({required String adminUserId}) async {
    _adminUserId = adminUserId;
    emit(const ApplicationAdminLoading());

    final summaryResult =
        await _repository.getAdminDashboard(adminUserId: adminUserId);
    if (summaryResult is FailureResult<ApplicationAdminDashboardSummary>) {
      emit(ApplicationAdminFailure(summaryResult.failure.message));
      return;
    }

    final approvalsResult = await _repository.getApprovalQueue(
      adminUserId: adminUserId,
      targetType: _targetType,
      status: _status,
    );
    final staffResult =
        await _repository.getManagedStaff(adminUserId: adminUserId);
    final auditResult = await _repository.getAuditLogs(
      adminUserId: adminUserId,
      query: _auditQuery,
    );

    if (approvalsResult is FailureResult<List<AdminApprovalItem>>) {
      emit(ApplicationAdminFailure(approvalsResult.failure.message));
      return;
    }
    if (staffResult is FailureResult<List<ApplicationStaffProfile>>) {
      emit(ApplicationAdminFailure(staffResult.failure.message));
      return;
    }
    if (auditResult is FailureResult<List<AdminAuditLogEntry>>) {
      emit(ApplicationAdminFailure(auditResult.failure.message));
      return;
    }

    emit(
      ApplicationAdminLoaded(
        summary:
            (summaryResult as Success<ApplicationAdminDashboardSummary>).data,
        approvals: (approvalsResult as Success<List<AdminApprovalItem>>).data,
        staffProfiles:
            (staffResult as Success<List<ApplicationStaffProfile>>).data,
        auditLogs: (auditResult as Success<List<AdminAuditLogEntry>>).data,
        filterTargetType: _targetType,
        filterStatus: _status,
        auditQuery: _auditQuery,
      ),
    );
  }

  Future<void> applyApprovalFilters({
    AdminApprovalTargetType? targetType,
    bool clearTargetType = false,
    AdminApprovalStatus? status,
    bool clearStatus = false,
  }) async {
    final current = state;
    final adminUserId = _adminUserId;
    if (current is! ApplicationAdminLoaded || adminUserId == null) return;

    _targetType = clearTargetType ? null : (targetType ?? _targetType);
    _status = clearStatus ? null : (status ?? _status);

    emit(
      current.copyWith(
        filterTargetType: _targetType,
        clearTargetType: clearTargetType,
        filterStatus: _status,
        clearStatus: clearStatus,
        isMutating: true,
        clearError: true,
      ),
    );

    final result = await _repository.getApprovalQueue(
      adminUserId: adminUserId,
      targetType: _targetType,
      status: _status,
    );
    result.when(
      success: (approvals) => emit(
        current.copyWith(
          approvals: approvals,
          filterTargetType: _targetType,
          clearTargetType: clearTargetType,
          filterStatus: _status,
          clearStatus: clearStatus,
          isMutating: false,
        ),
      ),
      failure: (f) => emit(
        current.copyWith(isMutating: false, errorMessage: f.message),
      ),
    );
  }

  Future<void> decideApprovalItem({
    required String itemId,
    required AdminApprovalStatus decision,
    required String reason,
  }) async {
    final current = state;
    final adminUserId = _adminUserId;
    if (current is! ApplicationAdminLoaded || adminUserId == null) return;

    emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));
    final result = await _repository.decideApprovalItem(
      adminUserId: adminUserId,
      itemId: itemId,
      decision: decision,
      reason: reason,
    );

    await result.when(
      success: (updated) async {
        await _reloadLoaded(
          feedbackMessage:
              '${updated.subjectTitle} marked ${updated.status.label}.',
        );
      },
      failure: (f) async {
        emit(current.copyWith(isMutating: false, errorMessage: f.message));
      },
    );
  }

  Future<void> updateStaffAccess({
    required String staffId,
    required Set<ApplicationStaffPermission> permissions,
    required Set<String> authorizedOrganizationIds,
    required bool isActive,
  }) async {
    final current = state;
    final adminUserId = _adminUserId;
    if (current is! ApplicationAdminLoaded || adminUserId == null) return;

    emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));
    final result = await _repository.updateStaffAccess(
      adminUserId: adminUserId,
      staffId: staffId,
      permissions: permissions,
      authorizedOrganizationIds: authorizedOrganizationIds,
      isActive: isActive,
    );

    await result.when(
      success: (updated) async {
        await _reloadLoaded(
          feedbackMessage: 'Updated staff access for ${updated.staffName}.',
        );
      },
      failure: (f) async {
        emit(current.copyWith(isMutating: false, errorMessage: f.message));
      },
    );
  }

  Future<void> updateCommissionPolicy({
    required double? defaultCommissionRatePercent,
    required int minReturnWindowDays,
    required int maxReturnWindowDays,
  }) async {
    final current = state;
    final adminUserId = _adminUserId;
    if (current is! ApplicationAdminLoaded || adminUserId == null) return;

    emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));
    final result = await _repository.updateCommissionPolicy(
      adminUserId: adminUserId,
      defaultCommissionRatePercent: defaultCommissionRatePercent,
      minReturnWindowDays: minReturnWindowDays,
      maxReturnWindowDays: maxReturnWindowDays,
    );

    await result.when(
      success: (updated) async {
        await _reloadLoaded(
          feedbackMessage: 'Saved Platform Policy v${updated.version}.',
        );
      },
      failure: (f) async {
        emit(current.copyWith(isMutating: false, errorMessage: f.message));
      },
    );
  }

  Future<void> searchAuditLogs(String query) async {
    final current = state;
    final adminUserId = _adminUserId;
    if (current is! ApplicationAdminLoaded || adminUserId == null) return;

    _auditQuery = query;
    emit(current.copyWith(auditQuery: query, isMutating: true, clearError: true));
    final result = await _repository.getAuditLogs(
      adminUserId: adminUserId,
      query: query,
    );
    result.when(
      success: (logs) => emit(
        current.copyWith(auditLogs: logs, auditQuery: query, isMutating: false),
      ),
      failure: (f) => emit(
        current.copyWith(isMutating: false, errorMessage: f.message),
      ),
    );
  }

  void clearFeedback() {
    final current = state;
    if (current is ApplicationAdminLoaded) {
      emit(current.copyWith(clearFeedback: true, clearError: true));
    }
  }

  Future<void> _reloadLoaded({String? feedbackMessage}) async {
    final current = state;
    final adminUserId = _adminUserId;
    if (current is! ApplicationAdminLoaded || adminUserId == null) return;

    final summaryResult =
        await _repository.getAdminDashboard(adminUserId: adminUserId);
    final approvalsResult = await _repository.getApprovalQueue(
      adminUserId: adminUserId,
      targetType: _targetType,
      status: _status,
    );
    final staffResult =
        await _repository.getManagedStaff(adminUserId: adminUserId);
    final auditResult = await _repository.getAuditLogs(
      adminUserId: adminUserId,
      query: _auditQuery,
    );

    if (summaryResult is Success<ApplicationAdminDashboardSummary> &&
        approvalsResult is Success<List<AdminApprovalItem>> &&
        staffResult is Success<List<ApplicationStaffProfile>> &&
        auditResult is Success<List<AdminAuditLogEntry>>) {
      emit(
        current.copyWith(
          summary: summaryResult.data,
          approvals: approvalsResult.data,
          staffProfiles: staffResult.data,
          auditLogs: auditResult.data,
          isMutating: false,
          feedbackMessage: feedbackMessage,
        ),
      );
    } else {
      emit(
        current.copyWith(
          isMutating: false,
          errorMessage: 'Unable to refresh Application Admin workspace.',
        ),
      );
    }
  }
}
