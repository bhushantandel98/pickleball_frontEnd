import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_dashboard_data.dart';
import 'package:pickleball_platform/features/coach/domain/repositories/coach_dashboard_repository.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_dashboard_state.dart';

/// Cubit managing Coach Dashboard data loading, refresh, and context filtering.
class CoachDashboardCubit extends Cubit<CoachDashboardState> {
  final CoachDashboardRepository repository;

  CoachDashboardCubit({
    required this.repository,
  }) : super(const CoachDashboardInitial());

  /// Loads initial Coach Dashboard data.
  Future<void> loadDashboard({String? coachId}) async {
    emit(const CoachDashboardLoading());

    final result = await repository.getDashboardData(coachId: coachId);
    switch (result) {
      case Success(:final data):
        if (data.isCompletelyEmpty) {
          emit(const CoachDashboardEmpty());
        } else {
          emit(CoachDashboardLoaded(data: data));
        }
      case FailureResult(:final failure):
        emit(CoachDashboardFailure(failure));
    }
  }

  /// Refreshes dashboard data while preserving the currently selected filter if loaded.
  Future<void> refreshDashboard({String? coachId}) async {
    final activeFilter = state is CoachDashboardLoaded
        ? (state as CoachDashboardLoaded).filter
        : const CoachDashboardFilter();

    final result = await repository.getDashboardData(coachId: coachId);
    switch (result) {
      case Success(:final data):
        if (data.isCompletelyEmpty) {
          emit(const CoachDashboardEmpty());
        } else {
          emit(CoachDashboardLoaded(data: data, filter: activeFilter));
        }
      case FailureResult(:final failure):
        emit(CoachDashboardFailure(failure));
    }
  }

  /// Switches the top-level dashboard context (All, Personal Coaching, Academy).
  void selectContextType(CoachContextType contextType) {
    final currentState = state;
    if (currentState is! CoachDashboardLoaded) return;

    if (contextType == CoachContextType.all ||
        contextType == CoachContextType.personal) {
      emit(
        currentState.copyWith(
          filter: CoachDashboardFilter(contextType: contextType),
        ),
      );
      return;
    }

    // When switching to Academy context, keep previously selected academy if valid,
    // otherwise allow viewing all accepted academies until a specific one is chosen.
    emit(
      currentState.copyWith(
        filter: currentState.filter.copyWith(
          contextType: CoachContextType.academy,
        ),
      ),
    );
  }

  /// Filters dashboard to a specific accepted academy (or all accepted academies if null).
  /// Clears any previously selected branch filter when the academy changes.
  void selectAcademy(String? academyId) {
    final currentState = state;
    if (currentState is! CoachDashboardLoaded) return;

    // Ensure only accepted affiliations can be selected
    if (academyId != null &&
        !currentState.data.acceptedAffiliations
            .any((a) => a.academyId == academyId)) {
      return;
    }

    emit(
      currentState.copyWith(
        filter: CoachDashboardFilter(
          contextType: CoachContextType.academy,
          selectedAcademyId: academyId,
          selectedBranchId: null,
        ),
      ),
    );
  }

  /// Filters dashboard to an assigned branch under the currently selected academy.
  void selectBranch(String? branchId) {
    final currentState = state;
    if (currentState is! CoachDashboardLoaded) return;

    if (currentState.filter.selectedAcademyId == null) return;

    if (branchId != null &&
        !currentState.availableBranches.any((b) => b.branchId == branchId)) {
      return;
    }

    emit(
      currentState.copyWith(
        filter: currentState.filter.copyWith(
          contextType: CoachContextType.academy,
          selectedBranchId: branchId,
          clearBranch: branchId == null,
        ),
      ),
    );
  }

  /// Resets all context, academy, and branch filters back to All.
  void clearFilters() {
    final currentState = state;
    if (currentState is! CoachDashboardLoaded) return;

    emit(
      currentState.copyWith(
        filter: const CoachDashboardFilter(),
      ),
    );
  }
}
