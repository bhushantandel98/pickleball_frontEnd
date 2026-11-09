import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/tournament_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/tournament_registration_state.dart';

class TournamentRegistrationCubit extends Cubit<TournamentRegistrationState> {
  final TournamentRepository repository;

  TournamentRegistrationCubit({required this.repository})
      : super(const TournamentRegistrationInitial());

  void init({
    required TournamentItem tournament,
    required TournamentCategory initialCategory,
    String playerName = 'Alex Rivera',
    String playerPhone = '+91 98765 43210',
    String playerEmail = 'alex.rivera@example.com',
    double playerRating = 3.85,
    int playerAge = 28,
  }) {
    emit(TournamentRegistrationReady(
      tournament: tournament,
      selectedCategory: initialCategory,
      playerName: playerName,
      playerPhone: playerPhone,
      playerEmail: playerEmail,
      playerRating: playerRating,
      playerAge: playerAge,
    ));
  }

  void selectCategory(TournamentCategory category) {
    if (state is! TournamentRegistrationReady) return;
    final current = state as TournamentRegistrationReady;

    if (!category.isRegistrationOpen) {
      return;
    }
    if (!category.isRatingEligible(current.playerRating) ||
        !category.isAgeEligible(current.playerAge)) {
      return;
    }

    emit(current.copyWith(
      selectedCategory: category,
      clearPartner: !category.isDoubles,
    ));
  }

  void updatePartnerName(String name) {
    if (state is! TournamentRegistrationReady) return;
    final current = state as TournamentRegistrationReady;
    final errors = Map<String, String>.from(current.errors)..remove('partnerName');
    emit(current.copyWith(partnerName: name, errors: errors));
  }

  void updatePartnerPhone(String phone) {
    if (state is! TournamentRegistrationReady) return;
    final current = state as TournamentRegistrationReady;
    emit(current.copyWith(partnerPhone: phone));
  }

  void updateTshirtSize(String size) {
    if (state is! TournamentRegistrationReady) return;
    final current = state as TournamentRegistrationReady;
    emit(current.copyWith(tshirtSize: size));
  }

  void updateEmergencyContact(String name, String phone) {
    if (state is! TournamentRegistrationReady) return;
    final current = state as TournamentRegistrationReady;
    final errors = Map<String, String>.from(current.errors)
      ..remove('emergencyContactName')
      ..remove('emergencyContactPhone');
    emit(current.copyWith(
      emergencyContactName: name,
      emergencyContactPhone: phone,
      errors: errors,
    ));
  }

  void updateEmergencyContactName(String name) {
    if (state is! TournamentRegistrationReady) return;
    final current = state as TournamentRegistrationReady;
    final errors = Map<String, String>.from(current.errors)
      ..remove('emergencyContactName');
    emit(current.copyWith(
      emergencyContactName: name,
      errors: errors,
    ));
  }

  void updateEmergencyContactPhone(String phone) {
    if (state is! TournamentRegistrationReady) return;
    final current = state as TournamentRegistrationReady;
    final errors = Map<String, String>.from(current.errors)
      ..remove('emergencyContactPhone');
    emit(current.copyWith(
      emergencyContactPhone: phone,
      errors: errors,
    ));
  }

  void toggleWaiver(bool accepted) {
    if (state is! TournamentRegistrationReady) return;
    final current = state as TournamentRegistrationReady;
    final errors = Map<String, String>.from(current.errors)..remove('waiver');
    emit(current.copyWith(acceptedWaiver: accepted, errors: errors));
  }

  void toggleRules(bool accepted) {
    if (state is! TournamentRegistrationReady) return;
    final current = state as TournamentRegistrationReady;
    final errors = Map<String, String>.from(current.errors)..remove('rules');
    emit(current.copyWith(acceptedRules: accepted, errors: errors));
  }

  Future<bool> submit() async {
    if (state is! TournamentRegistrationReady) return false;
    final current = state as TournamentRegistrationReady;

    // Validation
    final errors = <String, String>{};
    if (current.isDoubles &&
        (current.partnerName == null || current.partnerName!.trim().isEmpty)) {
      errors['partnerName'] = 'Partner full name is required for doubles.';
    }
    if (current.emergencyContactName.trim().isEmpty) {
      errors['emergencyContactName'] = 'Emergency contact full name is required.';
    }
    if (current.emergencyContactPhone.trim().isEmpty) {
      errors['emergencyContactPhone'] = 'Emergency contact phone number is required.';
    }
    if (!current.acceptedWaiver) {
      errors['waiver'] = 'You must accept the liability waiver.';
    }
    if (!current.acceptedRules) {
      errors['rules'] = 'You must acknowledge the tournament rules.';
    }

    if (errors.isNotEmpty) {
      emit(current.copyWith(errors: errors));
      return false;
    }

    emit(current.copyWith(isSubmitting: true));

    final payload = TournamentRegistrationPayload(
      tournamentId: current.tournament.id,
      categoryId: current.selectedCategory.id,
      playerName: current.playerName,
      playerPhone: current.playerPhone,
      playerEmail: current.playerEmail,
      playerRating: current.playerRating,
      playerAge: current.playerAge,
      partnerName: current.partnerName,
      partnerPhone: current.partnerPhone,
      tshirtSize: current.tshirtSize,
      emergencyContactName: current.emergencyContactName.trim(),
      emergencyContactPhone: current.emergencyContactPhone.trim(),
      acceptedWaiver: current.acceptedWaiver,
      acceptedRules: current.acceptedRules,
      entryFee: current.entryFee,
    );

    final result = await repository.registerForTournament(payload);
    switch (result) {
      case Success<TournamentRegistration>(:final data):
        emit(TournamentRegistrationSuccess(data));
        return true;
      case FailureResult(:final failure):
        emit(current.copyWith(isSubmitting: false));
        emit(TournamentRegistrationFailure(failure.message));
        return false;
    }
  }
}
