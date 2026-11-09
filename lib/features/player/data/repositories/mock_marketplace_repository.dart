import 'dart:math';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/marketplace_repository.dart';

/// In-memory mock repository implementing the Player Marketplace operations.
class MockMarketplaceRepository implements MarketplaceRepository {
  final bool shouldFail;
  final bool isEmpty;
  List<MarketplaceProduct>? customProducts;
  List<MarketplaceCartItem>? customCart;
  Set<String>? customWishlistIds;
  List<MarketplaceOrder>? customOrders;

  MockMarketplaceRepository({
    this.shouldFail = false,
    this.isEmpty = false,
    this.customProducts,
    this.customCart,
    this.customWishlistIds,
    this.customOrders,
  });

  static List<MarketplaceProduct> createDefaultProducts() {
    return [
      const MarketplaceProduct(
        id: 'prod_001',
        title: 'Pro Carbon 3K Precision Paddle',
        brand: 'Apex Paddle & Gear Co.',
        sellerName: 'Apex Paddle & Gear Co.',
        description:
            'Engineered for aggressive tournament play, featuring a 3K raw carbon fiber face '
            'and 16mm reactive polymer honeycomb core. Delivers maximum spin, touch, and acoustic pop.',
        price: 11999.0,
        originalPrice: 13499.0,
        rating: 4.8,
        reviewCount: 124,
        category: ProductCategory.paddles,
        imageUrl: 'assets/images/venues/grand_slam_arena.jpg',
        galleryImages: [
          'assets/images/venues/grand_slam_arena.jpg',
          'assets/images/venues/pinnacle_sports.jpg',
        ],
        inStock: true,
        stockCount: 42,
        returnPolicyDays: 14,
        specifications: {
          'Core': '16mm Reactive Polymer Core',
          'Face': 'Toray 3K Raw Carbon Fiber',
          'Weight': '7.9 - 8.2 oz',
          'Grip Size': '4.25 in',
          'USAPA Approved': 'Yes (Tournament Ready)',
        },
        availableColors: ['Matte Black', 'Apex Neon', 'Electric Blue'],
        isFeatured: true,
        isWishlisted: true,
      ),
      const MarketplaceProduct(
        id: 'prod_002',
        title: 'Official Tournament Outdoor Balls (Pack of 6)',
        brand: 'Apex Paddle & Gear Co.',
        sellerName: 'Apex Paddle & Gear Co.',
        description:
            'Rotationally molded 40-hole outdoor pickleballs engineered for true bounce '
            'and crack-resistance in tropical winds and heat.',
        price: 1599.0,
        originalPrice: 1999.0,
        rating: 4.9,
        reviewCount: 342,
        category: ProductCategory.balls,
        imageUrl: 'assets/images/venues/pinnacle_sports.jpg',
        galleryImages: ['assets/images/venues/pinnacle_sports.jpg'],
        inStock: true,
        stockCount: 150,
        returnPolicyDays: 7,
        specifications: {
          'Holes': '40 Precision-Drilled',
          'Material': 'Dura-Flex Polyethylene',
          'Color': 'Optic Yellow',
          'Pack Size': '6 Balls',
        },
        isFeatured: true,
      ),
      const MarketplaceProduct(
        id: 'prod_003',
        title: 'Regulation Portable Heavy-Duty Net System',
        brand: 'Apex Paddle & Gear Co.',
        sellerName: 'Apex Paddle & Gear Co.',
        description:
            'Official 22ft regulation width net with powder-coated steel frame and '
            'heavy-duty nylon carry bag. Sets up in under 5 minutes on any flat surface.',
        price: 14999.0,
        originalPrice: 16500.0,
        rating: 4.7,
        reviewCount: 56,
        category: ProductCategory.equipment,
        imageUrl: 'assets/images/venues/metro_pickleball.jpg',
        galleryImages: ['assets/images/venues/metro_pickleball.jpg'],
        inStock: true,
        stockCount: 18,
        returnPolicyDays: 10,
        specifications: {
          'Length': '22 Feet (Official USAPA)',
          'Center Height': '34 Inches',
          'Frame': 'Powder Coated Steel 1.2mm',
          'Weight': '9.5 kg',
        },
        isFeatured: false,
      ),
      const MarketplaceProduct(
        id: 'prod_004',
        title: 'Court Master Performance Grip Shoes',
        brand: 'Apex Paddle & Gear Co.',
        sellerName: 'Apex Paddle & Gear Co.',
        description:
            'Lateral support shoes with non-marking gum rubber herringbone tread for quick dink stops '
            'and explosive split-step court recovery.',
        price: 8999.0,
        originalPrice: 10499.0,
        rating: 4.5,
        reviewCount: 88,
        category: ProductCategory.footwear,
        imageUrl: 'assets/images/venues/pacific_pickleball.jpg',
        galleryImages: ['assets/images/venues/pacific_pickleball.jpg'],
        inStock: true,
        stockCount: 25,
        returnPolicyDays: 14,
        specifications: {
          'Outsole': 'Non-marking Gum Rubber',
          'Midsole': 'High-rebound EVA Foam',
          'Upper': 'Breathable Engineered Mesh',
        },
        availableSizes: ['UK 7', 'UK 8', 'UK 9', 'UK 10', 'UK 11'],
        availableColors: ['White / Cyan', 'Black / Lime'],
        isFeatured: false,
      ),
      const MarketplaceProduct(
        id: 'prod_005',
        title: 'Heavy-Duty Paddle Edge Guard Tape (3-Pack)',
        brand: 'Apex Paddle & Gear Co.',
        sellerName: 'Apex Paddle & Gear Co.',
        description:
            'Protective lead-compatible vinyl tape to shield paddle edges from court scuffs, scrapes, '
            'and low groundstroke dink impacts.',
        price: 799.0,
        originalPrice: 999.0,
        rating: 4.6,
        reviewCount: 210,
        category: ProductCategory.accessories,
        imageUrl: 'assets/images/venues/dink_smash_zone.jpg',
        galleryImages: ['assets/images/venues/dink_smash_zone.jpg'],
        inStock: true,
        stockCount: 80,
        returnPolicyDays: 7,
        specifications: {
          'Width': '20 mm',
          'Length': '80 cm per roll',
          'Adhesive': 'Residue-free acrylic',
        },
        isWishlisted: true,
      ),
      const MarketplaceProduct(
        id: 'prod_006',
        title: 'Pro Tour Pickleball Backpack with Thermal Pocket',
        brand: 'Apex Paddle & Gear Co.',
        sellerName: 'Apex Paddle & Gear Co.',
        description:
            'Compartmentalized bag holding up to 4 paddles with climate-protective thermal lining, '
            'ventilated shoe compartment, and fence hook.',
        price: 4499.0,
        originalPrice: 5299.0,
        rating: 4.8,
        reviewCount: 95,
        category: ProductCategory.equipment,
        imageUrl: 'assets/images/venues/sunrise_pickleball.jpg',
        galleryImages: ['assets/images/venues/sunrise_pickleball.jpg'],
        inStock: true,
        stockCount: 30,
        returnPolicyDays: 14,
        specifications: {
          'Capacity': '35 Litres',
          'Paddle Slot': 'Up to 4 Paddles',
          'Shoe Pocket': 'Isolated Ventilated',
        },
        availableColors: ['Graphite / Orange', 'All Black Stealth'],
      ),
      const MarketplaceProduct(
        id: 'prod_007',
        title: 'Hyper-Spin Raw Carbon Control Paddle',
        brand: 'Selkirk Sport Elite',
        sellerName: 'Apex Paddle & Gear Co.',
        description:
            'Designed for precision dink placement and reset drops. Features a T700 raw carbon '
            'grit surface providing maximum friction for cut serves and top-spin drives.',
        price: 13500.0,
        originalPrice: 15000.0,
        rating: 4.9,
        reviewCount: 180,
        category: ProductCategory.paddles,
        imageUrl: 'assets/images/venues/ace_point_arena.jpg',
        galleryImages: ['assets/images/venues/ace_point_arena.jpg'],
        inStock: true,
        stockCount: 12,
        returnPolicyDays: 14,
        specifications: {
          'Face': 'T700 Unidirectional Carbon Fiber',
          'Core': 'Polymer Honeycomb 14mm',
          'Weight': '8.0 oz',
        },
        isFeatured: true,
      ),
      const MarketplaceProduct(
        id: 'prod_008',
        title: 'Dri-Fit Tournament Performance Jersey',
        brand: 'Apex Paddle & Gear Co.',
        sellerName: 'Apex Paddle & Gear Co.',
        description:
            'Ultra-lightweight moisture-wicking jersey with 4-way stretch fabric designed '
            'for maximum mobility during long summer tournament matches.',
        price: 1999.0,
        originalPrice: 2499.0,
        rating: 4.4,
        reviewCount: 64,
        category: ProductCategory.apparel,
        imageUrl: 'assets/images/venues/grand_slam_arena.jpg',
        galleryImages: ['assets/images/venues/grand_slam_arena.jpg'],
        inStock: true,
        stockCount: 50,
        returnPolicyDays: 7,
        availableSizes: ['S', 'M', 'L', 'XL', 'XXL'],
        availableColors: ['Navy Blue', 'Forest Green', 'Crimson Red'],
      ),
    ];
  }

  static List<MarketplaceCartItem> createDefaultCart() {
    final products = createDefaultProducts();
    return [
      MarketplaceCartItem(
        id: 'cart_item_001',
        product: products[1], // Official Tournament Outdoor Balls
        quantity: 2,
      ),
    ];
  }

  static List<MarketplaceOrder> createDefaultOrders() {
    final products = createDefaultProducts();
    const defaultAddress = MarketplaceDeliveryAddress(
      fullName: 'Alex Rivera',
      phoneNumber: '+91 98765 43210',
      streetAddress: 'Flat 402, Sea View Apartments, Worli Sea Face',
      city: 'Mumbai',
      state: 'Maharashtra',
      postalCode: '400018',
      landmark: 'Near Worli Dairy',
    );

    return [
      MarketplaceOrder(
        id: 'PKL-ORD-20261025-1092',
        orderDate: DateTime(2026, 10, 25, 14, 30),
        items: [
          MarketplaceCartItem(
            id: 'ord_item_1',
            product: products[0], // Pro Carbon 3K Precision Paddle
            quantity: 1,
            selectedColor: 'Matte Black',
          ),
          MarketplaceCartItem(
            id: 'ord_item_2',
            product: products[4], // Paddle Edge Guard Tape
            quantity: 1,
          ),
        ],
        subtotal: 12798.0,
        deliveryFee: 0.0,
        totalAmount: 12798.0,
        deliveryAddress: defaultAddress,
        paymentMethod: 'Cash on Delivery',
        paymentStatus: 'Paid on Delivery',
        status: MarketplaceOrderStatus.delivered,
        trackingNumber: 'TRACK-9812-IN',
        estimatedDeliveryDate: DateTime(2026, 10, 28),
        trackingTimeline: [
          OrderStatusStep(
            title: 'Order Delivered',
            description: 'Package handed over at delivery address.',
            timestamp: DateTime(2026, 10, 28, 16, 45),
            isCompleted: true,
            isCurrent: true,
          ),
          OrderStatusStep(
            title: 'Out for Delivery',
            description: 'Courier executive out for delivery.',
            timestamp: DateTime(2026, 10, 28, 10, 15),
            isCompleted: true,
          ),
          OrderStatusStep(
            title: 'In Transit',
            description: 'Arrived at Mumbai Central Delivery Hub.',
            timestamp: DateTime(2026, 10, 26, 18, 30),
            isCompleted: true,
          ),
          OrderStatusStep(
            title: 'Order Placed & Confirmed',
            description: 'Seller Apex Paddle & Gear confirmed the order.',
            timestamp: DateTime(2026, 10, 25, 14, 30),
            isCompleted: true,
          ),
        ],
      ),
      MarketplaceOrder(
        id: 'PKL-ORD-20261030-1095',
        orderDate: DateTime(2026, 10, 30, 11, 15),
        items: [
          MarketplaceCartItem(
            id: 'ord_item_3',
            product: products[2], // Regulation Portable Net
            quantity: 1,
          ),
        ],
        subtotal: 14999.0,
        deliveryFee: 0.0,
        totalAmount: 14999.0,
        deliveryAddress: defaultAddress,
        paymentMethod: 'UPI / Card upon Delivery',
        paymentStatus: 'Pending Delivery',
        status: MarketplaceOrderStatus.inTransit,
        trackingNumber: 'TRACK-9854-IN',
        estimatedDeliveryDate: DateTime(2026, 11, 11),
        trackingTimeline: [
          OrderStatusStep(
            title: 'In Transit',
            description: 'Dispatched from seller fulfillment warehouse.',
            timestamp: DateTime(2026, 10, 31, 14, 00),
            isCompleted: true,
            isCurrent: true,
          ),
          OrderStatusStep(
            title: 'Processing',
            description: 'Item packed and quality checked.',
            timestamp: DateTime(2026, 10, 30, 17, 30),
            isCompleted: true,
          ),
          OrderStatusStep(
            title: 'Order Placed',
            description: 'Order received and verified.',
            timestamp: DateTime(2026, 10, 30, 11, 15),
            isCompleted: true,
          ),
        ],
      ),
      MarketplaceOrder(
        id: 'PKL-ORD-20261102-1098',
        orderDate: DateTime(2026, 11, 2, 19, 05),
        items: [
          MarketplaceCartItem(
            id: 'ord_item_4',
            product: products[1], // Balls 6-pack
            quantity: 1,
          ),
        ],
        subtotal: 1599.0,
        deliveryFee: 150.0,
        totalAmount: 1749.0,
        deliveryAddress: defaultAddress,
        paymentMethod: 'Cash on Delivery',
        paymentStatus: 'Pending Delivery',
        status: MarketplaceOrderStatus.processing,
        estimatedDeliveryDate: DateTime(2026, 11, 13),
        trackingTimeline: [
          OrderStatusStep(
            title: 'Processing',
            description: 'Order confirmed. Seller preparing dispatch.',
            timestamp: DateTime(2026, 11, 3, 10, 00),
            isCompleted: true,
            isCurrent: true,
          ),
          OrderStatusStep(
            title: 'Order Placed',
            description: 'Order verified by platform.',
            timestamp: DateTime(2026, 11, 2, 19, 05),
            isCompleted: true,
          ),
        ],
      ),
    ];
  }

  void _initCustomData() {
    customProducts ??= createDefaultProducts();
    customCart ??= createDefaultCart();
    customWishlistIds ??= {'prod_001', 'prod_005'};
    customOrders ??= createDefaultOrders();
  }

  @override
  Future<Result<List<MarketplaceProduct>>> getProducts({
    ProductFilter? filter,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to load marketplace products catalogue.'),
      );
    }
    if (isEmpty) {
      return const Success([]);
    }

    _initCustomData();

    var result = List<MarketplaceProduct>.from(customProducts!);

    // Sync wishlist state
    result = result.map((p) {
      final isWish = customWishlistIds!.contains(p.id);
      return p.copyWith(isWishlisted: isWish);
    }).toList();

    if (filter != null) {
      // Query filter
      if (filter.query != null && filter.query!.trim().isNotEmpty) {
        final q = filter.query!.toLowerCase().trim();
        result = result.where((p) {
          return p.title.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q) ||
              p.category.displayName.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q);
        }).toList();
      }

      // Category filter
      if (filter.category != null) {
        result = result.where((p) => p.category == filter.category).toList();
      }

      // In stock only
      if (filter.inStockOnly) {
        result = result.where((p) => p.inStock && p.stockCount > 0).toList();
      }

      // Price range
      if (filter.minPrice != null) {
        result = result.where((p) => p.price >= filter.minPrice!).toList();
      }
      if (filter.maxPrice != null) {
        result = result.where((p) => p.price <= filter.maxPrice!).toList();
      }

      // Rating
      if (filter.minRating != null) {
        result = result.where((p) => p.rating >= filter.minRating!).toList();
      }

      // Sorting
      switch (filter.sort) {
        case ProductSortOption.featured:
          result.sort((a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0));
          break;
        case ProductSortOption.priceLow:
        case ProductSortOption.priceLowToHigh:
          result.sort((a, b) => a.price.compareTo(b.price));
          break;
        case ProductSortOption.priceHigh:
        case ProductSortOption.priceHighToLow:
          result.sort((a, b) => b.price.compareTo(a.price));
          break;
        case ProductSortOption.ratingHigh:
        case ProductSortOption.ratingHighToLow:
          result.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case ProductSortOption.newest:
          result.sort((a, b) => b.id.compareTo(a.id));
          break;
      }
    }

    return Success(result);
  }

  @override
  Future<Result<MarketplaceProduct>> getProductById(String id) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to retrieve product details.'),
      );
    }

    _initCustomData();

    final product = customProducts!.firstWhere(
      (p) => p.id == id,
      orElse: () => const MarketplaceProduct(
        id: '',
        title: '',
        brand: '',
        sellerName: '',
        description: '',
        price: 0,
        rating: 0,
        reviewCount: 0,
        category: ProductCategory.paddles,
        imageUrl: '',
        stockCount: 0,
      ),
    );

    if (product.id.isEmpty) {
      return const FailureResult(
        NotFoundFailure(message: 'Product not found in marketplace catalog.'),
      );
    }

    final isWish = customWishlistIds!.contains(product.id);
    return Success(product.copyWith(isWishlisted: isWish));
  }

  @override
  Future<Result<List<MarketplaceProduct>>> getWishlist() async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to retrieve your wishlist.'),
      );
    }
    if (isEmpty) {
      return const Success([]);
    }

    _initCustomData();

    final wishlist = customProducts!
        .where((p) => customWishlistIds!.contains(p.id))
        .map((p) => p.copyWith(isWishlisted: true))
        .toList();

    return Success(wishlist);
  }

  @override
  Future<Result<bool>> toggleWishlist(String productId) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to update wishlist state.'),
      );
    }

    _initCustomData();

    final isPresent = customWishlistIds!.contains(productId);
    if (isPresent) {
      customWishlistIds!.remove(productId);
      return const Success(false);
    } else {
      customWishlistIds!.add(productId);
      return const Success(true);
    }
  }

  @override
  Future<Result<List<MarketplaceCartItem>>> getCart() async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to load shopping cart.'),
      );
    }
    if (isEmpty) {
      return const Success([]);
    }

    _initCustomData();
    return Success(List<MarketplaceCartItem>.from(customCart!));
  }

  @override
  Future<Result<List<MarketplaceCartItem>>> addToCart(
    MarketplaceProduct product, {
    int quantity = 1,
    String? size,
    String? color,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to add product to cart.'),
      );
    }

    _initCustomData();

    final existingIndex = customCart!.indexWhere(
      (item) =>
          item.product.id == product.id &&
          item.selectedSize == size &&
          item.selectedColor == color,
    );

    if (existingIndex != -1) {
      final existing = customCart![existingIndex];
      customCart![existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      final newItem = MarketplaceCartItem(
        id: 'cart_item_${DateTime.now().millisecondsSinceEpoch}',
        product: product,
        quantity: quantity,
        selectedSize: size,
        selectedColor: color,
      );
      customCart!.add(newItem);
    }

    return Success(List<MarketplaceCartItem>.from(customCart!));
  }

  @override
  Future<Result<List<MarketplaceCartItem>>> updateCartQuantity(
    String itemId,
    int quantity,
  ) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to update item quantity in cart.'),
      );
    }

    _initCustomData();

    final index = customCart!.indexWhere((i) => i.id == itemId);
    if (index == -1) {
      return const FailureResult(
        NotFoundFailure(message: 'Cart item not found.'),
      );
    }

    if (quantity <= 0) {
      customCart!.removeAt(index);
    } else {
      customCart![index] = customCart![index].copyWith(quantity: quantity);
    }

    return Success(List<MarketplaceCartItem>.from(customCart!));
  }

  @override
  Future<Result<List<MarketplaceCartItem>>> removeFromCart(String itemId) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to remove item from cart.'),
      );
    }

    _initCustomData();
    customCart!.removeWhere((i) => i.id == itemId);
    return Success(List<MarketplaceCartItem>.from(customCart!));
  }

  @override
  Future<Result<void>> clearCart() async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to clear shopping cart.'),
      );
    }

    _initCustomData();
    customCart!.clear();
    return const Success(null);
  }

  static String generateOrderReference() {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    final rand = Random().nextInt(9000) + 1000;
    return 'PKL-ORD-$dateStr-$rand';
  }

  @override
  Future<Result<MarketplaceOrder>> placeOrder({
    required List<MarketplaceCartItem> items,
    required MarketplaceDeliveryAddress address,
    required String paymentMethod,
    double deliveryFee = 0.0,
    double discount = 0.0,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to place marketplace order.'),
      );
    }

    if (items.isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Shopping cart is empty. Add products to place an order.'),
      );
    }

    if (address.fullName.trim().isEmpty ||
        address.phoneNumber.trim().isEmpty ||
        address.streetAddress.trim().isEmpty ||
        address.city.trim().isEmpty ||
        address.postalCode.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Please complete all required delivery address fields.'),
      );
    }

    _initCustomData();

    final subtotal = items.fold<double>(
      0.0,
      (acc, item) => acc + item.itemTotal,
    );
    final total = (subtotal + deliveryFee - discount).clamp(0.0, 999999.0);

    final now = DateTime.now();
    final estimatedDelivery = now.add(const Duration(days: 4));

    final order = MarketplaceOrder(
      id: generateOrderReference(),
      orderDate: now,
      items: List<MarketplaceCartItem>.from(items),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      totalAmount: total,
      deliveryAddress: address,
      paymentMethod: paymentMethod,
      paymentStatus: 'Pending Delivery',
      status: MarketplaceOrderStatus.placed,
      estimatedDeliveryDate: estimatedDelivery,
      trackingTimeline: [
        OrderStatusStep(
          title: 'Order Placed',
          description: 'Your order has been recorded and will be prepared by the seller.',
          timestamp: now,
          isCompleted: true,
          isCurrent: true,
        ),
      ],
    );

    customOrders!.insert(0, order);
    customCart!.clear();

    return Success(order);
  }

  @override
  Future<Result<List<MarketplaceOrder>>> getMyOrders() async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to retrieve your order history.'),
      );
    }
    if (isEmpty) {
      return const Success([]);
    }

    _initCustomData();
    return Success(List<MarketplaceOrder>.from(customOrders!));
  }

  @override
  Future<Result<MarketplaceOrder>> getOrderById(String orderId) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to retrieve order details.'),
      );
    }

    _initCustomData();

    final order = customOrders!.firstWhere(
      (o) => o.id == orderId,
      orElse: () => MarketplaceOrder(
        id: '',
        orderDate: DateTime.now(),
        items: const [],
        subtotal: 0,
        totalAmount: 0,
        deliveryAddress: const MarketplaceDeliveryAddress(
          fullName: '',
          phoneNumber: '',
          streetAddress: '',
          city: '',
          state: '',
          postalCode: '',
        ),
        estimatedDeliveryDate: DateTime.now(),
      ),
    );

    if (order.id.isEmpty) {
      return const FailureResult(
        NotFoundFailure(message: 'Order record not found.'),
      );
    }

    return Success(order);
  }

  @override
  Future<Result<MarketplaceOrder>> cancelOrder(
    String orderId,
    String reason,
  ) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Failed to cancel order.'),
      );
    }

    _initCustomData();

    final index = customOrders!.indexWhere((o) => o.id == orderId);
    if (index == -1) {
      return const FailureResult(
        NotFoundFailure(message: 'Order record not found.'),
      );
    }

    final currentOrder = customOrders![index];
    if (!currentOrder.canCancel) {
      return const FailureResult(
        ValidationFailure(
          message: 'This order is already in transit or delivered and cannot be cancelled.',
        ),
      );
    }

    final updatedTimeline = List<OrderStatusStep>.from(currentOrder.trackingTimeline)
      ..insert(
        0,
        OrderStatusStep(
          title: 'Order Cancelled',
          description: 'Cancelled by player. Reason: $reason',
          timestamp: DateTime.now(),
          isCompleted: true,
          isCurrent: true,
        ),
      );

    final updatedOrder = currentOrder.copyWith(
      status: MarketplaceOrderStatus.cancelled,
      paymentStatus: 'Cancelled / No Charge',
      cancellationReason: reason,
      trackingTimeline: updatedTimeline,
    );

    customOrders![index] = updatedOrder;
    return Success(updatedOrder);
  }
}
