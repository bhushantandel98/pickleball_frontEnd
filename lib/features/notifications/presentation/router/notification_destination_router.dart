import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_context.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/features/notifications/domain/entities/notification_item.dart';

/// Centralized router dispatching user notification selections to their
/// respective screen destinations, guarding against cross-role / cross-context
/// navigation, or displaying informative previews for unimplemented destinations.
abstract final class NotificationDestinationRouter {
  /// Navigates to the relevant destination for [notification].
  ///
  /// 1. Compares the notification's role, organization, and tournament context
  ///    against the active [SessionContext].
  /// 2. If the role or organization/tournament context differs, displays an
  ///    informative dialog with a "Switch Role" action rather than navigating
  ///    into the wrong context.
  /// 3. If the context matches and the destination exists, navigates normally.
  /// 4. If the destination is not implemented, displays the notification-details
  ///    fallback dialog.
  static void navigateToDestination(
    BuildContext context,
    NotificationItem notification, {
    SessionContext? sessionOverride,
    VoidCallback? onSwitchRole,
  }) {
    final session = _resolveSession(context, sessionOverride);
    final route = notification.destinationRoute?.trim();
    final targetRole = notification.roleContext ??
        (route != null && route.isNotEmpty
            ? UserRole.fromRoutePath(route)
            : null);

    if (session != null &&
        session.isAuthenticated &&
        hasContextMismatch(session, notification, targetRole: targetRole)) {
      _showContextMismatchDialog(
        context,
        notification,
        targetRole: targetRole,
        onSwitchRole: onSwitchRole,
      );
      return;
    }

    if (route != null && route.isNotEmpty) {
      final router = GoRouter.maybeOf(context);
      if (router != null && _isRouteImplemented(router, route)) {
        context.push(route);
        return;
      }
    }

    _showNotificationDetailsDialog(context, notification);
  }

  /// Evaluates whether [notification] requires a different role, organization,
  /// or tournament context than the currently active [session].
  static bool hasContextMismatch(
    SessionContext session,
    NotificationItem notification, {
    UserRole? targetRole,
  }) {
    final effectiveRole = targetRole ??
        notification.roleContext ??
        (notification.destinationRoute != null
            ? UserRole.fromRoutePath(notification.destinationRoute!)
            : null);

    // 1. Role comparison
    if (effectiveRole != null && session.activeRole != effectiveRole) {
      return true;
    }

    // 2. Organization context comparison
    final notifOrgId = notification.organizationId?.trim();
    final notifOrgName = notification.organizationName?.trim();
    final hasNotifOrg = (notifOrgId != null && notifOrgId.isNotEmpty) ||
        (notifOrgName != null && notifOrgName.isNotEmpty);

    if (hasNotifOrg) {
      final activeOrgId = session.activeOrganizationId?.trim();
      final activeOrgName = session.activeOrganizationName?.trim();

      if (notifOrgId != null &&
          notifOrgId.isNotEmpty &&
          activeOrgId != null &&
          activeOrgId.isNotEmpty) {
        if (notifOrgId != activeOrgId) return true;
      } else if (notifOrgName != null &&
          notifOrgName.isNotEmpty &&
          activeOrgName != null &&
          activeOrgName.isNotEmpty) {
        if (notifOrgName != activeOrgName) return true;
      } else {
        return true;
      }
    }

    // 3. Tournament context comparison
    final notifTournId = notification.tournamentId?.trim();
    final notifTournName = notification.tournamentName?.trim();
    final hasNotifTourn = (notifTournId != null && notifTournId.isNotEmpty) ||
        (notifTournName != null && notifTournName.isNotEmpty);

    if (hasNotifTourn) {
      final activeTournId = session.activeTournamentId?.trim();
      final activeTournName = session.activeTournamentName?.trim();

      if (notifTournId != null &&
          notifTournId.isNotEmpty &&
          activeTournId != null &&
          activeTournId.isNotEmpty) {
        if (notifTournId != activeTournId) return true;
      } else if (notifTournName != null &&
          notifTournName.isNotEmpty &&
          activeTournName != null &&
          activeTournName.isNotEmpty) {
        if (notifTournName != activeTournName) return true;
      } else {
        return true;
      }
    }

    return false;
  }

  static SessionContext? _resolveSession(
    BuildContext context,
    SessionContext? sessionOverride,
  ) {
    if (sessionOverride != null) return sessionOverride;
    try {
      return context.read<SessionCubit>().state;
    } catch (_) {
      if (sl.isRegistered<SessionCubit>()) {
        return sl<SessionCubit>().state;
      }
      return null;
    }
  }

  static bool _isRouteImplemented(GoRouter router, String route) {
    try {
      final uri = Uri.parse(route);
      final matchList = router.configuration.findMatch(uri);
      return matchList.matches.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static void _showContextMismatchDialog(
    BuildContext context,
    NotificationItem notification, {
    UserRole? targetRole,
    VoidCallback? onSwitchRole,
  }) {
    final theme = Theme.of(context);
    final orgLabel = notification.organizationName ?? notification.organizationId;
    final tournLabel = notification.tournamentName ?? notification.tournamentId;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.swap_horiz, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Switch Role or Context',
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'This notification belongs to a different role or operating context than your current active session.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (targetRole != null) ...[
              Text(
                'Role: ${targetRole.displayName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
            ],
            if (orgLabel != null && orgLabel.isNotEmpty) ...[
              Text(
                'Organization: $orgLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
            ],
            if (tournLabel != null && tournLabel.isNotEmpty) ...[
              Text(
                'Tournament: $tournLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          AppButton.outline(
            label: 'Cancel',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          AppButton.primary(
            label: 'Switch Role',
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (onSwitchRole != null) {
                onSwitchRole();
                return;
              }
              final router = GoRouter.maybeOf(context);
              if (router != null) {
                context.go(AppRoutes.roleSelection);
              }
            },
          ),
        ],
      ),
    );
  }

  static void _showNotificationDetailsDialog(
    BuildContext context,
    NotificationItem notification,
  ) {
    final theme = Theme.of(context);
    final targetRole = notification.roleContext;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(notification.category.icon, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notification.title,
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (targetRole != null) ...[
              Text(
                'Role: ${targetRole.displayName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (notification.organizationName != null) ...[
              Text(
                'Organization: ${notification.organizationName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (notification.tournamentName != null) ...[
              Text(
                'Tournament: ${notification.tournamentName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (notification.relatedEntityId != null) ...[
              Text(
                'Reference ID: ${notification.relatedEntityId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        actions: [
          AppButton.primary(
            label: 'Close',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }
}
