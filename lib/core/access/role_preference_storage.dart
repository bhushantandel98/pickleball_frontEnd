import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract contract for storing and retrieving the user's preferred role and role assignment.
///
/// Implementations can use SharedPreferences, secure storage, or in-memory mocks.
abstract interface class RolePreferenceStorage {
  /// Retrieves the saved preferred role for the given [userId], or `null` if unset.
  Future<UserRole?> getPreferredRole(String userId);

  /// Saves the preferred [role] for the given [userId].
  Future<void> setPreferredRole(String userId, UserRole role);

  /// Clears the saved preferred role for the given [userId].
  Future<void> clearPreferredRole(String userId);

  /// Retrieves the saved preferred role assignment ID for the given [userId], or `null` if unset.
  Future<String?> getPreferredAssignmentId(String userId);

  /// Saves the preferred [assignmentId] for the given [userId].
  Future<void> setPreferredAssignmentId(String userId, String assignmentId);

  /// Clears the saved preferred role assignment ID for the given [userId].
  Future<void> clearPreferredAssignmentId(String userId);
}

/// In-memory mock implementation of [RolePreferenceStorage].
///
/// Suitable for development, testing, and mock environments.
/// Must never be registered in release builds (ADR-015).
class MockRolePreferenceStorage implements RolePreferenceStorage {
  final Map<String, UserRole> _preferences = {};
  final Map<String, String> _assignmentPreferences = {};

  @override
  Future<UserRole?> getPreferredRole(String userId) async {
    return _preferences[userId];
  }

  @override
  Future<void> setPreferredRole(String userId, UserRole role) async {
    _preferences[userId] = role;
  }

  @override
  Future<void> clearPreferredRole(String userId) async {
    _preferences.remove(userId);
  }

  @override
  Future<String?> getPreferredAssignmentId(String userId) async {
    return _assignmentPreferences[userId];
  }

  @override
  Future<void> setPreferredAssignmentId(String userId, String assignmentId) async {
    _assignmentPreferences[userId] = assignmentId;
  }

  @override
  Future<void> clearPreferredAssignmentId(String userId) async {
    _assignmentPreferences.remove(userId);
  }

  /// Clears all preferences in memory. Useful for test teardowns.
  void reset() {
    _preferences.clear();
    _assignmentPreferences.clear();
  }
}

/// Production implementation of [RolePreferenceStorage] backed by [SharedPreferences].
///
/// Registered in [initRemoteServiceLocator] and used in production release builds.
class SharedPrefsRolePreferenceStorage implements RolePreferenceStorage {
  static const String _keyPrefix = 'preferred_role_';
  static const String _assignmentKeyPrefix = 'preferred_role_assignment_';
  final SharedPreferences? prefs;

  const SharedPrefsRolePreferenceStorage({this.prefs});

  Future<SharedPreferences> _getPrefs() async =>
      prefs ?? await SharedPreferences.getInstance();

  @override
  Future<UserRole?> getPreferredRole(String userId) async {
    final prefs = await _getPrefs();
    final roleId = prefs.getString('$_keyPrefix$userId');
    if (roleId == null) return null;
    return UserRole.fromId(roleId);
  }

  @override
  Future<void> setPreferredRole(String userId, UserRole role) async {
    final prefs = await _getPrefs();
    await prefs.setString('$_keyPrefix$userId', role.id);
  }

  @override
  Future<void> clearPreferredRole(String userId) async {
    final prefs = await _getPrefs();
    await prefs.remove('$_keyPrefix$userId');
  }

  @override
  Future<String?> getPreferredAssignmentId(String userId) async {
    final prefs = await _getPrefs();
    return prefs.getString('$_assignmentKeyPrefix$userId');
  }

  @override
  Future<void> setPreferredAssignmentId(String userId, String assignmentId) async {
    final prefs = await _getPrefs();
    await prefs.setString('$_assignmentKeyPrefix$userId', assignmentId);
  }

  @override
  Future<void> clearPreferredAssignmentId(String userId) async {
    final prefs = await _getPrefs();
    await prefs.remove('$_assignmentKeyPrefix$userId');
  }
}
