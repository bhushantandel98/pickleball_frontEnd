import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

abstract class ProductDetailsState extends Equatable {
  const ProductDetailsState();

  @override
  List<Object?> get props => [];
}

class ProductDetailsInitial extends ProductDetailsState {
  const ProductDetailsInitial();
}

class ProductDetailsLoading extends ProductDetailsState {
  const ProductDetailsLoading();
}

class ProductDetailsLoaded extends ProductDetailsState {
  final MarketplaceProduct product;
  final bool isWishlisted;
  final int selectedQuantity;
  final String? selectedSize;
  final String? selectedColor;
  final int cartItemCount;
  final bool isAddingToCart;
  final String? actionMessage;

  const ProductDetailsLoaded({
    required this.product,
    this.isWishlisted = false,
    this.selectedQuantity = 1,
    this.selectedSize,
    this.selectedColor,
    this.cartItemCount = 0,
    this.isAddingToCart = false,
    this.actionMessage,
  });

  ProductDetailsLoaded copyWith({
    MarketplaceProduct? product,
    bool? isWishlisted,
    int? selectedQuantity,
    String? selectedSize,
    String? selectedColor,
    int? cartItemCount,
    bool? isAddingToCart,
    String? actionMessage,
  }) {
    return ProductDetailsLoaded(
      product: product ?? this.product,
      isWishlisted: isWishlisted ?? this.isWishlisted,
      selectedQuantity: selectedQuantity ?? this.selectedQuantity,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      isAddingToCart: isAddingToCart ?? this.isAddingToCart,
      actionMessage: actionMessage,
    );
  }

  @override
  List<Object?> get props => [
        product,
        isWishlisted,
        selectedQuantity,
        selectedSize,
        selectedColor,
        cartItemCount,
        isAddingToCart,
        actionMessage,
      ];
}

class ProductDetailsFailure extends ProductDetailsState {
  final String message;

  const ProductDetailsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
