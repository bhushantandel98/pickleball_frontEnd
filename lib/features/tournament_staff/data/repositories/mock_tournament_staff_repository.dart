import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/entities/tournament_organizer_entities.dart';
import 'package:pickleball_platform/features/tournament_staff/domain/entities/tournament_staff_entities.dart';
import 'package:pickleball_platform/features/tournament_staff/domain/repositories/tournament_staff_repository.dart';

/// Mock implementation of [TournamentStaffRepository] for Feature 5.2.
///
/// Enforces:
/// - Strict [tournamentId] and [staffId] validation (`ForbiddenFailure`).
/// - Exclusion of records belonging to other tournaments (`tourn_other_999`).
/// - Repository-level delegated permission checks (`manageCheckIn`,
///   `manageReferees`, `editMatchScore`).
class MockTournamentStaffRepository implements TournamentStaffRepository {
  bool shouldFail;

  late TournamentStaffProfile _staffProfile;
  late List<TournamentCheckInRecord> _allCheckIns;
  late List<OrganizerMatchSlot> _allMatches;
  late List<TournamentRefereeOption> _allReferees;

  MockTournamentStaffRepository({
    this.shouldFail = false,
    TournamentStaffProfile? customProfile,
  }) {
    _seedData(customProfile: customProfile);
  }

  void _seedData({TournamentStaffProfile? customProfile}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _staffProfile = customProfile ??
        const TournamentStaffProfile(
          staffId: 'user_tstaff_001',
          tournamentId: 'tourn_org_001',
          tournamentName: 'Mumbai Monsoon Championship 2026',
          venueName: 'Grand Slam Pickleball Arena, Mumbai',
          staffName: 'Sneha Kulkarni',
          staffEmail: 'sneha.kulkarni@pacificseries.in',
          roleTitle: 'Tournament Operations Desk',
          permissions: {
            TournamentStaffPermission.viewDashboard,
            TournamentStaffPermission.manageCheckIn,
            TournamentStaffPermission.manageReferees,
            TournamentStaffPermission.editMatchScore,
          },
          isActive: true,
        );

    _allCheckIns = [
      TournamentCheckInRecord(
        id: 'chk_001',
        tournamentId: 'tourn_org_001',
        categoryName: "Men's Singles Open",
        participantLabel: 'Aarav Mehta',
        eventFormat: TournamentEventFormat.singles,
        isCheckedIn: true,
        checkedInAt: now.subtract(const Duration(minutes: 40)),
      ),
      const TournamentCheckInRecord(
        id: 'chk_002',
        tournamentId: 'tourn_org_001',
        categoryName: "Men's Singles Open",
        participantLabel: 'Rohan Kapoor',
        eventFormat: TournamentEventFormat.singles,
        isCheckedIn: false,
      ),
      const TournamentCheckInRecord(
        id: 'chk_003',
        tournamentId: 'tourn_org_001',
        categoryName: 'Mixed Doubles 3.5',
        participantLabel: 'Ananya Verma / Karan Shah',
        eventFormat: TournamentEventFormat.mixedDoubles,
        isCheckedIn: false,
      ),
      // Cross-tournament record that must never leak to tourn_org_001 staff.
      const TournamentCheckInRecord(
        id: 'chk_other_999',
        tournamentId: 'tourn_other_999',
        categoryName: 'Restricted Rival Open',
        participantLabel: 'Hidden Player',
        eventFormat: TournamentEventFormat.singles,
        isCheckedIn: false,
      ),
    ];

    _allMatches = [
      OrganizerMatchSlot(
        id: 'm_cat_ms_open_1',
        tournamentId: 'tourn_org_001',
        organizerId: 'org_tourn_001',
        categoryId: 'cat_ms_open',
        categoryName: "Men's Singles Open",
        bracketFormat: TournamentBracketFormat.knockout,
        roundLabel: 'Semifinal',
        matchNumber: 1,
        participantA: '(#1) Aarav Mehta',
        participantB: '(#4) Devansh Joshi',
        courtName: 'Court 1',
        scheduledTime: today.add(const Duration(hours: 10)),
        refereeId: 'user_ref_001',
        refereeName: 'Rajesh Iyer',
        status: OrganizerMatchStatus.inProgress,
      ),
      OrganizerMatchSlot(
        id: 'm_cat_ms_open_2',
        tournamentId: 'tourn_org_001',
        organizerId: 'org_tourn_001',
        categoryId: 'cat_ms_open',
        categoryName: "Men's Singles Open",
        bracketFormat: TournamentBracketFormat.knockout,
        roundLabel: 'Semifinal',
        matchNumber: 2,
        participantA: '(#2) Rohan Kapoor',
        participantB: '(#3) Vikram Singh',
        courtName: 'Court 2',
        scheduledTime: today.add(const Duration(hours: 11)),
        refereeId: 'user_ref_002',
        refereeName: 'Meera Krishnan',
        status: OrganizerMatchStatus.completed,
        scoreSummary: '11-7, 11-9',
        winnerLabel: '(#2) Rohan Kapoor',
      ),
      // Cross-tournament match that must never leak.
      OrganizerMatchSlot(
        id: 'm_other_999',
        tournamentId: 'tourn_other_999',
        organizerId: 'org_tourn_999',
        categoryId: 'cat_other',
        categoryName: 'Restricted Rival Open',
        bracketFormat: TournamentBracketFormat.knockout,
        roundLabel: 'Final',
        matchNumber: 1,
        participantA: 'Hidden A',
        participantB: 'Hidden B',
        courtName: 'Center Court',
        scheduledTime: today.add(const Duration(hours: 12)),
      ),
    ];

    _allReferees = const [
      TournamentRefereeOption(
        refereeAssignmentId: 'stf_t_002',
        tournamentId: 'tourn_org_001',
        userId: 'user_ref_001',
        name: 'Rajesh Iyer',
        email: 'rajesh.iyer@refereeindia.org',
        isActive: true,
      ),
      TournamentRefereeOption(
        refereeAssignmentId: 'stf_t_003',
        tournamentId: 'tourn_org_001',
        userId: 'user_ref_002',
        name: 'Meera Krishnan',
        email: 'meera.krishnan@refereeindia.org',
        isActive: true,
      ),
      TournamentRefereeOption(
        refereeAssignmentId: 'stf_other_999',
        tournamentId: 'tourn_other_999',
        userId: 'user_ref_999',
        name: 'Other Tournament Ref',
        email: 'other@ref.org',
        isActive: true,
      ),
    ];
  }

  FailureResult<TournamentStaffWorkspaceData>? _validateContext({
    required String tournamentId,
    required String staffId,
  }) {
    if (tournamentId.trim().isEmpty ||
        tournamentId.trim() != _staffProfile.tournamentId) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Unauthorized: tournament context mismatch.',
        ),
      );
    }
    if (staffId.trim().isEmpty || staffId.trim() != _staffProfile.staffId) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Unauthorized: tournament staff identity mismatch.',
        ),
      );
    }
    if (!_staffProfile.isActive) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Access revoked: tournament staff assignment is inactive.',
        ),
      );
    }
    return null;
  }

  FailureResult<TournamentStaffWorkspaceData>? _requirePermission(
    TournamentStaffPermission permission,
  ) {
    if (!_staffProfile.hasPermission(permission)) {
      return FailureResult(
        ForbiddenFailure(
          message:
              'Permission denied: "${permission.label}" is not delegated to your staff role.',
        ),
      );
    }
    return null;
  }

  TournamentStaffWorkspaceData _buildScopedWorkspace() {
    final tid = _staffProfile.tournamentId;
    return TournamentStaffWorkspaceData(
      staffProfile: _staffProfile,
      checkIns: _allCheckIns.where((c) => c.tournamentId == tid).toList(),
      matches: _allMatches.where((m) => m.tournamentId == tid).toList(),
      referees: _allReferees.where((r) => r.tournamentId == tid).toList(),
    );
  }

  @override
  Future<Result<TournamentStaffWorkspaceData>> getWorkspace({
    required String tournamentId,
    required String staffId,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        NetworkFailure(message: 'Unable to load tournament staff workspace.'),
      );
    }
    final err = _validateContext(tournamentId: tournamentId, staffId: staffId);
    if (err != null) return err;

    return Success(_buildScopedWorkspace());
  }

  @override
  Future<Result<TournamentStaffWorkspaceData>> toggleCheckIn({
    required String tournamentId,
    required String staffId,
    required String checkInId,
    required bool isCheckedIn,
  }) async {
    final err = _validateContext(tournamentId: tournamentId, staffId: staffId) ??
        _requirePermission(TournamentStaffPermission.manageCheckIn);
    if (err != null) return err;

    final idx = _allCheckIns.indexWhere(
      (c) => c.id == checkInId && c.tournamentId == tournamentId,
    );
    if (idx == -1) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Check-in record not found in your assigned tournament.',
        ),
      );
    }

    _allCheckIns[idx] = _allCheckIns[idx].copyWith(
      isCheckedIn: isCheckedIn,
      checkedInAt: isCheckedIn ? DateTime.now() : null,
    );

    return Success(_buildScopedWorkspace());
  }

  @override
  Future<Result<TournamentStaffWorkspaceData>> assignMatchReferee({
    required String tournamentId,
    required String staffId,
    required String matchId,
    required String refereeAssignmentId,
  }) async {
    final err = _validateContext(tournamentId: tournamentId, staffId: staffId) ??
        _requirePermission(TournamentStaffPermission.manageReferees);
    if (err != null) return err;

    final matchIdx = _allMatches.indexWhere(
      (m) => m.id == matchId && m.tournamentId == tournamentId,
    );
    if (matchIdx == -1) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Match not found in your assigned tournament.',
        ),
      );
    }

    final ref = _allReferees
        .where((r) =>
            r.refereeAssignmentId == refereeAssignmentId &&
            r.tournamentId == tournamentId &&
            r.isActive)
        .firstOrNull;
    if (ref == null) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Selected referee is inactive or not assigned to this tournament.',
        ),
      );
    }

    _allMatches[matchIdx] = _allMatches[matchIdx].copyWith(
      refereeId: ref.userId,
      refereeName: ref.name,
    );

    return Success(_buildScopedWorkspace());
  }

  @override
  Future<Result<TournamentStaffWorkspaceData>> correctMatchScore({
    required String tournamentId,
    required String staffId,
    required String matchId,
    required String scoreSummary,
    required String winnerLabel,
    required String correctionReason,
  }) async {
    final err = _validateContext(tournamentId: tournamentId, staffId: staffId) ??
        _requirePermission(TournamentStaffPermission.editMatchScore);
    if (err != null) return err;

    final matchIdx = _allMatches.indexWhere(
      (m) => m.id == matchId && m.tournamentId == tournamentId,
    );
    if (matchIdx == -1) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Match not found in your assigned tournament.',
        ),
      );
    }

    if (scoreSummary.trim().isEmpty ||
        winnerLabel.trim().isEmpty ||
        correctionReason.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Score summary, winner, and correction reason are required.',
        ),
      );
    }

    _allMatches[matchIdx] = _allMatches[matchIdx].copyWith(
      status: OrganizerMatchStatus.completed,
      scoreSummary: scoreSummary.trim(),
      winnerLabel: winnerLabel.trim(),
    );

    return Success(_buildScopedWorkspace());
  }
}
