import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_product_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/seller_catalog_cubit.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/seller_catalog_state.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/widgets/seller_catalog_scaffold.dart';

/// Feature 6.3 — Product Submission Review, Feedback, Lifecycle & Publishing
/// Control screen.
class SellerProductReviewPage extends StatelessWidget {
  final String? productId;
  final SellerCatalogCubit? cubit;
  final String? sellerId;
  final String? userId;

  const SellerProductReviewPage({
    super.key,
    required this.productId,
    this.cubit,
    this.sellerId,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return SellerCatalogScaffold(
      cubit: cubit,
      sellerId: sellerId,
      userId: userId,
      title: 'Product Submission & Lifecycle',
      subtitle:
          'Review product readiness, Staff/Admin feedback, history & manual publishing.',
      actionsBuilder: (context, _) => [
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.marketplaceSellerProducts),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to Catalog'),
        ),
      ],
      bodyBuilder: (context, state) {
        SellerProduct? product;
        for (final item in state.products) {
          if (item.productId == productId) {
            product = item;
            break;
          }
        }

        if (product == null) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Product not found in your seller catalog.'),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: () =>
                      context.go(AppRoutes.marketplaceSellerProducts),
                  child: const Text('Return to Catalog'),
                ),
              ],
            ),
          );
        }

        return _ProductReviewBody(state: state, product: product);
      },
    );
  }
}

class _ProductReviewBody extends StatefulWidget {
  final SellerCatalogLoaded state;
  final SellerProduct product;

  const _ProductReviewBody({
    required this.state,
    required this.product,
  });

  @override
  State<_ProductReviewBody> createState() => _ProductReviewBodyState();
}

class _ProductReviewBodyState extends State<_ProductReviewBody> {
  final _submissionNoteCtrl = TextEditingController();

  @override
  void dispose() {
    _submissionNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<SellerCatalogCubit>();
    final product = widget.product;
    final state = widget.state;
    final statusColor = _statusColor(product.status);
    final readinessIssues = product.submissionReadinessIssues;
    final canSubmit = state.isVerifiedSeller &&
        product.status.canSubmitForReview &&
        readinessIssues.isEmpty &&
        !state.isMutating;
    final isResubmit = product.status == SellerProductStatus.needsInformation ||
        product.status == SellerProductStatus.rejected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Lifecycle Status & Action Availability
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  _StatusPill(
                    label: product.status.label,
                    color: statusColor,
                  ),
                  if (product.status == SellerProductStatus.approved)
                    _StatusPill(
                      label: product.isPublished ? 'Published' : 'Unpublished',
                      color: product.isPublished
                          ? AppColors.success
                          : AppColors.textSecondaryLight,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(product.status.description, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Action Availability: ${product.actionAvailabilitySummary}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Governance: Application Staff may review & recommend; only the single Application Admin grants final approval. Approval never auto-publishes.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  if (product.status.canEditDetails)
                    OutlinedButton.icon(
                      onPressed: () => context.go(
                        AppRoutes.marketplaceSellerProductEditPath(
                          product.productId,
                        ),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: Text(
                        isResubmit
                            ? 'Edit & Address Feedback'
                            : 'Edit Product Details',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 2. Review Feedback Alert (Needs Information / Rejected)
        if (product.reviewFeedback != null &&
            product.reviewFeedback!.trim().isNotEmpty) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      product.status == SellerProductStatus.rejected
                          ? Icons.error_outline
                          : Icons.feedback_outlined,
                      color: product.status == SellerProductStatus.rejected
                          ? AppColors.error
                          : AppColors.warning,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      product.status == SellerProductStatus.rejected
                          ? 'Rejection Feedback'
                          : 'Requested Information / Corrections',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: product.status == SellerProductStatus.rejected
                            ? AppColors.error
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(product.reviewFeedback!),
                if (product.status.canEditDetails) ...[
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: () => context.go(
                      AppRoutes.marketplaceSellerProductEditPath(
                        product.productId,
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Update Product to Resolve Feedback'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 3. Pre-Submission Product Details & Readiness Summary
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product Details Review',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(
                label: 'Category',
                value: '${product.category.displayName} • ${product.subcategory}',
              ),
              _InfoRow(label: 'Brand', value: product.brand),
              _InfoRow(
                label: 'Pickleball-Only',
                value: product.isPickleballOnlyConfirmed
                    ? 'Confirmed'
                    : 'Not confirmed',
              ),
              _InfoRow(label: 'Base SKU', value: product.baseSku),
              _InfoRow(
                label: 'Pricing & Stock',
                value:
                    '${product.formattedPrice} • ${product.totalStock} units (${product.variants.length} variants)',
              ),
              _InfoRow(
                label: 'Return Window',
                value: '${product.returnPolicyDays} days',
              ),
              _InfoRow(
                label: 'Images',
                value: product.images.isEmpty
                    ? 'None attached'
                    : '${product.images.length} selected (${product.images.where((i) => i.isHosted).length} hosted, ${product.images.where((i) => !i.isHosted).length} local preview)',
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Description',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 2),
              Text(product.description, style: theme.textTheme.bodyMedium),
              if (product.specifications.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: product.specifications.entries
                      .map((e) => Chip(label: Text('${e.key}: ${e.value}')))
                      .toList(),
                ),
              ],
              if (product.variants.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Variants', style: theme.textTheme.labelLarge),
                const SizedBox(height: 4),
                ...product.variants.map(
                  (v) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${v.displayLabel} (SKU: ${v.sku}) — ₹${v.sellingPrice.toStringAsFixed(0)} • Stock: ${v.stockCount}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
              if (product.status.canSubmitForReview) ...[
                const Divider(height: AppSpacing.lg),
                Text(
                  'Submission Readiness',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (!state.isVerifiedSeller)
                  _ChecklistItem(
                    ok: false,
                    text:
                        'Seller account must be Verified/Approved before submitting (Current: ${state.sellerProfile.verificationStatus.label}).',
                  )
                else
                  const _ChecklistItem(
                    ok: true,
                    text: 'Verified Seller account confirmed.',
                  ),
                if (readinessIssues.isEmpty)
                  const _ChecklistItem(
                    ok: true,
                    text: 'All mandatory pickleball catalog fields & images complete.',
                  )
                else
                  ...readinessIssues.map(
                    (issue) => _ChecklistItem(ok: false, text: issue),
                  ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _submissionNoteCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: isResubmit
                        ? 'Response Note for Reviewer (optional)'
                        : 'Submission Note (optional)',
                    hintText: isResubmit
                        ? 'Describe the corrections you made for Staff/Admin review...'
                        : 'Optional note for Application Staff review...',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.icon(
                  onPressed: canSubmit
                      ? () => cubit.submitProductForReview(
                            product.productId,
                            submissionNote: _submissionNoteCtrl.text,
                          )
                      : null,
                  icon: const Icon(Icons.send_outlined),
                  label: Text(
                    isResubmit
                        ? 'Resubmit for Review'
                        : 'Submit Product for Review',
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 4. Manual Publishing Control Card
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manual Publishing Control',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (product.status == SellerProductStatus.approved) ...[
                Text(
                  product.isLiveInBuyerCatalog
                      ? 'This approved product is currently PUBLISHED and eligible for the Player Marketplace catalog.'
                      : 'This product is APPROVED by Application Admin but currently UNPUBLISHED (hidden from buyers) until you publish it.',
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Switch(
                      value: product.isPublished,
                      onChanged: state.isMutating
                          ? null
                          : (next) => cubit.togglePublish(
                                productId: product.productId,
                                isPublished: next,
                              ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      product.isPublished ? 'Published (Live)' : 'Unpublished',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ] else
                Text(
                  'Publishing is disabled until the single Application Admin approves this product (Current status: ${product.status.label}). Approval never auto-publishes.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 5. Review History Timeline
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submission & Review History (${product.reviewHistory.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (product.reviewHistory.isEmpty)
                const Text(
                  'No submission or review events yet. Submit this product once ready.',
                )
              else
                ...product.reviewHistory.reversed.map((record) {
                  final formattedDate =
                      DateFormat('dd MMM yyyy, HH:mm').format(record.timestamp);
                  final color = _statusColor(record.status);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _StatusPill(
                                label: record.status.label,
                                color: color,
                              ),
                              Text(
                                record.actorRole,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                formattedDate,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(record.note, style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  Color _statusColor(SellerProductStatus status) {
    switch (status) {
      case SellerProductStatus.draft:
        return AppColors.textSecondaryLight;
      case SellerProductStatus.submittedForReview:
        return AppColors.info;
      case SellerProductStatus.staffRecommended:
        return AppColors.secondary;
      case SellerProductStatus.needsInformation:
        return AppColors.warning;
      case SellerProductStatus.approved:
        return AppColors.success;
      case SellerProductStatus.rejected:
        return AppColors.error;
    }
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  final bool ok;
  final String text;

  const _ChecklistItem({required this.ok, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            size: 18,
            color: ok ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
