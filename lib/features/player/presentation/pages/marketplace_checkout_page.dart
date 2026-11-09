import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_text_field.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_checkout_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_checkout_state.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/category_icon_helper.dart';

/// Player Marketplace Checkout Page with Delivery Address inputs and Pay on Delivery confirmation.
class MarketplaceCheckoutPage extends StatelessWidget {
  final List<MarketplaceCartItem>? directItems;

  const MarketplaceCheckoutPage({
    super.key,
    this.directItems,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MarketplaceCheckoutCubit(
        repository: sl(),
        directItems: directItems,
      )..initializeCheckout(),
      child: const _MarketplaceCheckoutView(),
    );
  }
}

class _MarketplaceCheckoutView extends StatefulWidget {
  const _MarketplaceCheckoutView();

  @override
  State<_MarketplaceCheckoutView> createState() => _MarketplaceCheckoutViewState();
}

class _MarketplaceCheckoutViewState extends State<_MarketplaceCheckoutView> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pinController;
  late final TextEditingController _landmarkController;

  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _pinController = TextEditingController();
    _landmarkController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _syncControllers(MarketplaceDeliveryAddress address) {
    if (!_controllersInitialized) {
      _nameController.text = address.fullName;
      _phoneController.text = address.phoneNumber;
      _streetController.text = address.streetAddress;
      _cityController.text = address.city;
      _stateController.text = address.state;
      _pinController.text = address.postalCode;
      _landmarkController.text = address.landmark ?? '';
      _controllersInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return BlocConsumer<MarketplaceCheckoutCubit, MarketplaceCheckoutState>(
      listener: (context, state) {
        if (state is MarketplaceCheckoutReady) {
          _syncControllers(state.address);
          if (state.generalError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.generalError!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        } else if (state is MarketplaceCheckoutSuccess) {
          _showSuccessDialog(context, state.order);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Checkout'),
          ),
          body: SafeArea(
            child: _buildBody(context, state, theme, currency),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    MarketplaceCheckoutState state,
    ThemeData theme,
    NumberFormat currency,
  ) {
    if (state is MarketplaceCheckoutLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (state is MarketplaceCheckoutFailure) {
      return ErrorStateView(
        message: state.message,
        onRetry: () => context.read<MarketplaceCheckoutCubit>().initializeCheckout(),
      );
    }

    if (state is MarketplaceCheckoutReady) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Delivery Address Form
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Delivery Address',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  AppTextField(
                    controller: _nameController,
                    label: 'Full Name *',
                    hint: 'Receiver name',
                    validator: (_) => state.fieldErrors['fullName'],
                    onChanged: (val) => context.read<MarketplaceCheckoutCubit>().updateFullName(val),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _phoneController,
                    label: 'Mobile Phone Number *',
                    hint: '10-digit number for delivery updates',
                    keyboardType: TextInputType.phone,
                    validator: (_) => state.fieldErrors['phoneNumber'],
                    onChanged: (val) => context.read<MarketplaceCheckoutCubit>().updatePhoneNumber(val),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _streetController,
                    label: 'House / Flat / Street Address *',
                    hint: 'Apartment, building, street, area',
                    maxLines: 2,
                    validator: (_) => state.fieldErrors['streetAddress'],
                    onChanged: (val) => context.read<MarketplaceCheckoutCubit>().updateStreetAddress(val),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _cityController,
                          label: 'City *',
                          hint: 'e.g. Bengaluru',
                          validator: (_) => state.fieldErrors['city'],
                          onChanged: (val) => context.read<MarketplaceCheckoutCubit>().updateCity(val),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppTextField(
                          controller: _stateController,
                          label: 'State *',
                          hint: 'e.g. Karnataka',
                          validator: (_) => state.fieldErrors['state'],
                          onChanged: (val) => context.read<MarketplaceCheckoutCubit>().updateState(val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _pinController,
                          label: 'PIN Code *',
                          hint: '6-digit PIN',
                          keyboardType: TextInputType.number,
                          validator: (_) => state.fieldErrors['postalCode'],
                          onChanged: (val) => context.read<MarketplaceCheckoutCubit>().updatePostalCode(val),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppTextField(
                          controller: _landmarkController,
                          label: 'Landmark (Optional)',
                          hint: 'e.g. Near club',
                          onChanged: (val) => context.read<MarketplaceCheckoutCubit>().updateLandmark(val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Section 2: Payment Method
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.payment_outlined, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Payment Method',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  RadioGroup<String>(
                    groupValue: state.paymentMethod,
                    onChanged: (val) {
                      if (val != null) {
                        context.read<MarketplaceCheckoutCubit>().updatePaymentMethod(val);
                      }
                    },
                    child: const Column(
                      children: [
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: 'Pay upon Receipt (UPI / Cash)',
                          title: Text('Pay upon Receipt (UPI / Cash)'),
                          subtitle: Text('Pay via UPI QR code or Cash when your parcel arrives.'),
                        ),
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: 'Online Payment (Prepaid)',
                          title: Text('Online Payment (Prepaid)'),
                          subtitle: Text('Credit/Debit Card, Netbanking, UPI (Fast track)'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Section 3: Ordered Items Preview
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Items (${state.items.length})',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 24),
                  for (final item in state.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: item.product.imageUrl.isNotEmpty
                                ? Image.asset(
                                    item.product.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Icon(
                                      getCategoryIcon(item.product.category),
                                      size: 22,
                                    ),
                                  )
                                : Icon(
                                    getCategoryIcon(item.product.category),
                                    size: 22,
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Qty: ${item.quantity}${item.selectedSize != null ? ' • Size: ${item.selectedSize}' : ''}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            currency.format(item.totalPrice),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Section 4: Price Breakdown & Place Order CTA
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal', style: theme.textTheme.bodyMedium),
                      Text(currency.format(state.subtotal), style: theme.textTheme.bodyMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Delivery Charges', style: theme.textTheme.bodyMedium),
                      Text(
                        state.deliveryFee == 0 ? 'FREE' : currency.format(state.deliveryFee),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: state.deliveryFee == 0 ? theme.colorScheme.primary : null,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Payable',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        currency.format(state.totalAmount),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      label: 'Place Order (${currency.format(state.totalAmount)})',
                      isLoading: state.isSubmitting,
                      onPressed: () {
                        context.read<MarketplaceCheckoutCubit>().submitOrder();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _showSuccessDialog(BuildContext context, MarketplaceOrder order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        title: const Text('Order Placed Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Ref: ${order.referenceId}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Thank you! Your order has been placed and will be delivered to ${order.deliveryAddress.fullName}.',
            ),
            const SizedBox(height: 8),
            Text(
              'Payment: ${order.paymentMethod}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppRoutes.playerMarketplace);
            },
            child: const Text('Continue Shopping'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pushReplacement(AppRoutes.playerMarketplaceOrderDetailsPath(order.id));
            },
            child: const Text('View Order'),
          ),
        ],
      ),
    );
  }
}
