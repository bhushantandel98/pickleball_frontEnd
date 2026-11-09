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
import 'package:pickleball_platform/core/widgets/app_dialog.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/tournament_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/tournament_details_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/tournament_details_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/tournament_category_card.dart';

/// Screen presenting complete tournament details, event categories, eligibility rules, and registration action.
class TournamentDetailsPage extends StatelessWidget {
  final String tournamentId;
  final TournamentDetailsCubit? cubit;

  const TournamentDetailsPage({
    super.key,
    required this.tournamentId,
    this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<TournamentDetailsCubit>.value(
        value: cubit!..loadTournament(),
        child: const _TournamentDetailsView(),
      );
    }

    return BlocProvider<TournamentDetailsCubit>(
      create: (_) => TournamentDetailsCubit(
        repository: sl<TournamentRepository>(),
        tournamentId: tournamentId,
      )..loadTournament(),
      child: const _TournamentDetailsView(),
    );
  }
}

class _TournamentDetailsView extends StatefulWidget {
  const _TournamentDetailsView();

  @override
  State<_TournamentDetailsView> createState() => _TournamentDetailsViewState();
}

class _TournamentDetailsViewState extends State<_TournamentDetailsView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showWithdrawConfirmation(
    BuildContext context,
    TournamentRegistration registration,
  ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AppConfirmationDialog(
          title: 'Withdraw from Tournament',
          message:
              'Are you sure you want to withdraw from ${registration.categoryName}? '
              'Your entry spot will be released.',
          confirmLabel: 'Withdraw',
          cancelLabel: 'Keep Entry',
          isDestructive: true,
          onConfirm: () {
            context.read<TournamentDetailsCubit>().withdraw(registration.id);
          },
        );
      },
    );
  }

  Widget _buildHeroBanner(BuildContext context, TournamentItem tournament) {
    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMd),
                ),
                child: tournament.imageUrl != null
                    ? Image.asset(
                        tournament.imageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 180,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.emoji_events_outlined, size: 56),
                          ),
                        ),
                      )
                    : Container(
                        height: 180,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.emoji_events_outlined, size: 56),
                        ),
                      ),
              ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: tournament.status == TournamentStatus.registrationOpen
                    ? const AppChip.success(label: 'Registration Open')
                    : AppChip.neutral(label: tournament.status.displayName),
              ),
              if (tournament.isRegistered)
                const Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: AppChip.info(
                    label: 'Entered',
                    icon: Icon(Icons.check, size: 12),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Organized by ${tournament.organizerName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Venue & City
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${tournament.venueName}, ${tournament.address}, ${tournament.city}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Dates & Registration Deadline
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tournament.formattedDateRange,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.timer_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Deadline: ${tournament.formattedDeadline}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, TournamentItem tournament) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // About Tournament
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About the Tournament',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                tournament.description,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricItem(
                    context,
                    label: 'Total Prize Pool',
                    value: tournament.prizePool,
                    icon: Icons.monetization_on_outlined,
                  ),
                  _buildMetricItem(
                    context,
                    label: 'Match Format',
                    value: 'Best 2 of 3',
                    icon: Icons.sports_tennis_outlined,
                  ),
                  _buildMetricItem(
                    context,
                    label: 'Total Capacity',
                    value: '${tournament.totalCapacity} Players',
                    icon: Icons.groups_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Scoring & Equipment Summary
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scoring & Equipment',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Format: ${tournament.scoringFormat}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Sanctioned: Official USAPA / IPA pickleball standards.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab(
    BuildContext context,
    TournamentDetailsLoaded loaded,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: loaded.tournament.categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final category = loaded.tournament.categories[index];
        final isEligible = loaded.isCategoryEligible(category);
        final isRegistered =
            loaded.tournament.registeredCategoryIds.contains(category.id);

        return TournamentCategoryCard(
          key: Key('category_card_${category.id}'),
          category: category,
          isEligible: isEligible,
          isRegistered: isRegistered,
        );
      },
    );
  }

  Widget _buildRulesTab(BuildContext context, TournamentItem tournament) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Official Tournament Rules',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...tournament.rules.map((rule) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rule,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cancellation & Withdrawal Policy',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Withdrawal with 100% refund is available up to 48 hours prior to registration deadline. '
                'Once tournament draws are published, entries are locked and non-refundable.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    TournamentDetailsLoaded loaded,
  ) {
    final theme = Theme.of(context);
    final tournament = loaded.tournament;
    final isRegistered = loaded.playerRegistration != null || tournament.isRegistered;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isRegistered ? 'Registration Status' : 'Entry Fee From',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  isRegistered
                      ? (loaded.playerRegistration?.status.displayName ?? 'Registered')
                      : tournament.formattedFeeFrom,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isRegistered
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const Spacer(),

            // Action Button
            if (isRegistered) ...[
              if (tournament.status == TournamentStatus.inProgress)
                AppButton.primary(
                  key: const Key('tournament_match_day_button'),
                  label: 'Match Day Hub',
                  icon: const Icon(Icons.scoreboard_outlined, size: 16),
                  onPressed: () => context.push(AppRoutes.playerMatchDay),
                )
              else if (loaded.playerRegistration != null)
                AppButton.secondary(
                  key: const Key('tournament_withdraw_button'),
                  label: 'Withdraw Entry',
                  isLoading: loaded.isWithdrawing,
                  onPressed: () => _showWithdrawConfirmation(
                    context,
                    loaded.playerRegistration!,
                  ),
                )
              else
                AppButton.primary(
                  label: 'Entered',
                  onPressed: null,
                ),
            ] else if (tournament.isRegistrationOpen) ...[
              AppButton.primary(
                key: const Key('tournament_register_now_button'),
                label: 'Register Now',
                icon: const Icon(Icons.app_registration),
                onPressed: () {
                  context.push(
                    AppRoutes.playerTournamentRegistrationPath(tournament.id),
                  );
                },
              ),
            ] else ...[
              AppButton.secondary(
                label: tournament.status == TournamentStatus.upcoming
                    ? 'Registration Opens Soon'
                    : 'Registration Closed',
                onPressed: null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CommonAppBar(
          title: 'Tournament Details',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
      ),
      body: BlocConsumer<TournamentDetailsCubit, TournamentDetailsState>(
        listener: (context, state) {
          if (state is TournamentDetailsLoaded &&
              state.feedbackMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.feedbackMessage!),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<TournamentDetailsCubit>().clearFeedback();
          }
        },
        builder: (context, state) {
          if (state is TournamentDetailsLoading ||
              state is TournamentDetailsInitial) {
            return const LoadingView(message: 'Loading tournament details...');
          }

          if (state is TournamentDetailsFailure) {
            return ErrorStateView(
              title: 'Tournament Unavailable',
              message: state.message,
              onRetry: () =>
                  context.read<TournamentDetailsCubit>().loadTournament(),
            );
          }

          final loadedState = state as TournamentDetailsLoaded;
          final tournament = loadedState.tournament;

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => context
                      .read<TournamentDetailsCubit>()
                      .loadTournament(isRefresh: true),
                  child: ResponsiveContainer(
                    maxWidth: AppSpacing.maxContentWidth,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroBanner(context, tournament),
                          const SizedBox(height: AppSpacing.md),

                          // Tab Bar
                          TabBar(
                            controller: _tabController,
                            tabs: const [
                              Tab(text: 'Overview'),
                              Tab(text: 'Categories'),
                              Tab(text: 'Rules'),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Tab Content
                          AnimatedBuilder(
                            animation: _tabController,
                            builder: (context, _) {
                              switch (_tabController.index) {
                                case 0:
                                  return _buildOverviewTab(context, tournament);
                                case 1:
                                  return _buildCategoriesTab(context, loadedState);
                                case 2:
                                  return _buildRulesTab(context, tournament);
                                default:
                                  return const SizedBox.shrink();
                              }
                            },
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Sticky Bottom Action Bar
              _buildBottomBar(context, loadedState),
            ],
          );
        },
      ),
    );
  }
}
