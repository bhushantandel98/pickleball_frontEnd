import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/player/domain/entities/player_dashboard_data.dart';

/// State representation for the Player Dashboard.
sealed class PlayerDashboardState extends Equatable {
  const PlayerDashboardState();

  @override
  List<Object?> get props => [];
}

/// Initial state before loading begins.
class PlayerDashboardInitial extends PlayerDashboardState {
  const PlayerDashboardInitial();
}

/// Loading state while fetching dashboard data.
class PlayerDashboardLoading extends PlayerDashboardState {
  const PlayerDashboardLoading();
}

/// Loaded state with full aggregate player dashboard data.
class PlayerDashboardLoaded extends PlayerDashboardState {
  final PlayerDashboardData data;

  const PlayerDashboardLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

/// Empty state when no player data exists.
class PlayerDashboardEmpty extends PlayerDashboardState {
  final String message;

  const PlayerDashboardEmpty({
    this.message = 'No player information available.',
  });

  @override
  List<Object?> get props => [message];
}

/// Failure state when dashboard data loading encounters an error.
class PlayerDashboardFailure extends PlayerDashboardState {
  final Failure failure;

  const PlayerDashboardFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
