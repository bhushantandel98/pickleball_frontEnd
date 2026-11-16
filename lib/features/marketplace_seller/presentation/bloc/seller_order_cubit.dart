import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_order_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/repositories/seller_order_repository.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/seller_order_state.dart';

class SellerOrderCubit extends Cubit<SellerOrderState> {
  final SellerOrderRepository _repository;

  SellerOrderCubit({required SellerOrderRepository repository})
      : _repository = repository, // ignore: prefer_initializing_formals
        super(const SellerOrderInitial());

  String? _userId;
  String? _sellerId;
  SellerOrderFilter _currentFilter = const SellerOrderFilter();

  Future<void> loadOrders({
    required String userId,
    required String sellerId,
    SellerOrderFilter? filter,
  }) async {
    _userId = userId;
    _sellerId = sellerId;
    if (filter != null) {
      _currentFilter = filter;
    }
    emit(const SellerOrderLoading());

    final metricsResult = await _repository.getDashboardMetrics(
      sellerId: sellerId,
      userId: userId,
    );
    if (metricsResult is FailureResult<SellerDashboardMetrics>) {
      emit(SellerOrderFailure(metricsResult.failure.message));
      return;
    }

    final ordersResult = await _repository.getSellerOrders(
      sellerId: sellerId,
      userId: userId,
      filter: _currentFilter,
    );
    ordersResult.when(
      success: (orders) => emit(
        SellerOrderLoaded(
          metrics: (metricsResult as Success<SellerDashboardMetrics>).data,
          orders: orders,
          filter: _currentFilter,
        ),
      ),
      failure: (f) => emit(SellerOrderFailure(f.message)),
    );
  }

  Future<void> applyFilter(SellerOrderFilter filter) async {
    final current = state;
    final userId = _userId;
    final sellerId = _sellerId;
    _currentFilter = filter;
    if (current is! SellerOrderLoaded || userId == null || sellerId == null) {
      return;
    }

    emit(current.copyWith(filter: filter, isMutating: true, clearError: true));
    final result = await _repository.getSellerOrders(
      sellerId: sellerId,
      userId: userId,
      filter: filter,
    );
    result.when(
      success: (orders) => emit(
        current.copyWith(
          orders: orders,
          filter: filter,
          isMutating: false,
        ),
      ),
      failure: (f) => emit(
        current.copyWith(isMutating: false, errorMessage: f.message),
      ),
    );
  }

  Future<void> acceptOrder(String orderId) async {
    final current = state;
    final userId = _userId;
    final sellerId = _sellerId;
    if (current is! SellerOrderLoaded || userId == null || sellerId == null) {
      return;
    }

    emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));
    final result = await _repository.acceptOrder(
      sellerId: sellerId,
      userId: userId,
      orderId: orderId,
    );

    await result.when(
      success: (updated) async {
        await _refreshLoaded(
          feedbackMessage: 'Order ${updated.orderId} accepted (Processing).',
        );
      },
      failure: (f) async {
        emit(current.copyWith(isMutating: false, errorMessage: f.message));
      },
    );
  }

  Future<void> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    final current = state;
    final userId = _userId;
    final sellerId = _sellerId;
    if (current is! SellerOrderLoaded || userId == null || sellerId == null) {
      return;
    }

    emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));
    final result = await _repository.cancelSellerOrder(
      sellerId: sellerId,
      userId: userId,
      orderId: orderId,
      reason: reason,
    );

    await result.when(
      success: (updated) async {
        await _refreshLoaded(
          feedbackMessage: 'Order ${updated.orderId} cancelled.',
        );
      },
      failure: (f) async {
        emit(current.copyWith(isMutating: false, errorMessage: f.message));
      },
    );
  }

  Future<void> markDispatched({
    required String orderId,
    required String carrierName,
    required String trackingNumber,
    String? trackingUrl,
    String? note,
  }) async {
    final current = state;
    final userId = _userId;
    final sellerId = _sellerId;
    if (current is! SellerOrderLoaded || userId == null || sellerId == null) {
      return;
    }

    emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));
    final result = await _repository.markOrderDispatched(
      sellerId: sellerId,
      userId: userId,
      orderId: orderId,
      carrierName: carrierName,
      trackingNumber: trackingNumber,
      trackingUrl: trackingUrl,
      note: note,
    );

    await result.when(
      success: (updated) async {
        await _refreshLoaded(
          feedbackMessage:
              'Order ${updated.orderId} marked Dispatched (In Transit).',
        );
      },
      failure: (f) async {
        emit(current.copyWith(isMutating: false, errorMessage: f.message));
      },
    );
  }

  Future<void> markOutForDelivery({
    required String orderId,
    String? note,
  }) async {
    final current = state;
    final userId = _userId;
    final sellerId = _sellerId;
    if (current is! SellerOrderLoaded || userId == null || sellerId == null) {
      return;
    }

    emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));
    final result = await _repository.markOrderOutForDelivery(
      sellerId: sellerId,
      userId: userId,
      orderId: orderId,
      note: note,
    );

    await result.when(
      success: (updated) async {
        await _refreshLoaded(
          feedbackMessage:
              'Order ${updated.orderId} marked Out for Delivery.',
        );
      },
      failure: (f) async {
        emit(current.copyWith(isMutating: false, errorMessage: f.message));
      },
    );
  }

  Future<void> markDelivered({
    required String orderId,
    String? note,
  }) async {
    final current = state;
    final userId = _userId;
    final sellerId = _sellerId;
    if (current is! SellerOrderLoaded || userId == null || sellerId == null) {
      return;
    }

    emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));
    final result = await _repository.markOrderDelivered(
      sellerId: sellerId,
      userId: userId,
      orderId: orderId,
      note: note,
    );

    await result.when(
      success: (updated) async {
        await _refreshLoaded(
          feedbackMessage:
              'Order ${updated.orderId} confirmed Delivered.',
        );
      },
      failure: (f) async {
        emit(current.copyWith(isMutating: false, errorMessage: f.message));
      },
    );
  }

  void clearFeedback() {
    final current = state;
    if (current is SellerOrderLoaded) {
      emit(current.copyWith(clearFeedback: true, clearError: true));
    }
  }

  Future<void> _refreshLoaded({String? feedbackMessage}) async {
    final current = state;
    final userId = _userId;
    final sellerId = _sellerId;
    if (current is! SellerOrderLoaded || userId == null || sellerId == null) {
      return;
    }

    final metricsResult = await _repository.getDashboardMetrics(
      sellerId: sellerId,
      userId: userId,
    );
    final ordersResult = await _repository.getSellerOrders(
      sellerId: sellerId,
      userId: userId,
      filter: _currentFilter,
    );

    if (metricsResult is Success<SellerDashboardMetrics> &&
        ordersResult is Success<List<SellerOrderView>>) {
      emit(
        current.copyWith(
          metrics: metricsResult.data,
          orders: ordersResult.data,
          filter: _currentFilter,
          isMutating: false,
          feedbackMessage: feedbackMessage,
        ),
      );
    } else {
      final err = metricsResult.failureOrNull ?? ordersResult.failureOrNull;
      emit(
        current.copyWith(
          isMutating: false,
          errorMessage: err?.message ?? 'Unable to refresh seller orders.',
        ),
      );
    }
  }
}
