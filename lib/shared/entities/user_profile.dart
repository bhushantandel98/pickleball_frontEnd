import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/access/user_role.dart';

/// Central domain entity representing an authenticated user's profile and multi-role context.
class UserProfile extends Equatable {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? avatarUrl;
  final List<UserRole> availableRoles;
  final UserRole? activeRole;
  final bool isSuspended;
  final double? rating;
  final String? organizationId;
  final bool publicPlayerProfile;
  final bool showMatchHistory;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.avatarUrl,
    required this.availableRoles,
    this.activeRole,
    this.isSuspended = false,
    this.rating,
    this.organizationId,
    this.publicPlayerProfile = true,
    this.showMatchHistory = true,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatarUrl,
    List<UserRole>? availableRoles,
    UserRole? activeRole,
    bool? isSuspended,
    double? rating,
    String? organizationId,
    bool? publicPlayerProfile,
    bool? showMatchHistory,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      availableRoles: availableRoles ?? this.availableRoles,
      activeRole: activeRole ?? this.activeRole,
      isSuspended: isSuspended ?? this.isSuspended,
      rating: rating ?? this.rating,
      organizationId: organizationId ?? this.organizationId,
      publicPlayerProfile: publicPlayerProfile ?? this.publicPlayerProfile,
      showMatchHistory: showMatchHistory ?? this.showMatchHistory,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        avatarUrl,
        availableRoles,
        activeRole,
        isSuspended,
        rating,
        organizationId,
        publicPlayerProfile,
        showMatchHistory,
        createdAt,
      ];
}
