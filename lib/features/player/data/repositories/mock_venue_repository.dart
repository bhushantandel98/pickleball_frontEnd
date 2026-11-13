import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_item.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/venue_repository.dart';

/// In-memory mock implementation of [VenueRepository] adhering to ADR-011 and ADR-015.
class MockVenueRepository implements VenueRepository {
  final List<VenueItem>? customVenues;
  final bool shouldFail;

  const MockVenueRepository({
    this.customVenues,
    this.shouldFail = false,
  });

  static List<VenueItem> get defaultVenues => _defaultVenues;

  static final List<VenueItem> _defaultVenues = [
    const VenueItem(
      id: 'org_venue_001',
      name: 'Grand Slam Pickleball Arena',
      imageUrl: 'assets/images/venues/venue_grand_slam.png',
      galleryImages: [
        'assets/images/venues/venue_grand_slam.png',
        'assets/images/venues/venue_pinnacle.png',
        'assets/images/venues/venue_dink_smash.png',
      ],
      description:
          'Premier indoor pickleball facility in Andheri West featuring 8 tournament-grade courts with professional cushioning, optimal LED lighting, pro equipment rental, and an on-site cafe for community post-match social sessions.',
      address: '742 Evergreen Terrace, Andheri West',
      city: 'Mumbai',
      distanceKm: 1.8,
      courtCount: 8,
      surfaceTypes: ['Pro Cushion', 'Acrylic Hardcourt'],
      isIndoor: true,
      hasNightLights: true,
      amenities: [
        'Night Lights',
        'Equipment Rental',
        'Pro Shop',
        'Locker Rooms',
        'Parking',
        'Cafeteria',
        'Showers',
        'Drinking Water',
        'Seating',
      ],
      rating: 4.85,
      reviewCount: 214,
      minHourlyRate: 500.0,
      maxHourlyRate: 900.0,
      operatingHours: '06:00 - 23:00',
      cancellationPolicy: 'Free cancellation up to 4 hours before slot time. 50% refund within 2 to 4 hours.',
      supportedSports: ['Pickleball', 'Tennis'],
      reviews: [
        VenueReview(
          id: 'rev_001_1',
          reviewerName: 'Vikram Mehta',
          rating: 5.0,
          date: '02 Nov 2026',
          comment: 'Outstanding court surface and lighting. The bounce is true and the staff is very welcoming! Will definitely book again.',
        ),
        VenueReview(
          id: 'rev_001_2',
          reviewerName: 'Ananya Sharma',
          rating: 4.8,
          date: '28 Oct 2026',
          comment: 'Great indoor facility! Clean locker rooms, pro equipment rentals, and lovely cafe for recovery smoothies.',
        ),
        VenueReview(
          id: 'rev_001_3',
          reviewerName: 'Rohan Deshmukh',
          rating: 4.6,
          date: '15 Oct 2026',
          comment: 'Good value for money during morning hours. Clean courts and plenty of parking available.',
        ),
      ],
    ),
    const VenueItem(
      id: 'org_venue_002',
      name: 'Pinnacle Sports Complex & Courts',
      imageUrl: 'assets/images/venues/venue_pinnacle.png',
      galleryImages: [
        'assets/images/venues/venue_pinnacle.png',
        'assets/images/venues/venue_metro.png',
        'assets/images/venues/venue_sunrise.png',
      ],
      description:
          'Spacious sports complex located at Lower Parel offering 6 floodlit acrylic hardcourts, dedicated coaching programs, locker facilities, and convenient urban transit access.',
      address: 'Plot 12, Senapati Bapat Marg, Lower Parel',
      city: 'Mumbai',
      distanceKm: 4.2,
      courtCount: 6,
      surfaceTypes: ['Acrylic Hardcourt'],
      isIndoor: false,
      hasNightLights: true,
      amenities: [
        'Night Lights',
        'Equipment Rental',
        'Locker Rooms',
        'Parking',
        'Coaching Available',
        'Drinking Water',
        'Washrooms',
      ],
      rating: 4.70,
      reviewCount: 168,
      minHourlyRate: 450.0,
      maxHourlyRate: 750.0,
      operatingHours: '06:00 - 22:30',
      cancellationPolicy: 'Free cancellation up to 6 hours before slot time.',
      supportedSports: ['Pickleball'],
      reviews: [
        VenueReview(
          id: 'rev_002_1',
          reviewerName: 'Kunal Kapoor',
          rating: 4.7,
          date: '30 Oct 2026',
          comment: 'Top-notch floodlights for night games. Courts are well maintained.',
        ),
        VenueReview(
          id: 'rev_002_2',
          reviewerName: 'Priya Nambiar',
          rating: 4.6,
          date: '20 Oct 2026',
          comment: 'Coaching staff is knowledgeable and patient. Loved the evening vibe.',
        ),
      ],
    ),
    const VenueItem(
      id: 'org_venue_003',
      name: 'Dink & Smash Elite Club',
      imageUrl: 'assets/images/venues/venue_dink_smash.png',
      galleryImages: [
        'assets/images/venues/venue_dink_smash.png',
        'assets/images/venues/venue_pacific.png',
        'assets/images/venues/venue_ace_point.png',
      ],
      description:
          'Thane\'s flagship luxury racquet club boasting 10 climate-controlled indoor courts with polyurethane surfaces, modern showers, pro shop, and weekend tournaments.',
      address: 'Sector 15, Hiranandani Estate, Thane',
      city: 'Thane',
      distanceKm: 8.5,
      courtCount: 10,
      surfaceTypes: ['Pro Cushion', 'Polyurethane'],
      isIndoor: true,
      hasNightLights: true,
      amenities: [
        'Night Lights',
        'Equipment Rental',
        'Pro Shop',
        'Locker Rooms',
        'Showers',
        'Parking',
        'Cafeteria',
        'Drinking Water',
        'Seating',
      ],
      rating: 4.92,
      reviewCount: 340,
      minHourlyRate: 800.0,
      maxHourlyRate: 1400.0,
      operatingHours: '05:30 - 23:30',
      cancellationPolicy: 'Free cancellation up to 12 hours before slot time. Rescheduling permitted once.',
      supportedSports: ['Pickleball', 'Badminton'],
      reviews: [
        VenueReview(
          id: 'rev_003_1',
          reviewerName: 'Sameer Joshi',
          rating: 5.0,
          date: '03 Nov 2026',
          comment: 'World class facility! The acoustic panels make a huge difference in indoor comfort.',
        ),
      ],
    ),
    const VenueItem(
      id: 'org_venue_004',
      name: 'Metro Courts Pickleball Hub',
      imageUrl: 'assets/images/venues/venue_metro.png',
      galleryImages: [
        'assets/images/venues/venue_metro.png',
        'assets/images/venues/venue_sunrise.png',
      ],
      description:
          'Centrally located outdoor pickleball hub right next to Ghatkopar Metro Station, offering accessible open-air courts with equipment rentals.',
      address: 'Near Metro Station, Ghatkopar East',
      city: 'Mumbai',
      distanceKm: 3.1,
      courtCount: 4,
      surfaceTypes: ['Acrylic Hardcourt'],
      isIndoor: false,
      hasNightLights: false,
      amenities: [
        'Equipment Rental',
        'Parking',
        'Drinking Water',
      ],
      rating: 4.25,
      reviewCount: 82,
      minHourlyRate: 400.0,
      maxHourlyRate: 550.0,
      operatingHours: '06:00 - 19:00',
      cancellationPolicy: 'Free cancellation up to 2 hours before slot time.',
      supportedSports: ['Pickleball'],
      reviews: [
        VenueReview(
          id: 'rev_004_1',
          reviewerName: 'Divya Iyer',
          rating: 4.3,
          date: '25 Oct 2026',
          comment: 'Very convenient location right by the metro. Good pricing for quick casual matches.',
        ),
      ],
    ),
    const VenueItem(
      id: 'org_venue_005',
      name: 'Pacific Rackets & Paddle Arena',
      imageUrl: 'assets/images/venues/venue_pacific.png',
      galleryImages: [
        'assets/images/venues/venue_pacific.png',
        'assets/images/venues/venue_grand_slam.png',
      ],
      description:
          'Expansive indoor arena in Malad West with 8 cushioned courts, complete pro shop accessories, and ample parking space for evening group play.',
      address: 'Link Road, Malad West',
      city: 'Mumbai',
      distanceKm: 6.9,
      courtCount: 8,
      surfaceTypes: ['Pro Cushion'],
      isIndoor: true,
      hasNightLights: true,
      amenities: [
        'Night Lights',
        'Equipment Rental',
        'Pro Shop',
        'Locker Rooms',
        'Parking',
        'Drinking Water',
      ],
      rating: 4.65,
      reviewCount: 129,
      minHourlyRate: 650.0,
      maxHourlyRate: 1100.0,
      operatingHours: '06:00 - 23:00',
      cancellationPolicy: 'Free cancellation up to 4 hours before slot time.',
      supportedSports: ['Pickleball'],
      reviews: [
        VenueReview(
          id: 'rev_005_1',
          reviewerName: 'Aditya Rao',
          rating: 4.7,
          date: '01 Nov 2026',
          comment: 'High ceilings and plenty of run-off space around the sidelines. Highly recommended.',
        ),
      ],
    ),
    const VenueItem(
      id: 'org_venue_006',
      name: 'Sunrise Community Recreation Grounds',
      imageUrl: 'assets/images/venues/venue_sunrise.png',
      galleryImages: [
        'assets/images/venues/venue_sunrise.png',
        'assets/images/venues/venue_pinnacle.png',
      ],
      description:
          'Peaceful outdoor community recreational facility on Palm Beach Road featuring scenic park surroundings, dedicated coaching, and budget-friendly pricing.',
      address: 'Palm Beach Road, Vashi',
      city: 'Navi Mumbai',
      distanceKm: 14.5,
      courtCount: 6,
      surfaceTypes: ['Acrylic Hardcourt'],
      isIndoor: false,
      hasNightLights: true,
      amenities: [
        'Night Lights',
        'Parking',
        'Coaching Available',
        'Drinking Water',
        'Seating',
      ],
      rating: 4.10,
      reviewCount: 95,
      minHourlyRate: 350.0,
      maxHourlyRate: 500.0,
      operatingHours: '06:00 - 21:00',
      cancellationPolicy: 'Free cancellation up to 3 hours before slot time.',
      supportedSports: ['Pickleball'],
      reviews: [
        VenueReview(
          id: 'rev_006_1',
          reviewerName: 'Tanvi Shinde',
          rating: 4.2,
          date: '19 Oct 2026',
          comment: 'Affordable and pleasant morning environment. Great for weekend matches with friends.',
        ),
      ],
    ),
    const VenueItem(
      id: 'org_venue_007',
      name: 'Ace Point Indoor Pickleball Hub',
      imageUrl: 'assets/images/venues/venue_ace_point.png',
      galleryImages: [
        'assets/images/venues/venue_ace_point.png',
        'assets/images/venues/venue_dink_smash.png',
        'assets/images/venues/venue_grand_slam.png',
      ],
      description:
          '24-hour elite flagship indoor arena at BKC, offering 12 tournament-spec courts, top-tier amenities, recovery zones, and full hospitality.',
      address: 'Bandra-Kurla Complex (BKC)',
      city: 'Mumbai',
      distanceKm: 5.0,
      courtCount: 12,
      surfaceTypes: ['Pro Cushion', 'Polyurethane'],
      isIndoor: true,
      hasNightLights: true,
      amenities: [
        'Night Lights',
        'Equipment Rental',
        'Pro Shop',
        'Locker Rooms',
        'Showers',
        'Parking',
        'Cafeteria',
        'Coaching Available',
        'Drinking Water',
        'Seating',
      ],
      rating: 4.95,
      reviewCount: 420,
      minHourlyRate: 1000.0,
      maxHourlyRate: 1600.0,
      operatingHours: '24 Hours',
      cancellationPolicy: 'Free cancellation up to 6 hours before slot time.',
      supportedSports: ['Pickleball', 'Tennis'],
      reviews: [
        VenueReview(
          id: 'rev_007_1',
          reviewerName: 'Harsh Vardhan',
          rating: 5.0,
          date: '04 Nov 2026',
          comment: 'Best courts in Mumbai hands down. The 24-hour availability is unbeatable for late night practice.',
        ),
        VenueReview(
          id: 'rev_007_2',
          reviewerName: 'Meera Sen',
          rating: 4.9,
          date: '29 Oct 2026',
          comment: 'Stunning facility with pristine courts and top-notch locker rooms.',
        ),
      ],
    ),
  ];

  @override
  Future<Result<List<VenueItem>>> getVenues({VenueFilter? filter}) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Unable to load venues'));
    }

    final source = customVenues ?? _defaultVenues;
    final criteria = filter ?? const VenueFilter.defaultFilter();

    final filtered = source.where((venue) {
      // 1. Search Query (name, address, city, amenities)
      final trimmedQuery = criteria.searchQuery.trim().toLowerCase();
      if (trimmedQuery.isNotEmpty) {
        final matchName = venue.name.toLowerCase().contains(trimmedQuery);
        final matchAddress = venue.address.toLowerCase().contains(trimmedQuery);
        final matchCity = venue.city.toLowerCase().contains(trimmedQuery);
        final matchAmenity = venue.amenities.any((a) => a.toLowerCase().contains(trimmedQuery));
        if (!matchName && !matchAddress && !matchCity && !matchAmenity) {
          return false;
        }
      }

      // 2. Distance filter
      if (criteria.maxDistanceKm != null &&
          venue.distanceKm > criteria.maxDistanceKm!) {
        return false;
      }

      // 3. Rating filter
      if (criteria.minRating != null && venue.rating < criteria.minRating!) {
        return false;
      }

      // 4. Price tier filter
      switch (criteria.priceTier) {
        case VenuePriceTier.any:
          break;
        case VenuePriceTier.budget:
          if (venue.minHourlyRate > 600) return false;
        case VenuePriceTier.mid:
          if (venue.minHourlyRate > 1000 || venue.maxHourlyRate < 600) {
            return false;
          }
        case VenuePriceTier.premium:
          if (venue.maxHourlyRate < 1000) return false;
      }

      // 5. Indoor only filter
      if (criteria.indoorOnly && !venue.isIndoor) {
        return false;
      }

      // 6. Required amenities
      for (final required in criteria.requiredAmenities) {
        if (!venue.amenities.contains(required)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sorting
    switch (criteria.sortBy) {
      case VenueSortOption.distanceAsc:
        filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      case VenueSortOption.ratingDesc:
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
      case VenueSortOption.priceAsc:
        filtered.sort((a, b) => a.minHourlyRate.compareTo(b.minHourlyRate));
      case VenueSortOption.priceDesc:
        filtered.sort((a, b) => b.maxHourlyRate.compareTo(a.maxHourlyRate));
      case VenueSortOption.nameAsc:
        filtered.sort((a, b) => a.name.compareTo(b.name));
    }

    return Success(filtered);
  }

  @override
  Future<Result<VenueItem>> getVenueById(String id) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Venue not found'));
    }

    final source = customVenues ?? _defaultVenues;
    final match = source.where((v) => v.id == id);
    if (match.isEmpty) {
      return const FailureResult(NotFoundFailure(message: 'Venue not found'));
    }
    return Success(match.first);
  }

  @override
  Future<Result<List<CourtItem>>> getCourts(String venueId, {DateTime? date}) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Unable to load courts'));
    }

    final venueResult = await getVenueById(venueId);
    if (venueResult case FailureResult(:final failure)) {
      return FailureResult(failure);
    }
    final venue = (venueResult as Success<VenueItem>).data;

    final targetDate = date ?? DateTime.now();
    final daySeed = targetDate.day;

    final courts = List.generate(venue.courtCount, (index) {
      final courtNum = index + 1;
      final surface = venue.surfaceTypes[index % venue.surfaceTypes.length];
      // Deterministic available slot count based on court and date
      final availableCount = 7 + ((daySeed + courtNum * 3) % 6);

      return CourtItem(
        id: '${venue.id}_court_$courtNum',
        venueId: venue.id,
        name: courtNum == 1 ? 'Court 1 (Center Court)' : 'Court $courtNum',
        courtNumber: courtNum,
        surfaceType: surface,
        isIndoor: venue.isIndoor,
        hasLighting: venue.hasNightLights,
        isActive: true,
        availableSlotCount: availableCount,
      );
    });

    return Success(courts);
  }

  @override
  Future<Result<List<CourtSlot>>> getCourtSlots({
    required String venueId,
    required String courtId,
    required DateTime date,
  }) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Unable to load slots'));
    }

    final venueResult = await getVenueById(venueId);
    if (venueResult case FailureResult(:final failure)) {
      return FailureResult(failure);
    }
    final venue = (venueResult as Success<VenueItem>).data;

    // Extract court index from ID
    final courtIndex = int.tryParse(courtId.split('_').last) ?? 1;
    final daySeed = date.day;

    // Generate slots from 06:00 to 22:00
    final List<CourtSlot> slots = [];
    const startHour = 6;
    const endHour = 22;

    for (int hour = startHour; hour < endHour; hour++) {
      final startFormatted = '${hour.toString().padLeft(2, '0')}:00';
      final endFormatted = '${(hour + 1).toString().padLeft(2, '0')}:00';
      final isPeak = hour >= 18 && hour <= 21;
      final price = isPeak ? venue.maxHourlyRate : venue.minHourlyRate;

      // Deterministic status based on date, court and hour
      final hash = (daySeed * 7 + courtIndex * 13 + hour * 3);
      SlotStatus status;
      if (hash % 5 == 0) {
        status = SlotStatus.booked;
      } else if (hash % 11 == 0) {
        status = SlotStatus.unavailable;
      } else {
        status = SlotStatus.available;
      }

      slots.add(
        CourtSlot(
          id: '${courtId}_slot_$startFormatted',
          courtId: courtId,
          venueId: venue.id,
          startTime: startFormatted,
          endTime: endFormatted,
          price: price,
          status: status,
        ),
      );
    }

    return Success(slots);
  }
}
