import 'package:pickleball_platform/features/tournament_staff/domain/entities/tournament_staff_entities.dart';

/// DTO for [TournamentStaffProfile] API serialization.
class TournamentStaffProfileModel {
  final String staffId;
  final String tournamentId;
  final String tournamentName;
  final String venueName;
  final String staffName;
  final String staffEmail;
  final String roleTitle;
  final List<String> permissionCodes;
  final bool isActive;

  const TournamentStaffProfileModel({
    required this.staffId,
    required this.tournamentId,
    required this.tournamentName,
    required this.venueName,
    required this.staffName,
    required this.staffEmail,
    required this.roleTitle,
    required this.permissionCodes,
    required this.isActive,
  });

  factory TournamentStaffProfileModel.fromJson(Map<String, dynamic> json) {
    return TournamentStaffProfileModel(
      staffId: json['staffId'] as String? ?? '',
      tournamentId: json['tournamentId'] as String? ?? '',
      tournamentName: json['tournamentName'] as String? ?? '',
      venueName: json['venueName'] as String? ?? '',
      staffName: json['staffName'] as String? ?? '',
      staffEmail: json['staffEmail'] as String? ?? '',
      roleTitle: json['roleTitle'] as String? ?? 'Tournament Staff',
      permissionCodes: (json['permissions'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  static String _normalizePermissionCode(String code) {
    return code.trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  /// Maps only explicit backend permission codes; never grants implicit permissions.
  TournamentStaffProfile toEntity() {
    final mapped = <TournamentStaffPermission>{};
    for (final code in permissionCodes) {
      final normalized = _normalizePermissionCode(code);
      if (normalized.isEmpty) continue;
      for (final perm in TournamentStaffPermission.values) {
        if (_normalizePermissionCode(perm.name) == normalized) {
          mapped.add(perm);
        }
      }
    }

    return TournamentStaffProfile(
      staffId: staffId,
      tournamentId: tournamentId,
      tournamentName: tournamentName,
      venueName: venueName,
      staffName: staffName,
      staffEmail: staffEmail,
      roleTitle: roleTitle,
      permissions: mapped,
      isActive: isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'staffId': staffId,
        'tournamentId': tournamentId,
        'tournamentName': tournamentName,
        'venueName': venueName,
        'staffName': staffName,
        'staffEmail': staffEmail,
        'roleTitle': roleTitle,
        'permissions': permissionCodes,
        'isActive': isActive,
      };
}
