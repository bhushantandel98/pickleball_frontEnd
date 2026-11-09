import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/venue_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/venue_details_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/venue_details_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/venue_amenity_chip.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/venue_gallery_view.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/venue_reviews_section.dart';

/// Detailed view for a pickleball venue, courts, amenities, and booking policies.
class VenueDetailsPage extends StatelessWidget {
  final String venueId;
  final VenueDetailsCubit? cubit;

  const VenueDetailsPage({
    super.key,
    required this.venueId,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<VenueDetailsCubit>.value(
        value: cubit!,
        child: _VenueDetailsView(venueId: venueId),
      );
    }

    try {
      final existing = context.read<VenueDetailsCubit>();
      return BlocProvider<VenueDetailsCubit>.value(
        value: existing,
        child: _VenueDetailsView(venueId: venueId),
      );
    } catch (_) {
      return BlocProvider<VenueDetailsCubit>(
        create: (_) => VenueDetailsCubit(repository: sl<VenueRepository>())
          ..loadVenueDetails(venueId),
        child: _VenueDetailsView(venueId: venueId),
      );
    }
  }
}

class _VenueDetailsView extends StatefulWidget {
  final String venueId;

  const _VenueDetailsView({required this.venueId});

  @override
  State<_VenueDetailsView> createState() => _VenueDetailsViewState();
}

class _VenueDetailsViewState extends State<_VenueDetailsView> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<VenueDetailsCubit>();
    if (cubit.state is VenueDetailsInitial) {
      cubit.loadVenueDetails(widget.venueId);
    }
  }

  void _handleBackNavigation(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.playerVenues);
    }
  }

  void _handleContinueToAvailability(BuildContext context, VenueItem venue) {
    context.push(
      AppRoutes.playerCourtAvailabilityPath(venue.id),
      extra: venue.name,
    );
  }

  Widget _buildOverviewCard(BuildContext context, VenueItem venue) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            venue.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          // Badges: Rating, Reviews, Distance & Operating Status
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xxs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxxs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 3),
                    Text(
                      venue.rating.toStringAsFixed(1),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '(${venue.reviewCount} reviews)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Text('•'),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.navigation_outlined,
                    size: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${venue.distanceKm.toStringAsFixed(1)} km away',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Text('•'),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xxxs,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: AppSpacing.borderRadiusSm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Open Now',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Address Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${venue.address}, ${venue.city}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (venue.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'About This Venue',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              venue.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCourtsAndFacilitiesCard(BuildContext context, VenueItem venue) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Courts & Facilities',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Summary features
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppChip.neutral(
                label: '${venue.courtCount} Courts',
              ),
              AppChip.neutral(
                label: venue.isIndoor ? 'Indoor Arena' : 'Outdoor Facility',
              ),
              if (venue.hasNightLights)
                const AppChip.neutral(
                  label: 'Night Floodlights',
                ),
              ...venue.surfaceTypes.map(
                (surface) => AppChip.neutral(label: surface),
              ),
              ...venue.supportedSports.map(
                (sport) => AppChip.neutral(label: sport),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          // Specific detailed specs
          _buildSpecRow(
            context,
            icon: Icons.sports_tennis_rounded,
            title: 'Court Count',
            value: '${venue.courtCount} Verified Courts',
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildSpecRow(
            context,
            icon: Icons.layers_outlined,
            title: 'Court Surfaces',
            value: venue.surfaceTypes.join(', '),
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildSpecRow(
            context,
            icon: venue.isIndoor ? Icons.roofing_rounded : Icons.wb_sunny_outlined,
            title: 'Environment',
            value: venue.isIndoor ? 'Indoor Climate-Controlled' : 'Open Air Outdoor',
          ),
          const SizedBox(height: AppSpacing.xs),
          _buildSpecRow(
            context,
            icon: Icons.light_mode_outlined,
            title: 'Lighting',
            value: venue.hasNightLights
                ? 'High-lumen LED Night Floodlights'
                : 'Daylight play only',
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$title: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesCard(BuildContext context, VenueItem venue) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities & Services',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Available on-site amenities for players and spectators.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: venue.amenities
                .map((a) => VenueAmenityChip(amenity: a))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingAndPoliciesCard(BuildContext context, VenueItem venue) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pricing & Operational Policies',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Price Info
          Row(
            children: [
              Text(
                'Court Pricing: ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${venue.minHourlyRate.toStringAsFixed(0)} - ₹${venue.maxHourlyRate.toStringAsFixed(0)} / hr',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                'Operating Hours: ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                venue.operatingHours,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Cancellation Policy Container
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: AppSpacing.borderRadiusSm,
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.policy_outlined,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cancellation Policy',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        venue.cancellationPolicy,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBookingCard(BuildContext context, VenueItem venue) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'From ₹${venue.minHourlyRate.toStringAsFixed(0)} / hr',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          Text(
            '₹${venue.minHourlyRate.toStringAsFixed(0)} - ₹${venue.maxHourlyRate.toStringAsFixed(0)} per court session',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Operating: ${venue.operatingHours}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.sports_tennis, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  '${venue.courtCount} courts available for reservation',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              label: 'Check Availability',
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: () => _handleContinueToAvailability(context, venue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileBottomBar(BuildContext context, VenueItem venue) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From ₹${venue.minHourlyRate.toStringAsFixed(0)}/hr',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  '${venue.courtCount} courts',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton.primary(
                label: 'Check Availability',
                icon: const Icon(Icons.calendar_month_outlined),
                onPressed: () => _handleContinueToAvailability(context, venue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VenueDetailsCubit, VenueDetailsState>(
      builder: (context, state) {
        return switch (state) {
          VenueDetailsInitial() || VenueDetailsLoading() => Scaffold(
              appBar: CommonAppBar(
                title: 'Venue Details',
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _handleBackNavigation(context),
                ),
              ),
              body: const LoadingView(message: 'Loading venue details...'),
            ),
          VenueDetailsFailure(:final failure) => Scaffold(
              appBar: CommonAppBar(
                title: 'Venue Details',
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => _handleBackNavigation(context),
                ),
              ),
              body: ErrorStateView(
                title: 'Venue Not Found',
                message: failure.message,
                onRetry: () => _handleBackNavigation(context),
              ),
            ),
          VenueDetailsLoaded(:final venue, :final selectedImageIndex) => LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 800;
                final cubit = context.read<VenueDetailsCubit>();
                final galleryImages = venue.effectiveGalleryImages;

                return Scaffold(
                  appBar: CommonAppBar(
                    title: venue.name,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => _handleBackNavigation(context),
                    ),
                  ),
                  bottomNavigationBar:
                      isDesktop ? null : _buildMobileBottomBar(context, venue),
                  body: ResponsiveContainer(
                    maxWidth: AppSpacing.maxContentWidth,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Main Column
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      VenueGalleryView(
                                        images: galleryImages,
                                        selectedIndex: selectedImageIndex,
                                        onSelectImage: (index) =>
                                            cubit.selectGalleryImage(index),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      _buildOverviewCard(context, venue),
                                      const SizedBox(height: AppSpacing.md),
                                      _buildCourtsAndFacilitiesCard(context, venue),
                                      const SizedBox(height: AppSpacing.md),
                                      _buildAmenitiesCard(context, venue),
                                      const SizedBox(height: AppSpacing.md),
                                      _buildPricingAndPoliciesCard(context, venue),
                                      const SizedBox(height: AppSpacing.md),
                                      VenueReviewsSection(
                                        rating: venue.rating,
                                        reviewCount: venue.reviewCount,
                                        reviews: venue.reviews,
                                      ),
                                      const SizedBox(height: AppSpacing.xl),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                // Right Sticky Sidebar Column
                                Expanded(
                                  flex: 2,
                                  child: _buildDesktopBookingCard(context, venue),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                VenueGalleryView(
                                  images: galleryImages,
                                  selectedIndex: selectedImageIndex,
                                  onSelectImage: (index) =>
                                      cubit.selectGalleryImage(index),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _buildOverviewCard(context, venue),
                                const SizedBox(height: AppSpacing.md),
                                _buildCourtsAndFacilitiesCard(context, venue),
                                const SizedBox(height: AppSpacing.md),
                                _buildAmenitiesCard(context, venue),
                                const SizedBox(height: AppSpacing.md),
                                _buildPricingAndPoliciesCard(context, venue),
                                const SizedBox(height: AppSpacing.md),
                                VenueReviewsSection(
                                  rating: venue.rating,
                                  reviewCount: venue.reviewCount,
                                  reviews: venue.reviews,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
        };
      },
    );
  }
}
