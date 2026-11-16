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

/// Seller-entered dispatch & delivery metadata for a seller's order slice
/// (Feature 6.5).
///
/// [isManualSellerEntry] is `true` when no live carrier tracking API is
/// connected; tracking references are manually provided by the seller.
class SellerOrderFulfilmentDetails extends Equatable {
  final String? carrierName;
  final String? trackingNumber;
  final String? trackingUrl;
  final DateTime? dispatchedAt;
  final DateTime? deliveredAt;
  final String? fulfilmentNote;
  final bool isManualSellerEntry;

  const SellerOrderFulfilmentDetails({
    this.carrierName,
    this.trackingNumber,
    this.trackingUrl,
    this.dispatchedAt,
    this.deliveredAt,
    this.fulfilmentNote,
    this.isManualSellerEntry = true,
  });

  SellerOrderFulfilmentDetails copyWith({
    String? carrierName,
    String? trackingNumber,
    String? trackingUrl,
    DateTime? dispatchedAt,
    DateTime? deliveredAt,
    String? fulfilmentNote,
    bool? isManualSellerEntry,
  }) {
    return SellerOrderFulfilmentDetails(
      carrierName: carrierName ?? this.carrierName,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      trackingUrl: trackingUrl ?? this.trackingUrl,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      fulfilmentNote: fulfilmentNote ?? this.fulfilmentNote,
      isManualSellerEntry: isManualSellerEntry ?? this.isManualSellerEntry,
    );
  }

  @override
  List<Object?> get props => [
        carrierName,
        trackingNumber,
        trackingUrl,
        dispatchedAt,
        deliveredAt,
        fulfilmentNote,
        isManualSellerEntry,
      ];
}

/// Return eligibility state for an order item computed from its order-placement
/// return window snapshot and delivery timestamp (Feature 6.6).
enum SellerReturnEligibilityStatus {
  snapshotUnavailable('Return Policy Snapshot Unavailable (Legacy Order)'),
  nonReturnable('Non-Returnable (0-day policy)'),
  cancelledOrder('Order Cancelled'),
  pendingDelivery('Starts Upon Delivery'),
  withinWindow('Within Return Window'),
  windowExpired('Return Window Closed');

  final String label;
  const SellerReturnEligibilityStatus(this.label);
}

/// Immutable snapshot of a product's return policy captured at order placement.
///
/// Subsequent edits to `SellerProduct.returnPolicyDays` must NEVER alter
/// [snapshottedReturnWindowDays] for historical orders. When `null`, the order
/// predates snapshot persistence and must be surfaced explicitly as unavailable.
class SellerOrderItemReturnSnapshot extends Equatable {
  final String orderItemId;
  final String productId;
  final String productTitle;
  final int quantity;
  final double lineGrossAmount;
  final int? snapshottedReturnWindowDays;
  final DateTime snapshottedAt;
  final DateTime? deliveredAt;
  final SellerReturnEligibilityStatus eligibilityStatus;
  final DateTime? returnWindowEndsAt;

  const SellerOrderItemReturnSnapshot({
    required this.orderItemId,
    required this.productId,
    required this.productTitle,
    required this.quantity,
    required this.lineGrossAmount,
    required this.snapshottedReturnWindowDays,
    required this.snapshottedAt,
    this.deliveredAt,
    required this.eligibilityStatus,
    this.returnWindowEndsAt,
  });

  String get policyLabel {
    if (snapshottedReturnWindowDays == null) {
      return 'Return policy snapshot unavailable (legacy order)';
    }
    return snapshottedReturnWindowDays == 0
        ? 'Non-returnable (0 days)'
        : '$snapshottedReturnWindowDays-day return window';
  }

  @override
  List<Object?> get props => [
        orderItemId,
        productId,
        productTitle,
        quantity,
        lineGrossAmount,
        snapshottedReturnWindowDays,
        snapshottedAt,
        deliveredAt,
        eligibilityStatus,
        returnWindowEndsAt,
      ];
}

/// Read-only payout status distinguishing estimated net settlement from
/// verified backend/payment-provider transfers.
enum SellerPayoutStatus {
  notApplicableCancelled('Cancelled — Not Eligible'),
  commissionNotConfigured('Commission Not Configured — Net Unavailable'),
  pendingFulfilment('Pending Delivery & Return Window'),
  inReturnWindowHold('Held During Return Window'),
  awaitingProviderPayout('Eligible — Awaiting Backend/Provider Payout');

  final String label;
  const SellerPayoutStatus(this.label);
}

/// Read-only order-level settlement snapshot for a single seller's slice of an
/// order (Feature 6.6).
///
/// When [snapshottedCommissionRatePercent] is `null` (no approved commission
/// rule configured at order placement), [commissionAmount] and
/// [estimatedNetSettlement] remain `null` instead of assuming a rate.
class SellerOrderSettlementSnapshot extends Equatable {
  final String orderId;
  final String sellerId;
  final double grossAmount;
  final double? snapshottedCommissionRatePercent;
  final double? commissionAmount;
  final double otherDeductionsAmount;
  final double? estimatedNetSettlement;
  final SellerPayoutStatus payoutStatus;
  final String commissionRuleLabel;
  final DateTime snapshottedAt;
  final bool isReadOnly;

  const SellerOrderSettlementSnapshot({
    required this.orderId,
    required this.sellerId,
    required this.grossAmount,
    required this.snapshottedCommissionRatePercent,
    required this.commissionAmount,
    this.otherDeductionsAmount = 0.0,
    required this.estimatedNetSettlement,
    required this.payoutStatus,
    required this.commissionRuleLabel,
    required this.snapshottedAt,
    this.isReadOnly = true,
  });

  bool get isCommissionConfigured => snapshottedCommissionRatePercent != null;

  static String _fmt(double amount) => NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 0,
        locale: 'en_IN',
      ).format(amount);

  String get formattedGrossAmount => _fmt(grossAmount);
  String get formattedCommissionAmount =>
      commissionAmount != null ? _fmt(commissionAmount!) : 'Not configured';
  String get formattedOtherDeductions => _fmt(otherDeductionsAmount);
  String get formattedEstimatedNetSettlement => estimatedNetSettlement != null
      ? _fmt(estimatedNetSettlement!)
      : 'Unavailable (commission not configured)';

  @override
  List<Object?> get props => [
        orderId,
        sellerId,
        grossAmount,
        snapshottedCommissionRatePercent,
        commissionAmount,
        otherDeductionsAmount,
        estimatedNetSettlement,
        payoutStatus,
        commissionRuleLabel,
        snapshottedAt,
        isReadOnly,
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
  final SellerOrderFulfilmentDetails? fulfilment;
  final List<SellerOrderItemReturnSnapshot> itemReturnSnapshots;
  final SellerOrderSettlementSnapshot? settlementSnapshot;

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
    this.fulfilment,
    this.itemReturnSnapshots = const [],
    this.settlementSnapshot,
  });

  int get totalUnits =>
      sellerItems.fold<int>(0, (sum, item) => sum + item.quantity);

  bool get canAcceptOrder => status == MarketplaceOrderStatus.placed;

  bool get canCancelOrder =>
      status == MarketplaceOrderStatus.placed ||
      status == MarketplaceOrderStatus.processing;

  bool get canMarkDispatched => status == MarketplaceOrderStatus.processing;

  bool get canMarkOutForDelivery => status == MarketplaceOrderStatus.inTransit;

  bool get canMarkDelivered => status == MarketplaceOrderStatus.outForDelivery;

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
        fulfilment,
        itemReturnSnapshots,
        settlementSnapshot,
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
