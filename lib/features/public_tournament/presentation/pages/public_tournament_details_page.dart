import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_tournament_repository.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/tournament_repository.dart';

/// Public unauthenticated Tournament Details & Schedule overview
/// (`/public/tournaments/:id`).
class PublicTournamentDetailsPage extends StatefulWidget {
  final String tournamentId;
  final TournamentRepository? repository;

  const PublicTournamentDetailsPage({
    super.key,
    required this.tournamentId,
    this.repository,
  });

  @override
  State<PublicTournamentDetailsPage> createState() =>
      _PublicTournamentDetailsPageState();
}

class _PublicTournamentDetailsPageState
    extends State<PublicTournamentDetailsPage> {
  late final TournamentRepository _repository;
  bool _isLoading = true;
  String? _error;
  TournamentItem? _tournament;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ??
        (sl.isRegistered<TournamentRepository>()
            ? sl<TournamentRepository>()
            : MockTournamentRepository());
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _repository.getTournamentById(widget.tournamentId);
    if (!mounted) return;
    result.when(
      success: (item) => setState(() {
        _tournament = item;
        _isLoading = false;
      }),
      failure: (f) => setState(() {
        _error = f.message;
        _isLoading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final padding = isDesktop ? AppSpacing.xl : AppSpacing.md;

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Public Tournament Details',
        actions: [
          TextButton.icon(
            onPressed: () => context.go(AppRoutes.publicRankings),
            icon: const Icon(Icons.leaderboard_outlined),
            label: const Text('Rankings'),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Sign In'),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingView(message: 'Loading public tournament details...')
          : _error != null || _tournament == null
              ? ErrorStateView(
                  title: 'Tournament Unavailable',
                  message: _error ?? 'Tournament could not be found.',
                  onRetry: _load,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: padding,
                      vertical: AppSpacing.lg,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: AppSpacing.xs,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        _tournament!.name,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          _tournament!.status.displayName,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${_tournament!.venueName}, ${_tournament!.city} • Organizer: ${_tournament!.organizerName}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Dates: ${DateFormat('dd MMM yyyy').format(_tournament!.startDate)} – ${DateFormat('dd MMM yyyy').format(_tournament!.endDate)} • Prize Pool: ${_tournament!.prizePool}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(_tournament!.description),
                                  const SizedBox(height: AppSpacing.md),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.xs,
                                    children: [
                                      FilledButton.icon(
                                        onPressed: () =>
                                            context.go(AppRoutes.login),
                                        icon: const Icon(Icons.login),
                                        label: const Text(
                                          'Sign In to Register',
                                        ),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => context.go(
                                          AppRoutes.publicRankings,
                                        ),
                                        icon: const Icon(
                                          Icons.leaderboard_outlined,
                                        ),
                                        label: const Text(
                                          'View Platform Rankings',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Divisions & Categories (${_tournament!.categories.length})',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ..._tournament!.categories.map(
                              (cat) => Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.sm,
                                ),
                                child: AppCard(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              cat.name,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            Text(
                                              '${cat.eligibilitySummary} • Entry: ${cat.formattedFee}',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Chip(
                                        label: Text(
                                          '${cat.registeredCount}/${cat.maxParticipants} slots',
                                        ),
                                        backgroundColor: cat.isCapacityFull
                                            ? AppColors.error
                                                .withValues(alpha: 0.12)
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}
