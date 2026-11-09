import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

abstract class MarketplaceCheckoutState extends Equatable {
  const MarketplaceCheckoutState();

  @override
  List<Object?> get props => [];
}

class MarketplaceCheckoutInitial extends MarketplaceCheckoutState {
  const MarketplaceCheckoutInitial();
}

class MarketplaceCheckoutLoading extends MarketplaceCheckoutState {
  const MarketplaceCheckoutLoading();
}

class MarketplaceCheckoutReady extends MarketplaceCheckoutState {
  final List<MarketplaceCartItem> items;
  final MarketplaceDeliveryAddress address;
  final String paymentMethod;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final Map<String, String> fieldErrors;
  final bool isSubmitting;
  final String? generalError;

  const MarketplaceCheckoutReady({
    required this.items,
    required this.address,
    this.paymentMethod = 'Pay upon Receipt (UPI / Cash)',
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    this.fieldErrors = const {},
    this.isSubmitting = false,
    this.generalError,
  });

  bool get hasErrors => fieldErrors.isNotEmpty;

  MarketplaceCheckoutReady copyWith({
    List<MarketplaceCartItem>? items,
    MarketplaceDeliveryAddress? address,
    String? paymentMethod,
    double? subtotal,
    double? deliveryFee,
    double? totalAmount,
    Map<String, String>? fieldErrors,
    bool? isSubmitting,
    String? generalError,
  }) {
    return MarketplaceCheckoutReady(
      items: items ?? this.items,
      address: address ?? this.address,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      totalAmount: totalAmount ?? this.totalAmount,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      generalError: generalError,
    );
  }

  @override
  List<Object?> get props => [
        items,
        address,
        paymentMethod,
        subtotal,
        deliveryFee,
        totalAmount,
        fieldErrors,
        isSubmitting,
        generalError,
      ];
}

class MarketplaceCheckoutSuccess extends MarketplaceCheckoutState {
  final MarketplaceOrder order;

  const MarketplaceCheckoutSuccess(this.order);

  @override
  List<Object?> get props => [order];
}

class MarketplaceCheckoutFailure extends MarketplaceCheckoutState {
  final String message;

  const MarketplaceCheckoutFailure(this.message);

  @override
  List<Object?> get props => [message];
}
