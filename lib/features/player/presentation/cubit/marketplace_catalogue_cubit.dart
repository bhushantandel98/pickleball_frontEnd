import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/marketplace_repository.dart';
import 'marketplace_catalogue_state.dart';

class MarketplaceCatalogueCubit extends Cubit<MarketplaceCatalogueState> {
  final MarketplaceRepository _repository;

  MarketplaceCatalogueCubit(this._repository)
      : super(const MarketplaceCatalogueInitial());

  ProductFilter _currentFilter = const ProductFilter();
  String _currentQuery = '';

  ProductFilter get currentFilter => _currentFilter;
  String get currentQuery => _currentQuery;

  Future<void> loadCatalogue({
    String? query,
    ProductFilter? filter,
    bool showLoading = true,
  }) async {
    if (query != null) _currentQuery = query;
    if (filter != null) _currentFilter = filter;

    if (showLoading) {
      emit(const MarketplaceCatalogueLoading());
    }

    final effectiveFilter = _currentFilter.copyWith(
      query: _currentQuery.trim().isEmpty ? null : _currentQuery.trim(),
    );

    final productsResult = await _repository.getProducts(filter: effectiveFilter);

    switch (productsResult) {
      case Success(:final data):
        final wishlistResult = await _repository.getWishlist();
        final wishlistedIds = wishlistResult is Success<List<MarketplaceProduct>>
            ? wishlistResult.data.map((p) => p.id).toSet()
            : <String>{};

        final cartResult = await _repository.getCart();
        final cartItemCount = cartResult is Success<List<MarketplaceCartItem>>
            ? cartResult.data.fold<int>(0, (sum, item) => sum + item.quantity)
            : 0;

        emit(MarketplaceCatalogueLoaded(
          products: data,
          wishlistProductIds: wishlistedIds,
          cartItemCount: cartItemCount,
          query: _currentQuery,
          filter: _currentFilter,
        ));
      case FailureResult(:final failure):
        emit(MarketplaceCatalogueFailure(failure.message));
    }
  }

  void updateSearchQuery(String query) {
    _currentQuery = query;
    loadCatalogue(query: query, showLoading: false);
  }

  void updateCategory(ProductCategory category) {
    _currentFilter = _currentFilter.copyWith(category: category);
    loadCatalogue(filter: _currentFilter, showLoading: true);
  }

  void updateSortOption(ProductSortOption sortOption) {
    _currentFilter = _currentFilter.copyWith(sort: sortOption);
    loadCatalogue(filter: _currentFilter, showLoading: true);
  }

  void updateFilter(ProductFilter filter) {
    _currentFilter = filter;
    loadCatalogue(filter: _currentFilter, showLoading: true);
  }

  void resetFilter() {
    _currentFilter = const ProductFilter();
    _currentQuery = '';
    loadCatalogue(query: '', filter: const ProductFilter(), showLoading: true);
  }

  Future<void> toggleWishlist(String productId) async {
    final currentState = state;
    final toggleResult = await _repository.toggleWishlist(productId);

    if (toggleResult is Success<bool> && currentState is MarketplaceCatalogueLoaded) {
      final isNowWishlisted = toggleResult.data;
      final updatedIds = Set<String>.from(currentState.wishlistProductIds);
      if (isNowWishlisted) {
        updatedIds.add(productId);
      } else {
        updatedIds.remove(productId);
      }
      emit(currentState.copyWith(wishlistProductIds: updatedIds));
    }
  }

  Future<void> quickAddToCart(MarketplaceProduct product) async {
    final result = await _repository.addToCart(product, quantity: 1);
    if (result is Success<List<MarketplaceCartItem>> && state is MarketplaceCatalogueLoaded) {
      final count = result.data.fold<int>(0, (sum, item) => sum + item.quantity);
      final current = state as MarketplaceCatalogueLoaded;
      emit(current.copyWith(cartItemCount: count));
    }
  }

  Future<void> refresh() async {
    await loadCatalogue(showLoading: false);
  }
}
