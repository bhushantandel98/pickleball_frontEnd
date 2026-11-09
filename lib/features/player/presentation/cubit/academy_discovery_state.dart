import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';

sealed class AcademyDiscoveryState extends Equatable {
  const AcademyDiscoveryState();

  @override
  List<Object?> get props => [];
}

class AcademyDiscoveryInitial extends AcademyDiscoveryState {
  const AcademyDiscoveryInitial();
}

class AcademyDiscoveryLoading extends AcademyDiscoveryState {
  const AcademyDiscoveryLoading();
}

class AcademyDiscoveryLoaded extends AcademyDiscoveryState {
  final List<AcademyBranch> branches;
  final String searchQuery;
  final String selectedCity;
  final List<String> availableCities;

  const AcademyDiscoveryLoaded({
    required this.branches,
    this.searchQuery = '',
    this.selectedCity = 'All Cities',
    this.availableCities = const ['All Cities', 'Mumbai'],
  });

  bool get isEmpty => branches.isEmpty;

  AcademyDiscoveryLoaded copyWith({
    List<AcademyBranch>? branches,
    String? searchQuery,
    String? selectedCity,
    List<String>? availableCities,
  }) {
    return AcademyDiscoveryLoaded(
      branches: branches ?? this.branches,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCity: selectedCity ?? this.selectedCity,
      availableCities: availableCities ?? this.availableCities,
    );
  }

  @override
  List<Object?> get props => [branches, searchQuery, selectedCity, availableCities];
}

class AcademyDiscoveryError extends AcademyDiscoveryState {
  final String message;

  const AcademyDiscoveryError(this.message);

  @override
  List<Object?> get props => [message];
}
