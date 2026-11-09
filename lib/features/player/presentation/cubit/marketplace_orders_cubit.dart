import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/marketplace_repository.dart';
import 'marketplace_orders_state.dart';

class MarketplaceOrdersCubit extends Cubit<MarketplaceOrdersState> {
  final MarketplaceRepository _repository;

  MarketplaceOrdersCubit(this._repository) : super(const MarketplaceOrdersInitial());

  Future<void> loadOrders({bool showLoading = true}) async {
    if (showLoading) {
      emit(const MarketplaceOrdersLoading());
    }

    final result = await _repository.getMyOrders();
    switch (result) {
      case Success(:final data):
        final currentFilter = (state is MarketplaceOrdersLoaded)
            ? (state as MarketplaceOrdersLoaded).filterStatus
            : null;
        emit(MarketplaceOrdersLoaded(
          orders: data,
          filterStatus: currentFilter,
        ));
      case FailureResult(:final failure):
        emit(MarketplaceOrdersFailure(failure.message));
    }
  }

  void filterByStatus(MarketplaceOrderStatus? status) {
    if (state is MarketplaceOrdersLoaded) {
      final current = state as MarketplaceOrdersLoaded;
      emit(current.copyWith(
        filterStatus: status,
        clearStatusFilter: status == null,
      ));
    }
  }
}

class MarketplaceOrderDetailsCubit extends Cubit<MarketplaceOrderDetailsState> {
  final MarketplaceRepository repository;
  final String orderId;

  MarketplaceOrderDetailsCubit({
    required this.repository,
    required this.orderId,
  }) : super(const MarketplaceOrderDetailsInitial());

  Future<void> loadOrderDetails() async {
    emit(const MarketplaceOrderDetailsLoading());
    final result = await repository.getOrderById(orderId);
    switch (result) {
      case Success(:final data):
        emit(MarketplaceOrderDetailsLoaded(order: data));
      case FailureResult(:final failure):
        emit(MarketplaceOrderDetailsFailure(failure.message));
    }
  }

  Future<bool> cancelOrder(String reason) async {
    if (state is! MarketplaceOrderDetailsLoaded) return false;
    final current = state as MarketplaceOrderDetailsLoaded;

    if (!current.order.canBeCancelled) {
      emit(current.copyWith(userNotice: 'This order cannot be cancelled anymore.'));
      return false;
    }

    emit(current.copyWith(isCancelling: true));
    final result = await repository.cancelOrder(orderId, reason);
    switch (result) {
      case Success(:final data):
        emit(MarketplaceOrderDetailsLoaded(
          order: data,
          userNotice: 'Order cancelled successfully',
        ));
        return true;
      case FailureResult(:final failure):
        emit(current.copyWith(
          isCancelling: false,
          userNotice: failure.message,
        ));
        return false;
    }
  }
}
