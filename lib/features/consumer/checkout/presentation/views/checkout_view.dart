import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart' as legacy;

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/core/utils/location_helper.dart';
import 'package:bagyesrushappusernew/core/widgets/map_location_picker_sheet.dart';
import 'package:bagyesrushappusernew/features/consumer/checkout/domain/entities/checkout_model.dart';
import 'package:bagyesrushappusernew/features/consumer/checkout/presentation/states/checkout_state.dart';
import 'package:bagyesrushappusernew/features/consumer/checkout/presentation/viewmodels/checkout_payment_methods_provider.dart';
import 'package:bagyesrushappusernew/features/consumer/checkout/presentation/viewmodels/checkout_viewmodel.dart';
import 'package:bagyesrushappusernew/features/consumer/payment_methods/views/screens/add_payment_method_screen.dart';
import 'package:bagyesrushappusernew/src/cart/viewmodels/cart_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/model/payment_method.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodel/payment_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodel/payout_providers_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/views/widgets/payout_provider_visuals.dart';

/// Unwraps whichever [CheckoutState] variant carries a [CheckoutForm].
CheckoutForm _formFromState(CheckoutState state) => switch (state) {
      CheckoutIdle(:final form) => form,
      CheckoutPlacing(:final form) => form,
      CheckoutError(:final form) => form,
      _ => const CheckoutForm(),
    };

class CheckoutView extends ConsumerStatefulWidget {
  const CheckoutView({super.key});

  @override
  ConsumerState<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends ConsumerState<CheckoutView> {
  // Address starts empty — user MUST provide an address before placing order.
  final _addressController = TextEditingController();
  final _instructionsController = TextEditingController();
  bool _isLocatingCurrentPosition = false;
  bool _hasRequestedDeliveryQuote = false;

  @override
  void initState() {
    super.initState();
    // Sync address controller with checkout state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final form = _formFromState(ref.read(checkoutProvider));
      if (form.deliveryAddress.isNotEmpty) {
        _addressController.text = form.deliveryAddress;
      }
      if (form.deliveryInstructions.isNotEmpty) {
        _instructionsController.text = form.deliveryInstructions;
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    if (_isLocatingCurrentPosition) return;
    setState(() => _isLocatingCurrentPosition = true);
    try {
      final result = await LocationHelper.getCurrentLocation(
        accuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      switch (result.status) {
        case LocationStatus.success:
          final position = result.position!;
          _addressController.text = result.address;
          ref.read(checkoutProvider.notifier).updateAddressWithCoordinates(
                result.address,
                latitude: position.latitude,
                longitude: position.longitude,
              );
          break;
        case LocationStatus.serviceDisabled:
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Location services disabled. Enable GPS and try again.'),
          ));
          break;
        case LocationStatus.permissionDeniedForever:
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                const Text('Location permission denied. Enable it in Settings.'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: LocationHelper.openAppSettings,
            ),
          ));
          break;
        case LocationStatus.permissionDenied:
        case LocationStatus.timeout:
        case LocationStatus.error:
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Could not detect your location. Try picking on the map instead.'),
          ));
          break;
      }
    } finally {
      if (mounted) setState(() => _isLocatingCurrentPosition = false);
    }
  }

  void _openMapPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MapLocationPickerSheet(
        title: 'Delivery Address',
        onConfirm: (LatLng latLng, String address) {
          _addressController.text = address;
          ref.read(checkoutProvider.notifier).updateAddressWithCoordinates(
                address,
                latitude: latLng.latitude,
                longitude: latLng.longitude,
              );
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Pushes the existing "Add Payment Method" screen (the same one used
  /// from Profile → Payment Methods), providing it the `ChangeNotifier`s it
  /// expects since checkout's widget tree doesn't already have them. On
  /// success it pops back here with the newly-created method, which is then
  /// selected and the saved-methods list is refreshed.
  Future<void> _addPaymentMethod(BuildContext context) async {
    final result = await Navigator.of(context).push<PaymentMethod>(
      MaterialPageRoute(
        builder: (_) => legacy.MultiProvider(
          providers: [
            legacy.ChangeNotifierProvider<PaymentViewModel>(
              create: (_) => sl<PaymentViewModel>(param1: false),
            ),
            legacy.ChangeNotifierProvider<PayoutProvidersViewModel>(
              create: (_) => sl<PayoutProvidersViewModel>(),
            ),
          ],
          child: const AddPaymentMethodScreen(),
        ),
      ),
    );
    if (!mounted || result == null) return;
    ref.invalidate(checkoutPaymentMethodsProvider);
    ref.read(checkoutProvider.notifier).selectPaymentMethod(result);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cartVm = legacy.Provider.of<CartViewModel>(context);
    final cart = cartVm.cart;
    final checkoutState = ref.watch(checkoutProvider);

    // React to success → clear the server cart, then navigate to tracking
    ref.listen<CheckoutState>(checkoutProvider, (_, next) {
      if (next is CheckoutSuccess) {
        legacy.Provider.of<CartViewModel>(context, listen: false).clearCart();
        context.go(AppRoutes.trackOrder, extra: next.orderId);
      } else if (next is CheckoutError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
        ref.read(checkoutProvider.notifier).resetAfterError();
      }
    });

    // Auto-select the customer's default (or first) saved payment method
    // once the list loads, so they aren't forced to tap it explicitly.
    ref.listen<AsyncValue<List<PaymentMethod>>>(checkoutPaymentMethodsProvider,
        (_, next) {
      final methods = next.valueOrNull;
      if (methods == null || methods.isEmpty) return;
      if (_formFromState(ref.read(checkoutProvider)).selectedPaymentMethod !=
          null) {
        return;
      }
      final defaultMethod =
          methods.firstWhere((m) => m.isDefault, orElse: () => methods.first);
      ref.read(checkoutProvider.notifier).selectPaymentMethod(defaultMethod);
    });

    final isPlacing = checkoutState is CheckoutPlacing;
    final form = _formFromState(checkoutState);

    final hasValidAddress = form.deliveryAddress.trim().length >= 5;
    final hasPaymentMethod = form.selectedPaymentMethod != null;

    // Prefer the live quote once it's loaded; fall back to the cart's
    // (possibly stale) embedded fee while loading, on error, or before the
    // first fetch completes — the screen never shows a broken/empty total.
    final effectiveDeliveryFee =
        form.deliveryQuoteFee ?? cart?.deliveryFee ?? 0;
    final deliveryFeeCurrency = form.deliveryQuoteCurrency ?? 'GHS';
    final effectiveTotal = (cart?.subtotal ?? 0) + effectiveDeliveryFee;

    if (cart == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (!_hasRequestedDeliveryQuote) {
      _hasRequestedDeliveryQuote = true;
      final vendorId = cart.vendorId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(checkoutProvider.notifier).fetchDeliveryQuote(vendorId);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                w * 0.05, w * 0.03, w * 0.05, w * 0.04,
              ),
              children: [
                // ── Step 1: Delivery address ──
                _SectionHeader(number: '1', title: 'Delivery Address'),
                SizedBox(height: w * 0.03),

                // Address selector tile
                _AddressSelectorTile(
                  controller: _addressController,
                  hasValidAddress: hasValidAddress,
                  isLocatingCurrentPosition: _isLocatingCurrentPosition,
                  onChanged: (v) =>
                      ref.read(checkoutProvider.notifier).updateAddress(v),
                  onUseCurrentLocation: _useCurrentLocation,
                  onPickOnMap: _openMapPicker,
                ),

                SizedBox(height: w * 0.025),
                TextField(
                  controller: _instructionsController,
                  maxLines: 2,
                  onChanged: (v) => ref
                      .read(checkoutProvider.notifier)
                      .updateInstructions(v),
                  decoration: InputDecoration(
                    hintText: 'Delivery instructions (optional)',
                    prefixIcon: const Icon(
                      Icons.note_alt_outlined,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(w * 0.03),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                SizedBox(height: w * 0.055),

                // ── Step 2: Payment method ──
                _SectionHeader(number: '2', title: 'Payment Method'),
                SizedBox(height: w * 0.03),
                ref.watch(checkoutPaymentMethodsProvider).when(
                      loading: () => const _PaymentMethodsLoading(),
                      error: (_, _) => _PaymentMethodsErrorView(
                        onRetry: () =>
                            ref.invalidate(checkoutPaymentMethodsProvider),
                      ),
                      data: (methods) => methods.isEmpty
                          ? _NoPaymentMethodsCard(
                              onAdd: () => _addPaymentMethod(context),
                            )
                          : Column(
                              children: [
                                ...methods.map((m) => _PaymentOption(
                                      method: m,
                                      isSelected:
                                          form.selectedPaymentMethod?.id ==
                                              m.id,
                                      onTap: () {
                                        HapticFeedback.selectionClick();
                                        ref
                                            .read(checkoutProvider.notifier)
                                            .selectPaymentMethod(m);
                                      },
                                    )),
                                SizedBox(height: w * 0.02),
                                _AddPaymentMethodButton(
                                  onTap: () => _addPaymentMethod(context),
                                ),
                              ],
                            ),
                    ),

                SizedBox(height: w * 0.055),

                // ── Step 3: Order summary ──
                _SectionHeader(number: '3', title: 'Order Summary'),
                SizedBox(height: w * 0.03),
                Container(
                  padding: EdgeInsets.all(w * 0.04),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(w * 0.035),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      ...cart.items.map((ci) => Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: w * 0.012),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: w * 0.02,
                                    vertical: w * 0.005,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${ci.quantity}×',
                                    style: TextStyle(
                                      fontSize: w * 0.03,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: w * 0.025),
                                Expanded(
                                  child: Text(
                                    ci.name,
                                    style: TextStyle(
                                      fontSize: w * 0.033,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  'GHS ${ci.lineTotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: w * 0.033,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const Divider(color: AppColors.divider),
                      _TotalRow(label: 'Subtotal', value: cart.subtotal),
                      _DeliveryFeeRow(
                        isFetching: form.isFetchingDeliveryQuote,
                        error: form.deliveryQuoteError,
                        fee: effectiveDeliveryFee,
                        currency: deliveryFeeCurrency,
                        onRetry: () => ref
                            .read(checkoutProvider.notifier)
                            .fetchDeliveryQuote(cart.vendorId),
                      ),
                      SizedBox(height: w * 0.01),
                      _TotalRow(
                        label: 'Total',
                        value: effectiveTotal,
                        currency: deliveryFeeCurrency,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Place order button ──
          Container(
            padding: EdgeInsets.fromLTRB(
                w * 0.05, w * 0.03, w * 0.05, w * 0.06),
            decoration: const BoxDecoration(
              color: AppColors.scaffold,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Validation warnings
                if (!hasValidAddress)
                  const _ValidationWarning(
                    message:
                        'Please enter a valid delivery address to continue',
                  )
                else if (!hasPaymentMethod)
                  const _ValidationWarning(
                    message: 'Please select a payment method to continue',
                  ),
                ElevatedButton(
                  onPressed:
                      (isPlacing || !hasValidAddress || !hasPaymentMethod)
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              ref
                                  .read(checkoutProvider.notifier)
                                  .placeOrder(cart);
                            },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, w * 0.13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(w * 0.035),
                    ),
                  ),
                  child: isPlacing
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Place Order · $deliveryFeeCurrency ${effectiveTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: w * 0.038,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Address Selector Tile ────────────────────────────────────────────────

class _AddressSelectorTile extends StatelessWidget {
  final TextEditingController controller;
  final bool hasValidAddress;
  final bool isLocatingCurrentPosition;
  final ValueChanged<String> onChanged;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onPickOnMap;

  const _AddressSelectorTile({
    required this.controller,
    required this.hasValidAddress,
    required this.isLocatingCurrentPosition,
    required this.onChanged,
    required this.onUseCurrentLocation,
    required this.onPickOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(
          color: hasValidAddress
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
          width: hasValidAddress ? 1.5 : 0.8,
        ),
      ),
      child: Column(
        children: [
          // ── Address text field ──
          TextField(
            controller: controller,
            onChanged: onChanged,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Enter your delivery address',
              prefixIcon: Icon(
                Icons.location_on_rounded,
                color: hasValidAddress ? AppColors.success : AppColors.primary,
              ),
              suffixIcon: hasValidAddress
                  ? Icon(Icons.check_circle_rounded,
                      color: AppColors.success, size: w * 0.05)
                  : null,
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: w * 0.04,
                vertical: w * 0.04,
              ),
            ),
          ),

          // ── Quick actions ──
          Container(
            padding: EdgeInsets.fromLTRB(w * 0.04, 0, w * 0.04, w * 0.03),
            child: Row(
              children: [
                _QuickAddressChip(
                  icon: Icons.my_location_rounded,
                  label: isLocatingCurrentPosition
                      ? 'Locating…'
                      : 'Use current location',
                  isLoading: isLocatingCurrentPosition,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onUseCurrentLocation();
                  },
                ),
                SizedBox(width: w * 0.02),
                _QuickAddressChip(
                  icon: Icons.map_rounded,
                  label: 'Pick on map',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onPickOnMap();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAddressChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  const _QuickAddressChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.025,
          vertical: w * 0.015,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(w * 0.02),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: w * 0.035,
                height: w * 0.035,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              Icon(icon, size: w * 0.035, color: AppColors.primary),
            SizedBox(width: w * 0.015),
            Text(
              label,
              style: TextStyle(
                fontSize: w * 0.028,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String number;
  final String title;

  const _SectionHeader({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Row(
      children: [
        Container(
          width: w * 0.07,
          height: w * 0.07,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: w * 0.035,
            ),
          ),
        ),
        SizedBox(width: w * 0.025),
        Text(
          title,
          style: TextStyle(
            fontSize: w * 0.042,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final provider = method.provider;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.only(bottom: w * 0.025),
        padding: EdgeInsets.all(w * 0.04),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.07)
              : AppColors.card,
          borderRadius: BorderRadius.circular(w * 0.03),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 0.8,
          ),
        ),
        child: Row(
          children: [
            provider != null
                ? PayoutProviderAvatar(provider: provider, size: w * 0.09)
                : Icon(Icons.phone_android_rounded,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: w * 0.055),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.displayTitle,
                    style: TextStyle(
                      fontSize: w * 0.037,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${provider?.isBank == true ? 'Bank Account' : 'Mobile Money'} • ${method.maskedPhone}',
                    style: TextStyle(
                      fontSize: w * 0.03,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _AddPaymentMethodButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPaymentMethodButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add),
      label: const Text('Add Payment Method'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(w * 0.03),
        ),
        minimumSize: Size(double.infinity, w * 0.12),
      ),
    );
  }
}

class _PaymentMethodsLoading extends StatelessWidget {
  const _PaymentMethodsLoading();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.06),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _PaymentMethodsErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _PaymentMethodsErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: w * 0.055),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Text(
              'Could not load your payment methods',
              style:
                  TextStyle(fontSize: w * 0.034, color: AppColors.textPrimary),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _NoPaymentMethodsCard extends StatelessWidget {
  final VoidCallback onAdd;

  const _NoPaymentMethodsCard({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.all(w * 0.05),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: w * 0.09, color: AppColors.textSecondary),
          SizedBox(height: w * 0.025),
          Text(
            'No payment method added yet',
            style: TextStyle(
              fontSize: w * 0.036,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.02),
          _AddPaymentMethodButton(onTap: onAdd),
        ],
      ),
    );
  }
}

class _ValidationWarning extends StatelessWidget {
  final String message;

  const _ValidationWarning({required this.message});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.only(bottom: w * 0.025),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: w * 0.045),
          SizedBox(width: w * 0.02),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: w * 0.03,
                color: AppColors.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Delivery fee" line — shows a spinner while the live quote
/// (`GET /customer/delivery-quote`) is loading, a Retry action if it failed,
/// or the resolved fee otherwise. [fee] is always the effective value
/// (quote if loaded, else the cart's own fee) so the total stays honest
/// even while this row is mid-fetch or errored.
class _DeliveryFeeRow extends StatelessWidget {
  final bool isFetching;
  final String? error;
  final double fee;
  final String currency;
  final VoidCallback onRetry;

  const _DeliveryFeeRow({
    required this.isFetching,
    required this.error,
    required this.fee,
    required this.currency,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    if (isFetching) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: w * 0.01),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery fee',
              style: TextStyle(fontSize: w * 0.033, color: AppColors.textSecondary),
            ),
            SizedBox(
              width: w * 0.035,
              height: w * 0.035,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: w * 0.01),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Delivery fee unavailable',
                style: TextStyle(fontSize: w * 0.033, color: AppColors.error),
              ),
            ),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: w * 0.033,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return _TotalRow(label: 'Delivery fee', value: fee, currency: currency);
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  final String currency;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.currency = 'GHS',
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.01),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.033,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: isBold
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
          Text(
            '$currency ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isBold ? w * 0.038 : w * 0.033,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isBold ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
