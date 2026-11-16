import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_order_entities.dart';

/// Repository contract for Feature 6.4 — Marketplace Seller Dashboard & Order
/// Management.
///
/// Reuses existing Player Marketplace order infrastructure while enforcing
/// strict [sellerId] + [userId] ownership and multi-seller item/financial
/// isolation. Sellers cannot modify payment status or payment records.
abstract class SellerOrderRepository {
  /// Computes Seller Dashboard metrics strictly from orders containing
  /// products owned by [sellerId].
  Future<Result<SellerDashboardMetrics>> getDashboardMetrics({
    required String sellerId,
    required String userId,
  });

  /// Lists orders containing at least one product owned by [sellerId].
  Future<Result<List<SellerOrderView>>> getSellerOrders({
    required String sellerId,
    required String userId,
    SellerOrderFilter? filter,
  });

  /// Fetches a single seller-scoped order view by [orderId].
  Future<Result<SellerOrderView>> getSellerOrderById({
    required String sellerId,
    required String userId,
    required String orderId,
  });

  /// Accepts a newly placed order (`placed` -> `processing`) owned by
  /// [sellerId].
  Future<Result<SellerOrderView>> acceptOrder({
    required String sellerId,
    required String userId,
    required String orderId,
  });

  /// Cancels an order in `placed` or `processing` status with a mandatory
  /// [reason]. Does not execute refunds or alter payment records.
  Future<Result<SellerOrderView>> cancelSellerOrder({
    required String sellerId,
    required String userId,
    required String orderId,
    required String reason,
  });

  /// Marks the seller's order slice as dispatched (`processing` -> `inTransit`)
  /// with carrier & tracking details (Feature 6.5).
  Future<Result<SellerOrderView>> markOrderDispatched({
    required String sellerId,
    required String userId,
    required String orderId,
    required String carrierName,
    required String trackingNumber,
    String? trackingUrl,
    String? note,
  });

  /// Marks the seller's order slice as out for delivery (`inTransit` ->
  /// `outForDelivery`) (Feature 6.5).
  Future<Result<SellerOrderView>> markOrderOutForDelivery({
    required String sellerId,
    required String userId,
    required String orderId,
    String? note,
  });

  /// Confirms delivery for the seller's order slice (`outForDelivery` ->
  /// `delivered`) (Feature 6.5).
  Future<Result<SellerOrderView>> markOrderDelivered({
    required String sellerId,
    required String userId,
    required String orderId,
    String? note,
  });
}
