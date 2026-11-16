import 'package:equatable/equatable.dart';

/// Delegated permissions assignable to Application Staff by the single
/// Application Admin.
///
/// Platform governance rule: Application Staff cannot self-escalate
/// permissions, cannot grant final seller/product approvals, and cannot access
/// Application Admin-only policies, staff management, or payout controls.
enum ApplicationStaffPermission {
  viewDashboard('View Staff Dashboard'),
  reviewSellers('Review Seller KYC & Recommend'),
  reviewProducts('Review Product Catalog & Recommend'),
  handleSupportTickets('Support & Dispute Triage'),
  monitorPlatformHealth('Platform Operations Monitoring');

  final String label;
  const ApplicationStaffPermission(this.label);
}

/// Authenticated Application Staff profile and delegated permission scope.
class ApplicationStaffProfile extends Equatable {
  final String staffId;
  final String userId;
  final String organizationScopeId;
  final String staffName;
  final String staffEmail;
  final String roleTitle;
  final Set<ApplicationStaffPermission> permissions;
  final bool isActive;
  final DateTime assignedAt;

  const ApplicationStaffProfile({
    required this.staffId,
    required this.userId,
    required this.organizationScopeId,
    required this.staffName,
    required this.staffEmail,
    required this.roleTitle,
    required this.permissions,
    this.isActive = true,
    required this.assignedAt,
  });

  bool hasPermission(ApplicationStaffPermission permission) =>
      isActive && permissions.contains(permission);

  @override
  List<Object?> get props => [
        staffId,
        userId,
        organizationScopeId,
        staffName,
        staffEmail,
        roleTitle,
        permissions,
        isActive,
        assignedAt,
      ];
}

/// Categories of operational queue items handled by Application Staff.
enum StaffQueueCategory {
  sellerVerification('Seller Verification'),
  productCatalog('Product Catalog'),
  supportTriage('Support Triage'),
  complianceFlag('Compliance Flag');

  final String label;
  const StaffQueueCategory(this.label);

  ApplicationStaffPermission get requiredPermission {
    switch (this) {
      case StaffQueueCategory.sellerVerification:
        return ApplicationStaffPermission.reviewSellers;
      case StaffQueueCategory.productCatalog:
        return ApplicationStaffPermission.reviewProducts;
      case StaffQueueCategory.supportTriage:
      case StaffQueueCategory.complianceFlag:
        return ApplicationStaffPermission.handleSupportTickets;
    }
  }
}

/// Lifecycle statuses available to Application Staff.
///
/// Notice: Final `approved` / `rejected` decisions for Sellers & Products are
/// strictly reserved for Application Admin (never exposed here).
enum StaffQueueItemStatus {
  pendingReview('Pending Staff Review'),
  needsInformation('Needs Information'),
  recommendedToAdmin('Recommended to Admin'),
  escalatedToAdmin('Escalated to Admin'),
  resolved('Resolved (Support)');

  final String label;
  const StaffQueueItemStatus(this.label);
}

/// Organization-scoped operational queue item for Application Staff triage.
class StaffOperationalQueueItem extends Equatable {
  final String id;
  final String organizationId;
  final String organizationName;
  final StaffQueueCategory category;
  final String title;
  final String summary;
  final DateTime submittedAt;
  final StaffQueueItemStatus status;
  final String? staffNote;
  final String? updatedByStaffId;
  final DateTime? updatedAt;

  const StaffOperationalQueueItem({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.category,
    required this.title,
    required this.summary,
    required this.submittedAt,
    required this.status,
    this.staffNote,
    this.updatedByStaffId,
    this.updatedAt,
  });

  StaffOperationalQueueItem copyWith({
    StaffQueueItemStatus? status,
    String? staffNote,
    String? updatedByStaffId,
    DateTime? updatedAt,
  }) {
    return StaffOperationalQueueItem(
      id: id,
      organizationId: organizationId,
      organizationName: organizationName,
      category: category,
      title: title,
      summary: summary,
      submittedAt: submittedAt,
      status: status ?? this.status,
      staffNote: staffNote ?? this.staffNote,
      updatedByStaffId: updatedByStaffId ?? this.updatedByStaffId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        organizationId,
        organizationName,
        category,
        title,
        summary,
        submittedAt,
        status,
        staffNote,
        updatedByStaffId,
        updatedAt,
      ];
}

/// Aggregated dashboard summary for Application Staff.
class ApplicationStaffDashboardSummary extends Equatable {
  final ApplicationStaffProfile profile;
  final int pendingSellerReviews;
  final int pendingProductReviews;
  final int openSupportTickets;
  final int complianceAlerts;
  final int recommendedCount;
  final List<StaffOperationalQueueItem> recentQueueItems;

  const ApplicationStaffDashboardSummary({
    required this.profile,
    required this.pendingSellerReviews,
    required this.pendingProductReviews,
    required this.openSupportTickets,
    required this.complianceAlerts,
    required this.recommendedCount,
    required this.recentQueueItems,
  });

  @override
  List<Object?> get props => [
        profile,
        pendingSellerReviews,
        pendingProductReviews,
        openSupportTickets,
        complianceAlerts,
        recommendedCount,
        recentQueueItems,
      ];
}
