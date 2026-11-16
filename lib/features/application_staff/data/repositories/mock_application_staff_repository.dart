import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/application_staff/data/models/application_staff_models.dart';
import 'package:pickleball_platform/features/application_staff/domain/entities/application_staff_entities.dart';
import 'package:pickleball_platform/features/application_staff/domain/repositories/application_staff_repository.dart';

/// Mock implementation of [ApplicationStaffRepository] for Feature 7.1.
///
/// Enforces:
/// - Active staff membership (`isActive == true`).
/// - Permission-gated visibility & mutations (`ApplicationStaffPermission`).
/// - Strict organization-level item attribution (`organizationId`).
/// - Strict separation from Application Admin-only approvals, policies & payouts.
class MockApplicationStaffRepository implements ApplicationStaffRepository {
  final Map<String, ApplicationStaffProfileModel> _staffByUserId = {
    'user_app_staff_001': ApplicationStaffProfileModel(
      staffId: 'app_staff_001',
      userId: 'user_app_staff_001',
      organizationScopeId: 'platform_ops_in',
      authorizedOrganizationIds: const {
        'org_seller_001',
        'org_seller_002',
        'org_venue_001',
        'org_acad_001',
      },
      staffName: 'Elena Rostova',
      staffEmail: 'elena.rostova@platform-staff.com',
      roleTitle: 'Senior Marketplace & Operations Reviewer',
      permissions: const {
        ApplicationStaffPermission.viewDashboard,
        ApplicationStaffPermission.reviewSellers,
        ApplicationStaffPermission.reviewProducts,
        ApplicationStaffPermission.handleSupportTickets,
        ApplicationStaffPermission.monitorPlatformHealth,
      },
      isActive: true,
      assignedAt: DateTime(2024, 11, 1),
    ),
    // Restricted staff profile for verifying permission & org-scope filtering.
    'user_app_staff_002': ApplicationStaffProfileModel(
      staffId: 'app_staff_002',
      userId: 'user_app_staff_002',
      organizationScopeId: 'platform_ops_in',
      authorizedOrganizationIds: const {'org_venue_001'},
      staffName: 'Karan Mehta',
      staffEmail: 'karan.mehta@platform-staff.com',
      roleTitle: 'Support Triage Specialist',
      permissions: const {
        ApplicationStaffPermission.viewDashboard,
        ApplicationStaffPermission.handleSupportTickets,
      },
      isActive: true,
      assignedAt: DateTime(2025, 4, 15),
    ),
  };

  final List<StaffOperationalQueueItemModel> _queue = [
    StaffOperationalQueueItemModel(
      id: 'sq_001',
      organizationId: 'org_seller_001',
      organizationName: 'Apex Pickleball Gear Co.',
      category: StaffQueueCategory.sellerVerification,
      title: 'Seller KYC Review — Apex Pickleball Gear Co.',
      summary:
          'Private Limited seller submitted GST & PAN metadata. Verify address proof completeness before recommending to Application Admin.',
      submittedAt: DateTime(2026, 11, 14, 10, 30),
      status: StaffQueueItemStatus.pendingReview,
    ),
    StaffOperationalQueueItemModel(
      id: 'sq_002',
      organizationId: 'org_seller_002',
      organizationName: 'Dink & Smash Pro Shop',
      category: StaffQueueCategory.productCatalog,
      title: 'Product Review — Portable USAPA Regulation Pickleball Net System',
      summary:
          'Verify pickleball-only compliance, net dimension specs (22 ft), and product imagery before recommending to Application Admin.',
      submittedAt: DateTime(2026, 11, 14, 14, 15),
      status: StaffQueueItemStatus.pendingReview,
    ),
    StaffOperationalQueueItemModel(
      id: 'sq_003',
      organizationId: 'org_seller_002',
      organizationName: 'Dink & Smash Pro Shop',
      category: StaffQueueCategory.productCatalog,
      title: 'Product Clarification — Hex-Tacky Paddle Overgrip (Pack of 3)',
      summary:
          'Requested grip length (cm) in product specifications prior to Admin recommendation.',
      submittedAt: DateTime(2026, 11, 11, 14, 15),
      status: StaffQueueItemStatus.needsInformation,
      staffNote: 'Awaiting grip length specification from seller.',
      updatedByStaffId: 'app_staff_001',
      updatedAt: DateTime(2026, 11, 11, 14, 15),
    ),
    StaffOperationalQueueItemModel(
      id: 'sq_004',
      organizationId: 'org_venue_001',
      organizationName: 'Apex Pickleball Arena',
      category: StaffQueueCategory.supportTriage,
      title: 'Support Ticket #TKT-409 — Court Lighting Schedule Sync',
      summary:
          'Venue partner reported evening slot display mismatch on discovery feed; triage and confirm booking integrity.',
      submittedAt: DateTime(2026, 11, 15, 9, 45),
      status: StaffQueueItemStatus.pendingReview,
    ),
    StaffOperationalQueueItemModel(
      id: 'sq_005',
      organizationId: 'org_acad_001',
      organizationName: 'Summit Pickleball Academy',
      category: StaffQueueCategory.complianceFlag,
      title: 'Compliance Check — Coaching Batch Age-Group Labeling',
      summary:
          'Routine verification of U-14 junior batch guardian consent flag on academy listing.',
      submittedAt: DateTime(2026, 11, 15, 16, 20),
      status: StaffQueueItemStatus.recommendedToAdmin,
      staffNote: 'Verified documentation; recommended for Admin sign-off.',
      updatedByStaffId: 'app_staff_001',
      updatedAt: DateTime(2026, 11, 15, 17, 0),
    ),
    // Out-of-scope organization item to verify staff organization-scope isolation.
    StaffOperationalQueueItemModel(
      id: 'sq_006',
      organizationId: 'org_external_tenant_999',
      organizationName: 'External Region Pickleball Co.',
      category: StaffQueueCategory.sellerVerification,
      title: 'Seller KYC Review — External Region Pickleball Co.',
      summary:
          'Belongs to an organization outside app_staff_001 authorized scope and must remain hidden and unmodifiable.',
      submittedAt: DateTime(2026, 11, 15, 18, 0),
      status: StaffQueueItemStatus.pendingReview,
    ),
  ];

  Result<ApplicationStaffProfileModel> _requireActiveStaff({
    required String userId,
    String? staffId,
  }) {
    final profile = _staffByUserId[userId.trim()];
    if (profile == null) {
      return const FailureResult(
        ForbiddenFailure(
          message:
              'Application Staff profile not found for this authenticated user.',
        ),
      );
    }
    if (!profile.isActive) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Application Staff assignment is inactive or suspended.',
        ),
      );
    }
    if (staffId != null &&
        staffId.trim().isNotEmpty &&
        staffId.trim() != profile.staffId) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Forbidden: Staff identity mismatch.',
        ),
      );
    }
    if (!profile.hasPermission(ApplicationStaffPermission.viewDashboard)) {
      return const FailureResult(
        ForbiddenFailure(
          message:
              'Permission denied: viewDashboard permission is required.',
        ),
      );
    }
    return Success(profile);
  }

  List<StaffOperationalQueueItem> _visibleItemsFor(
    ApplicationStaffProfile profile,
  ) {
    return _queue
        .where(
          (item) =>
              profile.hasPermission(item.category.requiredPermission) &&
              profile.isAuthorizedForOrganization(item.organizationId),
        )
        .toList()
      ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  }

  @override
  Future<Result<ApplicationStaffDashboardSummary>> getStaffDashboard({
    required String userId,
    String? staffId,
  }) async {
    final staffCheck = _requireActiveStaff(userId: userId, staffId: staffId);
    if (staffCheck is FailureResult<ApplicationStaffProfileModel>) {
      return FailureResult(staffCheck.failure);
    }
    final profile = (staffCheck as Success<ApplicationStaffProfileModel>).data;
    final visible = _visibleItemsFor(profile);

    final pendingSellers = visible
        .where(
          (i) =>
              i.category == StaffQueueCategory.sellerVerification &&
              i.status == StaffQueueItemStatus.pendingReview,
        )
        .length;
    final pendingProducts = visible
        .where(
          (i) =>
              i.category == StaffQueueCategory.productCatalog &&
              i.status == StaffQueueItemStatus.pendingReview,
        )
        .length;
    final openTickets = visible
        .where(
          (i) =>
              i.category == StaffQueueCategory.supportTriage &&
              i.status != StaffQueueItemStatus.resolved,
        )
        .length;
    final complianceAlerts = visible
        .where(
          (i) =>
              i.category == StaffQueueCategory.complianceFlag &&
              i.status == StaffQueueItemStatus.pendingReview,
        )
        .length;
    final recommended = visible
        .where((i) => i.status == StaffQueueItemStatus.recommendedToAdmin)
        .length;

    return Success(
      ApplicationStaffDashboardSummary(
        profile: profile,
        pendingSellerReviews: pendingSellers,
        pendingProductReviews: pendingProducts,
        openSupportTickets: openTickets,
        complianceAlerts: complianceAlerts,
        recommendedCount: recommended,
        recentQueueItems: visible.take(5).toList(),
      ),
    );
  }

  @override
  Future<Result<List<StaffOperationalQueueItem>>> getOperationalQueue({
    required String userId,
    StaffQueueCategory? category,
    StaffQueueItemStatus? status,
    String? query,
  }) async {
    final staffCheck = _requireActiveStaff(userId: userId);
    if (staffCheck is FailureResult<ApplicationStaffProfileModel>) {
      return FailureResult(staffCheck.failure);
    }
    final profile = (staffCheck as Success<ApplicationStaffProfileModel>).data;

    if (category != null && !profile.hasPermission(category.requiredPermission)) {
      return FailureResult(
        ForbiddenFailure(
          message:
              'Permission denied: ${category.requiredPermission.label} is required.',
        ),
      );
    }

    var list = _visibleItemsFor(profile);
    if (category != null) {
      list = list.where((i) => i.category == category).toList();
    }
    if (status != null) {
      list = list.where((i) => i.status == status).toList();
    }
    final q = query?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      list = list.where((i) {
        return i.title.toLowerCase().contains(q) ||
            i.organizationName.toLowerCase().contains(q) ||
            i.summary.toLowerCase().contains(q);
      }).toList();
    }

    return Success(List<StaffOperationalQueueItem>.unmodifiable(list));
  }

  @override
  Future<Result<StaffOperationalQueueItem>> updateQueueItemStatus({
    required String userId,
    required String itemId,
    required StaffQueueItemStatus nextStatus,
    required String note,
  }) async {
    final staffCheck = _requireActiveStaff(userId: userId);
    if (staffCheck is FailureResult<ApplicationStaffProfileModel>) {
      return FailureResult(staffCheck.failure);
    }
    final profile = (staffCheck as Success<ApplicationStaffProfileModel>).data;

    final index = _queue.indexWhere((i) => i.id == itemId);
    if (index == -1) {
      return const FailureResult(
        NotFoundFailure(message: 'Operational queue item not found.'),
      );
    }

    final item = _queue[index];
    if (!profile.isAuthorizedForOrganization(item.organizationId)) {
      return const FailureResult(
        ForbiddenFailure(
          message:
              'Forbidden: Item belongs to an organization outside your authorized staff scope.',
        ),
      );
    }
    if (!profile.hasPermission(item.category.requiredPermission)) {
      return FailureResult(
        ForbiddenFailure(
          message:
              'Permission denied: ${item.category.requiredPermission.label} is required for this item.',
        ),
      );
    }

    if (nextStatus == StaffQueueItemStatus.pendingReview) {
      return const FailureResult(
        ValidationFailure(
          message: 'Select a valid staff triage or recommendation action.',
        ),
      );
    }
    if (nextStatus == StaffQueueItemStatus.resolved &&
        item.category != StaffQueueCategory.supportTriage) {
      return const FailureResult(
        ForbiddenFailure(
          message:
              'Only Support Triage items can be resolved by Application Staff. Seller & Product items require Application Admin final decision.',
        ),
      );
    }

    final trimmedNote = note.trim();
    if (trimmedNote.length < 5) {
      return const FailureResult(
        ValidationFailure(
          message: 'Provide an audit note (at least 5 characters).',
        ),
      );
    }

    final updated = StaffOperationalQueueItemModel(
      id: item.id,
      organizationId: item.organizationId,
      organizationName: item.organizationName,
      category: item.category,
      title: item.title,
      summary: item.summary,
      submittedAt: item.submittedAt,
      status: nextStatus,
      staffNote: trimmedNote,
      updatedByStaffId: profile.staffId,
      updatedAt: DateTime.now(),
    );
    _queue[index] = updated;
    return Success(updated);
  }
}
