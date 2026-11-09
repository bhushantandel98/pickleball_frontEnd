import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';

sealed class TournamentRegistrationState extends Equatable {
  const TournamentRegistrationState();

  @override
  List<Object?> get props => [];
}

class TournamentRegistrationInitial extends TournamentRegistrationState {
  const TournamentRegistrationInitial();
}

class TournamentRegistrationReady extends TournamentRegistrationState {
  final TournamentItem tournament;
  final TournamentCategory selectedCategory;
  final String playerName;
  final String playerPhone;
  final String playerEmail;
  final double playerRating;
  final String? partnerName;
  final String? partnerPhone;
  final double? partnerRating;
  final String tshirtSize;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final bool acceptedWaiver;
  final bool acceptedRules;
  final Map<String, String> errors;
  final bool isSubmitting;

  const TournamentRegistrationReady({
    required this.tournament,
    required this.selectedCategory,
    required this.playerName,
    required this.playerPhone,
    required this.playerEmail,
    required this.playerRating,
    this.partnerName,
    this.partnerPhone,
    this.partnerRating,
    this.tshirtSize = 'L',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.acceptedWaiver = false,
    this.acceptedRules = false,
    this.errors = const {},
    this.isSubmitting = false,
  });

  bool get isDoubles => selectedCategory.isDoubles;
  double get entryFee => selectedCategory.entryFee;

  TournamentRegistrationReady copyWith({
    TournamentItem? tournament,
    TournamentCategory? selectedCategory,
    String? playerName,
    String? playerPhone,
    String? playerEmail,
    double? playerRating,
    String? partnerName,
    String? partnerPhone,
    double? partnerRating,
    String? tshirtSize,
    String? emergencyContactName,
    String? emergencyContactPhone,
    bool? acceptedWaiver,
    bool? acceptedRules,
    Map<String, String>? errors,
    bool? isSubmitting,
    bool clearPartner = false,
  }) {
    return TournamentRegistrationReady(
      tournament: tournament ?? this.tournament,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      playerName: playerName ?? this.playerName,
      playerPhone: playerPhone ?? this.playerPhone,
      playerEmail: playerEmail ?? this.playerEmail,
      playerRating: playerRating ?? this.playerRating,
      partnerName: clearPartner ? null : (partnerName ?? this.partnerName),
      partnerPhone: clearPartner ? null : (partnerPhone ?? this.partnerPhone),
      partnerRating: clearPartner ? null : (partnerRating ?? this.partnerRating),
      tshirtSize: tshirtSize ?? this.tshirtSize,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      acceptedWaiver: acceptedWaiver ?? this.acceptedWaiver,
      acceptedRules: acceptedRules ?? this.acceptedRules,
      errors: errors ?? this.errors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        tournament,
        selectedCategory,
        playerName,
        playerPhone,
        playerEmail,
        playerRating,
        partnerName,
        partnerPhone,
        partnerRating,
        tshirtSize,
        emergencyContactName,
        emergencyContactPhone,
        acceptedWaiver,
        acceptedRules,
        errors,
        isSubmitting,
      ];
}

class TournamentRegistrationSuccess extends TournamentRegistrationState {
  final TournamentRegistration registration;

  const TournamentRegistrationSuccess(this.registration);

  @override
  List<Object?> get props => [registration];
}

class TournamentRegistrationFailure extends TournamentRegistrationState {
  final String message;

  const TournamentRegistrationFailure(this.message);

  @override
  List<Object?> get props => [message];
}
