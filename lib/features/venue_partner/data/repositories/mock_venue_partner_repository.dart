import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/venue_partner/domain/entities/venue_partner_entities.dart';
import 'package:pickleball_platform/features/venue_partner/domain/repositories/venue_partner_repository.dart';

/// Mock implementation of [VenuePartnerRepository] for Phase 3 — Feature 3.7.
///
/// Enforces:
/// - Strict partner ownership (`partnerId` must match `_data.profile.partnerId`).
/// - Cross-record ownership checks (`record.partnerId == partnerId`).
/// - Valid booking rules (slot duration > 0, advance window >= 1, cutoff >= 0).
/// - Valid booking lifecycle transitions and V1 offline-only manual payments.
class MockVenuePartnerRepository implements VenuePartnerRepository {
  bool shouldFail;
  late VenuePartnerWorkspaceData _data;

  MockVenuePartnerRepository({this.shouldFail = false}) {
    _seedData();
  }

  void _seedData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _data = VenuePartnerWorkspaceData(
      profile: const VenuePartnerProfile(
        partnerId: 'org_venue_001',
        partnerName: 'Grand Slam Pickleball Arena',
        ownerName: 'Vikram Singhania',
        contactEmail: 'ops@grandslamarena.com',
        contactPhone: '+91 98200 77889',
      ),
      locations: const [
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
      ],
      courts: const [
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
      ],
      availabilityBlocks: [
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
      ],
      bookings: [
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
          notes: 'Requested manual approval.',
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
      ],
      staffAssignments: const [
        VenueStaffAssignment(
          id: 'vstaff_001',
          partnerId: 'org_venue_001',
          locationId: 'loc_andheri',
          locationName: 'Andheri Arena',
          staffName: 'Marcus Bell',
          staffEmail: 'marcus.bell@grandslamarena.com',
          roleTitle: 'Front Desk & Court Operations',
          permissions: ['Check-in Bookings', 'Maintenance Tasks', 'Log Purchases'],
          isActive: true,
        ),
      ],
      expenses: [
        VenueExpenseRecord(
          id: 'exp_001',
          partnerId: 'org_venue_001',
          locationId: 'loc_andheri',
          locationName: 'Andheri Arena',
          title: 'Tournament Net Replacement (2x)',
          category: 'Equipment',
          amountInr: 6800,
          recordedAt: now.subtract(const Duration(days: 2)),
          submittedBy: 'Marcus Bell',
        ),
      ],
    );
  }

  FailureResult<VenuePartnerWorkspaceData>? _validatePartnerOwnership(
    String partnerId,
  ) {
    if (partnerId.trim().isEmpty || partnerId != _data.profile.partnerId) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Unauthorized: venue partner context mismatch.',
        ),
      );
    }
    return null;
  }

  @override
  Future<Result<VenuePartnerWorkspaceData>> getWorkspaceData({
    required String partnerId,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to load venue partner workspace.'),
      );
    }
    final err = _validatePartnerOwnership(partnerId);
    if (err != null) return err;
    return Success(_data);
  }

  @override
  Future<Result<VenuePartnerWorkspaceData>> createLocation({
    required String partnerId,
    required String name,
    required String city,
    required String address,
    required String operatingHours,
    required int slotDurationMinutes,
    required int advanceBookingWindowDays,
    required int cancellationCutoffHours,
    required VenueBookingRuleConfirmationMode confirmationMode,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to create venue location.'),
      );
    }
    final err = _validatePartnerOwnership(partnerId);
    if (err != null) return err;

    if (name.trim().isEmpty || city.trim().isEmpty || address.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Location name, city, and address are required.',
        ),
      );
    }
    if (slotDurationMinutes <= 0 ||
        advanceBookingWindowDays <= 0 ||
        cancellationCutoffHours < 0) {
      return const FailureResult(
        ValidationFailure(
          message: 'Booking rule values must be valid positive numbers.',
        ),
      );
    }

    final location = VenueLocation(
      id: 'loc_${DateTime.now().microsecondsSinceEpoch}',
      partnerId: partnerId,
      name: name.trim(),
      city: city.trim(),
      address: address.trim(),
      operatingHours: operatingHours.trim().isEmpty
          ? '06:00 AM – 10:00 PM'
          : operatingHours.trim(),
      slotDurationMinutes: slotDurationMinutes,
      advanceBookingWindowDays: advanceBookingWindowDays,
      cancellationCutoffHours: cancellationCutoffHours,
      confirmationMode: confirmationMode,
      isActive: true,
    );

    _data = VenuePartnerWorkspaceData(
      profile: _data.profile,
      locations: [..._data.locations, location],
      courts: _data.courts,
      availabilityBlocks: _data.availabilityBlocks,
      bookings: _data.bookings,
      staffAssignments: _data.staffAssignments,
      expenses: _data.expenses,
    );
    return Success(_data);
  }

  @override
  Future<Result<VenuePartnerWorkspaceData>> updateLocationAndRules({
    required String partnerId,
    required String locationId,
    required String name,
    required String city,
    required String address,
    required String operatingHours,
    required int slotDurationMinutes,
    required int advanceBookingWindowDays,
    required int cancellationCutoffHours,
    required VenueBookingRuleConfirmationMode confirmationMode,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update venue location.'),
      );
    }
    final err = _validatePartnerOwnership(partnerId);
    if (err != null) return err;

    final existing = _data.locations
        .where((l) => l.id == locationId && l.partnerId == partnerId)
        .firstOrNull;
    if (existing == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Location not found for this partner.'),
      );
    }
    if (name.trim().isEmpty || city.trim().isEmpty || address.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Location name, city, and address are required.',
        ),
      );
    }
    if (slotDurationMinutes <= 0 ||
        advanceBookingWindowDays <= 0 ||
        cancellationCutoffHours < 0) {
      return const FailureResult(
        ValidationFailure(
          message: 'Booking rule values must be valid positive numbers.',
        ),
      );
    }

    final updatedLocations = _data.locations.map((l) {
      if (l.id != locationId) return l;
      return l.copyWith(
        name: name.trim(),
        city: city.trim(),
        address: address.trim(),
        operatingHours: operatingHours.trim(),
        slotDurationMinutes: slotDurationMinutes,
        advanceBookingWindowDays: advanceBookingWindowDays,
        cancellationCutoffHours: cancellationCutoffHours,
        confirmationMode: confirmationMode,
      );
    }).toList();

    _data = VenuePartnerWorkspaceData(
      profile: _data.profile,
      locations: updatedLocations,
      courts: _data.courts,
      availabilityBlocks: _data.availabilityBlocks,
      bookings: _data.bookings,
      staffAssignments: _data.staffAssignments,
      expenses: _data.expenses,
    );
    return Success(_data);
  }

  @override
  Future<Result<VenuePartnerWorkspaceData>> toggleLocationStatus({
    required String partnerId,
    required String locationId,
    required bool isActive,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update location status.'),
      );
    }
    final err = _validatePartnerOwnership(partnerId);
    if (err != null) return err;

    final existing = _data.locations
        .where((l) => l.id == locationId && l.partnerId == partnerId)
        .firstOrNull;
    if (existing == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Location not found for this partner.'),
      );
    }

    final updated = _data.locations
        .map((l) => l.id == locationId ? l.copyWith(isActive: isActive) : l)
        .toList();

    _data = VenuePartnerWorkspaceData(
      profile: _data.profile,
      locations: updated,
      courts: _data.courts,
      availabilityBlocks: _data.availabilityBlocks,
      bookings: _data.bookings,
      staffAssignments: _data.staffAssignments,
      expenses: _data.expenses,
    );
    return Success(_data);
  }

  @override
  Future<Result<VenuePartnerWorkspaceData>> createCourt({
    required String partnerId,
    required String locationId,
    required String name,
    required String surfaceType,
    required bool isIndoor,
    required bool hasLighting,
    required double hourlyRateInr,
    required double peakHourlyRateInr,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to create court.'),
      );
    }
    final err = _validatePartnerOwnership(partnerId);
    if (err != null) return err;

    final location = _data.locations
        .where((l) => l.id == locationId && l.partnerId == partnerId)
        .firstOrNull;
    if (location == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Location not found for this partner.'),
      );
    }
    if (name.trim().isEmpty || hourlyRateInr < 0 || peakHourlyRateInr < 0) {
      return const FailureResult(
        ValidationFailure(
          message: 'Court name and non-negative hourly rates are required.',
        ),
      );
    }

    final court = VenueCourt(
      id: 'court_${DateTime.now().microsecondsSinceEpoch}',
      partnerId: partnerId,
      locationId: location.id,
      locationName: location.name,
      name: name.trim(),
      surfaceType:
          surfaceType.trim().isEmpty ? 'Acrylic' : surfaceType.trim(),
      isIndoor: isIndoor,
      hasLighting: hasLighting,
      hourlyRateInr: hourlyRateInr,
      peakHourlyRateInr: peakHourlyRateInr,
      isActive: true,
    );

    _data = VenuePartnerWorkspaceData(
      profile: _data.profile,
      locations: _data.locations,
      courts: [..._data.courts, court],
      availabilityBlocks: _data.availabilityBlocks,
      bookings: _data.bookings,
      staffAssignments: _data.staffAssignments,
      expenses: _data.expenses,
    );
    return Success(_data);
  }

  @override
  Future<Result<VenuePartnerWorkspaceData>> updateCourtPricing({
    required String partnerId,
    required String courtId,
    required double hourlyRateInr,
    required double peakHourlyRateInr,
    required bool isActive,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update court pricing.'),
      );
    }
    final err = _validatePartnerOwnership(partnerId);
    if (err != null) return err;

    final existing = _data.courts
        .where((c) => c.id == courtId && c.partnerId == partnerId)
        .firstOrNull;
    if (existing == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Court not found for this partner.'),
      );
    }
    if (hourlyRateInr < 0 || peakHourlyRateInr < 0) {
      return const FailureResult(
        ValidationFailure(message: 'Hourly rates cannot be negative.'),
      );
    }

    final updatedCourts = _data.courts.map((c) {
      if (c.id != courtId) return c;
      return c.copyWith(
        hourlyRateInr: hourlyRateInr,
        peakHourlyRateInr: peakHourlyRateInr,
        isActive: isActive,
      );
    }).toList();

    _data = VenuePartnerWorkspaceData(
      profile: _data.profile,
      locations: _data.locations,
      courts: updatedCourts,
      availabilityBlocks: _data.availabilityBlocks,
      bookings: _data.bookings,
      staffAssignments: _data.staffAssignments,
      expenses: _data.expenses,
    );
    return Success(_data);
  }

  @override
  Future<Result<VenuePartnerWorkspaceData>> createAvailabilityBlock({
    required String partnerId,
    required String courtId,
    required String title,
    required String reason,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to create availability block.'),
      );
    }
    final err = _validatePartnerOwnership(partnerId);
    if (err != null) return err;

    final court = _data.courts
        .where((c) => c.id == courtId && c.partnerId == partnerId)
        .firstOrNull;
    if (court == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Court not found for this partner.'),
      );
    }
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
      reason: reason.trim().isEmpty ? 'Manual hold' : reason.trim(),
      startTime: startTime,
      endTime: endTime,
    );

    _data = VenuePartnerWorkspaceData(
      profile: _data.profile,
      locations: _data.locations,
      courts: _data.courts,
      availabilityBlocks: [..._data.availabilityBlocks, block],
      bookings: _data.bookings,
      staffAssignments: _data.staffAssignments,
      expenses: _data.expenses,
    );
    return Success(_data);
  }

  @override
  Future<Result<VenuePartnerWorkspaceData>> removeAvailabilityBlock({
    required String partnerId,
    required String blockId,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to remove availability block.'),
      );
    }
    final err = _validatePartnerOwnership(partnerId);
    if (err != null) return err;

    final existing = _data.availabilityBlocks
        .where((b) => b.id == blockId && b.partnerId == partnerId)
        .firstOrNull;
    if (existing == null) {
      return const FailureResult(
        NotFoundFailure(
            message: 'Availability block not found for this partner.'),
      );
    }

    _data = VenuePartnerWorkspaceData(
      profile: _data.profile,
      locations: _data.locations,
      courts: _data.courts,
      availabilityBlocks:
          _data.availabilityBlocks.where((b) => b.id != blockId).toList(),
      bookings: _data.bookings,
      staffAssignments: _data.staffAssignments,
      expenses: _data.expenses,
    );
    return Success(_data);
  }

  @override
  Future<Result<VenuePartnerWorkspaceData>> updateBookingStatus({
    required String partnerId,
    required String bookingId,
    required PartnerBookingStatus newStatus,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update booking status.'),
      );
    }
    final err = _validatePartnerOwnership(partnerId);
    if (err != null) return err;

    final booking = _data.bookings
        .where((b) => b.id == bookingId && b.partnerId == partnerId)
        .firstOrNull;
    if (booking == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Booking not found for this partner.'),
      );
    }

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

    final updated = _data.bookings.map((b) {
      if (b.id != bookingId) return b;
      return b.copyWith(status: newStatus);
    }).toList();

    _data = VenuePartnerWorkspaceData(
      profile: _data.profile,
      locations: _data.locations,
      courts: _data.courts,
      availabilityBlocks: _data.availabilityBlocks,
      bookings: updated,
      staffAssignments: _data.staffAssignments,
      expenses: _data.expenses,
    );
    return Success(_data);
  }

  @override
  Future<Result<VenuePartnerWorkspaceData>> recordManualPayment({
    required String partnerId,
    required String bookingId,
    required ManualPaymentStatus paymentStatus,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to record manual payment.'),
      );
    }
    final err = _validatePartnerOwnership(partnerId);
    if (err != null) return err;

    final booking = _data.bookings
        .where((b) => b.id == bookingId && b.partnerId == partnerId)
        .firstOrNull;
    if (booking == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Booking not found for this partner.'),
      );
    }

    final updated = _data.bookings.map((b) {
      if (b.id != bookingId) return b;
      return b.copyWith(paymentStatus: paymentStatus);
    }).toList();

    _data = VenuePartnerWorkspaceData(
      profile: _data.profile,
      locations: _data.locations,
      courts: _data.courts,
      availabilityBlocks: _data.availabilityBlocks,
      bookings: updated,
      staffAssignments: _data.staffAssignments,
      expenses: _data.expenses,
    );
    return Success(_data);
  }

  @override
  Future<Result<VenuePartnerWorkspaceData>> addExpense({
    required String partnerId,
    required String locationId,
    required String title,
    required String category,
    required double amountInr,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to record expense.'),
      );
    }
    final err = _validatePartnerOwnership(partnerId);
    if (err != null) return err;

    final location = _data.locations
        .where((l) => l.id == locationId && l.partnerId == partnerId)
        .firstOrNull;
    if (location == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Location not found for this partner.'),
      );
    }
    if (title.trim().isEmpty || amountInr <= 0) {
      return const FailureResult(
        ValidationFailure(
          message: 'Expense title and positive amount are required.',
        ),
      );
    }

    final expense = VenueExpenseRecord(
      id: 'exp_${DateTime.now().microsecondsSinceEpoch}',
      partnerId: partnerId,
      locationId: location.id,
      locationName: location.name,
      title: title.trim(),
      category: category.trim().isEmpty ? 'Operations' : category.trim(),
      amountInr: amountInr,
      recordedAt: DateTime.now(),
      submittedBy: _data.profile.ownerName,
    );

    _data = VenuePartnerWorkspaceData(
      profile: _data.profile,
      locations: _data.locations,
      courts: _data.courts,
      availabilityBlocks: _data.availabilityBlocks,
      bookings: _data.bookings,
      staffAssignments: _data.staffAssignments,
      expenses: [..._data.expenses, expense],
    );
    return Success(_data);
  }

  @override
  Future<Result<VenuePartnerWorkspaceData>> toggleStaffActive({
    required String partnerId,
    required String staffAssignmentId,
    required bool isActive,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update venue staff status.'),
      );
    }
    final err = _validatePartnerOwnership(partnerId);
    if (err != null) return err;

    final existing = _data.staffAssignments
        .where((s) => s.id == staffAssignmentId && s.partnerId == partnerId)
        .firstOrNull;
    if (existing == null) {
      return const FailureResult(
        NotFoundFailure(
            message: 'Venue staff assignment not found for this partner.'),
      );
    }

    final updated = _data.staffAssignments
        .map((s) =>
            s.id == staffAssignmentId ? s.copyWith(isActive: isActive) : s)
        .toList();

    _data = VenuePartnerWorkspaceData(
      profile: _data.profile,
      locations: _data.locations,
      courts: _data.courts,
      availabilityBlocks: _data.availabilityBlocks,
      bookings: _data.bookings,
      staffAssignments: updated,
      expenses: _data.expenses,
    );
    return Success(_data);
  }
}
