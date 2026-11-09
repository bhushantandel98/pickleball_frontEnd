import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/tournament_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/tournament_discovery_state.dart';

class TournamentDiscoveryCubit extends Cubit<TournamentDiscoveryState> {
  final TournamentRepository repository;

  TournamentDiscoveryCubit({required this.repository})
      : super(const TournamentDiscoveryInitial());

  /// Loads tournaments from repository.
  Future<void> loadTournaments({
    bool isRefresh = false,
    TournamentFilter? initialFilter,
  }) async {
    if (!isRefresh && state is! TournamentDiscoveryLoaded) {
      emit(const TournamentDiscoveryLoading());
    }

    final activeFilter = initialFilter ??
        (state is TournamentDiscoveryLoaded
            ? (state as TournamentDiscoveryLoaded).filter
            : const TournamentFilter());

    final result = await repository.getTournaments(filter: activeFilter);
    switch (result) {
      case Success<List<TournamentItem>>(:final data):
        // Also fetch all tournaments if needed to allow instantaneous local filtering
        final allResult = await repository.getTournaments();
        final allList = allResult is Success<List<TournamentItem>>
            ? allResult.data
            : data;

        emit(TournamentDiscoveryLoaded(
          allTournaments: allList,
          filteredTournaments: data,
          filter: activeFilter,
        ));
      case FailureResult(:final failure):
        emit(TournamentDiscoveryFailure(failure.message));
    }
  }

  /// Updates text search query locally while preserving page mounting and text field focus.
  void updateSearchQuery(String query) {
    if (state is! TournamentDiscoveryLoaded) return;
    final current = state as TournamentDiscoveryLoaded;

    final updatedFilter = current.filter.copyWith(searchQuery: query);
    final filtered = _applyFilterLocally(current.allTournaments, updatedFilter);

    emit(current.copyWith(
      filter: updatedFilter,
      filteredTournaments: filtered,
    ));
  }

  /// Updates full filter criteria.
  void updateFilter(TournamentFilter newFilter) {
    if (state is! TournamentDiscoveryLoaded) return;
    final current = state as TournamentDiscoveryLoaded;

    final filtered = _applyFilterLocally(current.allTournaments, newFilter);

    emit(current.copyWith(
      filter: newFilter,
      filteredTournaments: filtered,
    ));
  }

  /// Updates sorting option.
  void updateSort(TournamentSortOption sortOption) {
    if (state is! TournamentDiscoveryLoaded) return;
    final current = state as TournamentDiscoveryLoaded;

    final updatedFilter = current.filter.copyWith(sortBy: sortOption);
    final filtered = _applyFilterLocally(current.allTournaments, updatedFilter);

    emit(current.copyWith(
      filter: updatedFilter,
      filteredTournaments: filtered,
    ));
  }

  /// Clears all active filters back to defaults.
  void clearFilters() {
    if (state is! TournamentDiscoveryLoaded) return;
    final current = state as TournamentDiscoveryLoaded;

    const defaultFilter = TournamentFilter();
    final filtered = _applyFilterLocally(current.allTournaments, defaultFilter);

    emit(current.copyWith(
      filter: defaultFilter,
      filteredTournaments: filtered,
    ));
  }

  List<TournamentItem> _applyFilterLocally(
    List<TournamentItem> source,
    TournamentFilter filter,
  ) {
    var list = List<TournamentItem>.from(source);

    // 1. Text search
    final query = filter.searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((t) {
        return t.name.toLowerCase().contains(query) ||
            t.venueName.toLowerCase().contains(query) ||
            t.city.toLowerCase().contains(query) ||
            t.organizerName.toLowerCase().contains(query);
      }).toList();
    }

    // 2. Status filter
    if (filter.status != null) {
      list = list.where((t) => t.status == filter.status).toList();
    }

    // 3. Category filter
    if (filter.category != null && filter.category!.isNotEmpty) {
      final catQuery = filter.category!.toLowerCase();
      list = list.where((t) {
        return t.categories.any((c) => c.name.toLowerCase().contains(catQuery));
      }).toList();
    }

    // 4. Open for registration
    if (filter.onlyOpenForRegistration) {
      list = list.where((t) => t.isRegistrationOpen).toList();
    }

    // 5. My registered tournaments
    if (filter.onlyMyEntries) {
      list = list.where((t) => t.isRegistered).toList();
    }

    // 6. Sorting
    switch (filter.sortBy) {
      case TournamentSortOption.dateSoonest:
        list.sort((a, b) => a.startDate.compareTo(b.startDate));
        break;
      case TournamentSortOption.dateLatest:
        list.sort((a, b) => b.startDate.compareTo(a.startDate));
        break;
      case TournamentSortOption.feeLowest:
        list.sort((a, b) => a.entryFeeFrom.compareTo(b.entryFeeFrom));
        break;
      case TournamentSortOption.feeHighest:
        list.sort((a, b) => b.entryFeeFrom.compareTo(a.entryFeeFrom));
        break;
      case TournamentSortOption.prizeHighest:
        list.sort((a, b) => b.prizePool.compareTo(a.prizePool));
        break;
    }

    return list;
  }
}
