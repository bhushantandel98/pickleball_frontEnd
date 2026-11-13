import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_profile.dart';
import 'package:pickleball_platform/features/coach/domain/repositories/coach_profile_repository.dart';

/// In-memory mock implementation of [CoachProfileRepository] for Phase 3 Feature 3.2.
class MockCoachProfileRepository implements CoachProfileRepository {
  final bool shouldFail;
  final bool simulateEmpty;
  CoachProfile? _profile;

  MockCoachProfileRepository({
    this.shouldFail = false,
    this.simulateEmpty = false,
    CoachProfile? initialProfile,
  }) : _profile = initialProfile ?? (simulateEmpty ? null : _defaultProfile());

  static CoachProfile _defaultProfile() {
    return const CoachProfile(
      coachId: 'coach_001',
      fullName: 'Vikram Malhotra',
      phone: '+91 98204 51234',
      email: 'vikram.malhotra@pickleballcoach.in',
      city: 'Mumbai',
      bio:
          'Former national-level racquet sports athlete coaching competitive singles and doubles pickleball mechanics across Mumbai.',
      avatarUrl: 'avatar:pro',
      yearsOfExperience: 7,
      coachingExperienceSummary:
          'Coached 120+ recreational and tournament players from 3.0 to 5.0 DUPR ratings across private and semi-private sessions.',
      professionalBackground:
          'Former Maharashtra State Tennis Quarterfinalist; full-time Pickleball Head Coach & Performance Specialist since 2019.',
      certifications: [
        CoachCertification(
          id: 'cert_001',
          name: 'IPTPA Level 2 Certified Teaching Pro',
          issuingBody: 'International Pickleball Teaching Professional Association',
          yearObtained: '2023',
          details: 'Advanced biomechanics, third-shot strategy & tournament prep.',
        ),
        CoachCertification(
          id: 'cert_002',
          name: 'PPR Certified Pickleball Coach',
          issuingBody: 'Professional Pickleball Registry',
          yearObtained: '2021',
          details: 'Adult & junior foundational stroke development.',
        ),
      ],
      specializations: [
        'Third-Shot Drop & Transition',
        'Doubles Kitchen Strategy',
        'Spin & Serve Mechanics',
        'Tournament Match Prep',
      ],
      services: [
        CoachServiceOffering(
          id: 'srv_001',
          name: '1-on-1 Private Technique Clinic',
          description:
              'Focused individual coaching covering footwork, dinking consistency, and shot selection.',
          durationMinutes: 60,
          fee: 1800,
        ),
        CoachServiceOffering(
          id: 'srv_002',
          name: 'Semi-Private Doubles Strategy (2 Players)',
          description:
              'Partnered court positioning, stacking, and communication drills for tournament pairs.',
          durationMinutes: 90,
          fee: 2600,
        ),
      ],
      defaultHourlyFee: 1800,
      feeNotes:
          'Personal coaching rates apply exclusively to private bookings. Court rental charges are settled separately at the venue.',
      isAcceptingPersonalInquiries: true,
      availabilityWindows: [
        CoachAvailabilityWindow(
          dayLabel: 'Mon, Wed, Fri',
          timeWindow: '06:30 – 09:30 & 17:00 – 19:00',
          locationNote: 'Bandra & Juhu Personal Venues',
        ),
        CoachAvailabilityWindow(
          dayLabel: 'Sat – Sun',
          timeWindow: '07:00 – 11:00',
          locationNote: 'Andheri West Courts',
        ),
      ],
      availabilityNote:
          'Display only — Calendar and slot scheduling is managed separately in Coach Availability & Scheduling.',
    );
  }

  @override
  Future<Result<CoachProfile>> getCoachProfile({String? coachId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to load coach profile.'),
      );
    }

    if (simulateEmpty || _profile == null) {
      return const FailureResult(
        NotFoundFailure(message: 'No coach profile found.'),
      );
    }

    return Success(_profile!);
  }

  @override
  Future<Result<CoachProfile>> updatePersonalDetails({
    required String coachId,
    required String fullName,
    required String phone,
    required String email,
    required String city,
    required String bio,
    String? avatarUrl,
    bool clearAvatar = false,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to save personal details.'),
      );
    }
    if (fullName.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Full name cannot be empty.'),
      );
    }
    if (phone.trim().length < 8) {
      return const FailureResult(
        ValidationFailure(message: 'Please enter a valid contact number.'),
      );
    }
    if (!email.contains('@') || !email.contains('.')) {
      return const FailureResult(
        ValidationFailure(message: 'Please enter a valid email address.'),
      );
    }
    if (city.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'City cannot be empty.'),
      );
    }

    final current = _profile ?? _defaultProfile();
    _profile = current.copyWith(
      fullName: fullName.trim(),
      phone: phone.trim(),
      email: email.trim(),
      city: city.trim(),
      bio: bio.trim(),
      avatarUrl: avatarUrl,
      clearAvatar: clearAvatar,
    );
    return Success(_profile!);
  }

  @override
  Future<Result<CoachProfile>> updateExperience({
    required String coachId,
    required int yearsOfExperience,
    required String coachingExperienceSummary,
    required String professionalBackground,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to update experience details.'),
      );
    }
    if (yearsOfExperience < 0 || yearsOfExperience > 60) {
      return const FailureResult(
        ValidationFailure(
          message: 'Years of experience must be between 0 and 60.',
        ),
      );
    }
    if (coachingExperienceSummary.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Coaching experience summary cannot be empty.',
        ),
      );
    }

    final current = _profile ?? _defaultProfile();
    _profile = current.copyWith(
      yearsOfExperience: yearsOfExperience,
      coachingExperienceSummary: coachingExperienceSummary.trim(),
      professionalBackground: professionalBackground.trim(),
    );
    return Success(_profile!);
  }

  @override
  Future<Result<CoachProfile>> addCertification({
    required String coachId,
    required CoachCertification certification,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to add certification.'),
      );
    }
    if (certification.name.trim().isEmpty ||
        certification.issuingBody.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Certification name and issuing body are required.',
        ),
      );
    }

    final current = _profile ?? _defaultProfile();
    final newCert = certification.copyWith(
      id: certification.id.isEmpty
          ? 'cert_${DateTime.now().millisecondsSinceEpoch}'
          : certification.id,
      name: certification.name.trim(),
      issuingBody: certification.issuingBody.trim(),
      yearObtained: certification.yearObtained.trim(),
      details: certification.details?.trim(),
    );
    _profile = current.copyWith(
      certifications: [...current.certifications, newCert],
    );
    return Success(_profile!);
  }

  @override
  Future<Result<CoachProfile>> updateCertification({
    required String coachId,
    required CoachCertification certification,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to update certification.'),
      );
    }
    if (certification.name.trim().isEmpty ||
        certification.issuingBody.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Certification name and issuing body are required.',
        ),
      );
    }

    final current = _profile ?? _defaultProfile();
    final updated = current.certifications.map((c) {
      return c.id == certification.id ? certification : c;
    }).toList();
    _profile = current.copyWith(certifications: updated);
    return Success(_profile!);
  }

  @override
  Future<Result<CoachProfile>> removeCertification({
    required String coachId,
    required String certificationId,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to remove certification.'),
      );
    }

    final current = _profile ?? _defaultProfile();
    final updated = current.certifications
        .where((c) => c.id != certificationId)
        .toList();
    _profile = current.copyWith(certifications: updated);
    return Success(_profile!);
  }

  @override
  Future<Result<CoachProfile>> updateSpecializations({
    required String coachId,
    required List<String> specializations,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to update specializations.'),
      );
    }

    final cleaned = specializations
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    final current = _profile ?? _defaultProfile();
    _profile = current.copyWith(specializations: cleaned);
    return Success(_profile!);
  }

  @override
  Future<Result<CoachProfile>> addService({
    required String coachId,
    required CoachServiceOffering service,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to add coaching service.'),
      );
    }
    if (service.name.trim().isEmpty || service.description.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Service name and description are required.',
        ),
      );
    }
    if (service.fee <= 0 || service.durationMinutes <= 0) {
      return const FailureResult(
        ValidationFailure(
          message: 'Service fee and duration must be greater than zero.',
        ),
      );
    }

    final current = _profile ?? _defaultProfile();
    final newService = service.copyWith(
      id: service.id.isEmpty
          ? 'srv_${DateTime.now().millisecondsSinceEpoch}'
          : service.id,
      name: service.name.trim(),
      description: service.description.trim(),
    );
    _profile = current.copyWith(
      services: [...current.services, newService],
    );
    return Success(_profile!);
  }

  @override
  Future<Result<CoachProfile>> updateService({
    required String coachId,
    required CoachServiceOffering service,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to update coaching service.'),
      );
    }
    if (service.name.trim().isEmpty || service.description.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Service name and description are required.',
        ),
      );
    }
    if (service.fee <= 0 || service.durationMinutes <= 0) {
      return const FailureResult(
        ValidationFailure(
          message: 'Service fee and duration must be greater than zero.',
        ),
      );
    }

    final current = _profile ?? _defaultProfile();
    final updated = current.services.map((s) {
      return s.id == service.id ? service : s;
    }).toList();
    _profile = current.copyWith(services: updated);
    return Success(_profile!);
  }

  @override
  Future<Result<CoachProfile>> removeService({
    required String coachId,
    required String serviceId,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to remove coaching service.'),
      );
    }

    final current = _profile ?? _defaultProfile();
    final updated =
        current.services.where((s) => s.id != serviceId).toList();
    _profile = current.copyWith(services: updated);
    return Success(_profile!);
  }

  @override
  Future<Result<CoachProfile>> updateFees({
    required String coachId,
    required double defaultHourlyFee,
    required String feeNotes,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to update personal coaching fees.'),
      );
    }
    if (defaultHourlyFee <= 0) {
      return const FailureResult(
        ValidationFailure(
          message: 'Hourly fee must be greater than zero.',
        ),
      );
    }

    final current = _profile ?? _defaultProfile();
    _profile = current.copyWith(
      defaultHourlyFee: defaultHourlyFee,
      feeNotes: feeNotes.trim(),
    );
    return Success(_profile!);
  }
}
