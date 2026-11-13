import 'package:pickleball_platform/core/access/session_context.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';

/// Reusable interface for modular client-side route evaluation.
///
/// NOTE: Client-side guards provide seamless UX and prevent disorientation.
/// Authoritative access enforcement is strictly handled by backend APIs.
abstract interface class RouteGuard {
  /// Evaluates whether [location] is accessible given [session].
  ///
  /// Returns a redirect route path string if intercepted, or `null` to allow navigation.
  String? evaluate(SessionContext session, String location);
}

/// Intercepts suspended accounts and redirects to [AppRoutes.accountSuspended].
class SuspendedAccountGuard implements RouteGuard {
  const SuspendedAccountGuard();

  @override
  String? evaluate(SessionContext session, String location) {
    if (!session.isSuspended) return null;

    // Allow viewing the suspended account screen itself and public routes
    if (location == AppRoutes.accountSuspended || AppRoutes.isPublic(location)) {
      return null;
    }

    return AppRoutes.accountSuspended;
  }
}

/// Enforces authentication for protected non-public routes.
class AuthRouteGuard implements RouteGuard {
  const AuthRouteGuard();

  @override
  String? evaluate(SessionContext session, String location) {
    if (session.isAuthenticated) return null;

    if (AppRoutes.isPublic(location)) {
      return null;
    }

    return AppRoutes.welcome;
  }
}

/// Redirects authenticated users away from visitor login/welcome entry screens
/// and the root path towards their active role dashboard or role selector.
class AuthEntryRedirectGuard implements RouteGuard {
  const AuthEntryRedirectGuard();

  @override
  String? evaluate(SessionContext session, String location) {
    if (!session.isAuthenticated) {
      if (location == AppRoutes.root) {
        return AppRoutes.welcome;
      }
      return null;
    }

    final isAuthEntry = AppRoutes.isAuthEntry(location);
    final isRoot = location == AppRoutes.root;

    if (isAuthEntry || isRoot) {
      if (session.activeRole != null) {
        return session.activeRole!.defaultDashboardPath;
      }
      return AppRoutes.roleSelection;
    }

    return null;
  }
}

/// Ensures authenticated users have an active role selected before entering
/// role-scoped areas of the application.
class ActiveRoleGuard implements RouteGuard {
  const ActiveRoleGuard();

  @override
  String? evaluate(SessionContext session, String location) {
    if (!session.isAuthenticated || session.isSuspended) return null;

    if (session.activeRole != null) return null;

    // Whitelisted routes when authenticated without an active role
    if (location == AppRoutes.roleSelection ||
        location == AppRoutes.profile ||
        location == AppRoutes.editProfile ||
        location == AppRoutes.accountSettings ||
        location == AppRoutes.notificationPreferences ||
        location == AppRoutes.notifications ||
        location == AppRoutes.marketplaceSellerOnboarding ||
        AppRoutes.isPublic(location)) {
      return null;
    }

    return AppRoutes.roleSelection;
  }
}

/// Checks that the user's active role matches the targeted role namespace.
///
/// If a user attempts to access `/venue-partner/*` while active as `player`,
/// they are redirected to [AppRoutes.permissionDenied].
class RoleAuthorizationGuard implements RouteGuard {
  const RoleAuthorizationGuard();

  @override
  String? evaluate(SessionContext session, String location) {
    if (!session.isAuthenticated || session.isSuspended) return null;

    final targetRole = UserRole.fromRoutePath(location);
    if (targetRole == null) return null; // Non-role-scoped route

    if (session.activeRole == null) return null; // Defer to ActiveRoleGuard

    // Any authenticated, non-suspended user may initiate independent seller
    // registration/onboarding before holding the marketplaceSeller role.
    if (location == AppRoutes.marketplaceSellerOnboarding) {
      return null;
    }

    if (session.activeRole != targetRole) {
      return AppRoutes.permissionDenied;
    }

    return null;
  }
}

/// Composite route guard pipeline executing all guards in prioritized order.
class CompositeRouteGuard implements RouteGuard {
  final List<RouteGuard> guards;

  const CompositeRouteGuard({
    this.guards = const [
      SuspendedAccountGuard(),
      AuthRouteGuard(),
      AuthEntryRedirectGuard(),
      ActiveRoleGuard(),
      RoleAuthorizationGuard(),
    ],
  });

  @override
  String? evaluate(SessionContext session, String location) {
    for (final guard in guards) {
      final redirect = guard.evaluate(session, location);
      if (redirect != null) {
        return redirect;
      }
    }
    return null;
  }

  /// Convenience evaluation method.
  static String? evaluateAll(SessionContext session, String location) {
    const composite = CompositeRouteGuard();
    return composite.evaluate(session, location);
  }
}
