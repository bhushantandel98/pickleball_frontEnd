import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/features/player/domain/entities/match_day_data.dart';

/// Interactive table displaying tournament pool stage standings, point differentials, and qualification.
class TournamentStandingsTable extends StatefulWidget {
  final List<StandingsRow> standings;

  const TournamentStandingsTable({
    super.key,
    required this.standings,
  });

  @override
  State<TournamentStandingsTable> createState() => _TournamentStandingsTableState();
}

class _TournamentStandingsTableState extends State<TournamentStandingsTable> {
  late String _selectedPool;

  @override
  void initState() {
    super.initState();
    final pools = widget.standings.map((s) => s.pool).toSet().toList();
    _selectedPool = pools.isNotEmpty ? pools.first : 'Pool A';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pools = widget.standings.map((s) => s.pool).toSet().toList();
    final poolRows = widget.standings.where((s) => s.pool == _selectedPool).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pool Selector
        if (pools.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: pools.map((pool) {
                final isSelected = pool == _selectedPool;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
                    label: Text(pool),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedPool = pool);
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

        // Standings Card Table
        AppCard(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 18,
              headingRowHeight: 40,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 48,
              columns: const [
                DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Player', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('P', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('W', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('L', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('Diff', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: poolRows.map((row) {
                return DataRow(
                  cells: [
                    DataCell(Text('${row.rank}')),
                    DataCell(
                      Text(
                        row.playerName,
                        style: TextStyle(
                          fontWeight: row.isQualified ? FontWeight.bold : FontWeight.normal,
                          color: row.isQualified ? theme.colorScheme.primary : null,
                        ),
                      ),
                    ),
                    DataCell(Text('${row.matchesPlayed}')),
                    DataCell(Text('${row.matchesWon}')),
                    DataCell(Text('${row.matchesLost}')),
                    DataCell(
                      Text(
                        row.pointDifferential >= 0 ? '+${row.pointDifferential}' : '${row.pointDifferential}',
                        style: TextStyle(
                          color: row.pointDifferential >= 0
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(
                      row.isQualified
                          ? const AppChip.success(label: 'Qualified')
                          : Text('-', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
