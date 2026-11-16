import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/marketplace_seller/data/repositories/mock_marketplace_seller_repository.dart';
import 'package:pickleball_platform/features/marketplace_seller/data/repositories/mock_seller_catalog_repository.dart';
import 'package:pickleball_platform/features/marketplace_seller/data/repositories/mock_seller_order_repository.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/repositories/marketplace_seller_repository.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/repositories/seller_catalog_repository.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/marketplace_seller_cubit.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/seller_order_cubit.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/seller_order_state.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/widgets/seller_page_scaffold.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_marketplace_repository.dart';
import 'package:pickleball_platform/features/player/domain/repositories/marketplace_repository.dart';

/// Marketplace Seller Dashboard — Profile & Verification Overview (Feature 6.1).
class SellerDashboardPage extends StatelessWidget {
  final MarketplaceSellerCubit? cubit;
  final String? sellerId;
  final String? userId;

  const SellerDashboardPage({
    super.key,
    this.cubit,
    this.sellerId,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return SellerPageScaffold(
      cubit: cubit,
      sellerId: sellerId,
      userId: userId,
      title: 'Seller Dashboard',
      subtitle:
          'Business profile, pickleball-only verification status & KYC readiness.',
      bodyBuilder: (context, state) {
        final theme = Theme.of(context);
        final profile = state.profile;
        final missingDocs = profile.missingRequiredDocumentTypes;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VerificationStatusCard(profile: profile),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.icon(
                  onPressed: () =>
                      context.go(AppRoutes.marketplaceSellerProducts),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Manage Product Catalog'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go(AppRoutes.marketplaceSellerProductCreate),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Pickleball Product'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      context.go(AppRoutes.marketplaceSellerOrders),
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Manage Orders'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SellerOrdersOverviewSection(
              sellerId: profile.sellerId,
              userId: profile.ownerUserId,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Business Profile',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () =>
                      context.go(AppRoutes.marketplaceSellerOnboarding),
                  icon: Icon(
                    profile.canEditProfile
                        ? Icons.edit_outlined
                        : Icons.visibility_outlined,
                  ),
                  label: Text(
                    profile.canEditProfile
                        ? 'Edit Profile & KYC'
                        : 'View Profile & KYC (Locked)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(label: 'Store Name', value: profile.businessName),
                  _DetailRow(
                    label: 'Legal Entity',
                    value:
                        '${profile.legalEntityName} (${profile.entityType.label})',
                  ),
                  _DetailRow(
                    label: 'Pickleball Focus',
                    value: profile.pickleballFocus.label,
                  ),
                  _DetailRow(
                    label: 'Verified Contact',
                    value:
                        '${profile.contactEmail} ${profile.isEmailVerified ? '(Verified)' : ''} • '
                        '${profile.contactPhone} ${profile.isMobileVerified ? '(Verified)' : ''}',
                  ),
                  _DetailRow(
                    label: 'Address',
                    value: profile.businessAddress.isEmpty
                        ? 'Not yet completed'
                        : '${profile.businessAddress}, ${profile.city}, ${profile.state} - ${profile.postalCode}',
                  ),
                  _DetailRow(
                    label: 'GSTIN / PAN',
                    value:
                        '${profile.gstNumber.isEmpty ? 'Not provided' : profile.gstNumber} • '
                        '${profile.panNumber.isEmpty ? 'PAN pending' : profile.panNumber}',
                  ),
                  if (profile.bankAccountLast4.isNotEmpty)
                    _DetailRow(
                      label: 'Settlement Account Ref',
                      value:
                          '${profile.bankAccountHolder} (•••• ${profile.bankAccountLast4}, ${profile.ifscCode})',
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Mandatory KYC Checklist (${profile.requiredDocumentTypes.length - missingDocs.length}/${profile.requiredDocumentTypes.length} complete)',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (profile.documents.isEmpty)
              const EmptyStateView(
                title: 'No KYC Documents Selected',
                message:
                    'Open Seller KYC Onboarding to attach your mandatory Address Proof, PAN Card, and Business documents.',
              )
            else
              AppCard(
                child: Column(
                  children: [
                    for (var i = 0; i < profile.documents.length; i++) ...[
                      _DocumentSummaryRow(doc: profile.documents[i]),
                      if (i < profile.documents.length - 1)
                        const Divider(height: AppSpacing.md),
                    ],
                  ],
                ),
              ),
            if (profile.submissionHistory.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Text('Submission History', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: profile.submissionHistory
                      .map(
                        (h) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Text(
                            '${h.submittedAt.toLocal().toString().split('.').first} — ${h.statusAtSubmission.label}'
                            '${h.reviewNote != null ? ': ${h.reviewNote}' : ''}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _VerificationStatusCard extends StatelessWidget {
  final SellerProfile profile;

  const _VerificationStatusCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = profile.verificationStatus;
    final badgeColor = switch (status) {
      SellerVerificationStatus.approved => AppColors.success,
      SellerVerificationStatus.rejected ||
      SellerVerificationStatus.suspended =>
        theme.colorScheme.error,
      SellerVerificationStatus.needsInformation => Colors.orange,
      SellerVerificationStatus.pendingReview ||
      SellerVerificationStatus.staffRecommended =>
        theme.colorScheme.primary,
      SellerVerificationStatus.draft => theme.colorScheme.secondary,
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Seller Verification Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Chip(
                label: Text(status.label),
                backgroundColor: badgeColor.withValues(alpha: 0.12),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(status.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Governance rule: Application Staff reviews & recommends; only Application Admin grants final seller approval. Product approvals are managed separately.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (profile.staffRecommendationNote != null &&
              profile.staffRecommendationNote!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Staff Note: ${profile.staffRecommendationNote}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (profile.adminDecisionReason != null &&
              profile.adminDecisionReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Admin Decision Note: ${profile.adminDecisionReason}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _DocumentSummaryRow extends StatelessWidget {
  final SellerKycDocument doc;

  const _DocumentSummaryRow({required this.doc});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          doc.mimeType == 'application/pdf'
              ? Icons.picture_as_pdf_outlined
              : Icons.image_outlined,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doc.type.label, style: theme.textTheme.titleSmall),
              Text(
                '${doc.fileName} (${doc.formattedSize}) • '
                '${doc.isLocalMockOnly ? 'Local preview (mock — not uploaded to server)' : 'Uploaded'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Chip(
          label: Text(doc.isVerifiedByStaff ? 'Staff Checked' : 'Attached'),
        ),
      ],
    );
  }
}

class _SellerOrdersOverviewSection extends StatelessWidget {
  final String sellerId;
  final String userId;

  const _SellerOrdersOverviewSection({
    required this.sellerId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocProvider<SellerOrderCubit>(
      create: (_) {
        if (sl.isRegistered<SellerOrderCubit>()) {
          return sl<SellerOrderCubit>()
            ..loadOrders(userId: userId, sellerId: sellerId);
        }
        final sellerRepo = sl.isRegistered<MarketplaceSellerRepository>()
            ? sl<MarketplaceSellerRepository>()
            : MockMarketplaceSellerRepository();
        final catalogRepo = sl.isRegistered<SellerCatalogRepository>()
            ? sl<SellerCatalogRepository>()
            : MockSellerCatalogRepository(sellerRepository: sellerRepo);
        final marketplaceRepo = sl.isRegistered<MarketplaceRepository>()
            ? sl<MarketplaceRepository>()
            : MockMarketplaceRepository();

        return SellerOrderCubit(
          repository: MockSellerOrderRepository(
            marketplaceRepository: marketplaceRepo,
            sellerRepository: sellerRepo,
            catalogRepository: catalogRepo,
          ),
        )..loadOrders(userId: userId, sellerId: sellerId);
      },
      child: BlocBuilder<SellerOrderCubit, SellerOrderState>(
        builder: (context, state) {
          if (state is SellerOrderLoading || state is SellerOrderInitial) {
            return const AppCard(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          if (state is SellerOrderFailure) {
            return AppCard(
              child: Text(
                'Order metrics unavailable: ${state.message}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                ),
              ),
            );
          }

          final metrics = (state as SellerOrderLoaded).metrics;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order Overview', style: theme.textTheme.titleLarge),
                  TextButton.icon(
                    onPressed: () =>
                        context.go(AppRoutes.marketplaceSellerOrders),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('All Orders'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _MetricTile(
                    label: 'Total Orders',
                    value: '${metrics.totalOrders}',
                  ),
                  _MetricTile(
                    label: 'New / Pending',
                    value: '${metrics.pendingOrders}',
                  ),
                  _MetricTile(
                    label: 'Processing',
                    value: '${metrics.processingOrders}',
                  ),
                  _MetricTile(
                    label: 'Completed',
                    value: '${metrics.completedOrders}',
                  ),
                  _MetricTile(
                    label: 'Cancelled',
                    value: '${metrics.cancelledOrders}',
                  ),
                  _MetricTile(
                    label: 'Gross Order Value',
                    value: metrics.formattedGrossOrderValue,
                    footnote: 'Not settled payout',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Recent Orders', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              if (metrics.recentOrders.isEmpty)
                const EmptyStateView(
                  title: 'No Orders Yet',
                  message:
                      'Orders containing your approved & published products will appear here.',
                )
              else
                AppCard(
                  child: Column(
                    children: metrics.recentOrders.map((order) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${order.orderId} • ${order.formattedSellerSubtotal}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${order.formattedOrderDate} • ${order.totalUnits} item(s) • ${order.status.displayName}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go(
                          AppRoutes.marketplaceSellerOrderDetailsPath(
                            order.orderId,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? footnote;

  const _MetricTile({
    required this.label,
    required this.value,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 170,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (footnote != null) ...[
              const SizedBox(height: 2),
              Text(
                footnote!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
