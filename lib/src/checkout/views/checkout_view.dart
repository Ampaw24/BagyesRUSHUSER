import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/core/utils/location_helper.dart';
import 'package:bagyesrushappusernew/core/widgets/custom_dialogs.dart';
import 'package:bagyesrushappusernew/core/widgets/map_location_picker_sheet.dart';
import 'package:bagyesrushappusernew/src/checkout/models/checkout_model.dart';
import 'package:bagyesrushappusernew/src/checkout/viewmodels/checkout_state.dart';
import 'package:bagyesrushappusernew/src/checkout/viewmodels/checkout_viewmodel.dart';
import 'package:bagyesrushappusernew/src/checkout/views/widgets/delivery_address_section.dart';
import 'package:bagyesrushappusernew/src/checkout/views/widgets/promo_code_section.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/views/order_payment_launcher.dart';
import 'package:bagyesrushappusernew/src/customer_address/models/delivery_location.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/models/wallet_split.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/customer_wallet_state.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/customer_wallet_viewmodel.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/views/widgets/use_wallet_tile.dart';
import 'package:bagyesrushappusernew/src/payment/views/screens/add_payment_method_screen.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_model.dart';
import 'package:bagyesrushappusernew/src/cart/viewmodels/cart_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/model/payment_method.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodel/payment_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/viewmodel/payout_providers_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/views/widgets/payout_provider_visuals.dart';
import 'package:bagyesrushappusernew/core/utils/money_format.dart';

/// Unwraps whichever [CheckoutState] variant carries a [CheckoutForm].
CheckoutForm _formFromState(CheckoutState state) => switch (state) {
      CheckoutIdle(:final form) => form,
      CheckoutPlacing(:final form) => form,
      CheckoutError(:final form) => form,
      CheckoutSuccess(:final form) => form,
    };

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final _instructionsController = TextEditingController();
  bool _isLocatingCurrentPosition = false;

  /// True from order creation until this screen hands off to tracking.
  bool _isPaying = false;

  /// Saved reference so dispose() doesn't call context.read on an unmounted
  /// widget, and so the listener can be detached.
  CheckoutViewModel? _vm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vm = context.read<CheckoutViewModel>();
      _vm = vm;
      vm.addListener(_onCheckoutStateChanged);

      final form = _formFromState(vm.state);
      if (form.deliveryInstructions.isNotEmpty) {
        _instructionsController.text = form.deliveryInstructions;
      }

      final vendorId = context.read<CartViewModel>().cart?.vendorId;
      if (vendorId != null) vm.loadAddresses(vendorId);
      vm.refreshPaymentMethods();

      // Refresh the cart so its totals, wallet split and promo verdict are
      // current, and the wallet so the toggle reflects the live balance.
      context.read<CartViewModel>().refresh();
      context.read<CustomerWalletViewmodel>().fetchWallet();
    });
  }

  void _onCheckoutStateChanged() {
    if (!mounted) return;
    final next = _vm!.state;
    if (next is CheckoutSuccess) {
      if (!_isPaying) _payThenTrack(next);
    } else if (next is CheckoutError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(next.message)),
      );
      _vm!.resetAfterError();
    }
  }

  /// Charges the order with the method picked here, then hands off to
  /// tracking. The backend deletes the cart when the order is created; the
  /// local copy is reset only after the hand-off, so this screen doesn't go
  /// blank behind the payment dialog.
  Future<void> _payThenTrack(CheckoutSuccess success) async {
    setState(() => _isPaying = true);
    final cartVm = context.read<CartViewModel>();
    final walletVm = context.read<CustomerWalletViewmodel>();
    final checkoutVm = _vm!;
    await OrderPaymentLauncher.payThenTrack(
      context,
      orderId: success.order.id,
      requiresPayment: success.requiresPayment,
      savedMethod: success.form.selectedPaymentMethod,
      settledMessage: 'Order placed — paid with your wallet.',
    );
    cartVm.reset();
    walletVm.fetchWallet();
    checkoutVm.resetAfterSuccess();
  }

  @override
  void dispose() {
    _vm?.removeListener(_onCheckoutStateChanged);
    _instructionsController.dispose();
    super.dispose();
  }

  void _selectPickedLocation(String address, double lat, double lng) {
    final vendorId = context.read<CartViewModel>().cart?.vendorId;
    if (vendorId == null) return;
    context.read<CheckoutViewModel>().selectLocation(
          DeliveryLocation(address: address, latitude: lat, longitude: lng),
          vendorId: vendorId,
        );
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
          _selectPickedLocation(
            result.address,
            position.latitude,
            position.longitude,
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
    final form = _formFromState(context.read<CheckoutViewModel>().state);
    final picked = form.pickedLocation;
    final saved = form.selectedAddress;
    final initialPosition = picked != null
        ? LatLng(picked.latitude, picked.longitude)
        : (saved?.latitude != null && saved?.longitude != null)
            ? LatLng(saved!.latitude!, saved.longitude!)
            : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => MapLocationPickerSheet(
        title: 'Delivery Address',
        initialPosition: initialPosition,
        onConfirm: (LatLng latLng, String address) =>
            _selectPickedLocation(address, latLng.latitude, latLng.longitude),
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
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<PaymentViewModel>(
              create: (_) => sl<PaymentViewModel>(param1: false),
            ),
            ChangeNotifierProvider<PayoutProvidersViewModel>(
              create: (_) => sl<PayoutProvidersViewModel>(),
            ),
          ],
          child: const AddPaymentMethodScreen(),
        ),
      ),
    );
    if (!mounted || result == null) return;
    final vm = context.read<CheckoutViewModel>();
    vm.refreshPaymentMethods();
    vm.selectPaymentMethod(result);
  }

  /// Shows the amount due before the order is created — placing it starts
  /// payment straight away, so Cancel leaves the customer free to edit.
  /// For a non-default address ([total] is null) the amount and wallet split
  /// shown are estimates; the backend settles both on creation.
  void _confirmAndPlaceOrder({
    required CartModel cart,
    required double? total,
    required double? deliveryFee,
    required WalletSplit split,
  }) {
    final checkoutVm = context.read<CheckoutViewModel>();
    final isEstimate = total == null;
    final amount = total ??
        (deliveryFee == null ? null : cart.estimatedTotalWith(deliveryFee));
    final shownSplit = isEstimate
        ? WalletSplit.from(
            balance:
                context.read<CustomerWalletViewmodel>().wallet?.balance ?? 0,
            total: amount,
            useWallet: _formFromState(checkoutVm.state).useWallet,
          )
        : split;
    CustomDialog.showConfirmation(
      context: context,
      title: 'Confirm Payment',
      subtitle: _paymentConfirmationMessage(
        total: amount,
        split: shownSplit,
        currency: cart.currency,
        isEstimate: isEstimate,
      ),
      confirmText:
          shownSplit.coversFully ? 'Pay with Wallet' : 'Proceed to Payment',
      onConfirm: () => checkoutVm.placeOrder(
        cart,
        walletCoversTotal: split.coversFully,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final cartVm = context.watch<CartViewModel>();
    final cart = cartVm.cart;
    final checkoutVm = context.watch<CheckoutViewModel>();
    final checkoutState = checkoutVm.state;
    final walletVm = context.watch<CustomerWalletViewmodel>();
    final walletState = walletVm.state;

    final isPlacing = checkoutState is CheckoutPlacing ||
        checkoutState is CheckoutSuccess ||
        _isPaying;
    final form = _formFromState(checkoutState);

    if (cart == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // Every figure is the backend's. The cart's totals are priced against
    // the default address; for any other address only the quoted fee is
    // known here, and the order response carries the final total.
    final currency = cart.currency;
    final usesCartQuote = form.usesCartQuote;
    final deliveryFee =
        usesCartQuote ? cart.deliveryFee : form.deliveryQuote?.fee;
    final deliveryError = usesCartQuote ? cart.deliveryError : null;
    final total = usesCartQuote ? cart.total : null;
    // `wallet.applied`/`payable` are priced against the cart's (default
    // address) total; for another address the split is settled server-side.
    final walletSplit = WalletSplit.fromServer(
      useWallet: form.useWallet && (walletVm.wallet?.balance ?? 0) > 0,
      applied: usesCartQuote ? cart.wallet?.applied : null,
      payable: usesCartQuote ? cart.wallet?.payable : null,
      total: total,
    );
    final hasPaymentMethod =
        form.selectedPaymentMethod != null || walletSplit.coversFully;
    final hasQuote = usesCartQuote
        ? cart.deliveryQuoteId != null
        : form.deliveryQuote != null;
    final blockedReason = cart.checkoutBlockedReason ??
        (!form.hasDestination
            ? 'Choose a delivery address to continue'
            : !hasQuote && !form.isFetchingDeliveryQuote
                ? (deliveryError ??
                    form.deliveryQuoteError ??
                    "Delivery isn't available to this address")
                : !hasPaymentMethod
                    ? 'Please select a payment method to continue'
                    : null);
    final canPlace = blockedReason == null &&
        hasQuote &&
        !isPlacing &&
        !cartVm.isMutating;

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
                DeliveryAddressSection(
                  status: checkoutVm.addressesStatus,
                  addresses: checkoutVm.addresses,
                  selected: form.selectedAddress,
                  pickedLocation: form.pickedLocation,
                  isLocating: _isLocatingCurrentPosition,
                  onSelect: (a) =>
                      checkoutVm.selectAddress(a, vendorId: cart.vendorId),
                  onRetry: () => checkoutVm.loadAddresses(cart.vendorId),
                  onUseCurrentLocation: _useCurrentLocation,
                  onPickOnMap: _openMapPicker,
                ),

                SizedBox(height: w * 0.025),
                TextField(
                  controller: _instructionsController,
                  maxLines: 2,
                  onChanged: checkoutVm.updateInstructions,
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
                UseWalletTile(
                  wallet: walletVm.wallet,
                  isLoading: walletState is CustomerWalletLoading,
                  hasError: walletState is CustomerWalletError,
                  useWallet: form.useWallet,
                  split: walletSplit,
                  onChanged: checkoutVm.setUseWallet,
                  onRetry: walletVm.fetchWallet,
                ),
                SizedBox(height: w * 0.03),
                if (walletSplit.coversFully)
                  Padding(
                    padding: EdgeInsets.only(bottom: w * 0.02),
                    child: Text(
                      'No mobile money needed — paid from your wallet',
                      style: TextStyle(
                        fontSize: w * 0.03,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: walletSplit.coversFully ? 0.4 : 1,
                  child: IgnorePointer(
                    ignoring: walletSplit.coversFully,
                    child: switch (checkoutVm.paymentMethodsStatus) {
                  PaymentMethodsStatus.loading =>
                    const _PaymentMethodsLoading(),
                  PaymentMethodsStatus.error => _PaymentMethodsErrorView(
                      onRetry: () => checkoutVm.refreshPaymentMethods(),
                    ),
                  PaymentMethodsStatus.loaded =>
                    checkoutVm.paymentMethods.isEmpty
                        ? _NoPaymentMethodsCard(
                            onAdd: () => _addPaymentMethod(context),
                          )
                        : Column(
                            children: [
                              ...checkoutVm.paymentMethods.map((m) => _PaymentOption(
                                    method: m,
                                    isSelected:
                                        form.selectedPaymentMethod?.id ==
                                            m.id,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      context
                                          .read<CheckoutViewModel>()
                                          .selectPaymentMethod(m);
                                    },
                                  )),
                              SizedBox(height: w * 0.02),
                              _AddPaymentMethodButton(
                                onTap: () => _addPaymentMethod(context),
                              ),
                            ],
                          ),
                    },
                  ),
                ),

                SizedBox(height: w * 0.055),

                // ── Promo code ──
                PromoCodeSection(
                  appliedCode: cart.hasPromo ? cart.promoCode : null,
                  description: null,
                  discount: cart.discount,
                  currency: currency,
                  isApplying: cartVm.isApplyingPromo,
                  error: cartVm.promoError ?? cart.promoError,
                  onApply: cartVm.applyPromoCode,
                  onRemove: cartVm.removePromoCode,
                  onEdited: cartVm.clearPromoError,
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
                                  formatMoney(ci.lineTotal, currency: currency),
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
                      _TotalRow(
                        label: 'Subtotal',
                        value: cart.subtotal,
                        currency: currency,
                      ),
                      if (cart.hasPromo && (cart.discount ?? 0) > 0)
                        _TotalRow(
                          label: 'Promo (${cart.promoCode})',
                          value: cart.discount,
                          currency: currency,
                          isDiscount: true,
                        ),
                      _DeliveryFeeRow(
                        isFetching: form.isFetchingDeliveryQuote,
                        error: deliveryError ?? form.deliveryQuoteError,
                        fee: deliveryFee,
                        currency: currency,
                        onRetry: usesCartQuote
                            ? cartVm.refresh
                            : () => checkoutVm.fetchDeliveryQuote(cart.vendorId),
                      ),
                      if ((cart.serviceFee ?? 0) > 0)
                        _TotalRow(
                          label: 'Service fee',
                          value: cart.serviceFee,
                          currency: currency,
                        ),
                      SizedBox(height: w * 0.01),
                      _TotalRow(
                        label: 'Total',
                        value: total,
                        currency: currency,
                        isBold: true,
                      ),
                      if (!usesCartQuote && form.hasDestination)
                        Padding(
                          padding: EdgeInsets.only(top: w * 0.01),
                          child: Text(
                            'Final total is confirmed when you place the order.',
                            style: TextStyle(
                              fontSize: w * 0.028,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      if (walletSplit.usesWallet) ...[
                        _TotalRow(
                          label: 'Paid from wallet',
                          value: walletSplit.walletAmount,
                          currency: currency,
                          isDiscount: true,
                        ),
                        _TotalRow(
                          label: 'To pay via mobile money',
                          value: walletSplit.remaining,
                          currency: currency,
                          isBold: true,
                        ),
                      ],
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
                if (blockedReason != null)
                  _ValidationWarning(message: blockedReason),
                ElevatedButton(
                  onPressed: canPlace
                      ? () {
                          HapticFeedback.mediumImpact();
                          _confirmAndPlaceOrder(
                            cart: cart,
                            total: total,
                            deliveryFee: deliveryFee,
                            split: walletSplit,
                          );
                        }
                      : null,
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
                          _placeOrderLabel(
                            total: total,
                            split: walletSplit,
                            currency: currency,
                          ),
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

/// The amount due is `wallet.payable` when the wallet is used, otherwise the
/// backend total — never `total − balance`.
String _placeOrderLabel({
  required double? total,
  required WalletSplit split,
  required String currency,
}) {
  if (total == null) return 'Place Order';
  if (split.coversFully) {
    return 'Pay with Wallet · ${formatMoney(total, currency: currency)}';
  }
  final due = split.usesWallet ? split.remaining : total;
  return 'Place Order · ${formatMoney(due, currency: currency)}';
}

/// [isEstimate] marks a client-side total for a non-default address; [total]
/// is null only when not even an estimate could be made.
String _paymentConfirmationMessage({
  required double? total,
  required WalletSplit split,
  required String currency,
  required bool isEstimate,
}) {
  if (total == null) {
    return 'Your final total, including delivery to this address, is '
        'confirmed when the order is placed.';
  }
  final formatted = formatMoney(total, currency: currency);
  final amount = isEstimate ? 'an estimated $formatted' : formatted;
  final message = split.coversFully
      ? 'You are about to pay $amount from your wallet balance.'
      : split.usesWallet
          ? 'You are about to pay $amount — '
              '${formatMoney(split.walletAmount, currency: currency)} from '
              'your wallet and '
              '${formatMoney(split.remaining, currency: currency)} via '
              'mobile money.'
          : 'You are about to pay $amount for this order.';
  return isEstimate
      ? '$message The final amount is confirmed when the order is placed.'
      : message;
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
/// or the quoted fee otherwise — `—` until there is an address to quote.
class _DeliveryFeeRow extends StatelessWidget {
  final bool isFetching;
  final String? error;
  final double? fee;
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
  final double? value;
  final bool isBold;
  final String currency;

  /// Renders [value] (always passed as a positive amount) with a leading
  /// "-" and a success tint, for the promo-discount and wallet lines.
  final bool isDiscount;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.currency = 'GHS',
    this.isDiscount = false,
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
            isDiscount && value != null
                ? '-${formatMoney(value, currency: currency)}'
                : formatMoney(value, currency: currency),
            style: TextStyle(
              fontSize: isBold ? w * 0.038 : w * 0.033,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: isDiscount
                  ? AppColors.success
                  : (isBold ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
