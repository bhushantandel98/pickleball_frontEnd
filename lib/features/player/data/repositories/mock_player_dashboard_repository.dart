import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/features/player/domain/entities/player_dashboard_data.dart';
import 'package:pickleball_platform/features/player/domain/repositories/player_dashboard_repository.dart';

/// In-memory mock implementation of [PlayerDashboardRepository] adhering to ADR-011 and ADR-015.
class MockPlayerDashboardRepository implements PlayerDashboardRepository {
  final bool isUpcomingEmpty;
  final bool isRecentEmpty;
  final PlayerDashboardData? customData;

  const MockPlayerDashboardRepository({
    this.isUpcomingEmpty = false,
    this.isRecentEmpty = false,
    this.customData,
  });

  @override
  Future<Result<PlayerDashboardData>> getDashboardData({String? userId}) async {
    if (customData != null) {
      return Success(customData!);
    }

    final profile = PlayerProfileSummary(
      userId: userId ?? 'user_player_001',
      fullName: 'Alex Rivera',
      avatarUrl: 'avatar:champion',
      skillRating: 3.85,
      ratingTier: 'Intermediate 3.5+',
      location: 'Mumbai, MH',
      playStyle: 'Right-handed • Mixed Doubles',
      memberSince: DateTime(2025, 3, 15),
    );

    const stats = PlayerStats(
      matchesPlayed: 24,
      winRatePercentage: 68.0,
      upcomingBookingsCount: 2,
      tournamentsEnteredCount: 1,
      skillRating: 3.85,
    );

    final now = DateTime.now();
    final matchTime = DateTime(now.year, now.month, now.day, 15, 45);
    final bookingTime = DateTime(now.year, now.month, now.day + 1, 7, 0);
    final coachingTime = DateTime(now.year, now.month, now.day + 3, 17, 0);

    String formatTimeSlot(DateTime dt, String time) {
      final diffDays = DateTime(dt.year, dt.month, dt.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;
      if (diffDays == 0) {
        return 'Today • $time';
      } else if (diffDays == 1) {
        return 'Tomorrow • $time';
      } else {
        const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day} • $time';
      }
    }

    final upcoming = isUpcomingEmpty
        ? const <UpcomingActivity>[]
        : <UpcomingActivity>[
            UpcomingActivity(
              id: 'up_001',
              title: 'Court Reservation',
              type: UpcomingActivityType.courtBooking,
              venueOrLocation: 'Grand Slam Pickleball Arena',
              courtName: 'Court 1 (Championship Cushioned)',
              dateTime: bookingTime,
              timeSlot: formatTimeSlot(bookingTime, '07:00 AM - 08:00 AM'),
              status: ActivityStatus.confirmed,
              statusLabel: 'Confirmed',
              actionRoute: AppRoutes.playerBookings,
            ),
            UpcomingActivity(
              id: 'up_002',
              title: 'Men\'s Singles Open — Round 1',
              type: UpcomingActivityType.tournamentMatch,
              venueOrLocation: 'National Pickleball Open 2026',
              courtName: 'Court 1 (Championship Court)',
              dateTime: matchTime,
              timeSlot: formatTimeSlot(matchTime, '03:45 PM'),
              status: ActivityStatus.scheduled,
              statusLabel: 'Scheduled',
              opponentOrCoach: 'vs Jordan Cruz (Seed #3)',
              actionRoute: AppRoutes.playerMatchDay,
            ),
            UpcomingActivity(
              id: 'up_003',
              title: 'Advanced Drill & Strategy Batch',
              type: UpcomingActivityType.coachingSession,
              venueOrLocation: 'Pinnacle Sports Academy (Downtown)',
              courtName: 'Court 4',
              dateTime: coachingTime,
              timeSlot: formatTimeSlot(coachingTime, '05:00 PM - 06:30 PM'),
              status: ActivityStatus.confirmed,
              statusLabel: 'Enrolled',
              opponentOrCoach: 'Coach David Miller',
              actionRoute: AppRoutes.playerAcademies,
            ),
          ];

    final recent = isRecentEmpty
        ? const <RecentActivityItem>[]
        : <RecentActivityItem>[
            RecentActivityItem(
              id: 'rec_001',
              title: 'Pacific Coast Masters — Quarter-final',
              description: 'Won against David Miller in straight sets (11-7, 11-5).',
              timestamp: DateTime.now().subtract(const Duration(days: 2)),
              category: RecentActivityCategory.match,
              resultBadge: 'Won 2-0',
              actionRoute: AppRoutes.playerTournaments,
            ),
            RecentActivityItem(
              id: 'rec_002',
              title: 'Court 3 Reservation Completed',
              description: '1 hour indoor hardcourt session at Grand Slam Arena.',
              timestamp: DateTime.now().subtract(const Duration(days: 4)),
              category: RecentActivityCategory.booking,
              resultBadge: 'Completed',
              actionRoute: AppRoutes.playerBookings,
            ),
            RecentActivityItem(
              id: 'rec_003',
              title: 'Pro Carbon 3K Paddle Delivered',
              description: 'Order #ORD-10921 delivered by Apex Paddle & Gear Co.',
              timestamp: DateTime.now().subtract(const Duration(days: 6)),
              category: RecentActivityCategory.marketplace,
              resultBadge: 'Delivered',
              actionRoute: AppRoutes.playerMarketplace,
            ),
          ];

    final data = PlayerDashboardData(
      profile: profile,
      stats: stats,
      upcomingActivities: upcoming,
      recentActivities: recent,
      unreadNotificationsCount: 3,
    );

    return Success(data);
  }
}
