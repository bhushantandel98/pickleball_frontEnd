import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/features/identity/domain/entities/auth_session.dart';

/// Data Transfer Object for authentication API responses.
///
/// Converts incoming JSON payloads from the Spring Boot backend into
/// compile-safe [AuthSession] domain entities.
class AuthResponseModel {
  final String userId;
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int? expiresIn;
  final String name;
  final String phone;
  final String? email;
  final List<String> roleIds;
  final String? activeRoleId;
  final bool isSuspended;

  const AuthResponseModel({
    required this.userId,
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn,
    required this.name,
    required this.phone,
    this.email,
    required this.roleIds,
    this.activeRoleId,
    this.isSuspended = false,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? json;

    final rawRoles = json['roles'] ?? user['roles'] ?? const <dynamic>[];
    final roleList = (rawRoles as List<dynamic>)
        .map((r) => r.toString())
        .toList();

    return AuthResponseModel(
      userId: (user['userId'] ?? user['id'] ?? '').toString(),
      accessToken: (json['accessToken'] ?? json['token'] ?? '').toString(),
      refreshToken: json['refreshToken']?.toString(),
      tokenType: (json['tokenType'] ?? 'Bearer').toString(),
      expiresIn: json['expiresIn'] as int?,
      name: (user['name'] ?? user['fullName'] ?? '').toString(),
      phone: (user['phone'] ?? user['mobileNumber'] ?? '').toString(),
      email: user['email']?.toString(),
      roleIds: roleList,
      activeRoleId: (json['activeRoleId'] ?? user['activeRole'])?.toString(),
      isSuspended: (user['isSuspended'] as bool?) ?? false,
    );
  }

  /// Converts this DTO to an immutable domain [AuthSession].
  AuthSession toEntity() {
    final available = <UserRole>[];
    for (final id in roleIds) {
      final role = UserRole.fromId(id) ??
          UserRole.values.where((r) => r.name.toLowerCase() == id.toLowerCase()).firstOrNull;
      if (role != null && !available.contains(role)) {
        available.add(role);
      }
    }

    UserRole? active;
    if (activeRoleId != null) {
      active = UserRole.fromId(activeRoleId!) ??
          UserRole.values.where((r) => r.name.toLowerCase() == activeRoleId!.toLowerCase()).firstOrNull;
    }

    return AuthSession(
      userId: userId,
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType,
      expiresIn: expiresIn,
      name: name,
      phone: phone,
      email: email,
      availableRoles: available,
      activeRole: active ?? (available.length == 1 ? available.first : null),
      isSuspended: isSuspended,
    );
  }
}
