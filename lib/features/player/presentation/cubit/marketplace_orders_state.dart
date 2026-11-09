import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

abstract class MarketplaceOrdersState extends Equatable {
  const MarketplaceOrdersState();

  @override
  List<Object?> get props => [];
}

class MarketplaceOrdersInitial extends MarketplaceOrdersState {
  const MarketplaceOrdersInitial();
}

class MarketplaceOrdersLoading extends MarketplaceOrdersState {
  const MarketplaceOrdersLoading();
}

class MarketplaceOrdersLoaded extends MarketplaceOrdersState {
  final List<MarketplaceOrder> orders;
  final MarketplaceOrderStatus? filterStatus;
  final String? noticeMessage;

  const MarketplaceOrdersLoaded({
    required this.orders,
    this.filterStatus,
    this.noticeMessage,
  });

  List<MarketplaceOrder> get filteredOrders {
    if (filterStatus == null) return orders;
    return orders.where((o) => o.status == filterStatus).toList();
  }

  bool get isEmpty => filteredOrders.isEmpty;

  MarketplaceOrdersLoaded copyWith({
    List<MarketplaceOrder>? orders,
    MarketplaceOrderStatus? filterStatus,
    bool clearStatusFilter = false,
    String? noticeMessage,
  }) {
    return MarketplaceOrdersLoaded(
      orders: orders ?? this.orders,
      filterStatus: clearStatusFilter ? null : (filterStatus ?? this.filterStatus),
      noticeMessage: noticeMessage,
    );
  }

  @override
  List<Object?> get props => [orders, filterStatus, noticeMessage];
}

class MarketplaceOrdersFailure extends MarketplaceOrdersState {
  final String message;

  const MarketplaceOrdersFailure(this.message);

  @override
  List<Object?> get props => [message];
}

abstract class MarketplaceOrderDetailsState extends Equatable {
  const MarketplaceOrderDetailsState();

  @override
  List<Object?> get props => [];
}

class MarketplaceOrderDetailsInitial extends MarketplaceOrderDetailsState {
  const MarketplaceOrderDetailsInitial();
}

class MarketplaceOrderDetailsLoading extends MarketplaceOrderDetailsState {
  const MarketplaceOrderDetailsLoading();
}

class MarketplaceOrderDetailsLoaded extends MarketplaceOrderDetailsState {
  final MarketplaceOrder order;
  final bool isCancelling;
  final String? userNotice;

  const MarketplaceOrderDetailsLoaded({
    required this.order,
    this.isCancelling = false,
    this.userNotice,
  });

  MarketplaceOrderDetailsLoaded copyWith({
    MarketplaceOrder? order,
    bool? isCancelling,
    String? userNotice,
  }) {
    return MarketplaceOrderDetailsLoaded(
      order: order ?? this.order,
      isCancelling: isCancelling ?? this.isCancelling,
      userNotice: userNotice,
    );
  }

  @override
  List<Object?> get props => [order, isCancelling, userNotice];
}

class MarketplaceOrderDetailsFailure extends MarketplaceOrderDetailsState {
  final String message;

  const MarketplaceOrderDetailsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
