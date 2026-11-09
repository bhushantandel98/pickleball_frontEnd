import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';

sealed class TournamentDiscoveryState extends Equatable {
  const TournamentDiscoveryState();

  @override
  List<Object?> get props => [];
}

class TournamentDiscoveryInitial extends TournamentDiscoveryState {
  const TournamentDiscoveryInitial();
}

class TournamentDiscoveryLoading extends TournamentDiscoveryState {
  const TournamentDiscoveryLoading();
}

class TournamentDiscoveryLoaded extends TournamentDiscoveryState {
  final List<TournamentItem> allTournaments;
  final List<TournamentItem> filteredTournaments;
  final TournamentFilter filter;

  const TournamentDiscoveryLoaded({
    required this.allTournaments,
    required this.filteredTournaments,
    this.filter = const TournamentFilter(),
  });

  bool get isEmpty => filteredTournaments.isEmpty;

  TournamentDiscoveryLoaded copyWith({
    List<TournamentItem>? allTournaments,
    List<TournamentItem>? filteredTournaments,
    TournamentFilter? filter,
  }) {
    return TournamentDiscoveryLoaded(
      allTournaments: allTournaments ?? this.allTournaments,
      filteredTournaments: filteredTournaments ?? this.filteredTournaments,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [allTournaments, filteredTournaments, filter];
}

class TournamentDiscoveryFailure extends TournamentDiscoveryState {
  final String message;

  const TournamentDiscoveryFailure(this.message);

  @override
  List<Object?> get props => [message];
}
