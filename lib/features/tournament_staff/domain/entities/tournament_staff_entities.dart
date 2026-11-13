import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/entities/tournament_organizer_entities.dart';

/// Delegated permissions assignable to Tournament Staff by a Tournament Organizer.
///
/// Staff cannot self-escalate permissions, alter tournament rules/draws, or
/// manage referees / edit match scores unless explicitly delegated.
enum TournamentStaffPermission {
  viewDashboard('View Dashboard'),
  manageCheckIn('Player Check-in & Match Monitor'),
  manageReferees('Manage Referees'),
  editMatchScore('Edit Match Score');

  final String label;
  const TournamentStaffPermission(this.label);
}

/// Authenticated Tournament Staff profile and delegated tournament scope.
class TournamentStaffProfile extends Equatable {
  final String staffId;
  final String tournamentId;
  final String tournamentName;
  final String venueName;
  final String staffName;
  final String staffEmail;
  final String roleTitle;
  final Set<TournamentStaffPermission> permissions;
  final bool isActive;

  const TournamentStaffProfile({
    required this.staffId,
    required this.tournamentId,
    required this.tournamentName,
    required this.venueName,
    required this.staffName,
    required this.staffEmail,
    required this.roleTitle,
    required this.permissions,
    this.isActive = true,
  });

  bool hasPermission(TournamentStaffPermission permission) =>
      isActive && permissions.contains(permission);

  @override
  List<Object?> get props => [
        staffId,
        tournamentId,
        tournamentName,
        venueName,
        staffName,
        staffEmail,
        roleTitle,
        permissions,
        isActive,
      ];
}

/// Tournament participant check-in record scoped to [tournamentId].
class TournamentCheckInRecord extends Equatable {
  final String id;
  final String tournamentId;
  final String categoryName;
  final String participantLabel;
  final TournamentEventFormat eventFormat;
  final bool isCheckedIn;
  final DateTime? checkedInAt;

  const TournamentCheckInRecord({
    required this.id,
    required this.tournamentId,
    required this.categoryName,
    required this.participantLabel,
    required this.eventFormat,
    this.isCheckedIn = false,
    this.checkedInAt,
  });

  TournamentCheckInRecord copyWith({
    bool? isCheckedIn,
    DateTime? checkedInAt,
  }) {
    return TournamentCheckInRecord(
      id: id,
      tournamentId: tournamentId,
      categoryName: categoryName,
      participantLabel: participantLabel,
      eventFormat: eventFormat,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkedInAt: checkedInAt ?? this.checkedInAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        categoryName,
        participantLabel,
        eventFormat,
        isCheckedIn,
        checkedInAt,
      ];
}

/// Assigned referee option available within [tournamentId] when [manageReferees]
/// is delegated.
class TournamentRefereeOption extends Equatable {
  final String refereeAssignmentId;
  final String tournamentId;
  final String userId;
  final String name;
  final String email;
  final bool isActive;

  const TournamentRefereeOption({
    required this.refereeAssignmentId,
    required this.tournamentId,
    required this.userId,
    required this.name,
    required this.email,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        refereeAssignmentId,
        tournamentId,
        userId,
        name,
        email,
        isActive,
      ];
}

/// Aggregated Tournament Staff workspace scoped strictly to [staffProfile.tournamentId].
class TournamentStaffWorkspaceData extends Equatable {
  final TournamentStaffProfile staffProfile;
  final List<TournamentCheckInRecord> checkIns;
  final List<OrganizerMatchSlot> matches;
  final List<TournamentRefereeOption> referees;

  const TournamentStaffWorkspaceData({
    required this.staffProfile,
    required this.checkIns,
    required this.matches,
    required this.referees,
  });

  @override
  List<Object?> get props => [staffProfile, checkIns, matches, referees];
}
