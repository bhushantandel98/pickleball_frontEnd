import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/marketplace_repository.dart';
import 'marketplace_wishlist_state.dart';

class MarketplaceWishlistCubit extends Cubit<MarketplaceWishlistState> {
  final MarketplaceRepository _repository;

  MarketplaceWishlistCubit(this._repository)
      : super(const MarketplaceWishlistInitial());

  Future<void> loadWishlist({bool showLoading = true}) async {
    if (showLoading) {
      emit(const MarketplaceWishlistLoading());
    }

    final result = await _repository.getWishlist();
    switch (result) {
      case Success(:final data):
        emit(MarketplaceWishlistLoaded(items: data));
      case FailureResult(:final failure):
        emit(MarketplaceWishlistFailure(failure.message));
    }
  }

  Future<void> removeFromWishlist(String productId) async {
    final currentState = state;
    if (currentState is! MarketplaceWishlistLoaded) return;

    final toggleResult = await _repository.toggleWishlist(productId);
    if (toggleResult is Success<bool>) {
      final updatedResult = await _repository.getWishlist();
      final updated = updatedResult is Success<List<MarketplaceProduct>>
          ? updatedResult.data
          : <MarketplaceProduct>[];
      emit(MarketplaceWishlistLoaded(
        items: updated,
        notice: 'Item removed from wishlist',
      ));
    } else {
      emit(currentState.copyWith(notice: 'Failed to update wishlist'));
    }
  }

  Future<void> moveToCart(MarketplaceProduct product) async {
    final currentState = state;
    if (currentState is! MarketplaceWishlistLoaded) return;

    final addResult = await _repository.addToCart(product, quantity: 1);
    if (addResult is Success<List<MarketplaceCartItem>>) {
      await _repository.toggleWishlist(product.id);
      final updatedWishlistResult = await _repository.getWishlist();
      final updatedWishlist = updatedWishlistResult is Success<List<MarketplaceProduct>>
          ? updatedWishlistResult.data
          : <MarketplaceProduct>[];
      emit(MarketplaceWishlistLoaded(
        items: updatedWishlist,
        notice: 'Moved "${product.name}" to cart',
      ));
    } else {
      emit(currentState.copyWith(notice: 'Failed to move item to cart'));
    }
  }
}
