import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_profile_entities.dart';

abstract class MarketplaceSellerState extends Equatable {
  const MarketplaceSellerState();

  @override
  List<Object?> get props => [];
}

class MarketplaceSellerInitial extends MarketplaceSellerState {
  const MarketplaceSellerInitial();
}

class MarketplaceSellerLoading extends MarketplaceSellerState {
  const MarketplaceSellerLoading();
}

/// Authenticated user has not yet registered a Marketplace Seller organization.
class MarketplaceSellerUnregistered extends MarketplaceSellerState {
  final String userId;
  final bool otpSent;
  final bool isMutating;
  final String? feedbackMessage;
  final String? errorMessage;

  const MarketplaceSellerUnregistered({
    required this.userId,
    this.otpSent = false,
    this.isMutating = false,
    this.feedbackMessage,
    this.errorMessage,
  });

  MarketplaceSellerUnregistered copyWith({
    bool? otpSent,
    bool? isMutating,
    String? feedbackMessage,
    String? errorMessage,
    bool clearFeedback = false,
    bool clearError = false,
  }) {
    return MarketplaceSellerUnregistered(
      userId: userId,
      otpSent: otpSent ?? this.otpSent,
      isMutating: isMutating ?? this.isMutating,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        userId,
        otpSent,
        isMutating,
        feedbackMessage,
        errorMessage,
      ];
}

class MarketplaceSellerLoaded extends MarketplaceSellerState {
  final SellerProfile profile;
  final bool isMutating;
  final String? feedbackMessage;
  final String? errorMessage;

  const MarketplaceSellerLoaded({
    required this.profile,
    this.isMutating = false,
    this.feedbackMessage,
    this.errorMessage,
  });

  MarketplaceSellerLoaded copyWith({
    SellerProfile? profile,
    bool? isMutating,
    String? feedbackMessage,
    String? errorMessage,
    bool clearFeedback = false,
    bool clearError = false,
  }) {
    return MarketplaceSellerLoaded(
      profile: profile ?? this.profile,
      isMutating: isMutating ?? this.isMutating,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [profile, isMutating, feedbackMessage, errorMessage];
}

class MarketplaceSellerFailure extends MarketplaceSellerState {
  final String message;

  const MarketplaceSellerFailure(this.message);

  @override
  List<Object?> get props => [message];
}
