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
import 'package:pickleball_platform/features/marketplace_seller/data/repositories/mock_seller_catalog_repository.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/repositories/marketplace_seller_repository.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/seller_catalog_cubit.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/seller_catalog_state.dart';

/// Shared DI-aware & [SessionCubit]-scoped wrapper for Feature 6.2 Seller
/// Catalog pages.
class SellerCatalogScaffold extends StatelessWidget {
  final SellerCatalogCubit? cubit;
  final String? sellerId;
  final String? userId;
  final String title;
  final String subtitle;
  final List<Widget> Function(BuildContext context, SellerCatalogLoaded state)?
      actionsBuilder;
  final Widget Function(BuildContext context, SellerCatalogLoaded state)
      bodyBuilder;

  const SellerCatalogScaffold({
    super.key,
    this.cubit,
    this.sellerId,
    this.userId,
    required this.title,
    required this.subtitle,
    this.actionsBuilder,
    required this.bodyBuilder,
  });

  (String, String)? _resolveAuthContext(BuildContext context) {
    try {
      final session = context.read<SessionCubit>().state;
      if (!session.isAuthenticated || session.isSuspended) return null;
      if (session.activeRole != UserRole.marketplaceSeller) return null;

      final sessionUserId = session.userId?.trim();
      final sessionSellerId = session.activeOrganizationId?.trim();
      if (sessionUserId == null ||
          sessionUserId.isEmpty ||
          sessionSellerId == null ||
          sessionSellerId.isEmpty) {
        return null;
      }

      if (userId != null &&
          userId!.trim().isNotEmpty &&
          userId!.trim() != sessionUserId) {
        return null;
      }
      if (sellerId != null &&
          sellerId!.trim().isNotEmpty &&
          sellerId!.trim() != sessionSellerId) {
        return null;
      }

      return (sessionUserId, sessionSellerId);
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
              'Sign in with an active Marketplace Seller organization to manage your product catalog.',
        ),
      );
    }

    final (resolvedUserId, resolvedSellerId) = auth;

    if (cubit != null) {
      return BlocProvider<SellerCatalogCubit>.value(
        value: cubit!,
        child: _SellerCatalogView(
          userId: resolvedUserId,
          sellerId: resolvedSellerId,
          title: title,
          subtitle: subtitle,
          actionsBuilder: actionsBuilder,
          bodyBuilder: bodyBuilder,
        ),
      );
    }

    return BlocProvider<SellerCatalogCubit>(
      create: (_) {
        if (sl.isRegistered<SellerCatalogCubit>()) {
          return sl<SellerCatalogCubit>()
            ..loadCatalog(
              userId: resolvedUserId,
              sellerId: resolvedSellerId,
            );
        }
        final sellerRepo = sl.isRegistered<MarketplaceSellerRepository>()
            ? sl<MarketplaceSellerRepository>()
            : MockMarketplaceSellerRepository();
        return SellerCatalogCubit(
          catalogRepository:
              MockSellerCatalogRepository(sellerRepository: sellerRepo),
          sellerRepository: sellerRepo,
        )..loadCatalog(
            userId: resolvedUserId,
            sellerId: resolvedSellerId,
          );
      },
      child: _SellerCatalogView(
        userId: resolvedUserId,
        sellerId: resolvedSellerId,
        title: title,
        subtitle: subtitle,
        actionsBuilder: actionsBuilder,
        bodyBuilder: bodyBuilder,
      ),
    );
  }
}

class _SellerCatalogView extends StatelessWidget {
  final String userId;
  final String sellerId;
  final String title;
  final String subtitle;
  final List<Widget> Function(BuildContext context, SellerCatalogLoaded state)?
      actionsBuilder;
  final Widget Function(BuildContext context, SellerCatalogLoaded state)
      bodyBuilder;

  const _SellerCatalogView({
    required this.userId,
    required this.sellerId,
    required this.title,
    required this.subtitle,
    required this.actionsBuilder,
    required this.bodyBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<SellerCatalogCubit, SellerCatalogState>(
      listener: (context, state) {
        if (state is SellerCatalogLoaded) {
          if (state.feedbackMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.feedbackMessage!)),
            );
            context.read<SellerCatalogCubit>().clearFeedback();
          } else if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
            context.read<SellerCatalogCubit>().clearFeedback();
          }
        }
      },
      builder: (context, state) {
        if (state is SellerCatalogInitial || state is SellerCatalogLoading) {
          return const Scaffold(
            body: LoadingView(message: 'Loading seller catalog...'),
          );
        }
        if (state is SellerCatalogFailure) {
          return Scaffold(
            body: ErrorStateView(
              title: 'Unable to Load Catalog',
              message: state.message,
              onRetry: () => context.read<SellerCatalogCubit>().loadCatalog(
                    userId: userId,
                    sellerId: sellerId,
                  ),
            ),
          );
        }
        final loaded = state as SellerCatalogLoaded;
        final isDesktop = ResponsiveLayout.isDesktop(context);
        final horizontalPadding =
            isDesktop ? AppSpacing.xl : AppSpacing.md;

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () => context.read<SellerCatalogCubit>().loadCatalog(
                  userId: userId,
                  sellerId: sellerId,
                ),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppSpacing.lg,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.sm,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          if (actionsBuilder != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: actionsBuilder!(context, loaded),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      bodyBuilder(context, loaded),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
