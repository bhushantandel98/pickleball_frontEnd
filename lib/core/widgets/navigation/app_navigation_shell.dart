import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/access/session_context.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/navigation/nav_destination_item.dart';
import 'package:pickleball_platform/core/widgets/navigation/role_nav_config.dart';

/// Standard navigation shell providing responsive layout adaptation (Mobile bottom nav,
/// Tablet rail, Desktop sidebar) for authenticated role routes.
class AppNavigationShell extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const AppNavigationShell({
    super.key,
    required this.child,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionContext>(
      builder: (context, session) {
        final activeRole = session.activeRole ?? UserRole.player;
        final destinations = RoleNavConfig.getDestinationsForRole(activeRole);
        final selectedIndex = _calculateSelectedIndex(destinations, state.uri.path);

        return ResponsiveLayout(
          mobile: (_) => _MobileShell(
            role: activeRole,
            session: session,
            destinations: destinations,
            selectedIndex: selectedIndex,
            child: child,
          ),
          tablet: (_) => _TabletShell(
            role: activeRole,
            session: session,
            destinations: destinations,
            selectedIndex: selectedIndex,
            child: child,
          ),
          desktop: (_) => _DesktopShell(
            role: activeRole,
            session: session,
            destinations: destinations,
            selectedIndex: selectedIndex,
            child: child,
          ),
        );
      },
    );
  }

  int _calculateSelectedIndex(List<NavDestinationItem> items, String currentPath) {
    for (int i = 0; i < items.length; i++) {
      if (currentPath == items[i].routePath ||
          (items[i].routePath != AppRoutes.playerDashboard &&
              currentPath.startsWith(items[i].routePath))) {
        return i;
      }
    }
    // Default to first item if matching base
    return 0;
  }
}

class _MobileShell extends StatelessWidget {
  final UserRole role;
  final SessionContext session;
  final List<NavDestinationItem> destinations;
  final int selectedIndex;
  final Widget child;

  const _MobileShell({
    required this.role,
    required this.session,
    required this.destinations,
    required this.selectedIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context, role, session),
      body: child,
      bottomNavigationBar: destinations.length > 1
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                context.go(destinations[index].routePath);
              },
              destinations: destinations.map((item) {
                return NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: item.selectedIcon != null
                      ? Icon(item.selectedIcon)
                      : null,
                  label: item.label,
                );
              }).toList(),
            )
          : null,
    );
  }
}

class _TabletShell extends StatelessWidget {
  final UserRole role;
  final SessionContext session;
  final List<NavDestinationItem> destinations;
  final int selectedIndex;
  final Widget child;

  const _TabletShell({
    required this.role,
    required this.session,
    required this.destinations,
    required this.selectedIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context, role, session),
      body: Row(
        children: [
          if (destinations.length > 1) ...[
            NavigationRail(
              selectedIndex: selectedIndex,
              labelType: NavigationRailLabelType.selected,
              onDestinationSelected: (index) {
                context.go(destinations[index].routePath);
              },
              destinations: destinations.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: item.selectedIcon != null
                      ? Icon(item.selectedIcon)
                      : null,
                  label: Text(item.label),
                );
              }).toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
          ],
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  final UserRole role;
  final SessionContext session;
  final List<NavDestinationItem> destinations;
  final int selectedIndex;
  final Widget child;

  const _DesktopShell({
    required this.role,
    required this.session,
    required this.destinations,
    required this.selectedIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 260,
            child: Material(
              color: theme.colorScheme.surface,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sports_tennis,
                          color: theme.colorScheme.primary,
                          size: AppSpacing.iconLg,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Pickleball',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: InkWell(
                      borderRadius: AppSpacing.borderRadiusSm,
                      onTap: () => context.go(AppRoutes.roleSelection),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: Row(
                          children: [
                            Icon(role.icon, size: AppSpacing.iconSm),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                role.displayName,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(Icons.swap_horiz, size: AppSpacing.iconSm),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: destinations.length,
                      itemBuilder: (context, index) {
                        final item = destinations[index];
                        final isSelected = index == selectedIndex;

                        return ListTile(
                          selected: isSelected,
                          leading: Icon(
                            isSelected && item.selectedIcon != null
                                ? item.selectedIcon
                                : item.icon,
                          ),
                          title: Text(item.label),
                          onTap: () => context.go(item.routePath),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign Out'),
                    onTap: () {
                      context.read<SessionCubit>().signOut();
                      context.go(AppRoutes.welcome);
                    },
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Scaffold(
              appBar: _buildAppBar(context, role, session, showLeading: false),
              body: child,
            ),
          ),
        ],
      ),
    );
  }
}

AppBar _buildAppBar(
  BuildContext context,
  UserRole role,
  SessionContext session, {
  bool showLeading = true,
}) {
  return AppBar(
    automaticallyImplyLeading: showLeading,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(role.displayName),
        if (session.activeOrganizationId != null)
          Text(
            'Org: ${session.activeOrganizationId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: AppChip.neutral(
          label: role.id,
          onTap: () => context.go(AppRoutes.roleSelection),
        ),
      ),
      if (session.availableRoles.length > 1) ...[
        IconButton(
          icon: const Icon(Icons.switch_account_outlined),
          tooltip: 'Switch Role',
          onPressed: () => context.go(AppRoutes.roleSelection),
        ),
      ],
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        tooltip: 'Notifications',
        onPressed: () => context.go(AppRoutes.notifications),
      ),
    ],
  );
}
