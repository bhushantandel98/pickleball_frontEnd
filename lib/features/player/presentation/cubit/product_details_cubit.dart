import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/marketplace_repository.dart';
import 'product_details_state.dart';

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  final MarketplaceRepository repository;
  final String productId;

  ProductDetailsCubit({
    required this.repository,
    required this.productId,
  }) : super(const ProductDetailsInitial());

  Future<void> loadProduct() async {
    emit(const ProductDetailsLoading());
    final result = await repository.getProductById(productId);

    switch (result) {
      case Success(:final data):
        final wishlistResult = await repository.getWishlist();
        final isWishlisted = wishlistResult is Success<List<MarketplaceProduct>>
            ? wishlistResult.data.any((p) => p.id == productId)
            : false;

        final cartResult = await repository.getCart();
        final cartItemCount = cartResult is Success<List<MarketplaceCartItem>>
            ? cartResult.data.fold<int>(0, (sum, item) => sum + item.quantity)
            : 0;

        emit(ProductDetailsLoaded(
          product: data,
          isWishlisted: isWishlisted,
          selectedQuantity: 1,
          selectedSize: data.availableSizes.isNotEmpty ? data.availableSizes.first : null,
          selectedColor: data.availableColors.isNotEmpty ? data.availableColors.first : null,
          cartItemCount: cartItemCount,
        ));
      case FailureResult(:final failure):
        emit(ProductDetailsFailure(failure.message));
    }
  }

  void selectSize(String size) {
    if (state is ProductDetailsLoaded) {
      final current = state as ProductDetailsLoaded;
      emit(current.copyWith(selectedSize: size));
    }
  }

  void selectColor(String color) {
    if (state is ProductDetailsLoaded) {
      final current = state as ProductDetailsLoaded;
      emit(current.copyWith(selectedColor: color));
    }
  }

  void incrementQuantity() {
    if (state is ProductDetailsLoaded) {
      final current = state as ProductDetailsLoaded;
      if (current.selectedQuantity < current.product.stockCount) {
        emit(current.copyWith(selectedQuantity: current.selectedQuantity + 1));
      }
    }
  }

  void decrementQuantity() {
    if (state is ProductDetailsLoaded) {
      final current = state as ProductDetailsLoaded;
      if (current.selectedQuantity > 1) {
        emit(current.copyWith(selectedQuantity: current.selectedQuantity - 1));
      }
    }
  }

  Future<void> toggleWishlist() async {
    if (state is! ProductDetailsLoaded) return;
    final current = state as ProductDetailsLoaded;

    final toggleResult = await repository.toggleWishlist(productId);
    if (toggleResult is Success<bool>) {
      final isWishlisted = toggleResult.data;
      emit(current.copyWith(
        isWishlisted: isWishlisted,
        actionMessage: isWishlisted ? 'Added to wishlist' : 'Removed from wishlist',
      ));
    } else {
      emit(current.copyWith(actionMessage: 'Failed to update wishlist'));
    }
  }

  Future<bool> addToCart() async {
    if (state is! ProductDetailsLoaded) return false;
    final current = state as ProductDetailsLoaded;

    if (!current.product.isInStock) {
      emit(current.copyWith(actionMessage: 'Item is currently out of stock'));
      return false;
    }

    emit(current.copyWith(isAddingToCart: true));
    final result = await repository.addToCart(
      current.product,
      quantity: current.selectedQuantity,
      size: current.selectedSize,
      color: current.selectedColor,
    );

    switch (result) {
      case Success(:final data):
        final cartItemCount = data.fold<int>(0, (sum, item) => sum + item.quantity);
        emit(current.copyWith(
          isAddingToCart: false,
          cartItemCount: cartItemCount,
          actionMessage: 'Added to cart successfully',
        ));
        return true;
      case FailureResult(:final failure):
        emit(current.copyWith(
          isAddingToCart: false,
          actionMessage: failure.message,
        ));
        return false;
    }
  }
}
