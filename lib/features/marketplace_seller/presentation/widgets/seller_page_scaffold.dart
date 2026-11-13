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
class SellerPageScaffold extends StatelessWidget {
  final MarketplaceSellerCubit? cubit;
  final String? sellerId;
  final String? userId;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, MarketplaceSellerLoaded state)
      bodyBuilder;

  const SellerPageScaffold({
    super.key,
    this.cubit,
    this.sellerId,
    this.userId,
    required this.title,
    required this.subtitle,
    required this.bodyBuilder,
  });

  (String, String)? _resolveAuthContext(BuildContext context) {
    try {
      final session = context.read<SessionCubit>().state;
      if (!session.isAuthenticated ||
          session.isSuspended ||
          session.activeRole != UserRole.marketplaceSeller) {
        return null;
      }

      final sessionSellerId = session.activeOrganizationId?.trim();
      final sessionUserId = session.userId?.trim();
      if (sessionSellerId == null ||
          sessionSellerId.isEmpty ||
          sessionUserId == null ||
          sessionUserId.isEmpty) {
        return null;
      }

      if (sellerId != null &&
          sellerId!.trim().isNotEmpty &&
          sellerId!.trim() != sessionSellerId) {
        return null;
      }
      if (userId != null &&
          userId!.trim().isNotEmpty &&
          userId!.trim() != sessionUserId) {
        return null;
      }

      return (sessionSellerId, sessionUserId);
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
              'A valid authenticated Marketplace Seller session with an assigned seller organization is required.',
        ),
      );
    }

    final (resolvedSellerId, resolvedUserId) = auth;

    if (cubit != null) {
      return BlocProvider<MarketplaceSellerCubit>.value(
        value: cubit!
          ..loadProfile(
            sellerId: resolvedSellerId,
            userId: resolvedUserId,
          ),
        child: _SellerScaffoldBody(
          title: title,
          subtitle: subtitle,
          bodyBuilder: bodyBuilder,
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
          sellerId: resolvedSellerId,
          userId: resolvedUserId,
        );
        return instance;
      },
      child: _SellerScaffoldBody(
        title: title,
        subtitle: subtitle,
        bodyBuilder: bodyBuilder,
      ),
    );
  }
}

class _SellerScaffoldBody extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context, MarketplaceSellerLoaded state)
      bodyBuilder;

  const _SellerScaffoldBody({
    required this.title,
    required this.subtitle,
    required this.bodyBuilder,
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
          if (state is MarketplaceSellerLoaded) {
            if (state.feedbackMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(state.feedbackMessage!)),
                );
              context.read<MarketplaceSellerCubit>().clearFeedback();
            } else if (state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              context.read<MarketplaceSellerCubit>().clearFeedback();
            }
          }
        },
        builder: (context, state) {
          if (state is MarketplaceSellerInitial ||
              state is MarketplaceSellerLoading) {
            return const LoadingView(
              message: 'Loading Marketplace Seller profile...',
            );
          }
          if (state is MarketplaceSellerFailure) {
            return ErrorStateView(
              title: 'Unable to Load Seller Profile',
              message: state.message,
              onRetry: () =>
                  context.read<MarketplaceSellerCubit>().refreshProfile(),
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
