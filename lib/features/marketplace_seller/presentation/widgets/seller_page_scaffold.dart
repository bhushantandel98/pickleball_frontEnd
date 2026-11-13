import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/marketplace_seller/data/repositories/mock_marketplace_seller_repository.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/marketplace_seller_cubit.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/marketplace_seller_state.dart';

/// Shared wrapper for Marketplace Seller pages providing DI-aware
/// [MarketplaceSellerCubit], strict session/role/organization validation via
/// [SessionCubit], snackbar feedback, pull-to-refresh, and loading/error states.
///
/// When [allowUnregistered] is `true` (e.g. Seller Onboarding), any authenticated,
/// non-suspended user may initiate independent seller registration even before
/// `activeOrganizationId` or `UserRole.marketplaceSeller` is assigned.
class SellerPageScaffold extends StatelessWidget {
  final MarketplaceSellerCubit? cubit;
  final String? sellerId;
  final String? userId;
  final bool allowUnregistered;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, MarketplaceSellerLoaded state)
      bodyBuilder;
  final Widget Function(
    BuildContext context,
    MarketplaceSellerUnregistered state,
  )? unregisteredBuilder;

  const SellerPageScaffold({
    super.key,
    this.cubit,
    this.sellerId,
    this.userId,
    this.allowUnregistered = false,
    required this.title,
    required this.subtitle,
    required this.bodyBuilder,
    this.unregisteredBuilder,
  });

  (String, String?)? _resolveAuthContext(BuildContext context) {
    try {
      final session = context.read<SessionCubit>().state;
      if (!session.isAuthenticated || session.isSuspended) {
        return null;
      }

      final sessionUserId = session.userId?.trim();
      if (sessionUserId == null || sessionUserId.isEmpty) {
        return null;
      }
      if (userId != null &&
          userId!.trim().isNotEmpty &&
          userId!.trim() != sessionUserId) {
        return null;
      }

      final sessionSellerId = session.activeOrganizationId?.trim();

      if (!allowUnregistered) {
        if (session.activeRole != UserRole.marketplaceSeller) {
          return null;
        }
        if (sessionSellerId == null || sessionSellerId.isEmpty) {
          return null;
        }
      }

      if (sellerId != null &&
          sellerId!.trim().isNotEmpty &&
          sellerId!.trim() != sessionSellerId) {
        return null;
      }

      final scopedSellerId =
          session.activeRole == UserRole.marketplaceSeller &&
                  sessionSellerId != null &&
                  sessionSellerId.isNotEmpty
              ? sessionSellerId
              : null;

      return (sessionUserId, scopedSellerId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = _resolveAuthContext(context);
    if (auth == null) {
      return const Scaffold(
        body: ErrorStateView(
          title: 'Marketplace Seller Access Required',
          message:
              'A valid authenticated session is required to access Marketplace Seller onboarding or dashboard.',
        ),
      );
    }

    final (resolvedUserId, resolvedSellerId) = auth;

    if (cubit != null) {
      return BlocProvider<MarketplaceSellerCubit>.value(
        value: cubit!
          ..loadProfile(
            userId: resolvedUserId,
            sellerId: resolvedSellerId,
          ),
        child: _SellerScaffoldBody(
          title: title,
          subtitle: subtitle,
          bodyBuilder: bodyBuilder,
          unregisteredBuilder: unregisteredBuilder,
        ),
      );
    }

    return BlocProvider<MarketplaceSellerCubit>(
      create: (_) {
        final instance = sl.isRegistered<MarketplaceSellerCubit>()
            ? sl<MarketplaceSellerCubit>()
            : MarketplaceSellerCubit(
                repository: MockMarketplaceSellerRepository(),
              );
        instance.loadProfile(
          userId: resolvedUserId,
          sellerId: resolvedSellerId,
        );
        return instance;
      },
      child: _SellerScaffoldBody(
        title: title,
        subtitle: subtitle,
        bodyBuilder: bodyBuilder,
        unregisteredBuilder: unregisteredBuilder,
      ),
    );
  }
}

class _SellerScaffoldBody extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, MarketplaceSellerLoaded state)
      bodyBuilder;
  final Widget Function(
    BuildContext context,
    MarketplaceSellerUnregistered state,
  )? unregisteredBuilder;

  const _SellerScaffoldBody({
    required this.title,
    required this.subtitle,
    required this.bodyBuilder,
    this.unregisteredBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: BlocConsumer<MarketplaceSellerCubit, MarketplaceSellerState>(
        listener: (context, state) {
          String? feedback;
          String? error;
          if (state is MarketplaceSellerLoaded) {
            feedback = state.feedbackMessage;
            error = state.errorMessage;
          } else if (state is MarketplaceSellerUnregistered) {
            feedback = state.feedbackMessage;
            error = state.errorMessage;
          }

          if (feedback != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(feedback)));
            context.read<MarketplaceSellerCubit>().clearFeedback();
          } else if (error != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(error),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            context.read<MarketplaceSellerCubit>().clearFeedback();
          }
        },
        builder: (context, state) {
          if (state is MarketplaceSellerInitial ||
              state is MarketplaceSellerLoading) {
            return const LoadingView(
              message: 'Loading Marketplace Seller workspace...',
            );
          }
          if (state is MarketplaceSellerFailure) {
            return ErrorStateView(
              title: 'Unable to Load Seller Workspace',
              message: state.message,
              onRetry: () =>
                  context.read<MarketplaceSellerCubit>().refreshProfile(),
            );
          }
          if (state is MarketplaceSellerUnregistered) {
            if (unregisteredBuilder != null) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ResponsiveContainer(
                  maxWidth: 1120,
                  child: unregisteredBuilder!(context, state),
                ),
              );
            }
            return const ErrorStateView(
              title: 'Seller Profile Not Registered',
              message:
                  'Complete independent seller registration at /marketplace-seller/onboarding first.',
            );
          }
          if (state is MarketplaceSellerLoaded) {
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<MarketplaceSellerCubit>().refreshProfile(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: ResponsiveContainer(
                  maxWidth: 1120,
                  child: bodyBuilder(context, state),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
