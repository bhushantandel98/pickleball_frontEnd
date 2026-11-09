import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_text_field.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/features/player/domain/repositories/coaching_academy_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_discovery_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_discovery_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/coach_discovery_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/coach_discovery_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/my_coaching_requests_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/my_coaching_requests_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/academy_branch_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/coach_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/coaching_request_tile.dart';

/// Main Player Discovery Page for Academies and Coaches.
///
/// Features 3 distinct tabs:
/// 1. Academies & Branches (Public Listings)
/// 2. Find Coaches (Registered Coach Directory)
/// 3. My Requests (Active Enrollment & Coaching Inquiries Tracking)
class PlayerAcademyCoachPage extends StatefulWidget {
  final AcademyDiscoveryCubit? academyCubit;
  final CoachDiscoveryCubit? coachCubit;
  final MyCoachingRequestsCubit? requestsCubit;

  const PlayerAcademyCoachPage({
    super.key,
    this.academyCubit,
    this.coachCubit,
    this.requestsCubit,
  });

  @override
  State<PlayerAcademyCoachPage> createState() => _PlayerAcademyCoachPageState();
}

class _PlayerAcademyCoachPageState extends State<PlayerAcademyCoachPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final AcademyDiscoveryCubit _academyCubit;
  late final CoachDiscoveryCubit _coachCubit;
  late final MyCoachingRequestsCubit _requestsCubit;

  final TextEditingController _academySearchController = TextEditingController();
  final TextEditingController _coachSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _academyCubit = widget.academyCubit ??
        AcademyDiscoveryCubit(sl<CoachingAcademyRepository>());
    _coachCubit = widget.coachCubit ??
        CoachDiscoveryCubit(sl<CoachingAcademyRepository>());
    _requestsCubit = widget.requestsCubit ??
        MyCoachingRequestsCubit(sl<CoachingAcademyRepository>());

    _academyCubit.loadBranches();
    _coachCubit.loadCoaches();
    _requestsCubit.loadRequests();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging && _tabController.index == 2) {
        _requestsCubit.loadRequests(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _academySearchController.dispose();
    _coachSearchController.dispose();
    if (widget.academyCubit == null) _academyCubit.close();
    if (widget.coachCubit == null) _coachCubit.close();
    if (widget.requestsCubit == null) _requestsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _academyCubit),
        BlocProvider.value(value: _coachCubit),
        BlocProvider.value(value: _requestsCubit),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Academies & Coaches'),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.school_outlined),
                text: 'Academies',
              ),
              Tab(
                icon: Icon(Icons.sports_tennis_outlined),
                text: 'Coaches',
              ),
              Tab(
                icon: Icon(Icons.assignment_outlined),
                text: 'My Requests',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAcademiesTab(theme),
            _buildCoachesTab(theme),
            _buildMyRequestsTab(theme),
          ],
        ),
      ),
    );
  }

  // --- Tab 1: Academy Branch Listings ---
  Widget _buildAcademiesTab(ThemeData theme) {
    return BlocBuilder<AcademyDiscoveryCubit, AcademyDiscoveryState>(
      builder: (context, state) {
        if (state is AcademyDiscoveryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AcademyDiscoveryError) {
          return Center(
            child: ErrorStateView(
              message: state.message,
              onRetry: () => _academyCubit.loadBranches(),
            ),
          );
        }

        if (state is AcademyDiscoveryLoaded) {
          return Column(
            children: [
              // Search & City Filters
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    AppTextField(
                      controller: _academySearchController,
                      hint: 'Search academy name, branch, or area...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _academySearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _academySearchController.clear();
                                _academyCubit.updateSearchQuery('');
                              },
                            )
                          : null,
                      onChanged: (val) => _academyCubit.updateSearchQuery(val),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: state.availableCities.map((city) {
                          final isSelected = state.selectedCity == city;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(city),
                              selected: isSelected,
                              onSelected: (_) => _academyCubit.filterByCity(city),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Listings / Empty View
              Expanded(
                child: state.isEmpty
                    ? Center(
                        child: EmptyStateView(
                          title: 'No Academy Branches Found',
                          message: 'No branches match your current search or city filter.',
                          actionLabel: 'Reset Filters',
                          onAction: () {
                            _academySearchController.clear();
                            _academyCubit.clearFilters();
                          },
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _academyCubit.loadBranches(showLoading: false),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.xl,
                          ),
                          itemCount: state.branches.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final branch = state.branches[index];
                            return AcademyBranchCard(
                              branch: branch,
                              onTap: () {
                                context.push(
                                  AppRoutes.playerAcademyDetailsPath(branch.id),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // --- Tab 2: Coaches Directory ---
  Widget _buildCoachesTab(ThemeData theme) {
    return BlocBuilder<CoachDiscoveryCubit, CoachDiscoveryState>(
      builder: (context, state) {
        if (state is CoachDiscoveryLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CoachDiscoveryError) {
          return Center(
            child: ErrorStateView(
              message: state.message,
              onRetry: () => _coachCubit.loadCoaches(),
            ),
          );
        }

        if (state is CoachDiscoveryLoaded) {
          return Column(
            children: [
              // Search & Specialization Filters
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    AppTextField(
                      controller: _coachSearchController,
                      hint: 'Search coach name, specialization, or club...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _coachSearchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _coachSearchController.clear();
                                _coachCubit.updateSearchQuery('');
                              },
                            )
                          : null,
                      onChanged: (val) => _coachCubit.updateSearchQuery(val),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: state.availableSpecializations.map((spec) {
                          final isSelected = state.selectedSpecialization == spec;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(
                                spec.length > 28 ? '${spec.substring(0, 25)}...' : spec,
                              ),
                              selected: isSelected,
                              onSelected: (_) =>
                                  _coachCubit.filterBySpecialization(spec),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Coach List / Empty View
              Expanded(
                child: state.isEmpty
                    ? Center(
                        child: EmptyStateView(
                          title: 'No Coaches Found',
                          message: 'No registered coaches match your search criteria.',
                          actionLabel: 'Reset Filters',
                          onAction: () {
                            _coachSearchController.clear();
                            _coachCubit.clearFilters();
                          },
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _coachCubit.loadCoaches(showLoading: false),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            AppSpacing.xl,
                          ),
                          itemCount: state.coaches.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            final coach = state.coaches[index];
                            return CoachCard(
                              coach: coach,
                              onTap: () {
                                context.push(
                                  AppRoutes.playerCoachDetailsPath(coach.id),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  // --- Tab 3: My Inquiries & Enrollment Requests ---
  Widget _buildMyRequestsTab(ThemeData theme) {
    return BlocBuilder<MyCoachingRequestsCubit, MyCoachingRequestsState>(
      builder: (context, state) {
        if (state is MyCoachingRequestsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is MyCoachingRequestsError) {
          return Center(
            child: ErrorStateView(
              message: state.message,
              onRetry: () => _requestsCubit.loadRequests(),
            ),
          );
        }

        if (state is MyCoachingRequestsLoaded) {
          if (state.isEmpty) {
            return Center(
              child: EmptyStateView(
                title: 'No Active Inquiries or Requests',
                message:
                    'You haven\'t submitted any academy enrollment requests or coach inquiries yet.',
                actionLabel: 'Explore Academies',
                onAction: () => _tabController.animateTo(0),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _requestsCubit.loadRequests(showLoading: false),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (state.enrollmentRequests.isNotEmpty) ...[
                  Text(
                    'Academy Enrollments (${state.enrollmentRequests.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Enrollment applications undergo review by academy staff. Waitlisted entries update as spots open.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...state.enrollmentRequests.map((req) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AcademyEnrollmentRequestTile(
                        request: req,
                        onCancel: () => _requestsCubit.cancelEnrollment(req.id),
                      ),
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (state.coachInquiries.isNotEmpty) ...[
                  Text(
                    'Coach Inquiries (${state.coachInquiries.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Coaches review inquiries directly. Coaching dashboard access is granted only after a coach approves.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...state.coachInquiries.map((inq) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: CoachInquiryRequestTile(
                        inquiry: inq,
                        onCancel: () => _requestsCubit.cancelInquiry(inq.id),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
