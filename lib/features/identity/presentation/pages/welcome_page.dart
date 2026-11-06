import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/identity/presentation/widgets/brand_logo_emblem.dart';

/// The initial landing and application entry screen.
///
/// Serves as the welcome gate for unauthenticated visitors, presenting the
/// brand identity, core platform value propositions, and actions to sign in
/// or register a new account.
class WelcomePage extends StatelessWidget {
  final VoidCallback? onLoginPressed;
  final VoidCallback? onRegisterPressed;

  const WelcomePage({
    super.key,
    this.onLoginPressed,
    this.onRegisterPressed,
  });

  void _handleLogin(BuildContext context) {
    if (onLoginPressed != null) {
      onLoginPressed!();
    } else {
      context.push(AppRoutes.login);
    }
  }

  void _handleRegister(BuildContext context) {
    if (onRegisterPressed != null) {
      onRegisterPressed!();
    } else {
      context.push(AppRoutes.register);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: ResponsiveContainer(
              maxWidth: AppSpacing.maxFormWidth,
              child: isDesktop
                  ? AppCard(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: _WelcomeContent(
                        onLogin: () => _handleLogin(context),
                        onRegister: () => _handleRegister(context),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.lg,
                        horizontal: AppSpacing.xs,
                      ),
                      child: _WelcomeContent(
                        onLogin: () => _handleLogin(context),
                        onRegister: () => _handleRegister(context),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeContent extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const _WelcomeContent({
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- 1. Brand Emblem & Logo ---
        const BrandLogoEmblem(size: 80.0),
        const SizedBox(height: AppSpacing.xl),

        // --- 2. Welcome Heading & Product Description ---
        Text(
          'Welcome to Pickleball',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'The unified platform connecting players, coaches, academies, venues, and tournament organizers in one seamless experience.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // --- 3. Platform Capabilities Highlights ---
        const _FeatureHighlightsRow(),
        const SizedBox(height: AppSpacing.xxl),

        // --- 4. Call-to-Action Buttons ---
        AppButton.primary(
          label: 'Sign In',
          icon: const Icon(Icons.login_rounded, size: AppSpacing.iconSm),
          onPressed: onLogin,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton.outline(
          label: 'Create Account',
          icon: const Icon(Icons.person_add_outlined, size: AppSpacing.iconSm),
          onPressed: onRegister,
        ),
        const SizedBox(height: AppSpacing.xl),

        // --- 5. Subtle Platform Trust & Terms Notice ---
        Text(
          'By continuing, you agree to the Pickleball Platform Terms of Service and Privacy Policy.',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withAlpha(180),
          ),
        ),
      ],
    );
  }
}

class _FeatureHighlightsRow extends StatelessWidget {
  const _FeatureHighlightsRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final highlights = [
      (Icons.sports_tennis_outlined, '12 Roles', 'Unified Context'),
      (Icons.stadium_outlined, 'Venues', 'Court Booking'),
      (Icons.emoji_events_outlined, 'Tournaments', 'Live Scoring'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withAlpha(100)
            : theme.colorScheme.surfaceContainerHighest.withAlpha(160),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(120),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: highlights.map((h) {
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  h.$1,
                  size: AppSpacing.iconMd,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  h.$2,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  h.$3,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
