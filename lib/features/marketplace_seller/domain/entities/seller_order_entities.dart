import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

/// Filter criteria for Seller Order Management.
class SellerOrderFilter extends Equatable {
  final String query;
  final MarketplaceOrderStatus? status;
  final DateTime? fromDate;
  final DateTime? toDate;

  const SellerOrderFilter({
    this.query = '',
    this.status,
    this.fromDate,
    this.toDate,
  });

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      status != null ||
      fromDate != null ||
      toDate != null;

  SellerOrderFilter copyWith({
    String? query,
    MarketplaceOrderStatus? status,
    bool clearStatus = false,
    DateTime? fromDate,
    bool clearFromDate = false,
    DateTime? toDate,
    bool clearToDate = false,
  }) {
    return SellerOrderFilter(
      query: query ?? this.query,
      status: clearStatus ? null : (status ?? this.status),
      fromDate: clearFromDate ? null : (fromDate ?? this.fromDate),
      toDate: clearToDate ? null : (toDate ?? this.toDate),
    );
  }

  @override
  List<Object?> get props => [query, status, fromDate, toDate];
}

/// Customer delivery details restricted to what is needed for seller
/// fulfilment. Sensitive street/phone fields are masked once an order is
/// completed or cancelled.
class SellerOrderFulfilmentAddress extends Equatable {
  final String recipientName;
  final String phoneNumber;
  final String streetAddress;
  final String city;
  final String state;
  final String postalCode;
  final String? landmark;
  final bool isMasked;

  const SellerOrderFulfilmentAddress({
    required this.recipientName,
    required this.phoneNumber,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.postalCode,
    this.landmark,
    this.isMasked = false,
  });

  factory SellerOrderFulfilmentAddress.fromMarketplaceAddress(
    MarketplaceDeliveryAddress address, {
    required MarketplaceOrderStatus status,
  }) {
    final shouldMask = status == MarketplaceOrderStatus.delivered ||
        status == MarketplaceOrderStatus.cancelled;
    if (!shouldMask) {
      return SellerOrderFulfilmentAddress(
        recipientName: address.fullName,
        phoneNumber: address.phoneNumber,
        streetAddress: address.streetAddress,
        city: address.city,
        state: address.state,
        postalCode: address.postalCode,
        landmark: address.landmark,
        isMasked: false,
      );
    }

    final digits = address.phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final last4 =
        digits.length >= 4 ? digits.substring(digits.length - 4) : '••••';

    return SellerOrderFulfilmentAddress(
      recipientName: address.fullName,
      phoneNumber: '••••••$last4',
      streetAddress: 'Hidden after order ${status.displayName.toLowerCase()}',
      city: address.city,
      state: address.state,
      postalCode: address.postalCode,
      isMasked: true,
    );
  }

  String get formattedLocation => '$city, $state - $postalCode';

  @override
  List<Object?> get props => [
        recipientName,
        phoneNumber,
        streetAddress,
        city,
        state,
        postalCode,
        landmark,
        isMasked,
      ];
}

/// Seller-scoped projection of [MarketplaceOrder].
///
/// For multi-seller orders, [sellerItems] and [sellerSubtotal] include ONLY the
/// items belonging to [sellerId]—never another seller's products or financials.
class SellerOrderView extends Equatable {
  final String orderId;
  final String sellerId;
  final DateTime orderDate;
  final MarketplaceOrderStatus status;
  final List<MarketplaceCartItem> sellerItems;
  final double sellerSubtotal;
  final bool isMultiSellerOrder;
  final SellerOrderFulfilmentAddress deliveryAddress;
  final String paymentMethod;
  final String paymentStatus;
  final List<OrderStatusStep> timeline;
  final String? cancellationReason;

  const SellerOrderView({
    required this.orderId,
    required this.sellerId,
    required this.orderDate,
    required this.status,
    required this.sellerItems,
    required this.sellerSubtotal,
    this.isMultiSellerOrder = false,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    this.timeline = const [],
    this.cancellationReason,
  });

  int get totalUnits =>
      sellerItems.fold<int>(0, (sum, item) => sum + item.quantity);

  bool get canAcceptOrder => status == MarketplaceOrderStatus.placed;

  bool get canCancelOrder =>
      status == MarketplaceOrderStatus.placed ||
      status == MarketplaceOrderStatus.processing;

  String get formattedOrderDate =>
      DateFormat('dd MMM yyyy, hh:mm a').format(orderDate);

  String get formattedSellerSubtotal => NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 0,
        locale: 'en_IN',
      ).format(sellerSubtotal);

  @override
  List<Object?> get props => [
        orderId,
        sellerId,
        orderDate,
        status,
        sellerItems,
        sellerSubtotal,
        isMultiSellerOrder,
        deliveryAddress,
        paymentMethod,
        paymentStatus,
        timeline,
        cancellationReason,
      ];
}

/// Aggregated Seller Dashboard metrics computed strictly from seller-owned
/// orders. [grossOrderValue] is NOT settled payout.
class SellerDashboardMetrics extends Equatable {
  final int totalOrders;
  final int pendingOrders;
  final int processingOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double grossOrderValue;
  final List<SellerOrderView> recentOrders;

  const SellerDashboardMetrics({
    this.totalOrders = 0,
    this.pendingOrders = 0,
    this.processingOrders = 0,
    this.completedOrders = 0,
    this.cancelledOrders = 0,
    this.grossOrderValue = 0.0,
    this.recentOrders = const [],
  });

  String get formattedGrossOrderValue => NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 0,
        locale: 'en_IN',
      ).format(grossOrderValue);

  @override
  List<Object?> get props => [
        totalOrders,
        pendingOrders,
        processingOrders,
        completedOrders,
        cancelledOrders,
        grossOrderValue,
        recentOrders,
      ];
}
