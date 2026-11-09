import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';

sealed class CoachDiscoveryState extends Equatable {
  const CoachDiscoveryState();

  @override
  List<Object?> get props => [];
}

class CoachDiscoveryInitial extends CoachDiscoveryState {
  const CoachDiscoveryInitial();
}

class CoachDiscoveryLoading extends CoachDiscoveryState {
  const CoachDiscoveryLoading();
}

class CoachDiscoveryLoaded extends CoachDiscoveryState {
  final List<CoachItem> coaches;
  final String searchQuery;
  final String selectedCity;
  final String selectedSpecialization;
  final List<String> availableCities;
  final List<String> availableSpecializations;

  const CoachDiscoveryLoaded({
    required this.coaches,
    this.searchQuery = '',
    this.selectedCity = 'All Cities',
    this.selectedSpecialization = 'All Specializations',
    this.availableCities = const ['All Cities', 'Mumbai'],
    this.availableSpecializations = const [
      'All Specializations',
      'Third-Shot Drop & Reset Mechanics',
      'Foundational Stroke Mechanics',
      'DUPR Skill Assessment & Rating Verification',
      'Women Doubles Strategy & Stacking',
    ],
  });

  bool get isEmpty => coaches.isEmpty;

  CoachDiscoveryLoaded copyWith({
    List<CoachItem>? coaches,
    String? searchQuery,
    String? selectedCity,
    String? selectedSpecialization,
    List<String>? availableCities,
    List<String>? availableSpecializations,
  }) {
    return CoachDiscoveryLoaded(
      coaches: coaches ?? this.coaches,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCity: selectedCity ?? this.selectedCity,
      selectedSpecialization: selectedSpecialization ?? this.selectedSpecialization,
      availableCities: availableCities ?? this.availableCities,
      availableSpecializations: availableSpecializations ?? this.availableSpecializations,
    );
  }

  @override
  List<Object?> get props => [
        coaches,
        searchQuery,
        selectedCity,
        selectedSpecialization,
        availableCities,
        availableSpecializations,
      ];
}

class CoachDiscoveryError extends CoachDiscoveryState {
  final String message;

  const CoachDiscoveryError(this.message);

  @override
  List<Object?> get props => [message];
}
