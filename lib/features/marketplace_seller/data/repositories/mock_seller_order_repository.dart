import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_order_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/repositories/marketplace_seller_repository.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/repositories/seller_catalog_repository.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/repositories/seller_order_repository.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/marketplace_repository.dart';

/// Mock implementation of [SellerOrderRepository] for Feature 6.4.
///
/// Reuses [MarketplaceRepository] orders alongside seller-scoped mock orders
/// (including multi-seller orders) while enforcing:
/// - Strict [sellerId] + [userId] ownership validation.
/// - Multi-seller item & financial isolation (a seller sees ONLY their own
///   items and item subtotal, never another seller's items or amounts).
/// - Read-only payment fields (sellers cannot alter payment records/status).
class MockSellerOrderRepository implements SellerOrderRepository {
  final MarketplaceRepository _marketplaceRepository;
  final MarketplaceSellerRepository _sellerRepository;
  final SellerCatalogRepository _catalogRepository;

  MockSellerOrderRepository({
    required MarketplaceRepository marketplaceRepository,
    required MarketplaceSellerRepository sellerRepository,
    required SellerCatalogRepository catalogRepository,
  })  : _marketplaceRepository = marketplaceRepository, // ignore: prefer_initializing_formals
        _sellerRepository = sellerRepository, // ignore: prefer_initializing_formals
        _catalogRepository = catalogRepository; // ignore: prefer_initializing_formals

  /// Per-seller slice overrides keyed by `'$orderId::$sellerId'` so that
  /// accepting or cancelling in a multi-seller order affects ONLY the acting
  /// seller's items without mutating another seller's items or status.
  final Map<String, _SellerOrderSliceState> _sellerSliceOverrides = {};
  final List<MarketplaceOrder> _supplementarySellerOrders = _buildMockOrders();

  static String _sliceKey(String orderId, String sellerId) =>
      '$orderId::$sellerId';

  static List<MarketplaceOrder> _buildMockOrders() {
    const buyerA = MarketplaceDeliveryAddress(
      fullName: 'Rohan Deshmukh',
      phoneNumber: '+91 98204 55112',
      streetAddress: '302 Emerald Residency, Baner Road',
      city: 'Pune',
      state: 'Maharashtra',
      postalCode: '411045',
      landmark: 'Opposite Balewadi High Street',
    );
    const buyerB = MarketplaceDeliveryAddress(
      fullName: 'Meera Krishnan',
      phoneNumber: '+91 98451 77889',
      streetAddress: '18 Indiranagar 12th Main, HAL 2nd Stage',
      city: 'Bengaluru',
      state: 'Karnataka',
      postalCode: '560008',
    );

    const dinkPaddle = MarketplaceProduct(
      id: 'sp_001',
      title: 'Vortex T700 Raw Carbon Paddle',
      brand: 'Dink & Smash',
      sellerId: 'org_seller_002',
      sellerName: 'Dink & Smash Pro Shop',
      description: 'USAPA-approved T700 raw carbon fiber pickleball paddle.',
      price: 10999,
      originalPrice: 12499,
      rating: 4.9,
      reviewCount: 28,
      category: ProductCategory.paddles,
      imageUrl: '',
      stockCount: 30,
      returnPolicyDays: 14,
    );

    const dinkBalls = MarketplaceProduct(
      id: 'sp_002',
      title: 'Pro-Flight 40 Outdoor Pickleballs (12-Pack)',
      brand: 'Dink & Smash',
      sellerId: 'org_seller_002',
      sellerName: 'Dink & Smash Pro Shop',
      description: '40-hole outdoor tournament pickleballs.',
      price: 2499,
      originalPrice: 2999,
      rating: 4.8,
      reviewCount: 19,
      category: ProductCategory.balls,
      imageUrl: '',
      stockCount: 45,
      returnPolicyDays: 7,
    );

    const apexBag = MarketplaceProduct(
      id: 'sp_005',
      title: 'Apex Tour 3-Paddle Sling Bag',
      brand: 'Apex',
      sellerId: 'org_seller_001',
      sellerName: 'Apex Pickleball Gear Co.',
      description: 'Thermal-lined pickleball sling bag.',
      price: 3499,
      originalPrice: 3999,
      rating: 4.6,
      reviewCount: 12,
      category: ProductCategory.bags,
      imageUrl: '',
      stockCount: 15,
      returnPolicyDays: 14,
    );

    return [
      // Multi-seller order: contains items from both org_seller_002 and org_seller_001.
      MarketplaceOrder(
        id: 'PKL-ORD-20261114-2001',
        orderDate: DateTime(2026, 11, 14, 10, 20),
        items: const [
          MarketplaceCartItem(
            id: 'ms_item_1',
            product: dinkPaddle,
            quantity: 1,
            selectedSize: 'Standard 16mm',
            selectedColor: 'Matte Carbon',
          ),
          MarketplaceCartItem(
            id: 'ms_item_2',
            product: apexBag,
            quantity: 1,
          ),
        ],
        subtotal: 14498,
        deliveryFee: 0,
        totalAmount: 14498,
        deliveryAddress: buyerA,
        paymentMethod: 'UPI (Razorpay Checkout)',
        paymentStatus: 'Paid',
        status: MarketplaceOrderStatus.placed,
        trackingTimeline: [
          OrderStatusStep(
            title: 'Order Placed',
            description: 'Buyer placed multi-seller order.',
            timestamp: DateTime(2026, 11, 14, 10, 20),
            isCompleted: true,
            isCurrent: true,
          ),
        ],
      ),
      MarketplaceOrder(
        id: 'PKL-ORD-20261113-2002',
        orderDate: DateTime(2026, 11, 13, 15, 45),
        items: const [
          MarketplaceCartItem(
            id: 'ms_item_3',
            product: dinkBalls,
            quantity: 2,
            selectedColor: 'Optic Yellow',
          ),
        ],
        subtotal: 4998,
        deliveryFee: 0,
        totalAmount: 4998,
        deliveryAddress: buyerB,
        paymentMethod: 'Card',
        paymentStatus: 'Paid',
        status: MarketplaceOrderStatus.processing,
        trackingTimeline: [
          OrderStatusStep(
            title: 'Processing',
            description: 'Seller accepted the order and is preparing items.',
            timestamp: DateTime(2026, 11, 13, 16, 10),
            isCompleted: true,
            isCurrent: true,
          ),
          OrderStatusStep(
            title: 'Order Placed',
            description: 'Order received from buyer.',
            timestamp: DateTime(2026, 11, 13, 15, 45),
            isCompleted: true,
          ),
        ],
      ),
      MarketplaceOrder(
        id: 'PKL-ORD-20261110-2003',
        orderDate: DateTime(2026, 11, 10, 12, 10),
        items: const [
          MarketplaceCartItem(
            id: 'ms_item_4',
            product: dinkPaddle,
            quantity: 1,
            selectedSize: 'Elongated 16mm',
            selectedColor: 'Court Blue',
          ),
        ],
        subtotal: 10999,
        deliveryFee: 0,
        totalAmount: 10999,
        deliveryAddress: buyerB,
        paymentMethod: 'UPI',
        paymentStatus: 'Paid',
        status: MarketplaceOrderStatus.delivered,
        trackingTimeline: [
          OrderStatusStep(
            title: 'Order Delivered',
            description: 'Delivered to customer.',
            timestamp: DateTime(2026, 11, 12, 17, 20),
            isCompleted: true,
            isCurrent: true,
          ),
          OrderStatusStep(
            title: 'Order Placed',
            description: 'Order received.',
            timestamp: DateTime(2026, 11, 10, 12, 10),
            isCompleted: true,
          ),
        ],
      ),
      MarketplaceOrder(
        id: 'PKL-ORD-20261108-2004',
        orderDate: DateTime(2026, 11, 8, 9, 30),
        items: const [
          MarketplaceCartItem(
            id: 'ms_item_5',
            product: dinkBalls,
            quantity: 1,
          ),
        ],
        subtotal: 2499,
        deliveryFee: 0,
        totalAmount: 2499,
        deliveryAddress: buyerA,
        paymentMethod: 'Cash on Delivery',
        paymentStatus: 'Not Collected',
        status: MarketplaceOrderStatus.cancelled,
        cancellationReason: 'Customer requested cancellation prior to dispatch.',
        trackingTimeline: [
          OrderStatusStep(
            title: 'Order Cancelled',
            description: 'Customer requested cancellation prior to dispatch.',
            timestamp: DateTime(2026, 11, 8, 11, 0),
            isCompleted: true,
            isCurrent: true,
          ),
        ],
      ),
    ];
  }

  Future<Result<SellerProfile>> _requireOwnedSeller({
    required String sellerId,
    required String userId,
  }) async {
    final profileResult = await _sellerRepository.getSellerProfileForUser(
      userId: userId,
      sellerId: sellerId,
    );
    return profileResult.when(
      success: (profile) {
        if (profile == null) {
          return const FailureResult(
            ForbiddenFailure(
              message:
                  'Seller profile not found or does not belong to the authenticated user.',
            ),
          );
        }
        if (profile.sellerId != sellerId || profile.ownerUserId != userId) {
          return const FailureResult(
            ForbiddenFailure(
              message:
                  'Forbidden: Seller ownership check failed for order access.',
            ),
          );
        }
        return Success(profile);
      },
      failure: (failure) => FailureResult(failure),
    );
  }

  bool _isOwnedItem(
    MarketplaceCartItem item,
    SellerProfile seller,
    Set<String> ownedProductIds,
  ) {
    final p = item.product;
    if (p.sellerId != null && p.sellerId!.trim().isNotEmpty) {
      return p.sellerId == seller.sellerId;
    }
    if (ownedProductIds.contains(p.id)) {
      return true;
    }
    final itemSeller = p.sellerName.trim().toLowerCase();
    final sellerBusiness = seller.businessName.trim().toLowerCase();
    if (itemSeller == sellerBusiness) return true;
    // Legacy mock alignment for Apex Paddle & Gear Co. (org_seller_001)
    if (seller.sellerId == 'org_seller_001' && itemSeller.contains('apex')) {
      return true;
    }
    return false;
  }

  Future<Result<List<SellerOrderView>>> _loadAllOwnedOrders(
    SellerProfile seller,
  ) async {
    final playerOrdersResult = await _marketplaceRepository.getMyOrders();
    if (playerOrdersResult is FailureResult<List<MarketplaceOrder>>) {
      return FailureResult(playerOrdersResult.failure);
    }

    final catalogResult = await _catalogRepository.getSellerProducts(
      sellerId: seller.sellerId,
      userId: seller.ownerUserId,
    );
    final ownedProductIds = catalogResult.when(
      success: (list) => list.map((p) => p.productId).toSet(),
      failure: (_) => <String>{},
    );

    final merged = <String, MarketplaceOrder>{};
    for (final o
        in (playerOrdersResult as Success<List<MarketplaceOrder>>).data) {
      merged[o.id] = o;
    }
    for (final o in _supplementarySellerOrders) {
      merged[o.id] = o;
    }

    final views = <SellerOrderView>[];
    for (final order in merged.values) {
      final ownedItems = order.items
          .where((item) => _isOwnedItem(item, seller, ownedProductIds))
          .toList();
      if (ownedItems.isEmpty) continue;

      final slice = _sellerSliceOverrides[_sliceKey(order.id, seller.sellerId)];
      final effectiveStatus = slice?.status ?? order.status;
      final effectiveTimeline = slice?.timeline ?? order.trackingTimeline;
      final effectiveCancellationReason =
          slice?.cancellationReason ?? order.cancellationReason;
      final effectiveFulfilment = slice?.fulfilment ??
          (order.trackingNumber != null &&
                  order.trackingNumber!.trim().isNotEmpty
              ? SellerOrderFulfilmentDetails(
                  trackingNumber: order.trackingNumber,
                  isManualSellerEntry: true,
                )
              : null);

      final sellerSubtotal =
          ownedItems.fold<double>(0.0, (sum, item) => sum + item.itemTotal);

      views.add(
        SellerOrderView(
          orderId: order.id,
          sellerId: seller.sellerId,
          orderDate: order.orderDate,
          status: effectiveStatus,
          sellerItems: ownedItems,
          sellerSubtotal: sellerSubtotal,
          isMultiSellerOrder: ownedItems.length < order.items.length,
          deliveryAddress: SellerOrderFulfilmentAddress.fromMarketplaceAddress(
            order.deliveryAddress,
            status: effectiveStatus,
          ),
          paymentMethod: order.paymentMethod,
          paymentStatus: order.paymentStatus,
          timeline: effectiveTimeline,
          cancellationReason: effectiveCancellationReason,
          fulfilment: effectiveFulfilment,
        ),
      );
    }

    views.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return Success(views);
  }

  @override
  Future<Result<SellerDashboardMetrics>> getDashboardMetrics({
    required String sellerId,
    required String userId,
  }) async {
    final sellerCheck = await _requireOwnedSeller(
      sellerId: sellerId,
      userId: userId,
    );
    if (sellerCheck is FailureResult<SellerProfile>) {
      return FailureResult(sellerCheck.failure);
    }
    final seller = (sellerCheck as Success<SellerProfile>).data;

    final ordersResult = await _loadAllOwnedOrders(seller);
    return ordersResult.when(
      success: (orders) {
        final pending = orders
            .where((o) => o.status == MarketplaceOrderStatus.placed)
            .length;
        final processing = orders
            .where((o) => o.status == MarketplaceOrderStatus.processing)
            .length;
        final completed = orders
            .where((o) => o.status == MarketplaceOrderStatus.delivered)
            .length;
        final cancelled = orders
            .where((o) => o.status == MarketplaceOrderStatus.cancelled)
            .length;
        final grossOrderValue = orders
            .where((o) => o.status != MarketplaceOrderStatus.cancelled)
            .fold<double>(0.0, (sum, o) => sum + o.sellerSubtotal);

        return Success(
          SellerDashboardMetrics(
            totalOrders: orders.length,
            pendingOrders: pending,
            processingOrders: processing,
            completedOrders: completed,
            cancelledOrders: cancelled,
            grossOrderValue: grossOrderValue,
            recentOrders: orders.take(5).toList(),
          ),
        );
      },
      failure: (f) => FailureResult(f),
    );
  }

  @override
  Future<Result<List<SellerOrderView>>> getSellerOrders({
    required String sellerId,
    required String userId,
    SellerOrderFilter? filter,
  }) async {
    final sellerCheck = await _requireOwnedSeller(
      sellerId: sellerId,
      userId: userId,
    );
    if (sellerCheck is FailureResult<SellerProfile>) {
      return FailureResult(sellerCheck.failure);
    }
    final seller = (sellerCheck as Success<SellerProfile>).data;

    final ordersResult = await _loadAllOwnedOrders(seller);
    return ordersResult.when(
      success: (orders) {
        var list = orders;
        if (filter != null) {
          final q = filter.query.trim().toLowerCase();
          if (q.isNotEmpty) {
            list = list.where((o) {
              final matchesId = o.orderId.toLowerCase().contains(q);
              final matchesCustomer =
                  o.deliveryAddress.recipientName.toLowerCase().contains(q) ||
                      o.deliveryAddress.city.toLowerCase().contains(q);
              final matchesProduct = o.sellerItems.any(
                (i) => i.product.title.toLowerCase().contains(q),
              );
              return matchesId || matchesCustomer || matchesProduct;
            }).toList();
          }
          if (filter.status != null) {
            list = list.where((o) => o.status == filter.status).toList();
          }
          if (filter.fromDate != null) {
            final from = DateTime(
              filter.fromDate!.year,
              filter.fromDate!.month,
              filter.fromDate!.day,
            );
            list = list.where((o) => !o.orderDate.isBefore(from)).toList();
          }
          if (filter.toDate != null) {
            final toEnd = DateTime(
              filter.toDate!.year,
              filter.toDate!.month,
              filter.toDate!.day,
              23,
              59,
              59,
            );
            list = list.where((o) => !o.orderDate.isAfter(toEnd)).toList();
          }
        }
        return Success(List<SellerOrderView>.unmodifiable(list));
      },
      failure: (f) => FailureResult(f),
    );
  }

  @override
  Future<Result<SellerOrderView>> getSellerOrderById({
    required String sellerId,
    required String userId,
    required String orderId,
  }) async {
    final sellerCheck = await _requireOwnedSeller(
      sellerId: sellerId,
      userId: userId,
    );
    if (sellerCheck is FailureResult<SellerProfile>) {
      return FailureResult(sellerCheck.failure);
    }
    final seller = (sellerCheck as Success<SellerProfile>).data;

    final ordersResult = await _loadAllOwnedOrders(seller);
    return ordersResult.when(
      success: (orders) {
        for (final order in orders) {
          if (order.orderId == orderId) {
            return Success(order);
          }
        }
        return const FailureResult(
          NotFoundFailure(
            message: 'Order not found or does not belong to this seller.',
          ),
        );
      },
      failure: (f) => FailureResult(f),
    );
  }

  Future<MarketplaceOrder?> _findRawOrder(String orderId) async {
    for (final o in _supplementarySellerOrders) {
      if (o.id == orderId) return o;
    }
    final playerResult = await _marketplaceRepository.getOrderById(orderId);
    return playerResult.dataOrNull;
  }

  @override
  Future<Result<SellerOrderView>> acceptOrder({
    required String sellerId,
    required String userId,
    required String orderId,
  }) async {
    final existingResult = await getSellerOrderById(
      sellerId: sellerId,
      userId: userId,
      orderId: orderId,
    );
    if (existingResult is FailureResult<SellerOrderView>) {
      return existingResult;
    }
    final currentView = (existingResult as Success<SellerOrderView>).data;
    if (!currentView.canAcceptOrder) {
      return FailureResult(
        ValidationFailure(
          message:
              'Only newly placed orders can be accepted. Current status: ${currentView.status.displayName}.',
        ),
      );
    }

    final raw = await _findRawOrder(orderId);
    if (raw == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Order record unavailable.'),
      );
    }

    final now = DateTime.now();
    _sellerSliceOverrides[_sliceKey(orderId, sellerId)] = _SellerOrderSliceState(
      status: MarketplaceOrderStatus.processing,
      timeline: [
        OrderStatusStep(
          title: 'Processing (Seller Items Accepted)',
          description:
              'Seller accepted their ${currentView.totalUnits} item(s) and began preparation.',
          timestamp: now,
          isCompleted: true,
          isCurrent: true,
        ),
        ...currentView.timeline.map(
          (s) => OrderStatusStep(
            title: s.title,
            description: s.description,
            timestamp: s.timestamp,
            isCompleted: s.isCompleted,
            isCurrent: false,
          ),
        ),
      ],
      cancellationReason: currentView.cancellationReason,
    );

    return getSellerOrderById(
      sellerId: sellerId,
      userId: userId,
      orderId: orderId,
    );
  }

  @override
  Future<Result<SellerOrderView>> cancelSellerOrder({
    required String sellerId,
    required String userId,
    required String orderId,
    required String reason,
  }) async {
    if (reason.trim().length < 5) {
      return const FailureResult(
        ValidationFailure(
          message: 'Provide a clear cancellation reason (at least 5 characters).',
        ),
      );
    }

    final existingResult = await getSellerOrderById(
      sellerId: sellerId,
      userId: userId,
      orderId: orderId,
    );
    if (existingResult is FailureResult<SellerOrderView>) {
      return existingResult;
    }
    final currentView = (existingResult as Success<SellerOrderView>).data;
    if (!currentView.canCancelOrder) {
      return FailureResult(
        ValidationFailure(
          message:
              'Order cannot be cancelled in status "${currentView.status.displayName}".',
        ),
      );
    }

    final raw = await _findRawOrder(orderId);
    if (raw == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Order record unavailable.'),
      );
    }

    final now = DateTime.now();
    _sellerSliceOverrides[_sliceKey(orderId, sellerId)] = _SellerOrderSliceState(
      status: MarketplaceOrderStatus.cancelled,
      cancellationReason: reason.trim(),
      timeline: [
        OrderStatusStep(
          title: 'Seller Items Cancelled',
          description: reason.trim(),
          timestamp: now,
          isCompleted: true,
          isCurrent: true,
        ),
        ...currentView.timeline.map(
          (s) => OrderStatusStep(
            title: s.title,
            description: s.description,
            timestamp: s.timestamp,
            isCompleted: s.isCompleted,
            isCurrent: false,
          ),
        ),
      ],
    );

    return getSellerOrderById(
      sellerId: sellerId,
      userId: userId,
      orderId: orderId,
    );
  }

  @override
  Future<Result<SellerOrderView>> markOrderDispatched({
    required String sellerId,
    required String userId,
    required String orderId,
    required String carrierName,
    required String trackingNumber,
    String? trackingUrl,
    String? note,
  }) async {
    final trimmedCarrier = carrierName.trim();
    final trimmedTracking = trackingNumber.trim();
    final trimmedUrl = trackingUrl?.trim() ?? '';

    if (trimmedCarrier.isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Carrier / courier name is required.'),
      );
    }
    if (trimmedTracking.isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Tracking reference number is required.'),
      );
    }
    if (trimmedUrl.isNotEmpty) {
      final uri = Uri.tryParse(trimmedUrl);
      if (uri == null ||
          !uri.hasScheme ||
          uri.host.isEmpty ||
          (uri.scheme != 'http' && uri.scheme != 'https')) {
        return const FailureResult(
          ValidationFailure(
            message: 'Tracking URL must be a valid http or https link.',
          ),
        );
      }
    }

    final existingResult = await getSellerOrderById(
      sellerId: sellerId,
      userId: userId,
      orderId: orderId,
    );
    if (existingResult is FailureResult<SellerOrderView>) {
      return existingResult;
    }
    final currentView = (existingResult as Success<SellerOrderView>).data;
    if (!currentView.canMarkDispatched) {
      return FailureResult(
        ValidationFailure(
          message:
              'Only Processing orders can be marked Dispatched (In Transit). Current status: ${currentView.status.displayName}.',
        ),
      );
    }

    final now = DateTime.now();
    final trimmedNote = note?.trim() ?? '';
    final stepDescription =
        'Carrier: $trimmedCarrier • Tracking: $trimmedTracking'
        '${trimmedNote.isNotEmpty ? ' • $trimmedNote' : ''}';

    _sellerSliceOverrides[_sliceKey(orderId, sellerId)] = _SellerOrderSliceState(
      status: MarketplaceOrderStatus.inTransit,
      fulfilment: SellerOrderFulfilmentDetails(
        carrierName: trimmedCarrier,
        trackingNumber: trimmedTracking,
        trackingUrl: trimmedUrl.isEmpty ? null : trimmedUrl,
        dispatchedAt: now,
        fulfilmentNote: trimmedNote.isEmpty ? null : trimmedNote,
        isManualSellerEntry: true,
      ),
      timeline: [
        OrderStatusStep(
          title: 'Dispatched (In Transit)',
          description: stepDescription,
          timestamp: now,
          isCompleted: true,
          isCurrent: true,
        ),
        ...currentView.timeline.map(
          (s) => OrderStatusStep(
            title: s.title,
            description: s.description,
            timestamp: s.timestamp,
            isCompleted: s.isCompleted,
            isCurrent: false,
          ),
        ),
      ],
    );

    return getSellerOrderById(
      sellerId: sellerId,
      userId: userId,
      orderId: orderId,
    );
  }

  @override
  Future<Result<SellerOrderView>> markOrderOutForDelivery({
    required String sellerId,
    required String userId,
    required String orderId,
    String? note,
  }) async {
    final existingResult = await getSellerOrderById(
      sellerId: sellerId,
      userId: userId,
      orderId: orderId,
    );
    if (existingResult is FailureResult<SellerOrderView>) {
      return existingResult;
    }
    final currentView = (existingResult as Success<SellerOrderView>).data;
    if (!currentView.canMarkOutForDelivery) {
      return FailureResult(
        ValidationFailure(
          message:
              'Only In Transit orders can be marked Out for Delivery. Current status: ${currentView.status.displayName}.',
        ),
      );
    }

    final now = DateTime.now();
    final trimmedNote = note?.trim() ?? '';
    final prevFulfilment = currentView.fulfilment;

    _sellerSliceOverrides[_sliceKey(orderId, sellerId)] = _SellerOrderSliceState(
      status: MarketplaceOrderStatus.outForDelivery,
      fulfilment: (prevFulfilment ?? const SellerOrderFulfilmentDetails())
          .copyWith(
        fulfilmentNote: trimmedNote.isNotEmpty
            ? trimmedNote
            : prevFulfilment?.fulfilmentNote,
      ),
      timeline: [
        OrderStatusStep(
          title: 'Out for Delivery',
          description: trimmedNote.isNotEmpty
              ? trimmedNote
              : 'Seller marked shipment as out for delivery.',
          timestamp: now,
          isCompleted: true,
          isCurrent: true,
        ),
        ...currentView.timeline.map(
          (s) => OrderStatusStep(
            title: s.title,
            description: s.description,
            timestamp: s.timestamp,
            isCompleted: s.isCompleted,
            isCurrent: false,
          ),
        ),
      ],
    );

    return getSellerOrderById(
      sellerId: sellerId,
      userId: userId,
      orderId: orderId,
    );
  }

  @override
  Future<Result<SellerOrderView>> markOrderDelivered({
    required String sellerId,
    required String userId,
    required String orderId,
    String? note,
  }) async {
    final existingResult = await getSellerOrderById(
      sellerId: sellerId,
      userId: userId,
      orderId: orderId,
    );
    if (existingResult is FailureResult<SellerOrderView>) {
      return existingResult;
    }
    final currentView = (existingResult as Success<SellerOrderView>).data;
    if (!currentView.canMarkDelivered) {
      return FailureResult(
        ValidationFailure(
          message:
              'Only Out for Delivery orders can be confirmed Delivered. Current status: ${currentView.status.displayName}.',
        ),
      );
    }

    final now = DateTime.now();
    final trimmedNote = note?.trim() ?? '';
    final prevFulfilment = currentView.fulfilment;

    _sellerSliceOverrides[_sliceKey(orderId, sellerId)] = _SellerOrderSliceState(
      status: MarketplaceOrderStatus.delivered,
      fulfilment: (prevFulfilment ?? const SellerOrderFulfilmentDetails())
          .copyWith(
        deliveredAt: now,
        fulfilmentNote: trimmedNote.isNotEmpty
            ? trimmedNote
            : prevFulfilment?.fulfilmentNote,
      ),
      timeline: [
        OrderStatusStep(
          title: 'Order Delivered',
          description: trimmedNote.isNotEmpty
              ? trimmedNote
              : 'Seller confirmed delivery of their order items.',
          timestamp: now,
          isCompleted: true,
          isCurrent: true,
        ),
        ...currentView.timeline.map(
          (s) => OrderStatusStep(
            title: s.title,
            description: s.description,
            timestamp: s.timestamp,
            isCompleted: s.isCompleted,
            isCurrent: false,
          ),
        ),
      ],
    );

    return getSellerOrderById(
      sellerId: sellerId,
      userId: userId,
      orderId: orderId,
    );
  }
}

class _SellerOrderSliceState {
  final MarketplaceOrderStatus status;
  final List<OrderStatusStep> timeline;
  final String? cancellationReason;
  final SellerOrderFulfilmentDetails? fulfilment;

  const _SellerOrderSliceState({
    required this.status,
    required this.timeline,
    this.cancellationReason,
    this.fulfilment,
  });
}
