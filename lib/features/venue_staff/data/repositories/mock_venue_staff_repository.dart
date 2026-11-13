import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/venue_partner/domain/entities/venue_partner_entities.dart';
import 'package:pickleball_platform/features/venue_staff/domain/entities/venue_staff_entities.dart';
import 'package:pickleball_platform/features/venue_staff/domain/repositories/venue_staff_repository.dart';

/// Mock implementation of [VenueStaffRepository] for Phase 3 — Feature 3.8.
///
/// Enforces:
/// - Partner & staff context validation (`partnerId`, `staffId`, `isActive`).
/// - Assigned location scoping (`loc_andheri` only; `loc_powai` is excluded).
/// - Repository-level delegated permission checks (`ForbiddenFailure`).
/// - Valid booking lifecycle transitions and V1 offline-only payment recording.
class MockVenueStaffRepository implements VenueStaffRepository {
  bool shouldFail;

  late VenueStaffProfile _staffProfile;
  late List<VenueLocation> _allPartnerLocations;
  late List<VenueCourt> _allPartnerCourts;
  late List<CourtAvailabilityBlock> _allPartnerBlocks;
  late List<VenuePartnerBooking> _allPartnerBookings;
  late List<VenueMaintenanceTask> _allPartnerTasks;
  late List<VenuePurchaseSubmission> _allPartnerPurchases;

  MockVenueStaffRepository({
    this.shouldFail = false,
    VenueStaffProfile? customStaffProfile,
  }) {
    _seedData(customStaffProfile: customStaffProfile);
  }

  void _seedData({VenueStaffProfile? customStaffProfile}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _staffProfile = customStaffProfile ??
        const VenueStaffProfile(
          staffId: 'user_venue_staff_001',
          partnerId: 'org_venue_001',
          partnerName: 'Grand Slam Pickleball Arena',
          staffName: 'Marcus Bell',
          staffEmail: 'marcus.bell@grandslamarena.com',
          roleTitle: 'Front Desk & Court Operations',
          assignedLocationIds: ['loc_andheri'],
          assignedLocationNames: ['Andheri Arena'],
          permissions: {
            VenueStaffPermission.viewDashboard,
            VenueStaffPermission.manageCheckIn,
            VenueStaffPermission.manageMaintenance,
            VenueStaffPermission.submitPurchases,
            VenueStaffPermission.recordOfflinePayments,
            VenueStaffPermission.viewReports,
          },
          isActive: true,
        );

    _allPartnerLocations = const [
      VenueLocation(
        id: 'loc_andheri',
        partnerId: 'org_venue_001',
        name: 'Andheri Arena',
        city: 'Mumbai',
        address: 'Plot 42, Link Road, Andheri West, Mumbai',
        operatingHours: '06:00 AM – 11:00 PM',
        slotDurationMinutes: 60,
        advanceBookingWindowDays: 14,
        cancellationCutoffHours: 6,
        confirmationMode: VenueBookingRuleConfirmationMode.autoConfirm,
        isActive: true,
      ),
      // Unassigned location — must never be exposed or mutated by this staff member.
      VenueLocation(
        id: 'loc_powai',
        partnerId: 'org_venue_001',
        name: 'Powai Lakefront Courts',
        city: 'Mumbai',
        address: 'Hiranandani Gardens, Powai, Mumbai',
        operatingHours: '06:30 AM – 10:00 PM',
        slotDurationMinutes: 60,
        advanceBookingWindowDays: 7,
        cancellationCutoffHours: 12,
        confirmationMode: VenueBookingRuleConfirmationMode.manualApproval,
        isActive: true,
      ),
    ];

    _allPartnerCourts = const [
      VenueCourt(
        id: 'court_a1',
        partnerId: 'org_venue_001',
        locationId: 'loc_andheri',
        locationName: 'Andheri Arena',
        name: 'Court 1 — Pro Cushion',
        surfaceType: 'Cushioned Acrylic',
        isIndoor: true,
        hasLighting: true,
        hourlyRateInr: 800,
        peakHourlyRateInr: 1100,
        isActive: true,
      ),
      VenueCourt(
        id: 'court_a2',
        partnerId: 'org_venue_001',
        locationId: 'loc_andheri',
        locationName: 'Andheri Arena',
        name: 'Court 2 — Pro Cushion',
        surfaceType: 'Cushioned Acrylic',
        isIndoor: true,
        hasLighting: true,
        hourlyRateInr: 800,
        peakHourlyRateInr: 1100,
        isActive: true,
      ),
      VenueCourt(
        id: 'court_p1',
        partnerId: 'org_venue_001',
        locationId: 'loc_powai',
        locationName: 'Powai Lakefront Courts',
        name: 'Court A — Outdoor Open',
        surfaceType: 'Tournament Hardcourt',
        isIndoor: false,
        hasLighting: true,
        hourlyRateInr: 650,
        peakHourlyRateInr: 900,
        isActive: true,
      ),
    ];

    _allPartnerBlocks = [
      CourtAvailabilityBlock(
        id: 'blk_001',
        partnerId: 'org_venue_001',
        locationId: 'loc_andheri',
        courtId: 'court_a2',
        courtName: 'Court 2 — Pro Cushion',
        title: 'LED Lighting Calibration',
        reason: 'Scheduled facility maintenance',
        startTime: today.add(const Duration(hours: 13)),
        endTime: today.add(const Duration(hours: 15)),
      ),
    ];

    _allPartnerBookings = [
      VenuePartnerBooking(
        id: 'bkg_vp_001',
        partnerId: 'org_venue_001',
        locationId: 'loc_andheri',
        locationName: 'Andheri Arena',
        courtId: 'court_a1',
        courtName: 'Court 1 — Pro Cushion',
        playerName: 'Siddharth Rao',
        playerPhone: '+91 98201 11223',
        slotStart: today.add(const Duration(hours: 18)),
        slotEnd: today.add(const Duration(hours: 19)),
        amountInr: 1100,
        status: PartnerBookingStatus.confirmed,
        paymentStatus: ManualPaymentStatus.paidAtVenue,
        notes: 'Paid via UPI at front desk.',
      ),
      VenuePartnerBooking(
        id: 'bkg_vp_002',
        partnerId: 'org_venue_001',
        locationId: 'loc_powai',
        locationName: 'Powai Lakefront Courts',
        courtId: 'court_p1',
        courtName: 'Court A — Outdoor Open',
        playerName: 'Meera Nair',
        playerPhone: '+91 98199 33445',
        slotStart: today.add(const Duration(hours: 19)),
        slotEnd: today.add(const Duration(hours: 20)),
        amountInr: 900,
        status: PartnerBookingStatus.pending,
        paymentStatus: ManualPaymentStatus.unpaid,
      ),
      VenuePartnerBooking(
        id: 'bkg_vp_003',
        partnerId: 'org_venue_001',
        locationId: 'loc_andheri',
        locationName: 'Andheri Arena',
        courtId: 'court_a1',
        courtName: 'Court 1 — Pro Cushion',
        playerName: 'Kabir Deshmukh',
        playerPhone: '+91 98207 55667',
        slotStart: today.add(const Duration(hours: 8)),
        slotEnd: today.add(const Duration(hours: 9)),
        amountInr: 800,
        status: PartnerBookingStatus.checkedIn,
        paymentStatus: ManualPaymentStatus.pendingVerification,
      ),
    ];

    _allPartnerTasks = [
      VenueMaintenanceTask(
        id: 'task_001',
        partnerId: 'org_venue_001',
        locationId: 'loc_andheri',
        locationName: 'Andheri Arena',
        courtId: 'court_a2',
        courtName: 'Court 2 — Pro Cushion',
        title: 'Inspect LED floodlight ballast',
        description: 'Verify court-side lux levels prior to evening slots.',
        status: VenueMaintenanceTaskStatus.inProgress,
        assignedToStaffId: _staffProfile.staffId,
        updatedAt: now.subtract(const Duration(hours: 1)),
      ),
      VenueMaintenanceTask(
        id: 'task_002',
        partnerId: 'org_venue_001',
        locationId: 'loc_andheri',
        locationName: 'Andheri Arena',
        courtId: 'court_a1',
        courtName: 'Court 1 — Pro Cushion',
        title: 'Center net tension check',
        description: 'Confirm 34-inch center strap height before morning play.',
        status: VenueMaintenanceTaskStatus.open,
        assignedToStaffId: _staffProfile.staffId,
        updatedAt: now.subtract(const Duration(hours: 3)),
      ),
      // Unassigned location task — excluded on read & blocked on mutation.
      VenueMaintenanceTask(
        id: 'task_003',
        partnerId: 'org_venue_001',
        locationId: 'loc_powai',
        locationName: 'Powai Lakefront Courts',
        courtId: 'court_p1',
        courtName: 'Court A — Outdoor Open',
        title: 'Dry outdoor baseline after rain',
        description: 'Squeegee surface before 4 PM slot.',
        status: VenueMaintenanceTaskStatus.open,
        assignedToStaffId: 'other_staff',
        updatedAt: now.subtract(const Duration(hours: 4)),
      ),
    ];

    _allPartnerPurchases = [
      VenuePurchaseSubmission(
        id: 'pur_001',
        partnerId: 'org_venue_001',
        locationId: 'loc_andheri',
        locationName: 'Andheri Arena',
        title: 'Tournament Net Replacement (2x)',
        category: 'Equipment',
        amountInr: 6800,
        receiptReference: 'RCPT-AND-2026-104',
        submittedByStaffId: _staffProfile.staffId,
        submittedByName: _staffProfile.staffName,
        submittedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  FailureResult<VenueStaffWorkspaceData>? _validateStaffContext({
    required String partnerId,
    required String staffId,
  }) {
    if (partnerId.trim().isEmpty || partnerId != _staffProfile.partnerId) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Unauthorized: venue partner context mismatch.',
        ),
      );
    }
    if (staffId.trim().isEmpty || staffId != _staffProfile.staffId) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Unauthorized: venue staff identity mismatch.',
        ),
      );
    }
    if (!_staffProfile.isActive) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Access revoked: venue staff account is inactive.',
        ),
      );
    }
    return null;
  }

  FailureResult<VenueStaffWorkspaceData>? _requirePermission(
    VenueStaffPermission permission,
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

  FailureResult<VenueStaffWorkspaceData>? _requireLocationAccess(
    String locationId,
  ) {
    if (!_staffProfile.canAccessLocation(locationId)) {
      return const FailureResult(
        ForbiddenFailure(
          message:
              'Unauthorized: you are not assigned to this venue location.',
        ),
      );
    }
    return null;
  }

  VenueStaffWorkspaceData _buildScopedWorkspace() {
    final allowedLocations = _staffProfile.assignedLocationIds.toSet();
    final partnerId = _staffProfile.partnerId;

    final locations = _allPartnerLocations
        .where((l) => l.partnerId == partnerId && allowedLocations.contains(l.id))
        .toList();

    final courts = _allPartnerCourts
        .where((c) =>
            c.partnerId == partnerId && allowedLocations.contains(c.locationId))
        .toList();

    final blocks = _allPartnerBlocks
        .where((b) =>
            b.partnerId == partnerId && allowedLocations.contains(b.locationId))
        .toList();

    final canSeeBookings =
        _staffProfile.hasPermission(VenueStaffPermission.manageCheckIn) ||
            _staffProfile
                .hasPermission(VenueStaffPermission.recordOfflinePayments) ||
            _staffProfile.hasPermission(VenueStaffPermission.viewReports);

    final bookings = canSeeBookings
        ? _allPartnerBookings
            .where((b) =>
                b.partnerId == partnerId &&
                allowedLocations.contains(b.locationId))
            .toList()
        : const <VenuePartnerBooking>[];

    final tasks =
        _staffProfile.hasPermission(VenueStaffPermission.manageMaintenance)
            ? _allPartnerTasks
                .where((t) =>
                    t.partnerId == partnerId &&
                    allowedLocations.contains(t.locationId))
                .toList()
            : const <VenueMaintenanceTask>[];

    final purchases =
        _staffProfile.hasPermission(VenueStaffPermission.submitPurchases)
            ? _allPartnerPurchases
                .where((p) =>
                    p.partnerId == partnerId &&
                    allowedLocations.contains(p.locationId))
                .toList()
            : const <VenuePurchaseSubmission>[];

    return VenueStaffWorkspaceData(
      staffProfile: _staffProfile,
      assignedLocations: locations,
      courts: courts,
      availabilityBlocks: blocks,
      bookings: bookings,
      maintenanceTasks: tasks,
      purchaseSubmissions: purchases,
    );
  }

  @override
  Future<Result<VenueStaffWorkspaceData>> getWorkspaceData({
    required String partnerId,
    required String staffId,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to load Venue Staff workspace.'),
      );
    }
    final err = _validateStaffContext(partnerId: partnerId, staffId: staffId);
    if (err != null) return err;
    return Success(_buildScopedWorkspace());
  }

  @override
  Future<Result<VenueStaffWorkspaceData>> updateBookingOperationalStatus({
    required String partnerId,
    required String staffId,
    required String bookingId,
    required PartnerBookingStatus newStatus,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update booking status.'),
      );
    }
    final err = _validateStaffContext(partnerId: partnerId, staffId: staffId);
    if (err != null) return err;

    final permErr = _requirePermission(VenueStaffPermission.manageCheckIn);
    if (permErr != null) return permErr;

    final booking = _allPartnerBookings
        .where((b) => b.id == bookingId && b.partnerId == partnerId)
        .firstOrNull;
    if (booking == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Booking not found for this venue partner.'),
      );
    }

    final locErr = _requireLocationAccess(booking.locationId);
    if (locErr != null) return locErr;

    if (booking.status == PartnerBookingStatus.cancelled ||
        booking.status == PartnerBookingStatus.declined) {
      if (newStatus != booking.status) {
        return const FailureResult(
          ValidationFailure(
            message: 'Closed bookings (cancelled or declined) cannot be reopened.',
          ),
        );
      }
    }

    _allPartnerBookings = _allPartnerBookings
        .map((b) => b.id == bookingId ? b.copyWith(status: newStatus) : b)
        .toList();

    return Success(_buildScopedWorkspace());
  }

  @override
  Future<Result<VenueStaffWorkspaceData>> recordOfflinePayment({
    required String partnerId,
    required String staffId,
    required String bookingId,
    required ManualPaymentStatus paymentStatus,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to record offline payment.'),
      );
    }
    final err = _validateStaffContext(partnerId: partnerId, staffId: staffId);
    if (err != null) return err;

    final permErr =
        _requirePermission(VenueStaffPermission.recordOfflinePayments);
    if (permErr != null) return permErr;

    final booking = _allPartnerBookings
        .where((b) => b.id == bookingId && b.partnerId == partnerId)
        .firstOrNull;
    if (booking == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Booking not found for this venue partner.'),
      );
    }

    final locErr = _requireLocationAccess(booking.locationId);
    if (locErr != null) return locErr;

    _allPartnerBookings = _allPartnerBookings
        .map((b) =>
            b.id == bookingId ? b.copyWith(paymentStatus: paymentStatus) : b)
        .toList();

    return Success(_buildScopedWorkspace());
  }

  @override
  Future<Result<VenueStaffWorkspaceData>> updateMaintenanceTaskStatus({
    required String partnerId,
    required String staffId,
    required String taskId,
    required VenueMaintenanceTaskStatus status,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update maintenance task.'),
      );
    }
    final err = _validateStaffContext(partnerId: partnerId, staffId: staffId);
    if (err != null) return err;

    final permErr = _requirePermission(VenueStaffPermission.manageMaintenance);
    if (permErr != null) return permErr;

    final task = _allPartnerTasks
        .where((t) => t.id == taskId && t.partnerId == partnerId)
        .firstOrNull;
    if (task == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Maintenance task not found for this partner.'),
      );
    }

    final locErr = _requireLocationAccess(task.locationId);
    if (locErr != null) return locErr;

    _allPartnerTasks = _allPartnerTasks
        .map((t) => t.id == taskId
            ? t.copyWith(status: status, updatedAt: DateTime.now())
            : t)
        .toList();

    return Success(_buildScopedWorkspace());
  }

  @override
  Future<Result<VenueStaffWorkspaceData>> createCourtMaintenanceBlock({
    required String partnerId,
    required String staffId,
    required String courtId,
    required String title,
    required String reason,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to create maintenance block.'),
      );
    }
    final err = _validateStaffContext(partnerId: partnerId, staffId: staffId);
    if (err != null) return err;

    final permErr = _requirePermission(VenueStaffPermission.manageMaintenance);
    if (permErr != null) return permErr;

    final court = _allPartnerCourts
        .where((c) => c.id == courtId && c.partnerId == partnerId)
        .firstOrNull;
    if (court == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Court not found for this venue partner.'),
      );
    }

    final locErr = _requireLocationAccess(court.locationId);
    if (locErr != null) return locErr;

    if (title.trim().isEmpty || !endTime.isAfter(startTime)) {
      return const FailureResult(
        ValidationFailure(
          message: 'Block title and valid end time after start time are required.',
        ),
      );
    }

    final block = CourtAvailabilityBlock(
      id: 'blk_${DateTime.now().microsecondsSinceEpoch}',
      partnerId: partnerId,
      locationId: court.locationId,
      courtId: court.id,
      courtName: court.name,
      title: title.trim(),
      reason: reason.trim().isEmpty ? 'Maintenance hold' : reason.trim(),
      startTime: startTime,
      endTime: endTime,
    );

    _allPartnerBlocks = [..._allPartnerBlocks, block];
    return Success(_buildScopedWorkspace());
  }

  @override
  Future<Result<VenueStaffWorkspaceData>> submitPurchaseWithReceipt({
    required String partnerId,
    required String staffId,
    required String locationId,
    required String title,
    required String category,
    required double amountInr,
    required String receiptReference,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to submit purchase receipt.'),
      );
    }
    final err = _validateStaffContext(partnerId: partnerId, staffId: staffId);
    if (err != null) return err;

    final permErr = _requirePermission(VenueStaffPermission.submitPurchases);
    if (permErr != null) return permErr;

    final locErr = _requireLocationAccess(locationId);
    if (locErr != null) return locErr;

    final location = _allPartnerLocations
        .where((l) => l.id == locationId && l.partnerId == partnerId)
        .firstOrNull;
    if (location == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Assigned location not found.'),
      );
    }

    if (title.trim().isEmpty ||
        amountInr <= 0 ||
        receiptReference.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message:
              'Purchase title, positive amount, and receipt reference are required.',
        ),
      );
    }

    final submission = VenuePurchaseSubmission(
      id: 'pur_${DateTime.now().microsecondsSinceEpoch}',
      partnerId: partnerId,
      locationId: location.id,
      locationName: location.name,
      title: title.trim(),
      category: category.trim().isEmpty ? 'Supplies' : category.trim(),
      amountInr: amountInr,
      receiptReference: receiptReference.trim(),
      submittedByStaffId: staffId,
      submittedByName: _staffProfile.staffName,
      submittedAt: DateTime.now(),
    );

    _allPartnerPurchases = [..._allPartnerPurchases, submission];
    return Success(_buildScopedWorkspace());
  }
}
