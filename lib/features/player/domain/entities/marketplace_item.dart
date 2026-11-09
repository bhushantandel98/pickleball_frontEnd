import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Categories of merchandise available in the Player Marketplace.
enum ProductCategory {
  all('All Categories'),
  paddles('Paddles'),
  balls('Balls'),
  equipment('Equipment'),
  footwear('Footwear'),
  shoes('Shoes'),
  bags('Bags'),
  apparel('Apparel'),
  accessories('Accessories');

  final String displayName;
  const ProductCategory(this.displayName);
}

/// Available sorting options for marketplace browsing.
enum ProductSortOption {
  featured('Featured'),
  priceLow('Price: Low to High'),
  priceHigh('Price: High to Low'),
  priceLowToHigh('Price: Low to High'),
  priceHighToLow('Price: High to Low'),
  ratingHigh('Highest Rated'),
  ratingHighToLow('Highest Rated'),
  newest('Newest Arrivals');

  final String displayName;
  const ProductSortOption(this.displayName);
}

/// Lifecycle statuses for player marketplace orders.
enum MarketplaceOrderStatus {
  placed('Order Placed'),
  processing('Processing'),
  inTransit('In Transit'),
  outForDelivery('Out for Delivery'),
  delivered('Delivered'),
  cancelled('Cancelled');

  final String displayName;
  const MarketplaceOrderStatus(this.displayName);

  bool get isActive =>
      this == MarketplaceOrderStatus.placed ||
      this == MarketplaceOrderStatus.processing ||
      this == MarketplaceOrderStatus.inTransit ||
      this == MarketplaceOrderStatus.outForDelivery;

  bool get isDelivered => this == MarketplaceOrderStatus.delivered;
  bool get isCancelled => this == MarketplaceOrderStatus.cancelled;
}

/// Filter criteria for querying marketplace products.
class ProductFilter extends Equatable {
  final String? query;
  final ProductCategory? category;
  final bool inStockOnly;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final String? brand;
  final ProductSortOption sort;

  const ProductFilter({
    this.query,
    this.category,
    this.inStockOnly = false,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.brand,
    this.sort = ProductSortOption.featured,
  });

  ProductSortOption get sortOption => sort;

  int get activeFilterCount {
    int count = 0;
    if (category != null && category != ProductCategory.all) count++;
    if (inStockOnly) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (minRating != null) count++;
    if (brand != null && brand!.isNotEmpty && brand != 'All Brands') count++;
    return count;
  }

  bool get isFiltered => activeFilterCount > 0 || (query != null && query!.trim().isNotEmpty);

  bool get hasActiveFilters => isFiltered;

  ProductFilter copyWith({
    String? query,
    ProductCategory? category,
    bool? inStockOnly,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? brand,
    ProductSortOption? sort,
    ProductSortOption? sortOption,
    bool clearCategory = false,
    bool clearBrand = false,
  }) {
    return ProductFilter(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      inStockOnly: inStockOnly ?? this.inStockOnly,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      brand: clearBrand ? null : (brand ?? this.brand),
      sort: sortOption ?? sort ?? this.sort,
    );
  }

  @override
  List<Object?> get props => [
        query,
        category,
        inStockOnly,
        minPrice,
        maxPrice,
        minRating,
        brand,
        sort,
      ];
}

/// Product item entity representing merchandise in catalog and details views.
class MarketplaceProduct extends Equatable {
  final String id;
  final String title;
  final String brand;
  final String sellerName;
  final String description;
  final double price;
  final double? originalPrice;
  final double rating;
  final int reviewCount;
  final ProductCategory category;
  final String imageUrl;
  final List<String> galleryImages;
  final bool inStock;
  final int stockCount;
  final int returnPolicyDays;
  final Map<String, String> specifications;
  final List<String> availableSizes;
  final List<String> availableColors;
  final bool isFeatured;
  final bool isWishlisted;

  const MarketplaceProduct({
    required this.id,
    required this.title,
    required this.brand,
    required this.sellerName,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.reviewCount,
    required this.category,
    required this.imageUrl,
    this.galleryImages = const [],
    this.inStock = true,
    required this.stockCount,
    this.returnPolicyDays = 7,
    this.specifications = const {},
    this.availableSizes = const [],
    this.availableColors = const [],
    this.isFeatured = false,
    this.isWishlisted = false,
  });

  String get name => title;
  bool get isInStock => inStock && stockCount > 0;
  bool get isLowStock => inStock && stockCount > 0 && stockCount <= 5;

  bool get hasDiscount =>
      originalPrice != null && originalPrice! > price && price > 0;

  int get discountPercentage {
    if (!hasDiscount) return 0;
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  String get formattedPrice => NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 0,
        locale: 'en_IN',
      ).format(price);

  String? get formattedOriginalPrice => originalPrice != null
      ? NumberFormat.currency(
          symbol: '₹',
          decimalDigits: 0,
          locale: 'en_IN',
        ).format(originalPrice)
      : null;

  MarketplaceProduct copyWith({
    String? id,
    String? title,
    String? brand,
    String? sellerName,
    String? description,
    double? price,
    double? originalPrice,
    double? rating,
    int? reviewCount,
    ProductCategory? category,
    String? imageUrl,
    List<String>? galleryImages,
    bool? inStock,
    int? stockCount,
    int? returnPolicyDays,
    Map<String, String>? specifications,
    List<String>? availableSizes,
    List<String>? availableColors,
    bool? isFeatured,
    bool? isWishlisted,
  }) {
    return MarketplaceProduct(
      id: id ?? this.id,
      title: title ?? this.title,
      brand: brand ?? this.brand,
      sellerName: sellerName ?? this.sellerName,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      inStock: inStock ?? this.inStock,
      stockCount: stockCount ?? this.stockCount,
      returnPolicyDays: returnPolicyDays ?? this.returnPolicyDays,
      specifications: specifications ?? this.specifications,
      availableSizes: availableSizes ?? this.availableSizes,
      availableColors: availableColors ?? this.availableColors,
      isFeatured: isFeatured ?? this.isFeatured,
      isWishlisted: isWishlisted ?? this.isWishlisted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        brand,
        sellerName,
        description,
        price,
        originalPrice,
        rating,
        reviewCount,
        category,
        imageUrl,
        galleryImages,
        inStock,
        stockCount,
        returnPolicyDays,
        specifications,
        availableSizes,
        availableColors,
        isFeatured,
        isWishlisted,
      ];
}

/// Item in the player's active shopping cart.
class MarketplaceCartItem extends Equatable {
  final String id;
  final MarketplaceProduct product;
  final int quantity;
  final String? selectedSize;
  final String? selectedColor;

  const MarketplaceCartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
    this.selectedSize,
    this.selectedColor,
  });

  double get itemTotal => product.price * quantity;
  double get totalPrice => itemTotal;

  String get formattedItemTotal => NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 0,
        locale: 'en_IN',
      ).format(itemTotal);

  MarketplaceCartItem copyWith({
    String? id,
    MarketplaceProduct? product,
    int? quantity,
    String? selectedSize,
    String? selectedColor,
  }) {
    return MarketplaceCartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
    );
  }

  @override
  List<Object?> get props => [
        id,
        product,
        quantity,
        selectedSize,
        selectedColor,
      ];
}

/// Shipping and contact address for placing marketplace orders.
class MarketplaceDeliveryAddress extends Equatable {
  final String fullName;
  final String phoneNumber;
  final String streetAddress;
  final String city;
  final String state;
  final String postalCode;
  final String? landmark;

  const MarketplaceDeliveryAddress({
    required this.fullName,
    required this.phoneNumber,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.postalCode,
    this.landmark,
  });

  String get formattedSummary =>
      '$streetAddress, ${landmark != null && landmark!.isNotEmpty ? '$landmark, ' : ''}$city, $state - $postalCode';

  String get formattedAddress => formattedSummary;

  MarketplaceDeliveryAddress copyWith({
    String? fullName,
    String? phoneNumber,
    String? streetAddress,
    String? city,
    String? state,
    String? postalCode,
    String? landmark,
  }) {
    return MarketplaceDeliveryAddress(
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      landmark: landmark ?? this.landmark,
    );
  }

  @override
  List<Object?> get props => [
        fullName,
        phoneNumber,
        streetAddress,
        city,
        state,
        postalCode,
        landmark,
      ];
}

/// A milestone in an order fulfillment lifecycle.
class OrderStatusStep extends Equatable {
  final String title;
  final String description;
  final DateTime? timestamp;
  final bool isCompleted;
  final bool isCurrent;

  const OrderStatusStep({
    required this.title,
    required this.description,
    this.timestamp,
    this.isCompleted = false,
    this.isCurrent = false,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        timestamp,
        isCompleted,
        isCurrent,
      ];
}

/// Player order record capturing products, pricing breakdown, address, and delivery tracking.
class MarketplaceOrder extends Equatable {
  final String id;
  final DateTime orderDate;
  final List<MarketplaceCartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double tax;
  final double discount;
  final double totalAmount;
  final MarketplaceDeliveryAddress deliveryAddress;
  final String paymentMethod;
  final String paymentStatus;
  final MarketplaceOrderStatus status;
  final String? trackingNumber;
  final DateTime? estimatedDeliveryDate;
  final List<OrderStatusStep> trackingTimeline;
  final String? cancellationReason;

  const MarketplaceOrder({
    required this.id,
    required this.orderDate,
    required this.items,
    required this.subtotal,
    this.deliveryFee = 0.0,
    this.tax = 0.0,
    this.discount = 0.0,
    required this.totalAmount,
    required this.deliveryAddress,
    this.paymentMethod = 'Cash on Delivery (Pay upon Receipt)',
    this.paymentStatus = 'Pending Delivery',
    this.status = MarketplaceOrderStatus.processing,
    this.trackingNumber,
    this.estimatedDeliveryDate,
    this.trackingTimeline = const [],
    this.cancellationReason,
  });

  DateTime get placedAt => orderDate;
  String get referenceId => id;
  List<OrderStatusStep> get trackingSteps => trackingTimeline;
  bool get canCancel =>
      status == MarketplaceOrderStatus.placed ||
      status == MarketplaceOrderStatus.processing;
  bool get canBeCancelled => canCancel;
  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);

  String get formattedTotal => NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 0,
        locale: 'en_IN',
      ).format(totalAmount);

  String get formattedSubtotal => NumberFormat.currency(
        symbol: '₹',
        decimalDigits: 0,
        locale: 'en_IN',
      ).format(subtotal);

  String get formattedDeliveryFee => deliveryFee == 0
      ? 'FREE'
      : NumberFormat.currency(
          symbol: '₹',
          decimalDigits: 0,
          locale: 'en_IN',
        ).format(deliveryFee);

  String get formattedOrderDate =>
      DateFormat('dd MMM yyyy, hh:mm a').format(orderDate);

  String? get formattedEstimatedDate => estimatedDeliveryDate != null
      ? DateFormat('EEEE, dd MMM yyyy').format(estimatedDeliveryDate!)
      : null;

  MarketplaceOrder copyWith({
    String? id,
    DateTime? orderDate,
    List<MarketplaceCartItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? tax,
    double? discount,
    double? totalAmount,
    MarketplaceDeliveryAddress? deliveryAddress,
    String? paymentMethod,
    String? paymentStatus,
    MarketplaceOrderStatus? status,
    String? trackingNumber,
    DateTime? estimatedDeliveryDate,
    List<OrderStatusStep>? trackingTimeline,
    String? cancellationReason,
  }) {
    return MarketplaceOrder(
      id: id ?? this.id,
      orderDate: orderDate ?? this.orderDate,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      status: status ?? this.status,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      estimatedDeliveryDate: estimatedDeliveryDate ?? this.estimatedDeliveryDate,
      trackingTimeline: trackingTimeline ?? this.trackingTimeline,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        orderDate,
        items,
        subtotal,
        deliveryFee,
        tax,
        discount,
        totalAmount,
        deliveryAddress,
        paymentMethod,
        paymentStatus,
        status,
        trackingNumber,
        estimatedDeliveryDate,
        trackingTimeline,
        cancellationReason,
      ];
}
