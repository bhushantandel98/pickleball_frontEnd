import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_dashboard_data.dart';

/// Base state hierarchy for the Coach Dashboard.
sealed class CoachDashboardState extends Equatable {
  const CoachDashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial state before dashboard fetch.
class CoachDashboardInitial extends CoachDashboardState {
  const CoachDashboardInitial();
}

/// Loading state while fetching coach dashboard data.
class CoachDashboardLoading extends CoachDashboardState {
  const CoachDashboardLoading();
}

/// Loaded state containing full coach data and active context filters.
class CoachDashboardLoaded extends CoachDashboardState {
  final CoachDashboardData data;
  final CoachDashboardFilter filter;

  const CoachDashboardLoaded({
    required this.data,
    this.filter = const CoachDashboardFilter(),
  });

  bool get showPersonalContext =>
      filter.contextType == CoachContextType.all ||
      filter.contextType == CoachContextType.personal;

  bool get showAcademyContext =>
      filter.contextType == CoachContextType.all ||
      filter.contextType == CoachContextType.academy;

  /// Assigned branches available for the currently selected accepted academy.
  List<AssignedBranchSummary> get availableBranches {
    if (filter.contextType != CoachContextType.academy ||
        filter.selectedAcademyId == null) {
      return const [];
    }
    for (final affiliation in data.acceptedAffiliations) {
      if (affiliation.academyId == filter.selectedAcademyId) {
        return affiliation.assignedBranches;
      }
    }
    return const [];
  }

  /// Upcoming sessions matching the active context filter, sorted chronologically.
  List<CoachSessionItem> get filteredSessions {
    final items = data.upcomingSessions.where((session) {
      switch (filter.contextType) {
        case CoachContextType.all:
          return true;
        case CoachContextType.personal:
          return session.contextType == CoachSessionContext.personal;
        case CoachContextType.academy:
          if (session.contextType != CoachSessionContext.academy) {
            return false;
          }
          if (filter.selectedAcademyId != null &&
              session.academyId != filter.selectedAcademyId) {
            return false;
          }
          if (filter.selectedBranchId != null &&
              session.branchId != filter.selectedBranchId) {
            return false;
          }
          return true;
      }
    }).toList();

    items.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return items;
  }

  /// Academy player summaries matching the active context, academy, and branch filters.
  List<AcademyPlayerSummary> get filteredAcademyPlayerSummaries {
    if (!showAcademyContext) return const [];

    return data.academyPlayerSummaries.where((summary) {
      if (filter.selectedAcademyId != null &&
          summary.academyId != filter.selectedAcademyId) {
        return false;
      }
      if (filter.selectedBranchId != null &&
          summary.branchId != filter.selectedBranchId) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Pending tasks matching the active context, academy, and branch filters.
  List<CoachPendingTask> get filteredPendingTasks {
    return data.pendingTasks.where((task) {
      switch (filter.contextType) {
        case CoachContextType.all:
          return true;
        case CoachContextType.personal:
          return task.contextType == CoachSessionContext.personal;
        case CoachContextType.academy:
          if (task.contextType != CoachSessionContext.academy) {
            return false;
          }
          if (filter.selectedAcademyId != null &&
              task.academyId != filter.selectedAcademyId) {
            return false;
          }
          if (filter.selectedBranchId != null &&
              task.branchId != filter.selectedBranchId) {
            return false;
          }
          return true;
      }
    }).toList();
  }

  /// Permitted academy finance summaries matching the active filters.
  List<AcademyFinanceSummary> get filteredAcademyFinanceSummaries {
    if (!showAcademyContext) return const [];

    return data.academyFinanceSummaries.where((summary) {
      if (filter.selectedAcademyId != null &&
          summary.academyId != filter.selectedAcademyId) {
        return false;
      }
      if (filter.selectedBranchId != null &&
          summary.branchId != filter.selectedBranchId) {
        return false;
      }
      return true;
    }).toList();
  }

  CoachDashboardLoaded copyWith({
    CoachDashboardData? data,
    CoachDashboardFilter? filter,
  }) {
    return CoachDashboardLoaded(
      data: data ?? this.data,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [data, filter];
}

/// Empty state when no coach dashboard data is available at all.
class CoachDashboardEmpty extends CoachDashboardState {
  final String message;

  const CoachDashboardEmpty({
    this.message = 'No coaching sessions, affiliations, or tasks available yet.',
  });

  @override
  List<Object?> get props => [message];
}

/// Failure state when dashboard loading encounters an error.
class CoachDashboardFailure extends CoachDashboardState {
  final Failure failure;

  const CoachDashboardFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
