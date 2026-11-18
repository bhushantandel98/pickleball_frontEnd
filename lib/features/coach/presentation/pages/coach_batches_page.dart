import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/coach/data/repositories/mock_coach_dashboard_repository.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_dashboard_data.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_dashboard_cubit.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_dashboard_state.dart';

/// Coach — Assigned Academy Batches screen (`/coach/batches`).
///
/// Displays academy-managed batches assigned to the authenticated coach across
/// accepted academy affiliations. Academy batch schedules are read-only for the
/// coach per Coach PRD.
class CoachBatchesPage extends StatefulWidget {
  final CoachDashboardCubit? cubit;

  const CoachBatchesPage({super.key, this.cubit});

  @override
  State<CoachBatchesPage> createState() => _CoachBatchesPageState();
}

class _CoachBatchesPageState extends State<CoachBatchesPage> {
  final _searchCtrl = TextEditingController();
  String? _selectedAcademyId;
  String? _selectedBranchId;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _resolveCoachId(BuildContext context) {
    try {
      final session = context.read<SessionCubit>().state;
      if (session.userId != null && session.userId!.trim().isNotEmpty) {
        return session.userId!.trim();
      }
    } catch (_) {}
    return 'user_coach_001';
  }

  @override
  Widget build(BuildContext context) {
    final coachId = _resolveCoachId(context);

    if (widget.cubit != null) {
      return BlocProvider<CoachDashboardCubit>.value(
        value: widget.cubit!,
        child: _buildBody(context, coachId),
      );
    }

    return BlocProvider<CoachDashboardCubit>(
      create: (_) {
        if (sl.isRegistered<CoachDashboardCubit>()) {
          return sl<CoachDashboardCubit>()..loadDashboard(coachId: coachId);
        }
        return CoachDashboardCubit(
          repository: MockCoachDashboardRepository(),
        )..loadDashboard(coachId: coachId);
      },
      child: _buildBody(context, coachId),
    );
  }

  Widget _buildBody(BuildContext context, String coachId) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final padding = isDesktop ? AppSpacing.xl : AppSpacing.md;

    return Scaffold(
      body: BlocBuilder<CoachDashboardCubit, CoachDashboardState>(
        builder: (context, state) {
          if (state is CoachDashboardInitial ||
              state is CoachDashboardLoading) {
            return const LoadingView(
              message: 'Loading assigned academy batches...',
            );
          }
          if (state is CoachDashboardFailure) {
            return ErrorStateView(
              title: 'Unable to Load Assigned Batches',
              message: state.failure.message,
              onRetry: () => context
                  .read<CoachDashboardCubit>()
                  .loadDashboard(coachId: coachId),
            );
          }
          if (state is CoachDashboardEmpty) {
            return const EmptyStateView(
              title: 'No Assigned Academy Batches',
              message:
                  'Batches assigned by affiliated academies will appear here.',
            );
          }

          final loaded = state as CoachDashboardLoaded;
          final data = loaded.data;
          final affiliations = data.acceptedAffiliations;

          final academyBatches = data.upcomingSessions
              .where((s) => s.contextType == CoachSessionContext.academy)
              .where((s) {
                if (_selectedAcademyId != null &&
                    s.academyId != _selectedAcademyId) {
                  return false;
                }
                if (_selectedBranchId != null &&
                    s.branchId != _selectedBranchId) {
                  return false;
                }
                final q = _query.trim().toLowerCase();
                if (q.isNotEmpty) {
                  return s.title.toLowerCase().contains(q) ||
                      s.venueOrBranchName.toLowerCase().contains(q) ||
                      (s.academyName?.toLowerCase().contains(q) ?? false);
                }
                return true;
              })
              .toList();

          return RefreshIndicator(
            onRefresh: () => context
                .read<CoachDashboardCubit>()
                .refreshDashboard(coachId: coachId),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: padding,
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
                                'Assigned Academy Batches',
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'View your affiliated academy branches and assigned batch schedules (read-only).',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                context.go(AppRoutes.coachCalendar),
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: const Text('Open Calendar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Read-only governance banner
                      AppCard(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Academy-managed batch schedules and participant rosters are controlled by the Academy Admin. Contact the Academy Coordinator for schedule changes.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Search & Affiliation Filters
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText:
                                    'Search batches by name, academy, or branch...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _query.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setState(() => _query = '');
                                        },
                                      )
                                    : null,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (v) => setState(() => _query = v),
                            ),
                            if (affiliations.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    FilterChip(
                                      label: const Text('All Academies'),
                                      selected: _selectedAcademyId == null,
                                      onSelected: (_) => setState(() {
                                        _selectedAcademyId = null;
                                        _selectedBranchId = null;
                                      }),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    ...affiliations.map(
                                      (aff) => Padding(
                                        padding: const EdgeInsets.only(
                                          right: AppSpacing.xs,
                                        ),
                                        child: FilterChip(
                                          label: Text(aff.academyName),
                                          selected:
                                              _selectedAcademyId == aff.academyId,
                                          onSelected: (_) => setState(() {
                                            _selectedAcademyId = aff.academyId;
                                            _selectedBranchId = null;
                                          }),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      if (academyBatches.isEmpty)
                        EmptyStateView(
                          title: _query.isNotEmpty || _selectedAcademyId != null
                              ? 'No Matching Batches'
                              : 'No Assigned Academy Batches',
                          message: _query.isNotEmpty ||
                                  _selectedAcademyId != null
                              ? 'Try clearing your search or academy filter.'
                              : 'Batches assigned by affiliated academies will appear here.',
                          actionLabel:
                              (_query.isNotEmpty || _selectedAcademyId != null)
                                  ? 'Clear Filters'
                                  : null,
                          onAction:
                              (_query.isNotEmpty || _selectedAcademyId != null)
                                  ? () {
                                      _searchCtrl.clear();
                                      setState(() {
                                        _query = '';
                                        _selectedAcademyId = null;
                                        _selectedBranchId = null;
                                      });
                                    }
                                  : null,
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: academyBatches.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final batch = academyBatches[index];
                            return AppCard(
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
                                        batch.title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Chip(label: Text(batch.sessionType)),
                                      Chip(
                                        label: Text(
                                          batch.status.name.toUpperCase(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${batch.academyName ?? 'Affiliated Academy'} • ${batch.venueOrBranchName}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Wrap(
                                    spacing: AppSpacing.lg,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        'Schedule: ${batch.dateLabel} • ${batch.timeRange}',
                                      ),
                                      Text(
                                        'Participants: ${batch.participantCount}',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          _showBatchDetails(context, batch),
                                      icon: const Icon(
                                        Icons.visibility_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Batch Details'),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBatchDetails(BuildContext context, CoachSessionItem batch) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(batch.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Academy: ${batch.academyName ?? 'Affiliated Academy'}'),
            Text('Branch / Court: ${batch.venueOrBranchName}'),
            Text('Type: ${batch.sessionType}'),
            Text('Date: ${batch.dateLabel}'),
            Text('Time: ${batch.timeRange}'),
            Text('Enrolled Participants: ${batch.participantCount}'),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Schedule modifications are managed by the Academy Admin.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go(AppRoutes.coachCalendar);
            },
            child: const Text('View in Calendar'),
          ),
        ],
      ),
    );
  }
}
