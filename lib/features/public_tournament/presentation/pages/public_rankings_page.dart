import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';

class _PublicRankingEntry {
  final int rank;
  final String playerName;
  final String city;
  final String division;
  final String ageGroup;
  final double rating;
  final int points;
  final int matchesPlayed;
  final int wins;

  const _PublicRankingEntry({
    required this.rank,
    required this.playerName,
    required this.city,
    required this.division,
    required this.ageGroup,
    required this.rating,
    required this.points,
    required this.matchesPlayed,
    required this.wins,
  });

  int get winPercent =>
      matchesPlayed == 0 ? 0 : ((wins / matchesPlayed) * 100).round();
}

/// Public unauthenticated Platform Rankings & Leaderboards (`/public/rankings`).
class PublicRankingsPage extends StatefulWidget {
  const PublicRankingsPage({super.key});

  @override
  State<PublicRankingsPage> createState() => _PublicRankingsPageState();
}

class _PublicRankingsPageState extends State<PublicRankingsPage> {
  final _searchCtrl = TextEditingController();
  String _selectedDivision = 'All';
  String _selectedAgeGroup = 'All';
  String _query = '';

  static const List<String> _divisions = [
    'All',
    'Men\'s Singles',
    'Women\'s Singles',
    'Men\'s Doubles',
    'Mixed Doubles',
  ];

  static const List<String> _ageGroups = ['All', 'Open', '35+', 'U-18'];

  static const List<_PublicRankingEntry> _mockRankings = [
    _PublicRankingEntry(
      rank: 1,
      playerName: 'Aarav Kulkarni',
      city: 'Mumbai',
      division: 'Men\'s Singles',
      ageGroup: 'Open',
      rating: 5.2,
      points: 2480,
      matchesPlayed: 38,
      wins: 33,
    ),
    _PublicRankingEntry(
      rank: 2,
      playerName: 'Ananya Rao',
      city: 'Bengaluru',
      division: 'Women\'s Singles',
      ageGroup: 'Open',
      rating: 5.0,
      points: 2390,
      matchesPlayed: 34,
      wins: 29,
    ),
    _PublicRankingEntry(
      rank: 3,
      playerName: 'Rohan Deshmukh',
      city: 'Pune',
      division: 'Men\'s Doubles',
      ageGroup: 'Open',
      rating: 4.8,
      points: 2150,
      matchesPlayed: 42,
      wins: 31,
    ),
    _PublicRankingEntry(
      rank: 4,
      playerName: 'Meera Krishnan',
      city: 'Chennai',
      division: 'Mixed Doubles',
      ageGroup: '35+',
      rating: 4.6,
      points: 1980,
      matchesPlayed: 29,
      wins: 22,
    ),
    _PublicRankingEntry(
      rank: 5,
      playerName: 'Kabir Verma',
      city: 'Delhi NCR',
      division: 'Men\'s Singles',
      ageGroup: 'U-18',
      rating: 4.4,
      points: 1840,
      matchesPlayed: 26,
      wins: 19,
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final padding = isDesktop ? AppSpacing.xl : AppSpacing.md;

    final filtered = _mockRankings.where((entry) {
      if (_selectedDivision != 'All' && entry.division != _selectedDivision) {
        return false;
      }
      if (_selectedAgeGroup != 'All' && entry.ageGroup != _selectedAgeGroup) {
        return false;
      }
      final q = _query.trim().toLowerCase();
      if (q.isNotEmpty) {
        return entry.playerName.toLowerCase().contains(q) ||
            entry.city.toLowerCase().contains(q) ||
            entry.division.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Public Platform Rankings',
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.welcome),
            child: const Text('Home'),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text('Sign In'),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                Text(
                  'Pickleball Leaderboard',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Official verified tournament standings (mock leaderboard dataset).',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search player name, city, or division...',
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
                      const SizedBox(height: AppSpacing.sm),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _divisions
                              .map(
                                (d) => Padding(
                                  padding: const EdgeInsets.only(
                                    right: AppSpacing.xs,
                                  ),
                                  child: FilterChip(
                                    label: Text(d),
                                    selected: _selectedDivision == d,
                                    onSelected: (_) =>
                                        setState(() => _selectedDivision = d),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _ageGroups
                              .map(
                                (a) => Padding(
                                  padding: const EdgeInsets.only(
                                    right: AppSpacing.xs,
                                  ),
                                  child: FilterChip(
                                    label: Text(a == 'All' ? 'All Ages' : a),
                                    selected: _selectedAgeGroup == a,
                                    onSelected: (_) =>
                                        setState(() => _selectedAgeGroup = a),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (filtered.isEmpty)
                  EmptyStateView(
                    title: 'No Matching Players',
                    message:
                        'No ranked players match your current division or search filters.',
                    actionLabel: 'Reset Filters',
                    onAction: () {
                      _searchCtrl.clear();
                      setState(() {
                        _query = '';
                        _selectedDivision = 'All';
                        _selectedAgeGroup = 'All';
                      });
                    },
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      return AppCard(
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: entry.rank <= 3
                                  ? AppColors.primary.withValues(alpha: 0.14)
                                  : theme.colorScheme.surfaceContainerHighest,
                              child: Text(
                                '#${entry.rank}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: entry.rank <= 3
                                      ? AppColors.primary
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.playerName,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    '${entry.city} • ${entry.division} (${entry.ageGroup})',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${entry.points} pts',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Rating ${entry.rating} • ${entry.winPercent}% win',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
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
  }
}
