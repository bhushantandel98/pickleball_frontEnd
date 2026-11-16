import 'package:pickleball_platform/features/application_staff/domain/entities/application_staff_entities.dart';

class ApplicationStaffProfileModel extends ApplicationStaffProfile {
  const ApplicationStaffProfileModel({
    required super.staffId,
    required super.userId,
    required super.organizationScopeId,
    super.authorizedOrganizationIds,
    required super.staffName,
    required super.staffEmail,
    required super.roleTitle,
    required super.permissions,
    super.isActive,
    required super.assignedAt,
  });

  factory ApplicationStaffProfileModel.fromJson(Map<String, dynamic> json) {
    final rawPerms = (json['permissions'] as List<dynamic>? ?? const []);
    final perms = rawPerms
        .map((p) => ApplicationStaffPermission.values.where((e) => e.name == p))
        .expand((e) => e)
        .toSet();
    final rawOrgs =
        (json['authorizedOrganizationIds'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet();

    return ApplicationStaffProfileModel(
      staffId: json['staffId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      organizationScopeId: json['organizationScopeId'] as String? ?? '',
      authorizedOrganizationIds: rawOrgs,
      staffName: json['staffName'] as String? ?? '',
      staffEmail: json['staffEmail'] as String? ?? '',
      roleTitle: json['roleTitle'] as String? ?? 'Platform Operations Staff',
      permissions: perms,
      // Default missing/null isActive to false for safety.
      isActive: json['isActive'] as bool? ?? false,
      assignedAt: DateTime.tryParse(json['assignedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'staffId': staffId,
        'userId': userId,
        'organizationScopeId': organizationScopeId,
        'authorizedOrganizationIds': authorizedOrganizationIds.toList(),
        'staffName': staffName,
        'staffEmail': staffEmail,
        'roleTitle': roleTitle,
        'permissions': permissions.map((p) => p.name).toList(),
        'isActive': isActive,
        'assignedAt': assignedAt.toIso8601String(),
      };
}

class StaffOperationalQueueItemModel extends StaffOperationalQueueItem {
  const StaffOperationalQueueItemModel({
    required super.id,
    required super.organizationId,
    required super.organizationName,
    required super.category,
    required super.title,
    required super.summary,
    required super.submittedAt,
    required super.status,
    super.staffNote,
    super.updatedByStaffId,
    super.updatedAt,
  });

  factory StaffOperationalQueueItemModel.fromJson(Map<String, dynamic> json) {
    final rawCat = json['category'] as String? ?? 'supportTriage';
    final category = StaffQueueCategory.values.firstWhere(
      (c) => c.name == rawCat,
      orElse: () => StaffQueueCategory.supportTriage,
    );
    final rawStatus = json['status'] as String? ?? 'pendingReview';
    final status = StaffQueueItemStatus.values.firstWhere(
      (s) => s.name == rawStatus,
      orElse: () => StaffQueueItemStatus.pendingReview,
    );

    return StaffOperationalQueueItemModel(
      id: json['id'] as String? ?? '',
      organizationId: json['organizationId'] as String? ?? '',
      organizationName: json['organizationName'] as String? ?? '',
      category: category,
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? '') ??
          DateTime.now(),
      status: status,
      staffNote: json['staffNote'] as String?,
      updatedByStaffId: json['updatedByStaffId'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'organizationId': organizationId,
        'organizationName': organizationName,
        'category': category.name,
        'title': title,
        'summary': summary,
        'submittedAt': submittedAt.toIso8601String(),
        'status': status.name,
        'staffNote': staffNote,
        'updatedByStaffId': updatedByStaffId,
        'updatedAt': updatedAt?.toIso8601String(),
      };
}
