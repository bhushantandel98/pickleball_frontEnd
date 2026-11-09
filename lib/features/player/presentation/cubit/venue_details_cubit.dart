import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/repositories/venue_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/venue_details_state.dart';

/// Cubit managing state and interactions for the Venue Details screen.
class VenueDetailsCubit extends Cubit<VenueDetailsState> {
  final VenueRepository repository;

  VenueDetailsCubit({
    required this.repository,
  }) : super(const VenueDetailsInitial());

  /// Loads venue details by [venueId].
  Future<void> loadVenueDetails(String venueId) async {
    emit(const VenueDetailsLoading());
    final result = await repository.getVenueById(venueId);

    switch (result) {
      case Success(:final data):
        emit(VenueDetailsLoaded(venue: data));
      case FailureResult(:final failure):
        emit(VenueDetailsFailure(failure));
    }
  }

  /// Selects active gallery image at [index].
  void selectGalleryImage(int index) {
    if (state is VenueDetailsLoaded) {
      final current = state as VenueDetailsLoaded;
      final images = current.venue.effectiveGalleryImages;
      if (index >= 0 && index < images.length) {
        emit(current.copyWith(selectedImageIndex: index));
      }
    }
  }
}
