import 'package:equatable/equatable.dart';

/// Supported sorting criteria for venue listings.
enum VenueSortOption {
  distanceAsc('Nearest First'),
  ratingDesc('Highest Rated'),
  priceAsc('Price: Low to High'),
  priceDesc('Price: High to Low'),
  nameAsc('Name (A-Z)');

  final String displayName;
  const VenueSortOption(this.displayName);
}

/// Price tier categorization for filtering.
enum VenuePriceTier {
  any('Any Price'),
  budget('Under ₹600/hr'),
  mid('₹600 - ₹1,000/hr'),
  premium('Above ₹1,000/hr');

  final String displayName;
  const VenuePriceTier(this.displayName);
}

/// Player review entity for a venue.
class VenueReview extends Equatable {
  final String id;
  final String reviewerName;
  final double rating;
  final String date;
  final String comment;
  final String? reviewerAvatar;

  const VenueReview({
    required this.id,
    required this.reviewerName,
    required this.rating,
    required this.date,
    required this.comment,
    this.reviewerAvatar,
  });

  @override
  List<Object?> get props => [id, reviewerName, rating, date, comment, reviewerAvatar];
}

/// Domain entity representing a pickleball venue location.
class VenueItem extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final List<String> galleryImages;
  final String description;
  final String address;
  final String city;
  final double distanceKm;
  final int courtCount;
  final List<String> surfaceTypes;
  final bool isIndoor;
  final bool hasNightLights;
  final List<String> amenities;
  final double rating;
  final int reviewCount;
  final double minHourlyRate;
  final double maxHourlyRate;
  final String operatingHours;
  final String cancellationPolicy;
  final List<String> supportedSports;
  final List<VenueReview> reviews;

  const VenueItem({
    required this.id,
    required this.name,
    this.imageUrl,
    this.galleryImages = const [],
    this.description = '',
    required this.address,
    required this.city,
    required this.distanceKm,
    required this.courtCount,
    required this.surfaceTypes,
    required this.isIndoor,
    required this.hasNightLights,
    required this.amenities,
    required this.rating,
    required this.reviewCount,
    required this.minHourlyRate,
    required this.maxHourlyRate,
    required this.operatingHours,
    this.cancellationPolicy = 'Free cancellation up to 4 hours before slot time.',
    this.supportedSports = const ['Pickleball'],
    this.reviews = const [],
  });

  /// Returns gallery images if available, otherwise falls back to primary image url.
  List<String> get effectiveGalleryImages {
    if (galleryImages.isNotEmpty) return galleryImages;
    if (imageUrl != null && imageUrl!.isNotEmpty) return [imageUrl!];
    return const [];
  }

  /// Formatted operating status description.
  String get operatingStatus => 'Open Now • $operatingHours';

  VenueItem copyWith({
    String? id,
    String? name,
    String? imageUrl,
    List<String>? galleryImages,
    String? description,
    String? address,
    String? city,
    double? distanceKm,
    int? courtCount,
    List<String>? surfaceTypes,
    bool? isIndoor,
    bool? hasNightLights,
    List<String>? amenities,
    double? rating,
    int? reviewCount,
    double? minHourlyRate,
    double? maxHourlyRate,
    String? operatingHours,
    String? cancellationPolicy,
    List<String>? supportedSports,
    List<VenueReview>? reviews,
  }) {
    return VenueItem(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      distanceKm: distanceKm ?? this.distanceKm,
      courtCount: courtCount ?? this.courtCount,
      surfaceTypes: surfaceTypes ?? this.surfaceTypes,
      isIndoor: isIndoor ?? this.isIndoor,
      hasNightLights: hasNightLights ?? this.hasNightLights,
      amenities: amenities ?? this.amenities,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      minHourlyRate: minHourlyRate ?? this.minHourlyRate,
      maxHourlyRate: maxHourlyRate ?? this.maxHourlyRate,
      operatingHours: operatingHours ?? this.operatingHours,
      cancellationPolicy: cancellationPolicy ?? this.cancellationPolicy,
      supportedSports: supportedSports ?? this.supportedSports,
      reviews: reviews ?? this.reviews,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        imageUrl,
        galleryImages,
        description,
        address,
        city,
        distanceKm,
        courtCount,
        surfaceTypes,
        isIndoor,
        hasNightLights,
        amenities,
        rating,
        reviewCount,
        minHourlyRate,
        maxHourlyRate,
        operatingHours,
        cancellationPolicy,
        supportedSports,
        reviews,
      ];
}

/// Filter criteria parameters for searching and narrowing venue listings.
class VenueFilter extends Equatable {
  final String searchQuery;
  final double? maxDistanceKm;
  final double? minRating;
  final VenuePriceTier priceTier;
  final Set<String> requiredAmenities;
  final bool indoorOnly;
  final VenueSortOption sortBy;

  const VenueFilter({
    this.searchQuery = '',
    this.maxDistanceKm,
    this.minRating,
    this.priceTier = VenuePriceTier.any,
    this.requiredAmenities = const {},
    this.indoorOnly = false,
    this.sortBy = VenueSortOption.distanceAsc,
  });

  /// Factory for default unfiltered criteria.
  const VenueFilter.defaultFilter()
      : searchQuery = '',
        maxDistanceKm = null,
        minRating = null,
        priceTier = VenuePriceTier.any,
        requiredAmenities = const {},
        indoorOnly = false,
        sortBy = VenueSortOption.distanceAsc;

  /// Counts how many non-text filters are currently active.
  int get activeFilterCount {
    var count = 0;
    if (maxDistanceKm != null) count++;
    if (minRating != null) count++;
    if (priceTier != VenuePriceTier.any) count++;
    if (requiredAmenities.isNotEmpty) count += requiredAmenities.length;
    if (indoorOnly) count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0 || searchQuery.isNotEmpty;

  VenueFilter copyWith({
    String? searchQuery,
    double? maxDistanceKm,
    bool clearMaxDistance = false,
    double? minRating,
    bool clearMinRating = false,
    VenuePriceTier? priceTier,
    Set<String>? requiredAmenities,
    bool? indoorOnly,
    VenueSortOption? sortBy,
  }) {
    return VenueFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      maxDistanceKm:
          clearMaxDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      priceTier: priceTier ?? this.priceTier,
      requiredAmenities: requiredAmenities ?? this.requiredAmenities,
      indoorOnly: indoorOnly ?? this.indoorOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        maxDistanceKm,
        minRating,
        priceTier,
        requiredAmenities,
        indoorOnly,
        sortBy,
      ];
}
