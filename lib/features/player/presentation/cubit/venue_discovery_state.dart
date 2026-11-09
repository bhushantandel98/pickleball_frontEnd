import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';

/// Sealed state representation for Venue Discovery & Search.
sealed class VenueDiscoveryState extends Equatable {
  const VenueDiscoveryState();

  @override
  List<Object?> get props => [];
}

/// Initial state before venue discovery begins.
class VenueDiscoveryInitial extends VenueDiscoveryState {
  const VenueDiscoveryInitial();
}

/// Loading state while querying venues.
class VenueDiscoveryLoading extends VenueDiscoveryState {
  const VenueDiscoveryLoading();
}

/// Loaded state delivering filtered/sorted venue listings.
class VenueDiscoveryLoaded extends VenueDiscoveryState {
  final List<VenueItem> venues;
  final VenueFilter filter;
  final int totalCount;

  const VenueDiscoveryLoaded({
    required this.venues,
    required this.filter,
    required this.totalCount,
  });

  bool get isEmpty => venues.isEmpty;

  VenueDiscoveryLoaded copyWith({
    List<VenueItem>? venues,
    VenueFilter? filter,
    int? totalCount,
  }) {
    return VenueDiscoveryLoaded(
      venues: venues ?? this.venues,
      filter: filter ?? this.filter,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  List<Object?> get props => [venues, filter, totalCount];
}

/// Failure state when fetching venues encounters an error.
class VenueDiscoveryFailure extends VenueDiscoveryState {
  final Failure failure;

  const VenueDiscoveryFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
