import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';

/// Contract for Player Academy and Coach discovery, enrollment, and inquiry operations.
abstract class CoachingAcademyRepository {
  /// Retrieves public academy branches matching optional search query and city.
  Future<Result<List<AcademyBranch>>> getAcademyBranches({
    String? query,
    String? city,
  });

  /// Retrieves detailed information for an academy branch including its programs and batches.
  Future<Result<AcademyBranch>> getAcademyBranchById(String branchId);

  /// Submits an enrollment request for an academy batch.
  ///
  /// In accordance with PRD rules, enrollment requires academy approval and is never auto-approved.
  /// When batch is full, it must only proceed if waitlist is enabled for that batch.
  Future<Result<AcademyEnrollmentRequest>> submitEnrollmentRequest({
    required String branchId,
    required String programId,
    required String batchId,
    required String playerName,
    required String playerPhone,
    String playerEmail = '',
    double? playerRating,
    required String emergencyContactName,
    required String emergencyContactPhone,
    String? notes,
    bool isWaitlist = false,
  });

  /// Retrieves the current player's submitted academy enrollment requests.
  Future<Result<List<AcademyEnrollmentRequest>>> getMyEnrollmentRequests();

  /// Cancels a pending or waitlisted enrollment request.
  Future<Result<AcademyEnrollmentRequest>> cancelEnrollmentRequest(String requestId);

  /// Retrieves registered coaches matching optional search query, city, or specialization.
  Future<Result<List<CoachItem>>> getCoaches({
    String? query,
    String? city,
    String? specialization,
  });

  /// Retrieves detailed profile and services for a registered coach.
  Future<Result<CoachItem>> getCoachById(String coachId);

  /// Submits a coaching inquiry or connection request to a coach.
  ///
  /// Note: Submitting does not grant coaching dashboard access. Access requires explicit coach grant.
  Future<Result<CoachInquiryRequest>> submitCoachInquiry({
    required String coachId,
    String? serviceId,
    required String playerName,
    required String playerPhone,
    String playerEmail = '',
    required String preferredDays,
    double? playerRating,
    required String trainingGoal,
    required String message,
  });

  /// Retrieves the current player's submitted coaching inquiries.
  Future<Result<List<CoachInquiryRequest>>> getMyCoachInquiries();

  /// Cancels a pending coaching inquiry.
  Future<Result<CoachInquiryRequest>> cancelCoachInquiry(String inquiryId);
}
