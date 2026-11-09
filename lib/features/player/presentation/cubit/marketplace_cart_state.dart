import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

abstract class MarketplaceCartState extends Equatable {
  const MarketplaceCartState();

  @override
  List<Object?> get props => [];
}

class MarketplaceCartInitial extends MarketplaceCartState {
  const MarketplaceCartInitial();
}

class MarketplaceCartLoading extends MarketplaceCartState {
  const MarketplaceCartLoading();
}

class MarketplaceCartLoaded extends MarketplaceCartState {
  final List<MarketplaceCartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double freeDeliveryThreshold;
  final double totalAmount;
  final bool isUpdating;
  final String? userNotice;

  const MarketplaceCartLoaded({
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.freeDeliveryThreshold,
    required this.totalAmount,
    this.isUpdating = false,
    this.userNotice,
  });

  bool get isEmpty => items.isEmpty;
  int get totalItemCount => items.fold(0, (sum, i) => sum + i.quantity);
  bool get qualifiesForFreeDelivery => subtotal >= freeDeliveryThreshold;
  double get amountNeededForFreeDelivery =>
      qualifiesForFreeDelivery ? 0 : (freeDeliveryThreshold - subtotal);

  MarketplaceCartLoaded copyWith({
    List<MarketplaceCartItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? freeDeliveryThreshold,
    double? totalAmount,
    bool? isUpdating,
    String? userNotice,
  }) {
    return MarketplaceCartLoaded(
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      freeDeliveryThreshold: freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      totalAmount: totalAmount ?? this.totalAmount,
      isUpdating: isUpdating ?? this.isUpdating,
      userNotice: userNotice,
    );
  }

  @override
  List<Object?> get props => [
        items,
        subtotal,
        deliveryFee,
        freeDeliveryThreshold,
        totalAmount,
        isUpdating,
        userNotice,
      ];
}

class MarketplaceCartFailure extends MarketplaceCartState {
  final String message;

  const MarketplaceCartFailure(this.message);

  @override
  List<Object?> get props => [message];
}
