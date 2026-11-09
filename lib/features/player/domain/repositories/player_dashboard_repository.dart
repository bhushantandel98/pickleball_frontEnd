import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/player_dashboard_data.dart';

/// Repository contract for fetching the aggregate Player Dashboard data.
abstract class PlayerDashboardRepository {
  /// Fetches the dashboard data for the given [userId], or active user if null.
  Future<Result<PlayerDashboardData>> getDashboardData({String? userId});
}
