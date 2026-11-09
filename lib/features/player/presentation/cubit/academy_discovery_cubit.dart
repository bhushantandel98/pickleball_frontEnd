import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/repositories/coaching_academy_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_discovery_state.dart';

class AcademyDiscoveryCubit extends Cubit<AcademyDiscoveryState> {
  final CoachingAcademyRepository _repository;

  AcademyDiscoveryCubit(this._repository) : super(const AcademyDiscoveryInitial());

  String _currentQuery = '';
  String _currentCity = 'All Cities';

  Future<void> loadBranches({bool showLoading = true}) async {
    if (showLoading) {
      emit(const AcademyDiscoveryLoading());
    }

    final result = await _repository.getAcademyBranches(
      query: _currentQuery.isNotEmpty ? _currentQuery : null,
      city: _currentCity != 'All Cities' ? _currentCity : null,
    );

    switch (result) {
      case Success(:final data):
        // Collect distinct cities
        final allResult = await _repository.getAcademyBranches();
        final Set<String> citySet = {'All Cities'};
        if (allResult is Success) {
          for (final b in (allResult as Success).data) {
            citySet.add(b.city);
          }
        }

        emit(AcademyDiscoveryLoaded(
          branches: data,
          searchQuery: _currentQuery,
          selectedCity: _currentCity,
          availableCities: citySet.toList(),
        ));
      case FailureResult(:final failure):
        emit(AcademyDiscoveryError(failure.message));
    }
  }

  void updateSearchQuery(String query) {
    _currentQuery = query;
    loadBranches(showLoading: false);
  }

  void filterByCity(String city) {
    _currentCity = city;
    loadBranches(showLoading: false);
  }

  void clearFilters() {
    _currentQuery = '';
    _currentCity = 'All Cities';
    loadBranches();
  }
}
