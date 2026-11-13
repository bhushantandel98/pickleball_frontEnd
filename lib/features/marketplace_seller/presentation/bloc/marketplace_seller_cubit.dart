import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/repositories/marketplace_seller_repository.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/marketplace_seller_state.dart';

class MarketplaceSellerCubit extends Cubit<MarketplaceSellerState> {
  final MarketplaceSellerRepository _repository;

  MarketplaceSellerCubit({required MarketplaceSellerRepository repository})
      // ignore: prefer_initializing_formals
      : _repository = repository,
        super(const MarketplaceSellerInitial());

  String? _activeSellerId;
  String? _activeUserId;

  Future<void> loadProfile({
    required String userId,
    String? sellerId,
  }) async {
    _activeUserId = userId;
    _activeSellerId = sellerId;
    emit(const MarketplaceSellerLoading());

    final result = await _repository.getSellerProfileForUser(
      userId: userId,
      sellerId: sellerId,
    );

    result.when(
      success: (profile) {
        if (profile == null) {
          emit(MarketplaceSellerUnregistered(userId: userId));
        } else {
          _activeSellerId = profile.sellerId;
          emit(MarketplaceSellerLoaded(profile: profile));
        }
      },
      failure: (failure) => emit(MarketplaceSellerFailure(failure.message)),
    );
  }

  Future<void> refreshProfile() async {
    final userId = _activeUserId;
    if (userId == null) return;
    await loadProfile(userId: userId, sellerId: _activeSellerId);
  }

  void clearFeedback() {
    final current = state;
    if (current is MarketplaceSellerLoaded) {
      emit(current.copyWith(clearFeedback: true, clearError: true));
    } else if (current is MarketplaceSellerUnregistered) {
      emit(current.copyWith(clearFeedback: true, clearError: true));
    }
  }

  Future<void> requestContactVerificationOtp({
    required String mobileNumber,
    required String email,
  }) async {
    final current = state;
    final userId = _activeUserId;
    if (current is! MarketplaceSellerUnregistered || userId == null) return;

    emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));
    final result = await _repository.requestContactVerificationOtp(
      userId: userId,
      mobileNumber: mobileNumber,
      email: email,
    );

    result.when(
      success: (_) => emit(
        current.copyWith(
          otpSent: true,
          isMutating: false,
          feedbackMessage:
              'Verification OTPs sent to mobile & email (mock OTP: 123456).',
        ),
      ),
      failure: (failure) => emit(
        current.copyWith(isMutating: false, errorMessage: failure.message),
      ),
    );
  }

  Future<SellerProfile?> registerSellerAccount({
    required String mobileNumber,
    required String mobileOtp,
    required String email,
    required String emailOtp,
    required String businessName,
    required String legalEntityName,
    required SellerEntityType entityType,
    required SellerPickleballFocus pickleballFocus,
    required bool isPickleballOnlyConfirmed,
  }) async {
    final current = state;
    final userId = _activeUserId;
    if (current is! MarketplaceSellerUnregistered || userId == null) {
      return null;
    }

    emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));
    final result = await _repository.registerSellerAccount(
      userId: userId,
      mobileNumber: mobileNumber,
      mobileOtp: mobileOtp,
      email: email,
      emailOtp: emailOtp,
      businessName: businessName,
      legalEntityName: legalEntityName,
      entityType: entityType,
      pickleballFocus: pickleballFocus,
      isPickleballOnlyConfirmed: isPickleballOnlyConfirmed,
    );

    SellerProfile? created;
    result.when(
      success: (profile) {
        _activeSellerId = profile.sellerId;
        created = profile;
        emit(
          MarketplaceSellerLoaded(
            profile: profile,
            feedbackMessage:
                'Seller organization created. Complete your address & mandatory KYC documents.',
          ),
        );
      },
      failure: (failure) => emit(
        current.copyWith(isMutating: false, errorMessage: failure.message),
      ),
    );
    return created;
  }

  Future<void> saveBusinessProfile(SellerProfile updatedProfile) async {
    await _runMutation(
      () => _repository.saveBusinessProfile(
        sellerId: _activeSellerId!,
        userId: _activeUserId!,
        updatedProfile: updatedProfile,
      ),
      successMessage: 'Seller business profile saved.',
    );
  }

  Future<void> attachKycDocument({
    required SellerDocumentType type,
    required String fileName,
    required String mimeType,
    required int fileSizeBytes,
    required String localFileRef,
    Uint8List? fileBytes,
  }) async {
    await _runMutation(
      () => _repository.attachKycDocument(
        sellerId: _activeSellerId!,
        userId: _activeUserId!,
        type: type,
        fileName: fileName,
        mimeType: mimeType,
        fileSizeBytes: fileSizeBytes,
        localFileRef: localFileRef,
        fileBytes: fileBytes,
      ),
      successMessage:
          '${type.label} selected locally (ready for verification submission).',
    );
  }

  Future<void> removeKycDocument(String documentId) async {
    await _runMutation(
      () => _repository.removeKycDocument(
        sellerId: _activeSellerId!,
        userId: _activeUserId!,
        documentId: documentId,
      ),
      successMessage: 'Document removed.',
    );
  }

  Future<void> submitForVerification() async {
    await _runMutation(
      () => _repository.submitForVerification(
        sellerId: _activeSellerId!,
        userId: _activeUserId!,
      ),
      successMessage:
          'Submitted for Application Staff review. Profile editing is now locked.',
    );
  }

  Future<void> _runMutation(
    Future<Result<SellerProfile>> Function() action, {
    required String successMessage,
  }) async {
    final current = state;
    final sellerId = _activeSellerId;
    final userId = _activeUserId;
    if (current is! MarketplaceSellerLoaded ||
        sellerId == null ||
        userId == null) {
      return;
    }

    emit(
      current.copyWith(
        isMutating: true,
        clearFeedback: true,
        clearError: true,
      ),
    );

    final result = await action();
    result.when(
      success: (profile) => emit(
        MarketplaceSellerLoaded(
          profile: profile,
          isMutating: false,
          feedbackMessage: successMessage,
        ),
      ),
      failure: (failure) => emit(
        current.copyWith(
          isMutating: false,
          errorMessage: failure.message,
        ),
      ),
    );
  }
}
