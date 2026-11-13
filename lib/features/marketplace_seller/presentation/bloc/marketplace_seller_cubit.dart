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
    required String sellerId,
    required String userId,
  }) async {
    _activeSellerId = sellerId;
    _activeUserId = userId;
    emit(const MarketplaceSellerLoading());

    final result = await _repository.getSellerProfile(
      sellerId: sellerId,
      userId: userId,
    );

    result.when(
      success: (profile) => emit(MarketplaceSellerLoaded(profile: profile)),
      failure: (failure) => emit(MarketplaceSellerFailure(failure.message)),
    );
  }

  Future<void> refreshProfile() async {
    final sellerId = _activeSellerId;
    final userId = _activeUserId;
    if (sellerId == null || userId == null) return;
    await loadProfile(sellerId: sellerId, userId: userId);
  }

  void clearFeedback() {
    final current = state;
    if (current is MarketplaceSellerLoaded) {
      emit(current.copyWith(clearFeedback: true, clearError: true));
    }
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

  Future<void> uploadKycDocument({
    required SellerDocumentType type,
    required String fileName,
  }) async {
    await _runMutation(
      () => _repository.uploadKycDocument(
        sellerId: _activeSellerId!,
        userId: _activeUserId!,
        type: type,
        fileName: fileName,
      ),
      successMessage: '${type.label} uploaded.',
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
          'Submitted for Application Staff review and Application Admin approval.',
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
