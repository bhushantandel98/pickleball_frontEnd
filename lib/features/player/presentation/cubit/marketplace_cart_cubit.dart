import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/marketplace_repository.dart';
import 'marketplace_cart_state.dart';

class MarketplaceCartCubit extends Cubit<MarketplaceCartState> {
  final MarketplaceRepository _repository;

  MarketplaceCartCubit(this._repository) : super(const MarketplaceCartInitial());

  static const double defaultFreeDeliveryThreshold = 999.0;
  static const double standardDeliveryFee = 99.0;

  Future<void> loadCart({bool showLoading = true}) async {
    if (showLoading) {
      emit(const MarketplaceCartLoading());
    }

    final result = await _repository.getCart();
    switch (result) {
      case Success(:final data):
        _emitLoaded(data);
      case FailureResult(:final failure):
        emit(MarketplaceCartFailure(failure.message));
    }
  }

  void _emitLoaded(List<MarketplaceCartItem> items, {String? notice}) {
    final subtotal = items.fold<double>(0, (sum, i) => sum + i.totalPrice);
    final deliveryFee = (subtotal >= defaultFreeDeliveryThreshold || items.isEmpty)
        ? 0.0
        : standardDeliveryFee;
    final totalAmount = items.isEmpty ? 0.0 : subtotal + deliveryFee;

    emit(MarketplaceCartLoaded(
      items: items,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      freeDeliveryThreshold: defaultFreeDeliveryThreshold,
      totalAmount: totalAmount,
      userNotice: notice,
    ));
  }

  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    final currentState = state;
    if (currentState is! MarketplaceCartLoaded) return;

    emit(currentState.copyWith(isUpdating: true));
    final result = await _repository.updateCartQuantity(cartItemId, newQuantity);
    switch (result) {
      case Success(:final data):
        _emitLoaded(data);
      case FailureResult(:final failure):
        emit(currentState.copyWith(
          isUpdating: false,
          userNotice: failure.message,
        ));
    }
  }

  Future<void> removeItem(String cartItemId) async {
    final currentState = state;
    if (currentState is! MarketplaceCartLoaded) return;

    emit(currentState.copyWith(isUpdating: true));
    final result = await _repository.removeFromCart(cartItemId);
    switch (result) {
      case Success(:final data):
        _emitLoaded(data, notice: 'Item removed from cart');
      case FailureResult(:final failure):
        emit(currentState.copyWith(
          isUpdating: false,
          userNotice: failure.message,
        ));
    }
  }

  Future<void> clearCart() async {
    emit(const MarketplaceCartLoading());
    final result = await _repository.clearCart();
    switch (result) {
      case Success():
        _emitLoaded([]);
      case FailureResult(:final failure):
        emit(MarketplaceCartFailure(failure.message));
    }
  }
}
