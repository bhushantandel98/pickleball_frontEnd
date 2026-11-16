import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/marketplace_seller/domain/entities/seller_order_entities.dart';

abstract class SellerOrderState extends Equatable {
  const SellerOrderState();

  @override
  List<Object?> get props => [];
}

class SellerOrderInitial extends SellerOrderState {
  const SellerOrderInitial();
}

class SellerOrderLoading extends SellerOrderState {
  const SellerOrderLoading();
}

class SellerOrderLoaded extends SellerOrderState {
  final SellerDashboardMetrics metrics;
  final List<SellerOrderView> orders;
  final SellerOrderFilter filter;
  final bool isMutating;
  final String? feedbackMessage;
  final String? errorMessage;

  const SellerOrderLoaded({
    required this.metrics,
    required this.orders,
    this.filter = const SellerOrderFilter(),
    this.isMutating = false,
    this.feedbackMessage,
    this.errorMessage,
  });

  SellerOrderLoaded copyWith({
    SellerDashboardMetrics? metrics,
    List<SellerOrderView>? orders,
    SellerOrderFilter? filter,
    bool? isMutating,
    String? feedbackMessage,
    bool clearFeedback = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SellerOrderLoaded(
      metrics: metrics ?? this.metrics,
      orders: orders ?? this.orders,
      filter: filter ?? this.filter,
      isMutating: isMutating ?? this.isMutating,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        metrics,
        orders,
        filter,
        isMutating,
        feedbackMessage,
        errorMessage,
      ];
}

class SellerOrderFailure extends SellerOrderState {
  final String message;

  const SellerOrderFailure(this.message);

  @override
  List<Object?> get props => [message];
}
