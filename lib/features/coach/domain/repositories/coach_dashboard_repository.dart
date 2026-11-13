import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_dashboard_data.dart';

/// Repository contract for fetching Coach Dashboard aggregated metrics and sessions.
abstract class CoachDashboardRepository {
  /// Loads the dashboard payload for the authenticated coach.
  Future<Result<CoachDashboardData>> getDashboardData({String? coachId});
}
