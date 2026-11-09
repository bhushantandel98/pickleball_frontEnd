import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';

/// State representation for the Venue Details screen.
sealed class VenueDetailsState extends Equatable {
  const VenueDetailsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before venue details loading begins.
class VenueDetailsInitial extends VenueDetailsState {
  const VenueDetailsInitial();
}

/// Loading state while venue details are being retrieved.
class VenueDetailsLoading extends VenueDetailsState {
  const VenueDetailsLoading();
}

/// Loaded state with full venue details and active gallery selection index.
class VenueDetailsLoaded extends VenueDetailsState {
  final VenueItem venue;
  final int selectedImageIndex;

  const VenueDetailsLoaded({
    required this.venue,
    this.selectedImageIndex = 0,
  });

  VenueDetailsLoaded copyWith({
    VenueItem? venue,
    int? selectedImageIndex,
  }) {
    return VenueDetailsLoaded(
      venue: venue ?? this.venue,
      selectedImageIndex: selectedImageIndex ?? this.selectedImageIndex,
    );
  }

  @override
  List<Object?> get props => [venue, selectedImageIndex];
}

/// Failure state when fetching venue details encounters an error or venue is not found.
class VenueDetailsFailure extends VenueDetailsState {
  final Failure failure;

  const VenueDetailsFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
