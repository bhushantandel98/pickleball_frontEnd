import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_profile.dart';

/// Repository contract for managing the Coach's personal profile,
/// experience, certifications, specializations, personal services, and fees.
abstract class CoachProfileRepository {
  Future<Result<CoachProfile>> getCoachProfile({String? coachId});

  Future<Result<CoachProfile>> updatePersonalDetails({
    required String coachId,
    required String fullName,
    required String phone,
    required String email,
    required String city,
    required String bio,
    String? avatarUrl,
    bool clearAvatar = false,
  });

  Future<Result<CoachProfile>> updateExperience({
    required String coachId,
    required int yearsOfExperience,
    required String coachingExperienceSummary,
    required String professionalBackground,
  });

  Future<Result<CoachProfile>> addCertification({
    required String coachId,
    required CoachCertification certification,
  });

  Future<Result<CoachProfile>> updateCertification({
    required String coachId,
    required CoachCertification certification,
  });

  Future<Result<CoachProfile>> removeCertification({
    required String coachId,
    required String certificationId,
  });

  Future<Result<CoachProfile>> updateSpecializations({
    required String coachId,
    required List<String> specializations,
  });

  Future<Result<CoachProfile>> addService({
    required String coachId,
    required CoachServiceOffering service,
  });

  Future<Result<CoachProfile>> updateService({
    required String coachId,
    required CoachServiceOffering service,
  });

  Future<Result<CoachProfile>> removeService({
    required String coachId,
    required String serviceId,
  });

  Future<Result<CoachProfile>> updateFees({
    required String coachId,
    required double defaultHourlyFee,
    required String feeNotes,
  });
}
