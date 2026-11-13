import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/entities/tournament_organizer_entities.dart';

/// Base state for Feature 5.1 — Tournament Organizer Module.
sealed class TournamentOrganizerState extends Equatable {
  const TournamentOrganizerState();

  @override
  List<Object?> get props => [];
}

class TournamentOrganizerInitial extends TournamentOrganizerState {
  const TournamentOrganizerInitial();
}

class TournamentOrganizerLoading extends TournamentOrganizerState {
  const TournamentOrganizerLoading();
}

class TournamentOrganizerLoaded extends TournamentOrganizerState {
  final TournamentOrganizerWorkspaceData data;
  final String? selectedTournamentId;
  final String? selectedCategoryId;
  final String? feedbackMessage;
  final bool isErrorFeedback;

  const TournamentOrganizerLoaded({
    required this.data,
    this.selectedTournamentId,
    this.selectedCategoryId,
    this.feedbackMessage,
    this.isErrorFeedback = false,
  });

  OrganizerTournament? get selectedTournament {
    if (data.tournaments.isEmpty) return null;
    if (selectedTournamentId != null) {
      final match =
          data.tournaments.where((t) => t.id == selectedTournamentId).firstOrNull;
      if (match != null) return match;
    }
    return data.tournaments.first;
  }

  OrganizerCategoryConfig? get selectedCategory {
    final tournament = selectedTournament;
    if (tournament == null || tournament.categories.isEmpty) return null;
    if (selectedCategoryId != null) {
      final match = tournament.categories
          .where((c) => c.id == selectedCategoryId)
          .firstOrNull;
      if (match != null) return match;
    }
    return tournament.categories.first;
  }

  List<OrganizerRegistrationRecord> get tournamentRegistrations {
    final t = selectedTournament;
    if (t == null) return const [];
    return data.registrations.where((r) => r.tournamentId == t.id).toList();
  }

  List<OrganizerMatchSlot> get tournamentMatches {
    final t = selectedTournament;
    if (t == null) return const [];
    return data.matches.where((m) => m.tournamentId == t.id).toList();
  }

  List<OrganizerStaffAssignment> get tournamentStaff {
    final t = selectedTournament;
    if (t == null) return const [];
    return data.staffAssignments.where((s) => s.tournamentId == t.id).toList();
  }

  double get tournamentGrossFeesInr => tournamentRegistrations
      .where((r) => r.status == OrganizerRegistrationStatus.autoConfirmed)
      .fold<double>(0, (sum, r) => sum + r.feePaidInr);

  Map<String, double> get categoryFeeBreakdown {
    final map = <String, double>{};
    for (final reg in tournamentRegistrations) {
      if (reg.status == OrganizerRegistrationStatus.autoConfirmed) {
        map[reg.categoryName] = (map[reg.categoryName] ?? 0) + reg.feePaidInr;
      }
    }
    return map;
  }

  TournamentOrganizerLoaded copyWith({
    TournamentOrganizerWorkspaceData? data,
    String? selectedTournamentId,
    String? selectedCategoryId,
    String? feedbackMessage,
    bool? isErrorFeedback,
    bool clearFeedback = false,
  }) {
    return TournamentOrganizerLoaded(
      data: data ?? this.data,
      selectedTournamentId: selectedTournamentId ?? this.selectedTournamentId,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      isErrorFeedback:
          clearFeedback ? false : (isErrorFeedback ?? this.isErrorFeedback),
    );
  }

  @override
  List<Object?> get props => [
        data,
        selectedTournamentId,
        selectedCategoryId,
        feedbackMessage,
        isErrorFeedback,
      ];
}

class TournamentOrganizerFailure extends TournamentOrganizerState {
  final Failure failure;

  const TournamentOrganizerFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
