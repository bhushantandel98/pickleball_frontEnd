import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

/// Centralized sample dataset catalog for mock development across all 12 platform roles.
///
/// Contains purely fictional data adhering to ADR-011 and ADR-015.
/// Provides populated datasets with diverse statuses and empty presets for testing.
abstract final class MockData {
  // ---------------------------------------------------------------------------
  // 1. User Profiles & Multi-Role Assignments
  // ---------------------------------------------------------------------------

  /// Fictional Player profile.
  static final UserProfile playerUser = UserProfile(
    id: 'user_player_001',
    name: 'Alex Rivera',
    email: 'alex.rivera@example.com',
    phone: '+1 555-0101',
    avatarUrl: null,
    availableRoles: const [UserRole.player],
    activeRole: UserRole.player,
    rating: 3.8,
    createdAt: DateTime(2025, 3, 15),
  );

  /// Fictional Coach profile.
  static final UserProfile coachUser = UserProfile(
    id: 'user_coach_001',
    name: 'Coach David Miller',
    email: 'david.miller@example.com',
    phone: '+1 555-0102',
    avatarUrl: null,
    availableRoles: const [UserRole.coach],
    activeRole: UserRole.coach,
    rating: 4.8,
    createdAt: DateTime(2024, 6, 1),
  );

  /// Fictional Academy Administrator profile.
  static final UserProfile academyAdminUser = UserProfile(
    id: 'user_academy_001',
    name: 'Pinnacle Sports Academy',
    email: 'admin@pinnaclesports.com',
    phone: '+1 555-0103',
    availableRoles: const [UserRole.academy],
    activeRole: UserRole.academy,
    organizationId: 'org_acad_001',
    createdAt: DateTime(2024, 1, 10),
  );

  /// Fictional Academy Staff profile.
  static final UserProfile academyStaffUser = UserProfile(
    id: 'user_acad_staff_001',
    name: 'Rachel Zane',
    email: 'rachel.zane@pinnaclesports.com',
    phone: '+1 555-0104',
    availableRoles: const [UserRole.academyStaff],
    activeRole: UserRole.academyStaff,
    organizationId: 'org_acad_001',
    createdAt: DateTime(2024, 8, 20),
  );

  /// Fictional Venue Partner profile.
  static final UserProfile venuePartnerUser = UserProfile(
    id: 'user_venue_partner_001',
    name: 'Grand Slam Pickleball Arena',
    email: 'ops@grandslamarena.com',
    phone: '+1 555-0105',
    availableRoles: const [UserRole.venuePartner],
    activeRole: UserRole.venuePartner,
    organizationId: 'org_venue_001',
    createdAt: DateTime(2024, 2, 1),
  );

  /// Fictional Venue Staff profile.
  static final UserProfile venueStaffUser = UserProfile(
    id: 'user_venue_staff_001',
    name: 'Marcus Bell',
    email: 'marcus.bell@grandslamarena.com',
    phone: '+1 555-0106',
    availableRoles: const [UserRole.venueStaff],
    activeRole: UserRole.venueStaff,
    organizationId: 'org_venue_001',
    createdAt: DateTime(2025, 1, 15),
  );

  /// Fictional Tournament Organizer profile.
  static final UserProfile tournamentOrganizerUser = UserProfile(
    id: 'user_tourn_org_001',
    name: 'Pacific Pickleball Series',
    email: 'organizer@pacificpickleball.org',
    phone: '+1 555-0107',
    availableRoles: const [UserRole.tournamentOrganizer],
    activeRole: UserRole.tournamentOrganizer,
    organizationId: 'org_tourn_001',
    createdAt: DateTime(2024, 4, 12),
  );

  /// Fictional Tournament Staff profile.
  static final UserProfile tournamentStaffUser = UserProfile(
    id: 'user_tourn_staff_001',
    name: 'Sara Connor',
    email: 'sara.connor@pacificpickleball.org',
    phone: '+1 555-0108',
    availableRoles: const [UserRole.tournamentStaff],
    activeRole: UserRole.tournamentStaff,
    organizationId: 'org_tourn_001',
    createdAt: DateTime(2025, 2, 5),
  );

  /// Fictional Referee profile.
  static final UserProfile refereeUser = UserProfile(
    id: 'user_referee_001',
    name: 'Carlos Vega',
    email: 'carlos.vega@referee-assoc.org',
    phone: '+1 555-0109',
    availableRoles: const [UserRole.referee],
    activeRole: UserRole.referee,
    createdAt: DateTime(2024, 9, 1),
  );

  /// Fictional Marketplace Seller profile.
  static final UserProfile marketplaceSellerUser = UserProfile(
    id: 'user_seller_001',
    name: 'Apex Paddle & Gear Co.',
    email: 'sales@apexpaddle.com',
    phone: '+1 555-0110',
    availableRoles: const [UserRole.marketplaceSeller],
    activeRole: UserRole.marketplaceSeller,
    createdAt: DateTime(2024, 5, 20),
  );

  /// Fictional Application Staff profile.
  static final UserProfile applicationStaffUser = UserProfile(
    id: 'user_app_staff_001',
    name: 'Elena Rostova',
    email: 'elena.rostova@platform-staff.com',
    phone: '+1 555-0111',
    availableRoles: const [UserRole.applicationStaff],
    activeRole: UserRole.applicationStaff,
    createdAt: DateTime(2024, 11, 1),
  );

  /// Fictional Application Admin profile.
  static final UserProfile applicationAdminUser = UserProfile(
    id: 'user_app_admin_001',
    name: 'Platform Administrator',
    email: 'root-admin@platform.internal',
    phone: '+1 555-0112',
    availableRoles: const [UserRole.applicationAdmin],
    activeRole: UserRole.applicationAdmin,
    createdAt: DateTime(2024, 1, 1),
  );

  /// Multi-role user: possesses Player, Coach, and Referee credentials.
  static final UserProfile multiRoleUser = UserProfile(
    id: 'user_multi_001',
    name: 'Jordan Cruz',
    email: 'jordan.cruz@example.com',
    phone: '+1 555-0113',
    availableRoles: const [UserRole.player, UserRole.coach, UserRole.referee],
    activeRole: UserRole.player,
    rating: 4.2,
    createdAt: DateTime(2024, 7, 10),
  );

  /// Multi-role user: possesses Player and Tournament Organizer credentials.
  static final UserProfile organizerPlayerUser = UserProfile(
    id: 'user_multi_002',
    name: 'Samira Khan',
    email: 'samira.khan@example.com',
    phone: '+1 555-0114',
    availableRoles: const [UserRole.player, UserRole.tournamentOrganizer],
    activeRole: UserRole.player,
    rating: 3.5,
    organizationId: 'org_tourn_001',
    createdAt: DateTime(2024, 10, 5),
  );

  /// Suspended user account for route guard and security gate testing.
  static final UserProfile suspendedUser = UserProfile(
    id: 'user_suspended_001',
    name: 'Taylor Hayes',
    email: 'taylor.hayes@example.com',
    phone: '+1 555-0115',
    availableRoles: const [UserRole.player],
    activeRole: UserRole.player,
    isSuspended: true,
    createdAt: DateTime(2024, 12, 1),
  );

  /// Complete list of sample users.
  static final List<UserProfile> allUsers = [
    playerUser,
    coachUser,
    academyAdminUser,
    academyStaffUser,
    venuePartnerUser,
    venueStaffUser,
    tournamentOrganizerUser,
    tournamentStaffUser,
    refereeUser,
    marketplaceSellerUser,
    applicationStaffUser,
    applicationAdminUser,
    multiRoleUser,
    organizerPlayerUser,
    suspendedUser,
  ];

  // ---------------------------------------------------------------------------
  // 2. Organization Memberships
  // ---------------------------------------------------------------------------

  static const List<Map<String, dynamic>> organizations = [
    {
      'id': 'org_acad_001',
      'type': 'academy',
      'name': 'Pinnacle Sports Academy',
      'branches': [
        {'id': 'branch_01', 'name': 'Downtown Campus', 'courtCount': 4},
        {'id': 'branch_02', 'name': 'Westside Facility', 'courtCount': 6},
      ],
      'activeStudents': 148,
      'coachCount': 8,
    },
    {
      'id': 'org_venue_001',
      'type': 'venue',
      'name': 'Grand Slam Pickleball Arena',
      'address': '742 Evergreen Terrace, Springfield',
      'courtCount': 8,
      'operatingHours': '06:00 - 23:00',
      'amenities': ['Pro Shop', 'Locker Rooms', 'Night Lights', 'Equipment Rental'],
    },
    {
      'id': 'org_tourn_001',
      'type': 'tournament_organizer',
      'name': 'Pacific Pickleball Series',
      'sanctionedBy': 'National Pickleball Association',
      'activeTournaments': 3,
    },
  ];

  // ---------------------------------------------------------------------------
  // 3. Notifications Catalog (Read & Unread variations)
  // ---------------------------------------------------------------------------

  static final List<Map<String, dynamic>> notifications = [
    {
      'id': 'notif_001',
      'title': 'Booking Confirmed',
      'message': 'Your court reservation for Court 1 at Grand Slam Arena is confirmed.',
      'category': 'booking',
      'isRead': false,
      'timestamp': DateTime(2026, 11, 2, 14, 30),
      'targetRoute': '/player/bookings',
    },
    {
      'id': 'notif_002',
      'title': 'Match Day Schedule Update',
      'message': 'Court 3 match time moved forward to 15:45. Please report for check-in.',
      'category': 'tournament',
      'isRead': false,
      'timestamp': DateTime(2026, 11, 2, 12, 15),
      'targetRoute': '/player/match-day',
    },
    {
      'id': 'notif_003',
      'title': 'Offline Payment Verified',
      'message': 'Venue staff verified your cash payment of \$35.00 for Booking #BK-9481.',
      'category': 'payment',
      'isRead': true,
      'timestamp': DateTime(2026, 11, 1, 18, 0),
      'targetRoute': '/player/bookings',
    },
    {
      'id': 'notif_004',
      'title': 'Tournament Draw Published',
      'message': 'Men\'s Singles Open bracket is now live for National Pickleball Open 2026.',
      'category': 'tournament',
      'isRead': true,
      'timestamp': DateTime(2026, 10, 31, 10, 0),
      'targetRoute': '/public/tournaments/tourn_001',
    },
    {
      'id': 'notif_005',
      'title': 'Seller KYC Approved',
      'message': 'Your merchant onboarding KYC documents have been reviewed and approved.',
      'category': 'seller',
      'isRead': true,
      'timestamp': DateTime(2026, 10, 30, 9, 30),
      'targetRoute': '/marketplace-seller',
    },
  ];

  // ---------------------------------------------------------------------------
  // 4. Tournament Information & Live Bracket Status
  // ---------------------------------------------------------------------------

  static const List<Map<String, dynamic>> tournaments = [
    {
      'id': 'tourn_001',
      'name': 'National Pickleball Open 2026',
      'status': 'inProgress',
      'venue': 'Grand Slam Pickleball Arena',
      'startDate': '2026-11-01',
      'endDate': '2026-11-05',
      'prizePool': '\$25,000',
      'categories': ['Men\'s Singles Open', 'Women\'s Singles Open', 'Mixed Doubles 3.5'],
      'bracketSlots': 32,
      'activeMatches': [
        {
          'fixtureId': 'fix_101',
          'court': 'Court 1 (Championship Court)',
          'playerA': 'Alex Rivera',
          'playerB': 'Jordan Cruz',
          'score': '11-9, 8-11, 6-4 (Set 3 Live)',
          'referee': 'Carlos Vega',
          'status': 'live',
        },
        {
          'fixtureId': 'fix_102',
          'court': 'Court 2',
          'playerA': 'Marcus Bell',
          'playerB': 'David Miller',
          'score': '11-7, 11-5',
          'referee': 'Sara Connor',
          'status': 'completed',
        },
      ],
    },
    {
      'id': 'tourn_002',
      'name': 'Monsoon Community Cup 2026',
      'status': 'registrationOpen',
      'venue': 'Pinnacle Sports Academy (Downtown)',
      'startDate': '2026-11-20',
      'endDate': '2026-11-22',
      'prizePool': '\$5,000',
      'categories': ['Junior Under-16', 'Senior Doubles 50+'],
      'bracketSlots': 16,
      'activeMatches': [],
    },
    {
      'id': 'tourn_003',
      'name': 'Pacific Coast Masters',
      'status': 'completed',
      'venue': 'Grand Slam Arena',
      'startDate': '2026-10-10',
      'endDate': '2026-10-12',
      'prizePool': '\$10,000',
      'champion': 'Jordan Cruz',
      'bracketSlots': 16,
      'activeMatches': [],
    },
  ];

  // ---------------------------------------------------------------------------
  // 5. Venue Facilities, Courts & Slot Availability Matrix
  // ---------------------------------------------------------------------------

  static const Map<String, dynamic> venueDetails = {
    'id': 'org_venue_001',
    'name': 'Grand Slam Pickleball Arena',
    'address': '742 Evergreen Terrace, Springfield',
    'courts': [
      {'id': 'court_1', 'name': 'Court 1 (Championship Cushioned)', 'surface': 'Pro Cushion', 'hourlyRate': 40.0},
      {'id': 'court_2', 'name': 'Court 2 (Outdoor Hardcourt)', 'surface': 'Acrylic Hardcourt', 'hourlyRate': 30.0},
      {'id': 'court_3', 'name': 'Court 3 (Indoor Hardcourt)', 'surface': 'Acrylic Hardcourt', 'hourlyRate': 35.0},
      {'id': 'court_4', 'name': 'Court 4 (Indoor Hardcourt)', 'surface': 'Acrylic Hardcourt', 'hourlyRate': 35.0},
      {'id': 'court_5', 'name': 'Court 5 (Training Court)', 'surface': 'Polyurethane', 'hourlyRate': 25.0},
      {'id': 'court_6', 'name': 'Court 6 (Training Court)', 'surface': 'Polyurethane', 'hourlyRate': 25.0},
    ],
    'slots': [
      {'time': '06:00 - 07:00', 'courtId': 'court_1', 'status': 'available', 'price': 30.0},
      {'time': '07:00 - 08:00', 'courtId': 'court_1', 'status': 'booked', 'price': 40.0},
      {'time': '08:00 - 09:00', 'courtId': 'court_1', 'status': 'available', 'price': 40.0},
      {'time': '17:00 - 18:00', 'courtId': 'court_2', 'status': 'reserved', 'price': 35.0},
      {'time': '18:00 - 19:00', 'courtId': 'court_2', 'status': 'available', 'price': 35.0},
      {'time': '19:00 - 20:00', 'courtId': 'court_3', 'status': 'offline_pending', 'price': 35.0},
    ],
  };

  // ---------------------------------------------------------------------------
  // 6. Booking Records (Upcoming, Completed, Cancelled, Offline Payment Pending)
  // ---------------------------------------------------------------------------

  static const List<Map<String, dynamic>> bookings = [
    {
      'id': 'BK-1001',
      'courtName': 'Court 1 (Championship Cushioned)',
      'venueName': 'Grand Slam Pickleball Arena',
      'date': 'Tomorrow, Nov 3',
      'timeSlot': '07:00 - 08:00',
      'status': 'confirmed',
      'paymentStatus': 'paid',
      'amount': 40.0,
      'isCancellable': true,
    },
    {
      'id': 'BK-0994',
      'courtName': 'Court 3 (Indoor Hardcourt)',
      'venueName': 'Grand Slam Pickleball Arena',
      'date': 'Yesterday, Nov 1',
      'timeSlot': '18:00 - 19:00',
      'status': 'completed',
      'paymentStatus': 'paid',
      'amount': 35.0,
      'isCancellable': false,
    },
    {
      'id': 'BK-0980',
      'courtName': 'Court 2 (Outdoor Hardcourt)',
      'venueName': 'Grand Slam Pickleball Arena',
      'date': 'Oct 28, 2026',
      'timeSlot': '10:00 - 11:00',
      'status': 'cancelled',
      'paymentStatus': 'refunded',
      'amount': 30.0,
      'isCancellable': false,
    },
    {
      'id': 'BK-1005',
      'courtName': 'Court 5 (Training Court)',
      'venueName': 'Grand Slam Pickleball Arena',
      'date': 'Today, Nov 2',
      'timeSlot': '19:00 - 20:00',
      'status': 'pending_payment',
      'paymentStatus': 'offline_cash_pending',
      'amount': 25.0,
      'isCancellable': true,
    },
  ];

  // ---------------------------------------------------------------------------
  // 7. Marketplace Products Catalog & Sample Orders
  // ---------------------------------------------------------------------------

  static const List<Map<String, dynamic>> products = [
    {
      'id': 'prod_001',
      'title': 'Pro Carbon 3K Precision Paddle',
      'seller': 'Apex Paddle & Gear Co.',
      'price': 149.99,
      'rating': 4.8,
      'reviewsCount': 124,
      'category': 'Paddles',
      'inStock': true,
      'stockCount': 42,
    },
    {
      'id': 'prod_002',
      'title': 'Official Tournament Outdoor Balls (Pack of 6)',
      'seller': 'Apex Paddle & Gear Co.',
      'price': 19.99,
      'rating': 4.9,
      'reviewsCount': 342,
      'category': 'Balls',
      'inStock': true,
      'stockCount': 150,
    },
    {
      'id': 'prod_003',
      'title': 'Regulation Portable Heavy-Duty Net System',
      'seller': 'Apex Paddle & Gear Co.',
      'price': 189.00,
      'rating': 4.7,
      'reviewsCount': 56,
      'category': 'Equipment',
      'inStock': true,
      'stockCount': 18,
    },
    {
      'id': 'prod_004',
      'title': 'Court Master Performance Grip Shoes',
      'seller': 'Apex Paddle & Gear Co.',
      'price': 119.50,
      'rating': 4.5,
      'reviewsCount': 88,
      'category': 'Footwear',
      'inStock': true,
      'stockCount': 25,
    },
    {
      'id': 'prod_005',
      'title': 'Heavy-Duty Paddle Edge Guard Tape (3-Pack)',
      'seller': 'Apex Paddle & Gear Co.',
      'price': 9.99,
      'rating': 4.6,
      'reviewsCount': 210,
      'category': 'Accessories',
      'inStock': true,
      'stockCount': 80,
    },
  ];

  static const List<Map<String, dynamic>> orders = [
    {
      'orderId': 'ORD-10921',
      'date': '2026-10-25',
      'items': ['Pro Carbon 3K Precision Paddle', 'Heavy-Duty Paddle Edge Guard Tape'],
      'total': 159.98,
      'status': 'delivered',
      'trackingNumber': 'TRACK-9812-US',
    },
    {
      'orderId': 'ORD-10955',
      'date': '2026-10-30',
      'items': ['Regulation Portable Heavy-Duty Net System'],
      'total': 189.00,
      'status': 'in_transit',
      'trackingNumber': 'TRACK-9854-US',
    },
    {
      'orderId': 'ORD-10988',
      'date': '2026-11-02',
      'items': ['Official Tournament Outdoor Balls (Pack of 6)'],
      'total': 19.99,
      'status': 'processing',
      'trackingNumber': null,
    },
  ];

  // ---------------------------------------------------------------------------
  // 8. Empty Dataset Presets
  // ---------------------------------------------------------------------------

  /// Empty notifications list for testing empty UI state.
  static const List<Map<String, dynamic>> emptyNotifications = [];

  /// Empty tournaments list for testing empty UI state.
  static const List<Map<String, dynamic>> emptyTournaments = [];

  /// Empty bookings list for testing empty UI state.
  static const List<Map<String, dynamic>> emptyBookings = [];

  /// Empty marketplace catalog for testing empty UI state.
  static const List<Map<String, dynamic>> emptyProducts = [];

  /// Empty orders list for testing empty UI state.
  static const List<Map<String, dynamic>> emptyOrders = [];
}
