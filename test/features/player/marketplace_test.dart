import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_marketplace_repository.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_cart_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_cart_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_catalogue_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_catalogue_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_checkout_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_checkout_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_orders_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_orders_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_wishlist_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_wishlist_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/product_details_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/product_details_state.dart';
import 'package:pickleball_platform/features/player/presentation/pages/marketplace_cart_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/marketplace_catalogue_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/marketplace_orders_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/product_details_page.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/cart_item_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/order_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/order_status_timeline.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/product_card.dart';

void setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  setUp(() async {
    sl.reset();
    await initServiceLocator();
  });

  tearDown(() {
    sl.reset();
  });

  group('MockMarketplaceRepository Unit Tests', () {
    test('getProducts returns pre-seeded default catalog', () async {
      final repo = MockMarketplaceRepository();
      final result = await repo.getProducts();

      expect(result, isA<Success<List<MarketplaceProduct>>>());
      final products = (result as Success<List<MarketplaceProduct>>).data;
      expect(products.length, greaterThanOrEqualTo(5));
      expect(products.any((p) => p.id == 'prod_001'), isTrue);
      expect(products.any((p) => p.category == ProductCategory.paddles), isTrue);
    });

    test('getProducts applies text search query', () async {
      final repo = MockMarketplaceRepository();
      final result = await repo.getProducts(
        filter: const ProductFilter(query: 'Selkirk'),
      );

      expect(result, isA<Success<List<MarketplaceProduct>>>());
      final products = (result as Success<List<MarketplaceProduct>>).data;
      expect(products.isNotEmpty, isTrue);
      for (final p in products) {
        expect(
          p.title.toLowerCase().contains('selkirk') ||
              p.brand.toLowerCase().contains('selkirk') ||
              p.description.toLowerCase().contains('selkirk'),
          isTrue,
        );
      }
    });

    test('getProducts filters by category and in-stock flag', () async {
      final repo = MockMarketplaceRepository();
      final result = await repo.getProducts(
        filter: const ProductFilter(
          category: ProductCategory.balls,
          inStockOnly: true,
        ),
      );

      expect(result, isA<Success<List<MarketplaceProduct>>>());
      final products = (result as Success<List<MarketplaceProduct>>).data;
      for (final p in products) {
        expect(p.category, equals(ProductCategory.balls));
        expect(p.inStock, isTrue);
      }
    });

    test('getProducts sorting by priceLow', () async {
      final repo = MockMarketplaceRepository();
      final result = await repo.getProducts(
        filter: const ProductFilter(sort: ProductSortOption.priceLow),
      );

      expect(result, isA<Success<List<MarketplaceProduct>>>());
      final products = (result as Success<List<MarketplaceProduct>>).data;
      for (int i = 0; i < products.length - 1; i++) {
        expect(products[i].price, lessThanOrEqualTo(products[i + 1].price));
      }
    });

    test('getProductById retrieves correct item or returns NotFoundFailure', () async {
      final repo = MockMarketplaceRepository();
      final successResult = await repo.getProductById('prod_001');
      expect(successResult, isA<Success<MarketplaceProduct>>());
      expect((successResult as Success<MarketplaceProduct>).data.id, equals('prod_001'));

      final failResult = await repo.getProductById('invalid_id_999');
      expect(failResult, isA<FailureResult<MarketplaceProduct>>());
      expect((failResult as FailureResult).failure, isA<NotFoundFailure>());
    });

    test('toggleWishlist updates wishlist set correctly', () async {
      final repo = MockMarketplaceRepository();

      final firstToggle = await repo.toggleWishlist('prod_002');
      expect(firstToggle, isA<Success<bool>>());
      final isAdded = (firstToggle as Success<bool>).data;
      expect(isAdded, isTrue);

      final secondToggle = await repo.toggleWishlist('prod_002');
      expect(secondToggle, isA<Success<bool>>());
      final isRemoved = (secondToggle as Success<bool>).data;
      expect(isRemoved, isFalse);
    });

    test('cart operations: add, update quantity, remove, and clear', () async {
      final repo = MockMarketplaceRepository();

      final product = (await repo.getProductById('prod_001') as Success<MarketplaceProduct>).data;
      final addResult = await repo.addToCart(product, quantity: 2);
      expect(addResult, isA<Success<List<MarketplaceCartItem>>>());
      final cart = (addResult as Success<List<MarketplaceCartItem>>).data;
      expect(cart.any((item) => item.product.id == 'prod_001'), isTrue);

      final cartItemId = cart.firstWhere((item) => item.product.id == 'prod_001').id;
      final updateResult = await repo.updateCartQuantity(cartItemId, 4);
      final updatedCart = (updateResult as Success<List<MarketplaceCartItem>>).data;
      expect(updatedCart.firstWhere((item) => item.id == cartItemId).quantity, equals(4));

      final removeResult = await repo.removeFromCart(cartItemId);
      final afterRemove = (removeResult as Success<List<MarketplaceCartItem>>).data;
      expect(afterRemove.any((item) => item.id == cartItemId), isFalse);

      final clearResult = await repo.clearCart();
      expect(clearResult, isA<Success<void>>());
      final emptyCart = (await repo.getCart() as Success<List<MarketplaceCartItem>>).data;
      expect(emptyCart.isEmpty, isTrue);
    });

    test('addToCart rejects non-positive quantities with ValidationFailure', () async {
      final repo = MockMarketplaceRepository();
      final product = (await repo.getProductById('prod_001') as Success<MarketplaceProduct>).data;

      final zeroResult = await repo.addToCart(product, quantity: 0);
      expect(zeroResult, isA<FailureResult<List<MarketplaceCartItem>>>());
      final zeroFailure = (zeroResult as FailureResult).failure;
      expect(zeroFailure, isA<ValidationFailure>());
      expect(zeroFailure.message, contains('Quantity must be at least 1'));

      final negativeResult = await repo.addToCart(product, quantity: -2);
      expect(negativeResult, isA<FailureResult<List<MarketplaceCartItem>>>());
      expect((negativeResult as FailureResult).failure, isA<ValidationFailure>());
    });

    test('addToCart rejects additions exceeding available stock with ValidationFailure', () async {
      final repo = MockMarketplaceRepository();
      final product = (await repo.getProductById('prod_007') as Success<MarketplaceProduct>).data;
      expect(product.stockCount, equals(12));

      // Attempt adding more than stock count
      final result = await repo.addToCart(product, quantity: 15);
      expect(result, isA<FailureResult<List<MarketplaceCartItem>>>());
      final failure = (result as FailureResult).failure;
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, contains('Exceeds available stock of 12'));

      // Add valid quantity (10)
      final validAdd = await repo.addToCart(product, quantity: 10);
      expect(validAdd, isA<Success<List<MarketplaceCartItem>>>());

      // Subsequent add that pushes total over available stock (10 + 5 = 15 > 12)
      final secondAdd = await repo.addToCart(product, quantity: 5);
      expect(secondAdd, isA<FailureResult<List<MarketplaceCartItem>>>());
      final secondFailure = (secondAdd as FailureResult).failure;
      expect(secondFailure, isA<ValidationFailure>());
      expect(secondFailure.message, contains('Exceeds available stock of 12'));

      // Ensure existing quantity in cart remains 10
      final cart = (await repo.getCart() as Success<List<MarketplaceCartItem>>).data;
      final item = cart.firstWhere((i) => i.product.id == 'prod_007');
      expect(item.quantity, equals(10));
    });

    test('updateCartQuantity rejects quantities exceeding available stock and preserves cart', () async {
      final repo = MockMarketplaceRepository();
      final product = (await repo.getProductById('prod_007') as Success<MarketplaceProduct>).data;

      final addResult = await repo.addToCart(product, quantity: 5);
      final cart = (addResult as Success<List<MarketplaceCartItem>>).data;
      final cartItem = cart.firstWhere((i) => i.product.id == 'prod_007');
      expect(cartItem.quantity, equals(5));

      // Attempt to update quantity to 25 (exceeds 12)
      final updateResult = await repo.updateCartQuantity(cartItem.id, 25);
      expect(updateResult, isA<FailureResult<List<MarketplaceCartItem>>>());
      final failure = (updateResult as FailureResult).failure;
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, contains('Only 12 item(s) available in stock'));

      // Verify that existing cart quantity remains unchanged at 5
      final cartAfter = (await repo.getCart() as Success<List<MarketplaceCartItem>>).data;
      final itemAfter = cartAfter.firstWhere((i) => i.id == cartItem.id);
      expect(itemAfter.quantity, equals(5));
    });

    test('order operations: place order, get orders, and cancel eligible order', () async {
      final repo = MockMarketplaceRepository();
      const address = MarketplaceDeliveryAddress(
        fullName: 'Test Player',
        phoneNumber: '9876543210',
        streetAddress: '123 Court Lane',
        city: 'Mumbai',
        state: 'Maharashtra',
        postalCode: '400001',
      );

      final product = (await repo.getProductById('prod_001') as Success<MarketplaceProduct>).data;
      final orderResult = await repo.placeOrder(
        items: [MarketplaceCartItem(id: 'c_test', product: product, quantity: 1)],
        address: address,
        paymentMethod: 'Pay upon Receipt (UPI / Cash)',
      );

      expect(orderResult, isA<Success<MarketplaceOrder>>());
      final placedOrder = (orderResult as Success<MarketplaceOrder>).data;
      expect(placedOrder.id, startsWith('PKL-ORD-'));
      expect(placedOrder.canCancel, isTrue);

      // Cancel placed order
      final cancelResult = await repo.cancelOrder(placedOrder.id, 'Ordered wrong item');
      expect(cancelResult, isA<Success<MarketplaceOrder>>());
      final cancelledOrder = (cancelResult as Success<MarketplaceOrder>).data;
      expect(cancelledOrder.status, equals(MarketplaceOrderStatus.cancelled));
      expect(cancelledOrder.cancellationReason, equals('Ordered wrong item'));
    });

    test('error harness: shouldFail returns FailureResult', () async {
      final failRepo = MockMarketplaceRepository(shouldFail: true);
      final result = await failRepo.getProducts();
      expect(result, isA<FailureResult<List<MarketplaceProduct>>>());
      expect((result as FailureResult).failure, isA<ServerFailure>());
    });
  });

  group('Marketplace Cubits Unit Tests', () {
    test('MarketplaceCatalogueCubit loads catalogue and toggles filters', () async {
      final repo = MockMarketplaceRepository();
      final cubit = MarketplaceCatalogueCubit(repo);

      await cubit.loadCatalogue();
      expect(cubit.state, isA<MarketplaceCatalogueLoaded>());
      final loaded = cubit.state as MarketplaceCatalogueLoaded;
      expect(loaded.products.isNotEmpty, isTrue);

      cubit.updateCategory(ProductCategory.balls);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state, isA<MarketplaceCatalogueLoaded>());

      cubit.resetFilter();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.currentFilter.category, isNull);
    });

    test('ProductDetailsCubit manages quantity and selections', () async {
      final repo = MockMarketplaceRepository();
      final cubit = ProductDetailsCubit(repository: repo, productId: 'prod_001');

      await cubit.loadProduct();
      expect(cubit.state, isA<ProductDetailsLoaded>());
      final loaded = cubit.state as ProductDetailsLoaded;
      expect(loaded.product.id, equals('prod_001'));
      expect(loaded.selectedQuantity, equals(1));

      cubit.incrementQuantity();
      expect((cubit.state as ProductDetailsLoaded).selectedQuantity, equals(2));

      cubit.decrementQuantity();
      expect((cubit.state as ProductDetailsLoaded).selectedQuantity, equals(1));

      final added = await cubit.addToCart();
      expect(added, isTrue);
    });

    test('MarketplaceCartCubit calculates delivery fee thresholds', () async {
      final repo = MockMarketplaceRepository();
      final cubit = MarketplaceCartCubit(repo);

      await cubit.loadCart();
      expect(cubit.state, isA<MarketplaceCartLoaded>());
      final loaded = cubit.state as MarketplaceCartLoaded;

      // Threshold ₹999 check
      if (loaded.subtotal >= 999) {
        expect(loaded.qualifiesForFreeDelivery, isTrue);
        expect(loaded.deliveryFee, equals(0.0));
      } else {
        expect(loaded.qualifiesForFreeDelivery, isFalse);
        expect(loaded.deliveryFee, equals(99.0));
      }
    });

    test('MarketplaceCartCubit updateQuantity retains items and sets notice when exceeding stock', () async {
      final repo = MockMarketplaceRepository();
      final cubit = MarketplaceCartCubit(repo);

      await cubit.loadCart();
      expect(cubit.state, isA<MarketplaceCartLoaded>());
      final initialLoaded = cubit.state as MarketplaceCartLoaded;
      final initialItem = initialLoaded.items.first;
      final originalQuantity = initialItem.quantity;

      // Update with an impossibly high quantity
      await cubit.updateQuantity(initialItem.id, 99999);
      expect(cubit.state, isA<MarketplaceCartLoaded>());
      final afterState = cubit.state as MarketplaceCartLoaded;

      // Quantity must remain unchanged
      expect(afterState.items.first.quantity, equals(originalQuantity));
      expect(afterState.userNotice, isNotNull);
      expect(afterState.userNotice, contains('available in stock'));
    });

    test('MarketplaceWishlistCubit loads wishlist, removes and moves to cart', () async {
      final repo = MockMarketplaceRepository();
      final cubit = MarketplaceWishlistCubit(repo);

      await cubit.loadWishlist();
      expect(cubit.state, isA<MarketplaceWishlistLoaded>());
      final initialItems = (cubit.state as MarketplaceWishlistLoaded).items;

      if (initialItems.isNotEmpty) {
        final firstProduct = initialItems.first;
        await cubit.moveToCart(firstProduct);
        expect((cubit.state as MarketplaceWishlistLoaded).items.any((p) => p.id == firstProduct.id), isFalse);
      }
    });

    test('MarketplaceCheckoutCubit validates required fields', () async {
      final repo = MockMarketplaceRepository();
      final cubit = MarketplaceCheckoutCubit(repository: repo);

      await cubit.initializeCheckout();
      expect(cubit.state, isA<MarketplaceCheckoutReady>());

      // Empty name triggers validation failure
      cubit.updateFullName('');
      final success = await cubit.submitOrder();
      expect(success, isFalse);
      expect((cubit.state as MarketplaceCheckoutReady).fieldErrors.containsKey('fullName'), isTrue);

      // Fix name and valid phone
      cubit.updateFullName('Rahul Verma');
      cubit.updatePhoneNumber('9876543210');
      cubit.updatePostalCode('560001');
      final validSubmit = await cubit.submitOrder();
      expect(validSubmit, isTrue);
      expect(cubit.state, isA<MarketplaceCheckoutSuccess>());
    });

    test('MarketplaceOrdersCubit filters by status', () async {
      final repo = MockMarketplaceRepository();
      final cubit = MarketplaceOrdersCubit(repo);

      await cubit.loadOrders();
      expect(cubit.state, isA<MarketplaceOrdersLoaded>());

      cubit.filterByStatus(MarketplaceOrderStatus.delivered);
      final delivered = (cubit.state as MarketplaceOrdersLoaded).filteredOrders;
      for (final o in delivered) {
        expect(o.status, equals(MarketplaceOrderStatus.delivered));
      }

      cubit.filterByStatus(null);
      expect((cubit.state as MarketplaceOrdersLoaded).filterStatus, isNull);
    });

    test('MarketplaceOrderDetailsCubit loads details and cancels order', () async {
      final repo = MockMarketplaceRepository();
      final orders = (await repo.getMyOrders() as Success<List<MarketplaceOrder>>).data;
      final cancellable = orders.firstWhere((o) => o.canCancel);

      final cubit = MarketplaceOrderDetailsCubit(repository: repo, orderId: cancellable.id);
      await cubit.loadOrderDetails();
      expect(cubit.state, isA<MarketplaceOrderDetailsLoaded>());

      final cancelled = await cubit.cancelOrder('Change of mind');
      expect(cancelled, isTrue);
      expect((cubit.state as MarketplaceOrderDetailsLoaded).order.status, equals(MarketplaceOrderStatus.cancelled));
    });
  });

  group('Marketplace Widget Tests', () {
    testWidgets('ProductCard displays product details and triggers callbacks', (tester) async {
      const product = MarketplaceProduct(
        id: 'p_test',
        title: 'Pro Carbon Paddle',
        brand: 'Selkirk',
        sellerName: 'Apex Sports',
        description: 'Elite tournament paddle',
        price: 7999,
        originalPrice: 9999,
        rating: 4.8,
        reviewCount: 42,
        category: ProductCategory.paddles,
        imageUrl: '',
        stockCount: 10,
      );

      bool tapped = false;
      bool wishlistToggled = false;
      bool cartAdded = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                height: 380,
                child: ProductCard(
                  product: product,
                  isWishlisted: false,
                  onTap: () => tapped = true,
                  onToggleWishlist: () => wishlistToggled = true,
                  onAddToCart: () => cartAdded = true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Pro Carbon Paddle'), findsOneWidget);
      expect(find.text('SELKIRK'), findsOneWidget);
      expect(find.text('₹7,999'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('(42)'), findsOneWidget);

      await tester.tap(find.byType(ProductCard));
      expect(tapped, isTrue);

      await tester.tap(find.byIcon(Icons.favorite_border));
      expect(wishlistToggled, isTrue);

      await tester.tap(find.byIcon(Icons.add_shopping_cart));
      expect(cartAdded, isTrue);
    });

    testWidgets('CartItemCard displays product, total, and handles quantity change', (tester) async {
      const product = MarketplaceProduct(
        id: 'p_cart',
        title: 'Performance Court Shoes',
        brand: 'Head',
        sellerName: 'Apex Sports',
        description: 'Shoes',
        price: 3500,
        rating: 4.5,
        reviewCount: 12,
        category: ProductCategory.footwear,
        imageUrl: '',
        stockCount: 15,
      );

      const cartItem = MarketplaceCartItem(
        id: 'c_item_1',
        product: product,
        quantity: 2,
        selectedSize: 'UK 9',
      );

      int? newQty;
      bool removed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CartItemCard(
              item: cartItem,
              onQuantityChanged: (q) => newQty = q,
              onRemove: () => removed = true,
            ),
          ),
        ),
      );

      expect(find.text('Performance Court Shoes'), findsOneWidget);
      expect(find.text('Size: UK 9'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('₹7,000'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      expect(newQty, equals(3));

      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(removed, isTrue);
    });

    testWidgets('OrderStatusTimeline renders steps accurately', (tester) async {
      final now = DateTime.now();
      final steps = [
        OrderStatusStep(
          title: 'Order Placed',
          description: 'Your order was verified',
          timestamp: now.subtract(const Duration(hours: 4)),
          isCompleted: true,
        ),
        OrderStatusStep(
          title: 'Processing',
          description: 'Being packaged at facility',
          timestamp: now.subtract(const Duration(hours: 1)),
          isCurrent: true,
        ),
        const OrderStatusStep(
          title: 'In Transit',
          description: 'Item dispatched',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: OrderStatusTimeline(steps: steps),
          ),
        ),
      );

      expect(find.text('Order Placed'), findsOneWidget);
      expect(find.text('Processing'), findsOneWidget);
      expect(find.text('In Transit'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    });

    testWidgets('MarketplaceCataloguePage renders catalogue and category chips', (tester) async {
      setTallViewport(tester);

      final repo = MockMarketplaceRepository();
      final cubit = MarketplaceCatalogueCubit(repo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MarketplaceCataloguePage(cubit: cubit),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pickleball Shop'), findsOneWidget);
      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('Paddles'), findsOneWidget);
      expect(find.text('Balls'), findsOneWidget);
      expect(find.byType(ProductCard), findsWidgets);
    });

    testWidgets('ProductDetailsPage renders product gallery and specifications', (tester) async {
      setTallViewport(tester);

      final repo = MockMarketplaceRepository();
      final cubit = ProductDetailsCubit(repository: repo, productId: 'prod_001');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ProductDetailsPage(
            productId: 'prod_001',
            cubit: cubit,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pro Carbon 3K Precision Paddle'), findsWidgets);
      expect(find.text('APEX PADDLE & GEAR CO.'), findsOneWidget);
      expect(find.text('Specifications'), findsOneWidget);
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('Buy Now'), findsOneWidget);
    });

    testWidgets('MarketplaceCartPage renders cart items and checkout summary', (tester) async {
      setTallViewport(tester);

      final repo = MockMarketplaceRepository();
      final cubit = MarketplaceCartCubit(repo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MarketplaceCartPage(cubit: cubit),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Shopping Cart'), findsOneWidget);
      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('Subtotal (2 items)'), findsOneWidget);
    });

    testWidgets('MarketplaceOrdersPage renders order history cards', (tester) async {
      setTallViewport(tester);

      final repo = MockMarketplaceRepository();
      final cubit = MarketplaceOrdersCubit(repo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MarketplaceOrdersPage(cubit: cubit),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('My Marketplace Orders'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'All Orders'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Active'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Delivered'), findsOneWidget);
      expect(find.byType(OrderCard), findsWidgets);
    });
  });
}
