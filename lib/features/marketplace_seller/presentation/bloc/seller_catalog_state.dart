import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_product_entities.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';

abstract class SellerCatalogState extends Equatable {
  const SellerCatalogState();

  @override
  List<Object?> get props => [];
}

class SellerCatalogInitial extends SellerCatalogState {
  const SellerCatalogInitial();
}

class SellerCatalogLoading extends SellerCatalogState {
  const SellerCatalogLoading();
}

class SellerCatalogLoaded extends SellerCatalogState {
  final SellerProfile sellerProfile;
  final List<SellerProduct> products;
  final SellerProductFilter filter;
  final bool isMutating;
  final String? feedbackMessage;
  final String? errorMessage;

  const SellerCatalogLoaded({
    required this.sellerProfile,
    required this.products,
    this.filter = const SellerProductFilter(),
    this.isMutating = false,
    this.feedbackMessage,
    this.errorMessage,
  });

  bool get isVerifiedSeller =>
      sellerProfile.verificationStatus == SellerVerificationStatus.approved;

  SellerCatalogLoaded copyWith({
    SellerProfile? sellerProfile,
    List<SellerProduct>? products,
    SellerProductFilter? filter,
    bool? isMutating,
    String? feedbackMessage,
    bool clearFeedback = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SellerCatalogLoaded(
      sellerProfile: sellerProfile ?? this.sellerProfile,
      products: products ?? this.products,
      filter: filter ?? this.filter,
      isMutating: isMutating ?? this.isMutating,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        sellerProfile,
        products,
        filter,
        isMutating,
        feedbackMessage,
        errorMessage,
      ];
}

class SellerCatalogFailure extends SellerCatalogState {
  final String message;

  const SellerCatalogFailure(this.message);

  @override
  List<Object?> get props => [message];
}
