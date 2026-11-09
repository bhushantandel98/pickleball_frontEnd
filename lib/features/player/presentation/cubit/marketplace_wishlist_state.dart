import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';

abstract class MarketplaceWishlistState extends Equatable {
  const MarketplaceWishlistState();

  @override
  List<Object?> get props => [];
}

class MarketplaceWishlistInitial extends MarketplaceWishlistState {
  const MarketplaceWishlistInitial();
}

class MarketplaceWishlistLoading extends MarketplaceWishlistState {
  const MarketplaceWishlistLoading();
}

class MarketplaceWishlistLoaded extends MarketplaceWishlistState {
  final List<MarketplaceProduct> items;
  final String? notice;

  const MarketplaceWishlistLoaded({
    required this.items,
    this.notice,
  });

  bool get isEmpty => items.isEmpty;

  MarketplaceWishlistLoaded copyWith({
    List<MarketplaceProduct>? items,
    String? notice,
  }) {
    return MarketplaceWishlistLoaded(
      items: items ?? this.items,
      notice: notice,
    );
  }

  @override
  List<Object?> get props => [items, notice];
}

class MarketplaceWishlistFailure extends MarketplaceWishlistState {
  final String message;

  const MarketplaceWishlistFailure(this.message);

  @override
  List<Object?> get props => [message];
}
