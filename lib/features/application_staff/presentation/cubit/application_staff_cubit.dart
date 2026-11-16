import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/application_staff/domain/entities/application_staff_entities.dart';
import 'package:pickleball_platform/features/application_staff/domain/repositories/application_staff_repository.dart';
import 'package:pickleball_platform/features/application_staff/presentation/cubit/application_staff_state.dart';

class ApplicationStaffCubit extends Cubit<ApplicationStaffState> {
  final ApplicationStaffRepository _repository;

  ApplicationStaffCubit({required ApplicationStaffRepository repository})
      : _repository = repository, // ignore: prefer_initializing_formals
        super(const ApplicationStaffInitial());

  String? _userId;
  String? _staffId;
  StaffQueueCategory? _category;
  StaffQueueItemStatus? _status;
  String _query = '';

  Future<void> load({
    required String userId,
    String? staffId,
  }) async {
    _userId = userId;
    _staffId = staffId;
    emit(const ApplicationStaffLoading());

    final summaryResult = await _repository.getStaffDashboard(
      userId: userId,
      staffId: staffId,
    );
    if (summaryResult is FailureResult<ApplicationStaffDashboardSummary>) {
      emit(ApplicationStaffFailure(summaryResult.failure.message));
      return;
    }

    final queueResult = await _repository.getOperationalQueue(
      userId: userId,
      category: _category,
      status: _status,
      query: _query,
    );
    queueResult.when(
      success: (items) => emit(
        ApplicationStaffLoaded(
          summary:
              (summaryResult as Success<ApplicationStaffDashboardSummary>).data,
          queueItems: items,
          selectedCategory: _category,
          selectedStatus: _status,
          searchQuery: _query,
        ),
      ),
      failure: (f) => emit(ApplicationStaffFailure(f.message)),
    );
  }

  Future<void> applyFilters({
    StaffQueueCategory? category,
    bool clearCategory = false,
    StaffQueueItemStatus? status,
    bool clearStatus = false,
    String? query,
  }) async {
    final current = state;
    final userId = _userId;
    if (current is! ApplicationStaffLoaded || userId == null) return;

    _category = clearCategory ? null : (category ?? _category);
    _status = clearStatus ? null : (status ?? _status);
    if (query != null) _query = query;

    emit(
      current.copyWith(
        selectedCategory: _category,
        clearCategory: clearCategory,
        selectedStatus: _status,
        clearStatus: clearStatus,
        searchQuery: _query,
        isMutating: true,
        clearError: true,
      ),
    );

    final result = await _repository.getOperationalQueue(
      userId: userId,
      category: _category,
      status: _status,
      query: _query,
    );
    result.when(
      success: (items) => emit(
        current.copyWith(
          queueItems: items,
          selectedCategory: _category,
          clearCategory: clearCategory,
          selectedStatus: _status,
          clearStatus: clearStatus,
          searchQuery: _query,
          isMutating: false,
        ),
      ),
      failure: (f) => emit(
        current.copyWith(isMutating: false, errorMessage: f.message),
      ),
    );
  }

  Future<void> updateQueueItem({
    required String itemId,
    required StaffQueueItemStatus nextStatus,
    required String note,
  }) async {
    final current = state;
    final userId = _userId;
    if (current is! ApplicationStaffLoaded || userId == null) return;

    emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));
    final result = await _repository.updateQueueItemStatus(
      userId: userId,
      itemId: itemId,
      nextStatus: nextStatus,
      note: note,
    );

    await result.when(
      success: (updated) async {
        final summaryResult = await _repository.getStaffDashboard(
          userId: userId,
          staffId: _staffId,
        );
        final queueResult = await _repository.getOperationalQueue(
          userId: userId,
          category: _category,
          status: _status,
          query: _query,
        );
        if (summaryResult is Success<ApplicationStaffDashboardSummary> &&
            queueResult is Success<List<StaffOperationalQueueItem>>) {
          emit(
            current.copyWith(
              summary: summaryResult.data,
              queueItems: queueResult.data,
              isMutating: false,
              feedbackMessage:
                  'Updated "${updated.title}" to ${updated.status.label}.',
            ),
          );
        } else {
          final err = summaryResult.failureOrNull ?? queueResult.failureOrNull;
          emit(
            current.copyWith(
              isMutating: false,
              errorMessage: err?.message ?? 'Unable to refresh staff queue.',
            ),
          );
        }
      },
      failure: (f) async {
        emit(current.copyWith(isMutating: false, errorMessage: f.message));
      },
    );
  }

  void clearFeedback() {
    final current = state;
    if (current is ApplicationStaffLoaded) {
      emit(current.copyWith(clearFeedback: true, clearError: true));
    }
  }
}
