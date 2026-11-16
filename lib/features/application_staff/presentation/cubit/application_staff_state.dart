import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/application_staff/domain/entities/application_staff_entities.dart';

abstract class ApplicationStaffState extends Equatable {
  const ApplicationStaffState();

  @override
  List<Object?> get props => [];
}

class ApplicationStaffInitial extends ApplicationStaffState {
  const ApplicationStaffInitial();
}

class ApplicationStaffLoading extends ApplicationStaffState {
  const ApplicationStaffLoading();
}

class ApplicationStaffLoaded extends ApplicationStaffState {
  final ApplicationStaffDashboardSummary summary;
  final List<StaffOperationalQueueItem> queueItems;
  final StaffQueueCategory? selectedCategory;
  final StaffQueueItemStatus? selectedStatus;
  final String searchQuery;
  final bool isMutating;
  final String? feedbackMessage;
  final String? errorMessage;

  const ApplicationStaffLoaded({
    required this.summary,
    required this.queueItems,
    this.selectedCategory,
    this.selectedStatus,
    this.searchQuery = '',
    this.isMutating = false,
    this.feedbackMessage,
    this.errorMessage,
  });

  ApplicationStaffProfile get profile => summary.profile;

  ApplicationStaffLoaded copyWith({
    ApplicationStaffDashboardSummary? summary,
    List<StaffOperationalQueueItem>? queueItems,
    StaffQueueCategory? selectedCategory,
    bool clearCategory = false,
    StaffQueueItemStatus? selectedStatus,
    bool clearStatus = false,
    String? searchQuery,
    bool? isMutating,
    String? feedbackMessage,
    bool clearFeedback = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ApplicationStaffLoaded(
      summary: summary ?? this.summary,
      queueItems: queueItems ?? this.queueItems,
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedStatus:
          clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      searchQuery: searchQuery ?? this.searchQuery,
      isMutating: isMutating ?? this.isMutating,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        summary,
        queueItems,
        selectedCategory,
        selectedStatus,
        searchQuery,
        isMutating,
        feedbackMessage,
        errorMessage,
      ];
}

class ApplicationStaffFailure extends ApplicationStaffState {
  final String message;

  const ApplicationStaffFailure(this.message);

  @override
  List<Object?> get props => [message];
}
