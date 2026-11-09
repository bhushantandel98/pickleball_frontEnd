import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/venue_discovery_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/venue_discovery_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/venue_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/venue_search_bar.dart';

/// Venue Discovery screen for exploring, searching, and filtering pickleball venues.
class VenueDiscoveryPage extends StatelessWidget {
  final VenueDiscoveryCubit? cubit;

  const VenueDiscoveryPage({
    super.key,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<VenueDiscoveryCubit>.value(
        value: cubit!,
        child: const _VenueDiscoveryView(),
      );
    }

    try {
      final existing = context.read<VenueDiscoveryCubit>();
      return BlocProvider<VenueDiscoveryCubit>.value(
        value: existing,
        child: const _VenueDiscoveryView(),
      );
    } catch (_) {
      return BlocProvider<VenueDiscoveryCubit>(
        create: (_) => sl<VenueDiscoveryCubit>(),
        child: const _VenueDiscoveryView(),
      );
    }
  }
}

class _VenueDiscoveryView extends StatefulWidget {
  const _VenueDiscoveryView();

  @override
  State<_VenueDiscoveryView> createState() => _VenueDiscoveryViewState();
}

class _VenueDiscoveryViewState extends State<_VenueDiscoveryView> {
  List<VenueItem>? _lastVenues;
  VenueFilter? _lastFilter;
  int? _lastTotalCount;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<VenueDiscoveryCubit>();
    if (cubit.state is VenueDiscoveryInitial) {
      cubit.loadVenues();
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<VenueDiscoveryCubit>();

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Venues Found',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'We couldn\'t find any venues matching your current search or filters. Try adjusting your criteria or clearing filters.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.outline(
              label: 'Clear Filters',
              icon: const Icon(Icons.refresh),
              onPressed: () => cubit.clearFilters(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent(
    BuildContext context, {
    required List<VenueItem> venues,
    required VenueFilter filter,
    required int totalCount,
  }) {
    final theme = Theme.of(context);
    final cubit = context.read<VenueDiscoveryCubit>();

    return RefreshIndicator(
      onRefresh: () => cubit.refreshVenues(),
      child: ResponsiveContainer(
        maxWidth: AppSpacing.maxContentWidth,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header & supporting text
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover Courts & Venues',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Find and reserve verified pickleball facilities, courts, and amenities nearby.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Search bar & filter controls (kept persistent, preserving input focus)
                  VenueSearchBar(
                    filter: filter,
                    onSearchChanged: (query) => cubit.updateSearchQuery(query),
                    onFilterChanged: (newFilter) => cubit.updateFilter(newFilter),
                    onSortChanged: (sort) => cubit.updateSortOption(sort),
                    onClearFilters: () => cubit.clearFilters(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Results counter & active sort label
                  Row(
                    children: [
                      Text(
                        venues.isEmpty
                            ? 'No venues'
                            : 'Showing $totalCount venue${totalCount == 1 ? '' : 's'}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Sorted by: ${filter.sortBy.displayName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
            // Venue listing or empty state
            if (venues.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyState(context),
              )
            else
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.crossAxisExtent > 800;

                  if (isDesktop) {
                    return SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppSpacing.md,
                        mainAxisSpacing: AppSpacing.md,
                        mainAxisExtent: 220,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final venue = venues[index];
                          return VenueCard(
                            venue: venue,
                            onTap: () {
                              context.push(
                                AppRoutes.playerVenueDetailsPath(venue.id),
                                extra: venue.name,
                              );
                            },
                          );
                        },
                        childCount: venues.length,
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final venue = venues[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: VenueCard(
                            venue: venue,
                            onTap: () {
                              context.push(
                                AppRoutes.playerVenueDetailsPath(venue.id),
                                extra: venue.name,
                              );
                            },
                          ),
                        );
                      },
                      childCount: venues.length,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<VenueDiscoveryCubit, VenueDiscoveryState>(
        listener: (context, state) {
          if (state is VenueDiscoveryLoaded) {
            _lastVenues = state.venues;
            _lastFilter = state.filter;
            _lastTotalCount = state.totalCount;
          }
        },
        builder: (context, state) {
          if (state is VenueDiscoveryLoaded) {
            _lastVenues = state.venues;
            _lastFilter = state.filter;
            _lastTotalCount = state.totalCount;
            return _buildLoadedContent(
              context,
              venues: state.venues,
              filter: state.filter,
              totalCount: state.totalCount,
            );
          }

          if (state is VenueDiscoveryFailure) {
            if (_lastVenues == null) {
              return ErrorStateView(
                title: 'Unable to Load Venues',
                message: state.failure.message,
                onRetry: () => context.read<VenueDiscoveryCubit>().loadVenues(),
              );
            }
          }

          // If venues were already loaded, keep the page and search field mounted
          if (_lastVenues != null && _lastFilter != null && _lastTotalCount != null) {
            return _buildLoadedContent(
              context,
              venues: _lastVenues!,
              filter: _lastFilter!,
              totalCount: _lastTotalCount!,
            );
          }

          return const LoadingView(message: 'Searching available venues...');
        },
      ),
    );
  }
}
