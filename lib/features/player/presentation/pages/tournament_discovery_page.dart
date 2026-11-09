import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/tournament_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/tournament_discovery_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/tournament_discovery_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/tournament_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/tournament_filter_sheet.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/tournament_search_bar.dart';

/// Screen enabling players to discover, search, filter, and view sanctioned tournaments.
class TournamentDiscoveryPage extends StatelessWidget {
  final TournamentDiscoveryCubit? cubit;

  const TournamentDiscoveryPage({super.key, this.cubit});

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<TournamentDiscoveryCubit>.value(
        value: cubit!..loadTournaments(),
        child: const _TournamentDiscoveryView(),
      );
    }

    return BlocProvider<TournamentDiscoveryCubit>(
      create: (_) => TournamentDiscoveryCubit(
        repository: sl<TournamentRepository>(),
      )..loadTournaments(),
      child: const _TournamentDiscoveryView(),
    );
  }
}

class _TournamentDiscoveryView extends StatelessWidget {
  const _TournamentDiscoveryView();

  void _openFilterSheet(BuildContext context, TournamentFilter currentFilter) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (sheetContext) {
        return TournamentFilterSheet(
          currentFilter: currentFilter,
          onApply: (newFilter) {
            context.read<TournamentDiscoveryCubit>().updateFilter(newFilter);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool hasFilters) {
    final theme = Theme.of(context);

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
              Icons.search_off_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasFilters ? 'No Tournaments Found' : 'No Tournaments Available',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                hasFilters
                    ? 'No tournaments match your current search and filter criteria. Try adjusting or clearing your filters.'
                    : 'There are currently no active or upcoming tournaments scheduled. Check back soon for new events.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton.primary(
                key: const Key('tournament_reset_filters_button'),
                label: 'Reset Filters',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  context.read<TournamentDiscoveryCubit>().clearFilters();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentList(
    BuildContext context,
    List<TournamentItem> tournaments,
  ) {
    final isWide = !ResponsiveLayout.isMobile(context);

    if (isWide) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          mainAxisExtent: 440,
        ),
        itemCount: tournaments.length,
        itemBuilder: (context, index) {
          final tournament = tournaments[index];
          return TournamentCard(
            key: Key('tournament_card_${tournament.id}'),
            tournament: tournament,
            onTap: () => context.push(
              AppRoutes.playerTournamentDetailsPath(tournament.id),
            ),
          );
        },
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tournaments.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final tournament = tournaments[index];
        return TournamentCard(
          key: Key('tournament_card_${tournament.id}'),
          tournament: tournament,
          onTap: () => context.push(
            AppRoutes.playerTournamentDetailsPath(tournament.id),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CommonAppBar(
          title: 'Tournaments',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.playerDashboard);
              }
            },
          ),
        ),
      ),
      body: BlocBuilder<TournamentDiscoveryCubit, TournamentDiscoveryState>(
        builder: (context, state) {
          if (state is TournamentDiscoveryLoading ||
              state is TournamentDiscoveryInitial) {
            return const LoadingView(message: 'Discovering tournaments...');
          }

          if (state is TournamentDiscoveryFailure) {
            return ErrorStateView(
              title: 'Unable to Load Tournaments',
              message: state.message,
              onRetry: () =>
                  context.read<TournamentDiscoveryCubit>().loadTournaments(),
            );
          }

          final loadedState = state as TournamentDiscoveryLoaded;

          return RefreshIndicator(
            onRefresh: () => context
                .read<TournamentDiscoveryCubit>()
                .loadTournaments(isRefresh: true),
            child: ResponsiveContainer(
              maxWidth: AppSpacing.maxContentWidth,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header text
                    Text(
                      'Compete & Excel',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Browse sanctioned pickleball tournaments, view division eligibility, and enter competitions.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Search, Filter Trigger & Sort Bar
                    TournamentSearchBar(
                      initialQuery: loadedState.filter.searchQuery,
                      onQueryChanged: (query) {
                        context
                            .read<TournamentDiscoveryCubit>()
                            .updateSearchQuery(query);
                      },
                      onOpenFilter: () =>
                          _openFilterSheet(context, loadedState.filter),
                      onSortSelected: (sortOption) {
                        context
                            .read<TournamentDiscoveryCubit>()
                            .updateSort(sortOption);
                      },
                      currentSort: loadedState.filter.sortBy,
                      activeFilterCount: loadedState.filter.activeFilterCount,
                      activeFilter: loadedState.filter,
                      onFilterQuickChanged: (newFilter) {
                        context
                            .read<TournamentDiscoveryCubit>()
                            .updateFilter(newFilter);
                      },
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Tournaments List or Empty State
                    if (loadedState.isEmpty)
                      _buildEmptyState(
                        context,
                        loadedState.filter.hasActiveFilters,
                      )
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Tournaments (${loadedState.filteredTournaments.length})',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (loadedState.filter.hasActiveFilters)
                            TextButton(
                              onPressed: () => context
                                  .read<TournamentDiscoveryCubit>()
                                  .clearFilters(),
                              child: const Text('Clear Filters'),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildTournamentList(
                        context,
                        loadedState.filteredTournaments,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
