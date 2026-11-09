import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/marketplace_repository.dart';
import 'marketplace_checkout_state.dart';

class MarketplaceCheckoutCubit extends Cubit<MarketplaceCheckoutState> {
  final MarketplaceRepository repository;
  final List<MarketplaceCartItem>? directItems;

  MarketplaceCheckoutCubit({
    required this.repository,
    this.directItems,
  }) : super(const MarketplaceCheckoutInitial());

  static const double defaultFreeDeliveryThreshold = 999.0;
  static const double standardDeliveryFee = 99.0;

  Future<void> initializeCheckout() async {
    emit(const MarketplaceCheckoutLoading());

    List<MarketplaceCartItem> items;
    if (directItems != null) {
      items = directItems!;
    } else {
      final cartResult = await repository.getCart();
      if (cartResult is FailureResult<List<MarketplaceCartItem>>) {
        emit(MarketplaceCheckoutFailure(cartResult.failure.message));
        return;
      }
      items = (cartResult as Success<List<MarketplaceCartItem>>).data;
    }

    if (items.isEmpty) {
      emit(const MarketplaceCheckoutFailure('Your cart is empty.'));
      return;
    }

    final subtotal = items.fold<double>(0, (sum, i) => sum + i.totalPrice);
    final deliveryFee = subtotal >= defaultFreeDeliveryThreshold ? 0.0 : standardDeliveryFee;
    final totalAmount = subtotal + deliveryFee;

    const defaultAddress = MarketplaceDeliveryAddress(
      fullName: 'Aarav Sharma',
      phoneNumber: '9876543210',
      streetAddress: 'Flat 402, Green Glen Layout, Bellandur',
      city: 'Bengaluru',
      state: 'Karnataka',
      postalCode: '560103',
      landmark: 'Opposite Community Park',
    );

    emit(MarketplaceCheckoutReady(
      items: items,
      address: defaultAddress,
      paymentMethod: 'Pay upon Receipt (UPI / Cash)',
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      totalAmount: totalAmount,
    ));
  }

  void updateFullName(String value) {
    _updateAddressField((addr) => addr.copyWith(fullName: value), 'fullName');
  }

  void updatePhoneNumber(String value) {
    _updateAddressField((addr) => addr.copyWith(phoneNumber: value), 'phoneNumber');
  }

  void updateStreetAddress(String value) {
    _updateAddressField((addr) => addr.copyWith(streetAddress: value), 'streetAddress');
  }

  void updateCity(String value) {
    _updateAddressField((addr) => addr.copyWith(city: value), 'city');
  }

  void updateState(String value) {
    _updateAddressField((addr) => addr.copyWith(state: value), 'state');
  }

  void updatePostalCode(String value) {
    _updateAddressField((addr) => addr.copyWith(postalCode: value), 'postalCode');
  }

  void updateLandmark(String value) {
    _updateAddressField((addr) => addr.copyWith(landmark: value), 'landmark');
  }

  void updatePaymentMethod(String method) {
    if (state is MarketplaceCheckoutReady) {
      final current = state as MarketplaceCheckoutReady;
      emit(current.copyWith(paymentMethod: method));
    }
  }

  void _updateAddressField(
    MarketplaceDeliveryAddress Function(MarketplaceDeliveryAddress) updater,
    String fieldKey,
  ) {
    if (state is MarketplaceCheckoutReady) {
      final current = state as MarketplaceCheckoutReady;
      final updatedAddress = updater(current.address);
      final errors = Map<String, String>.from(current.fieldErrors)..remove(fieldKey);
      emit(current.copyWith(address: updatedAddress, fieldErrors: errors));
    }
  }

  Map<String, String> _validateAddress(MarketplaceDeliveryAddress addr) {
    final errors = <String, String>{};

    if (addr.fullName.trim().isEmpty) {
      errors['fullName'] = 'Recipient full name is required';
    } else if (addr.fullName.trim().length < 3) {
      errors['fullName'] = 'Name must be at least 3 characters';
    }

    final phoneDigits = addr.phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (phoneDigits.isEmpty) {
      errors['phoneNumber'] = 'Phone number is required';
    } else if (phoneDigits.length < 10) {
      errors['phoneNumber'] = 'Enter a valid 10-digit phone number';
    }

    if (addr.streetAddress.trim().isEmpty) {
      errors['streetAddress'] = 'Street address is required';
    } else if (addr.streetAddress.trim().length < 5) {
      errors['streetAddress'] = 'Please enter a complete street address';
    }

    if (addr.city.trim().isEmpty) {
      errors['city'] = 'City is required';
    }

    if (addr.state.trim().isEmpty) {
      errors['state'] = 'State is required';
    }

    final pinDigits = addr.postalCode.replaceAll(RegExp(r'\D'), '');
    if (pinDigits.isEmpty) {
      errors['postalCode'] = 'PIN code is required';
    } else if (pinDigits.length != 6) {
      errors['postalCode'] = 'Enter a valid 6-digit PIN code';
    }

    return errors;
  }

  Future<bool> submitOrder() async {
    if (state is! MarketplaceCheckoutReady) return false;
    final current = state as MarketplaceCheckoutReady;

    final errors = _validateAddress(current.address);
    if (errors.isNotEmpty) {
      emit(current.copyWith(fieldErrors: errors, generalError: 'Please fix the errors above'));
      return false;
    }

    emit(current.copyWith(isSubmitting: true, generalError: null));

    final result = await repository.placeOrder(
      items: current.items,
      address: current.address,
      paymentMethod: current.paymentMethod,
      deliveryFee: current.deliveryFee,
    );

    switch (result) {
      case Success(:final data):
        emit(MarketplaceCheckoutSuccess(data));
        return true;
      case FailureResult(:final failure):
        emit(current.copyWith(
          isSubmitting: false,
          generalError: failure.message,
        ));
        return false;
    }
  }
}
