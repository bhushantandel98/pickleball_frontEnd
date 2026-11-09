import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

/// Contract interface for player marketplace data operations.
abstract class MarketplaceRepository {
  /// Fetches marketplace products matching the optional filter criteria.
  Future<Result<List<MarketplaceProduct>>> getProducts({ProductFilter? filter});

  /// Fetches a specific product by its ID.
  Future<Result<MarketplaceProduct>> getProductById(String id);

  /// Retrieves the player's saved wishlist products.
  Future<Result<List<MarketplaceProduct>>> getWishlist();

  /// Toggles the wishlist status of a product, returning the new wishlisted state.
  Future<Result<bool>> toggleWishlist(String productId);

  /// Retrieves all items currently in the player's shopping cart.
  Future<Result<List<MarketplaceCartItem>>> getCart();

  /// Adds a product to the cart with the given quantity, size, and color.
  Future<Result<List<MarketplaceCartItem>>> addToCart(
    MarketplaceProduct product, {
    int quantity = 1,
    String? size,
    String? color,
  });

  /// Updates the quantity of an existing cart item.
  Future<Result<List<MarketplaceCartItem>>> updateCartQuantity(
    String itemId,
    int quantity,
  );

  /// Removes an item from the cart.
  Future<Result<List<MarketplaceCartItem>>> removeFromCart(String itemId);

  /// Clears all items from the cart.
  Future<Result<void>> clearCart();

  /// Places a new order from current cart items and address.
  Future<Result<MarketplaceOrder>> placeOrder({
    required List<MarketplaceCartItem> items,
    required MarketplaceDeliveryAddress address,
    required String paymentMethod,
    double deliveryFee = 0.0,
    double discount = 0.0,
  });

  /// Retrieves the player's order history.
  Future<Result<List<MarketplaceOrder>>> getMyOrders();

  /// Retrieves a specific order by its ID with full tracking details.
  Future<Result<MarketplaceOrder>> getOrderById(String orderId);

  /// Cancels an active order with a cancellation reason.
  Future<Result<MarketplaceOrder>> cancelOrder(String orderId, String reason);
}
