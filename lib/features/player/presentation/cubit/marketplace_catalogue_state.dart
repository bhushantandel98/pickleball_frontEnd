import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

sealed class MarketplaceCatalogueState extends Equatable {
  const MarketplaceCatalogueState();

  @override
  List<Object?> get props => [];
}

class MarketplaceCatalogueInitial extends MarketplaceCatalogueState {
  const MarketplaceCatalogueInitial();
}

class MarketplaceCatalogueLoading extends MarketplaceCatalogueState {
  const MarketplaceCatalogueLoading();
}

class MarketplaceCatalogueLoaded extends MarketplaceCatalogueState {
  final List<MarketplaceProduct> products;
  final Set<String> wishlistProductIds;
  final int cartItemCount;
  final String query;
  final ProductFilter filter;

  const MarketplaceCatalogueLoaded({
    required this.products,
    this.wishlistProductIds = const {},
    this.cartItemCount = 0,
    this.query = '',
    this.filter = const ProductFilter(),
  });

  bool get isEmpty => products.isEmpty;
  bool get hasActiveFilters => filter.hasActiveFilters;
  int get wishlistItemCount => wishlistProductIds.length;
  List<MarketplaceProduct> get filteredProducts => products;
  List<MarketplaceProduct> get allProducts => products;

  MarketplaceCatalogueLoaded copyWith({
    List<MarketplaceProduct>? products,
    Set<String>? wishlistProductIds,
    int? cartItemCount,
    String? query,
    ProductFilter? filter,
  }) {
    return MarketplaceCatalogueLoaded(
      products: products ?? this.products,
      wishlistProductIds: wishlistProductIds ?? this.wishlistProductIds,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      query: query ?? this.query,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props => [
        products,
        wishlistProductIds,
        cartItemCount,
        query,
        filter,
      ];
}

class MarketplaceCatalogueFailure extends MarketplaceCatalogueState {
  final String message;

  const MarketplaceCatalogueFailure(this.message);

  @override
  List<Object?> get props => [message];
}
