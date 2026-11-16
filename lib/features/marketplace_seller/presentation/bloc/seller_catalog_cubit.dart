import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_product_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/repositories/marketplace_seller_repository.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/repositories/seller_catalog_repository.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/bloc/seller_catalog_state.dart';

class SellerCatalogCubit extends Cubit<SellerCatalogState> {
  final SellerCatalogRepository _catalogRepository;
  final MarketplaceSellerRepository _sellerRepository;

  SellerCatalogCubit({
    required SellerCatalogRepository catalogRepository,
    required MarketplaceSellerRepository sellerRepository,
  })  : _catalogRepository = catalogRepository, // ignore: prefer_initializing_formals
        _sellerRepository = sellerRepository, // ignore: prefer_initializing_formals
        super(const SellerCatalogInitial());

  String? _userId;
  String? _sellerId;
  SellerProductFilter _currentFilter = const SellerProductFilter();

  Future<void> loadCatalog({
    required String userId,
    required String sellerId,
    SellerProductFilter? filter,
  }) async {
    _userId = userId;
    _sellerId = sellerId;
    if (filter != null) {
      _currentFilter = filter;
    }
    emit(const SellerCatalogLoading());

    final profileResult = await _sellerRepository.getSellerProfileForUser(
      userId: userId,
      sellerId: sellerId,
    );

    if (profileResult is FailureResult<SellerProfile?>) {
      emit(SellerCatalogFailure(profileResult.failure.message));
      return;
    }

    final profile = (profileResult as Success<SellerProfile?>).data;
    if (profile == null) {
      emit(
        const SellerCatalogFailure(
          'Seller profile not found. Complete seller registration first.',
        ),
      );
      return;
    }

    final productsResult = await _catalogRepository.getSellerProducts(
      sellerId: sellerId,
      userId: userId,
      filter: _currentFilter,
    );

    productsResult.when(
      success: (products) => emit(
        SellerCatalogLoaded(
          sellerProfile: profile,
          products: products,
          filter: _currentFilter,
        ),
      ),
      failure: (failure) => emit(SellerCatalogFailure(failure.message)),
    );
  }

  Future<void> applyFilter(SellerProductFilter filter) async {
    final current = state;
    final userId = _userId;
    final sellerId = _sellerId;
    _currentFilter = filter;
    if (current is! SellerCatalogLoaded || userId == null || sellerId == null) {
      return;
    }

    emit(current.copyWith(filter: filter, isMutating: true, clearError: true));
    final result = await _catalogRepository.getSellerProducts(
      sellerId: sellerId,
      userId: userId,
      filter: filter,
    );
    result.when(
      success: (products) => emit(
        current.copyWith(
          products: products,
          filter: filter,
          isMutating: false,
        ),
      ),
      failure: (failure) => emit(
        current.copyWith(isMutating: false, errorMessage: failure.message),
      ),
    );
  }

  Future<SellerProduct?> saveProductDraft(SellerProduct product) async {
    final current = state;
    final userId = _userId;
    final sellerId = _sellerId;
    if (userId == null || sellerId == null) return null;

    if (current is SellerCatalogLoaded) {
      emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));
    }

    final result = await _catalogRepository.saveProductDraft(
      sellerId: sellerId,
      userId: userId,
      product: product,
    );

    SellerProduct? saved;
    await result.when(
      success: (productSaved) async {
        saved = productSaved;
        await _reloadProducts(
          feedbackMessage: 'Product "${productSaved.name}" saved.',
        );
      },
      failure: (failure) async {
        if (current is SellerCatalogLoaded) {
          emit(
            current.copyWith(isMutating: false, errorMessage: failure.message),
          );
        }
      },
    );
    return saved;
  }

  Future<bool> submitProductForReview(String productId) async {
    final current = state;
    final userId = _userId;
    final sellerId = _sellerId;
    if (current is! SellerCatalogLoaded || userId == null || sellerId == null) {
      return false;
    }

    emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));
    final result = await _catalogRepository.submitProductForReview(
      sellerId: sellerId,
      userId: userId,
      productId: productId,
    );

    var ok = false;
    await result.when(
      success: (submitted) async {
        ok = true;
        await _reloadProducts(
          feedbackMessage:
              '"${submitted.name}" submitted for Staff review & Admin approval. Approval will not auto-publish.',
        );
      },
      failure: (failure) async {
        emit(current.copyWith(isMutating: false, errorMessage: failure.message));
      },
    );
    return ok;
  }

  Future<void> togglePublish({
    required String productId,
    required bool isPublished,
  }) async {
    final current = state;
    final userId = _userId;
    final sellerId = _sellerId;
    if (current is! SellerCatalogLoaded || userId == null || sellerId == null) {
      return;
    }

    emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));
    final result = await _catalogRepository.setProductPublished(
      sellerId: sellerId,
      userId: userId,
      productId: productId,
      isPublished: isPublished,
    );

    await result.when(
      success: (updated) async {
        await _reloadProducts(
          feedbackMessage: updated.isPublished
              ? '"${updated.name}" is now Published to the Player Marketplace.'
              : '"${updated.name}" is now Unpublished.',
        );
      },
      failure: (failure) async {
        emit(current.copyWith(isMutating: false, errorMessage: failure.message));
      },
    );
  }

  Future<void> updateInventory({
    required String productId,
    int? stockCount,
    Map<String, int>? variantStockCounts,
  }) async {
    final current = state;
    final userId = _userId;
    final sellerId = _sellerId;
    if (current is! SellerCatalogLoaded || userId == null || sellerId == null) {
      return;
    }

    emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));
    final result = await _catalogRepository.updateProductInventory(
      sellerId: sellerId,
      userId: userId,
      productId: productId,
      stockCount: stockCount,
      variantStockCounts: variantStockCounts,
    );

    await result.when(
      success: (updated) async {
        await _reloadProducts(
          feedbackMessage:
              'Inventory updated for "${updated.name}" (${updated.totalStock} in stock).',
        );
      },
      failure: (failure) async {
        emit(current.copyWith(isMutating: false, errorMessage: failure.message));
      },
    );
  }

  Future<void> deleteDraft(String productId) async {
    final current = state;
    final userId = _userId;
    final sellerId = _sellerId;
    if (current is! SellerCatalogLoaded || userId == null || sellerId == null) {
      return;
    }

    emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));
    final result = await _catalogRepository.deleteDraftProduct(
      sellerId: sellerId,
      userId: userId,
      productId: productId,
    );

    await result.when(
      success: (_) async {
        await _reloadProducts(feedbackMessage: 'Draft product deleted.');
      },
      failure: (failure) async {
        emit(current.copyWith(isMutating: false, errorMessage: failure.message));
      },
    );
  }

  void clearFeedback() {
    final current = state;
    if (current is SellerCatalogLoaded) {
      emit(current.copyWith(clearFeedback: true, clearError: true));
    }
  }

  Future<void> _reloadProducts({String? feedbackMessage}) async {
    final current = state;
    final userId = _userId;
    final sellerId = _sellerId;
    if (current is! SellerCatalogLoaded || userId == null || sellerId == null) {
      return;
    }

    final productsResult = await _catalogRepository.getSellerProducts(
      sellerId: sellerId,
      userId: userId,
      filter: _currentFilter,
    );

    productsResult.when(
      success: (products) => emit(
        current.copyWith(
          products: products,
          filter: _currentFilter,
          isMutating: false,
          feedbackMessage: feedbackMessage,
        ),
      ),
      failure: (failure) => emit(
        current.copyWith(isMutating: false, errorMessage: failure.message),
      ),
    );
  }
}
