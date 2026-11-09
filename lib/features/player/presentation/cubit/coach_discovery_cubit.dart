import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/coaching_academy_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/coach_discovery_state.dart';

class CoachDiscoveryCubit extends Cubit<CoachDiscoveryState> {
  final CoachingAcademyRepository _repository;

  CoachDiscoveryCubit(this._repository) : super(const CoachDiscoveryInitial());

  String _currentQuery = '';
  String _currentCity = 'All Cities';
  String _currentSpecialization = 'All Specializations';

  Future<void> loadCoaches({bool showLoading = true}) async {
    if (showLoading) {
      emit(const CoachDiscoveryLoading());
    }

    final result = await _repository.getCoaches(
      query: _currentQuery.isNotEmpty ? _currentQuery : null,
      city: _currentCity != 'All Cities' ? _currentCity : null,
      specialization: _currentSpecialization != 'All Specializations'
          ? _currentSpecialization
          : null,
    );

    switch (result) {
      case Success(:final data):
        // Collect available specializations and cities
        final allResult = await _repository.getCoaches();
        final Set<String> citySet = {'All Cities'};
        final Set<String> specSet = {'All Specializations'};
        if (allResult is Success<List<CoachItem>>) {
          for (final coach in allResult.data) {
            citySet.add(coach.city);
            specSet.addAll(coach.specializations);
          }
        }

        emit(CoachDiscoveryLoaded(
          coaches: data,
          searchQuery: _currentQuery,
          selectedCity: _currentCity,
          selectedSpecialization: _currentSpecialization,
          availableCities: citySet.toList(),
          availableSpecializations: specSet.toList(),
        ));
      case FailureResult(:final failure):
        emit(CoachDiscoveryError(failure.message));
    }
  }

  void updateSearchQuery(String query) {
    _currentQuery = query;
    loadCoaches(showLoading: false);
  }

  void filterByCity(String city) {
    _currentCity = city;
    loadCoaches(showLoading: false);
  }

  void filterBySpecialization(String specialization) {
    _currentSpecialization = specialization;
    loadCoaches(showLoading: false);
  }

  void clearFilters() {
    _currentQuery = '';
    _currentCity = 'All Cities';
    _currentSpecialization = 'All Specializations';
    loadCoaches();
  }
}
