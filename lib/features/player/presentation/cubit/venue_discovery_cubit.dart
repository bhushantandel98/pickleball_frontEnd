import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/venue_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/venue_discovery_state.dart';

/// Cubit managing state for searching, filtering, and sorting venue listings.
class VenueDiscoveryCubit extends Cubit<VenueDiscoveryState> {
  final VenueRepository repository;
  VenueFilter _currentFilter = const VenueFilter.defaultFilter();

  VenueDiscoveryCubit({
    required this.repository,
  }) : super(const VenueDiscoveryInitial());

  VenueFilter get currentFilter => _currentFilter;

  /// Loads venues according to the given or active [filter].
  Future<void> loadVenues({VenueFilter? filter}) async {
    if (filter != null) {
      _currentFilter = filter;
    }

    emit(const VenueDiscoveryLoading());
    final result = await repository.getVenues(filter: _currentFilter);

    switch (result) {
      case Success(:final data):
        emit(
          VenueDiscoveryLoaded(
            venues: data,
            filter: _currentFilter,
            totalCount: data.length,
          ),
        );
      case FailureResult(:final failure):
        emit(VenueDiscoveryFailure(failure));
    }
  }

  /// Updates the text search query and re-queries venues without emitting full-screen loading.
  Future<void> updateSearchQuery(String query) async {
    _currentFilter = _currentFilter.copyWith(searchQuery: query);
    await _executeFilterQuery();
  }

  /// Applies updated filter parameters and re-queries venues.
  Future<void> updateFilter(VenueFilter newFilter) async {
    _currentFilter = newFilter;
    await _executeFilterQuery();
  }

  /// Updates the sorting criteria and re-queries venues.
  Future<void> updateSortOption(VenueSortOption option) async {
    _currentFilter = _currentFilter.copyWith(sortBy: option);
    await _executeFilterQuery();
  }

  /// Clears all applied filters and search terms back to defaults.
  Future<void> clearFilters() async {
    _currentFilter = const VenueFilter.defaultFilter();
    await _executeFilterQuery();
  }

  /// Refreshes venues preserving current filter and sort selections.
  Future<void> refreshVenues() async {
    final result = await repository.getVenues(filter: _currentFilter);
    switch (result) {
      case Success(:final data):
        emit(
          VenueDiscoveryLoaded(
            venues: data,
            filter: _currentFilter,
            totalCount: data.length,
          ),
        );
      case FailureResult(:final failure):
        if (state is! VenueDiscoveryLoaded) {
          emit(VenueDiscoveryFailure(failure));
        }
    }
  }

  Future<void> _executeFilterQuery() async {
    final result = await repository.getVenues(filter: _currentFilter);
    switch (result) {
      case Success(:final data):
        emit(
          VenueDiscoveryLoaded(
            venues: data,
            filter: _currentFilter,
            totalCount: data.length,
          ),
        );
      case FailureResult(:final failure):
        emit(VenueDiscoveryFailure(failure));
    }
  }
}
