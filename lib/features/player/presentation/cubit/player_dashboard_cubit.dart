import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/repositories/player_dashboard_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/player_dashboard_state.dart';

/// Cubit managing state lifecycle for the Player Dashboard.
class PlayerDashboardCubit extends Cubit<PlayerDashboardState> {
  final PlayerDashboardRepository repository;

  PlayerDashboardCubit({
    required this.repository,
  }) : super(const PlayerDashboardInitial());

  /// Loads the dashboard data.
  Future<void> loadDashboard({String? userId}) async {
    emit(const PlayerDashboardLoading());
    final result = await repository.getDashboardData(userId: userId);

    switch (result) {
      case Success(:final data):
        emit(PlayerDashboardLoaded(data));
      case FailureResult(:final failure):
        emit(PlayerDashboardFailure(failure));
    }
  }

  /// Refreshes dashboard data without clearing current loaded view if already loaded.
  Future<void> refreshDashboard({String? userId}) async {
    final result = await repository.getDashboardData(userId: userId);
    switch (result) {
      case Success(:final data):
        emit(PlayerDashboardLoaded(data));
      case FailureResult(:final failure):
        if (state is! PlayerDashboardLoaded) {
          emit(PlayerDashboardFailure(failure));
        }
    }
  }
}
