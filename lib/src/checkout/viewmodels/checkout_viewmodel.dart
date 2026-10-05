import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/common/app/session_aware.dart';
import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_model.dart';
import 'package:bagyesrushappusernew/src/checkout/models/checkout_model.dart';
import 'package:bagyesrushappusernew/src/checkout/viewmodels/checkout_state.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/repositories/consumer_orders_repository.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/customer_address/models/customer_address.dart';
import 'package:bagyesrushappusernew/src/customer_address/models/delivery_location.dart';
import 'package:bagyesrushappusernew/src/customer_address/repositories/customer_address_repository.dart';
import 'package:bagyesrushappusernew/src/payment/model/payment_method.dart';
import 'package:bagyesrushappusernew/src/payment/repository/payment_repository.dart';

enum PaymentMethodsStatus { loading, error, loaded }

enum AddressesStatus { loading, error, loaded }

// ─── Checkout ViewModel ────────────────────────────────────────────────────

class CheckoutViewModel extends ViewModel<CheckoutState> with SessionAware {
  CheckoutViewModel({
    required OrdersViewModel ordersViewModel,
    required ConsumerOrdersRepository ordersRepository,
    required PaymentRepository paymentRepository,
    required CustomerAddressRepository addressRepository,
    required CurrentUserProvider session,
  })  : _ordersViewModel = ordersViewModel,
        _ordersRepository = ordersRepository,
        _paymentRepository = paymentRepository,
        _addressRepository = addressRepository,
        super(const CheckoutIdle(form: CheckoutForm())) {
    bindSession(session);
  }

  /// Drops the previous account's saved payment methods, addresses and
  /// half-filled form on logout (see [SessionAware]) — the checkout screen
  /// reloads them on entry.
  void reset() {
    _paymentMethods = const [];
    _paymentMethodsStatus = PaymentMethodsStatus.loading;
    _addresses = const [];
    _addressesStatus = AddressesStatus.loading;
    emit(const CheckoutIdle(form: CheckoutForm()));
  }

  @override
  void onSignedOut() => reset();

  final OrdersViewModel _ordersViewModel;
  final ConsumerOrdersRepository _ordersRepository;
  final PaymentRepository _paymentRepository;
  final CustomerAddressRepository _addressRepository;

  // ─── Payment methods (orthogonal to the CheckoutState phase above) ───────

  PaymentMethodsStatus _paymentMethodsStatus = PaymentMethodsStatus.loading;
  List<PaymentMethod> _paymentMethods = const [];
  PaymentMethodsStatus get paymentMethodsStatus => _paymentMethodsStatus;
  List<PaymentMethod> get paymentMethods => _paymentMethods;

  /// The customer's saved mobile-money payment methods, for the checkout
  /// payment-method picker. Reuses the same [PaymentRepository] the
  /// Profile → Payment Methods screen uses.
  Future<void> _loadPaymentMethods() async {
    _paymentMethodsStatus = PaymentMethodsStatus.loading;
    notifyListeners();

    final result = await _paymentRepository.getCustomerPaymentMethods();
    result.fold(
      (failure) {
        _paymentMethodsStatus = PaymentMethodsStatus.error;
        notifyListeners();
      },
      (methods) {
        _paymentMethods = methods;
        _paymentMethodsStatus = PaymentMethodsStatus.loaded;
        notifyListeners();

        // Auto-select the customer's default (or first) saved payment method
        // once the list loads, so they aren't forced to tap it explicitly.
        if (methods.isNotEmpty && _currentForm.selectedPaymentMethod == null) {
          final defaultMethod = methods.firstWhere(
            (m) => m.isDefault,
            orElse: () => methods.first,
          );
          selectPaymentMethod(defaultMethod);
        }
      },
    );
  }

  Future<void> refreshPaymentMethods() => _loadPaymentMethods();

  // ─── Checkout form / submission state machine ─────────────────────────────

  CheckoutForm get _currentForm {
    final s = state;
    if (s is CheckoutIdle) return s.form;
    if (s is CheckoutPlacing) return s.form;
    if (s is CheckoutError) return s.form;
    return const CheckoutForm();
  }

  // ─── Saved addresses ──────────────────────────────────────────────────────

  AddressesStatus _addressesStatus = AddressesStatus.loading;
  List<CustomerAddress> _addresses = const [];
  AddressesStatus get addressesStatus => _addressesStatus;
  List<CustomerAddress> get addresses => _addresses;

  /// Loads saved addresses and preselects the default (whose quote is
  /// already embedded in the cart) unless a destination is already chosen.
  Future<void> loadAddresses(String vendorId) async {
    _addressesStatus = AddressesStatus.loading;
    notifyListeners();

    final result = await _addressRepository.getAddresses();
    result.fold(
      (_) {
        _addressesStatus = AddressesStatus.error;
        notifyListeners();
      },
      (list) {
        _addresses = list;
        _addressesStatus = AddressesStatus.loaded;
        notifyListeners();
        if (_currentForm.pickedLocation != null) return;
        final selected = _currentForm.selectedAddress;
        final stillSaved = selected != null && list.any((a) => a.id == selected.id);
        if (list.isNotEmpty && !stillSaved) {
          selectAddress(
            list.firstWhere((a) => a.isDefault, orElse: () => list.first),
            vendorId: vendorId,
          );
        }
      },
    );
  }

  /// Non-default addresses need their own quote; the default's is the
  /// cart's embedded one.
  void selectAddress(CustomerAddress address, {required String vendorId}) {
    emit(CheckoutIdle(
      form: _currentForm.copyWith(
        selectedAddress: address,
        pickedLocation: null,
        deliveryQuote: null,
        deliveryQuoteError: null,
        isFetchingDeliveryQuote: false,
      ),
    ));
    if (!address.isDefault) fetchDeliveryQuote(vendorId);
  }

  /// Uses a GPS / map-picked location as-is — it is not saved as a customer
  /// address; the quote and order carry its coordinates instead.
  void selectLocation(DeliveryLocation location, {required String vendorId}) {
    emit(CheckoutIdle(
      form: _currentForm.copyWith(
        selectedAddress: null,
        pickedLocation: location,
        deliveryQuote: null,
        deliveryQuoteError: null,
        isFetchingDeliveryQuote: false,
      ),
    ));
    fetchDeliveryQuote(vendorId);
  }

  void updateInstructions(String instructions) {
    emit(CheckoutIdle(
        form: _currentForm.copyWith(deliveryInstructions: instructions)));
  }

  void selectPaymentMethod(PaymentMethod method) {
    emit(CheckoutIdle(
        form: _currentForm.copyWith(selectedPaymentMethod: method)));
  }

  void setUseWallet(bool value) {
    emit(CheckoutIdle(form: _currentForm.copyWith(useWallet: value)));
  }

  /// [walletCoversTotal] — the cart's `wallet.payable` is zero, so no
  /// mobile-money account is needed.
  Future<void> placeOrder(
    CartModel cart, {
    bool walletCoversTotal = false,
  }) async {
    if (cart.isEmpty) return;
    final form = _currentForm;
    final quoteId =
        form.usesCartQuote ? cart.deliveryQuoteId : form.deliveryQuote?.id;
    final needsMethod = !(form.useWallet && walletCoversTotal);

    final problem = !form.hasDestination
        ? 'Please choose a delivery address'
        : quoteId == null
            ? (cart.deliveryError ?? "Delivery isn't available to this address")
            : (form.selectedPaymentMethod == null && needsMethod)
                ? 'Please select a payment method'
                : null;
    if (problem != null) {
      emit(CheckoutError(form: form, message: problem));
      return;
    }
    emit(CheckoutPlacing(form: form));

    try {
      final order = await _ordersViewModel.placeOrder(
        vendorId: cart.vendorId,
        // Checkout only offers saved mobile-money accounts; the backend enum
        // is `card` | `mobile_money` | cash.
        paymentMethod: 'mobile_money',
        customerAddressId: form.selectedAddress?.id,
        location: form.selectedAddress == null ? form.pickedLocation : null,
        deliveryQuoteId: quoteId!,
        useWallet: form.useWallet,
        notes: form.deliveryInstructions.trim(),
      );
      emit(CheckoutSuccess(
        order: order,
        form: form,
        requiresPayment: needsMethod && order.needsPayment,
      ));
    } on DioException catch (e) {
      emit(CheckoutError(
        form: form,
        message: NetworkUtils.handleDioException(e).value.message,
      ));
    } catch (e) {
      emit(CheckoutError(
        form: form,
        message: 'Failed to place order. Please try again.',
      ));
    }
  }

  /// Clears a completed checkout so the next visit starts from a fresh form.
  void resetAfterSuccess() {
    if (state is CheckoutSuccess) emit(const CheckoutIdle(form: CheckoutForm()));
  }

  void resetAfterError() {
    final s = state;
    if (s is CheckoutError) {
      emit(CheckoutIdle(form: s.form));
    }
  }

  /// `GET /customer/delivery-quote` for the selected non-default address or
  /// picked location.
  /// Only `data.id` is ever sent back (as `delivery_quote_id`); an expired
  /// quote is re-priced server-side, so it is never refreshed here.
  Future<void> fetchDeliveryQuote(String vendorId) async {
    final address = _currentForm.selectedAddress;
    final location = address == null ? _currentForm.pickedLocation : null;
    if (address == null && location == null) return;
    final requested = (address, location);
    emit(CheckoutIdle(
      form: _currentForm.copyWith(
        isFetchingDeliveryQuote: true,
        deliveryQuoteError: null,
      ),
    ));

    try {
      final quote = await _ordersRepository.getDeliveryQuote(
        vendorId: vendorId,
        customerAddressId: address?.id,
        location: location,
      );
      final current = _currentForm;
      if ((current.selectedAddress, current.pickedLocation) != requested) {
        return;
      }
      emit(CheckoutIdle(
        form: _currentForm.copyWith(
          isFetchingDeliveryQuote: false,
          deliveryQuote: quote,
        ),
      ));
    } on DioException catch (e) {
      emit(CheckoutIdle(
        form: _currentForm.copyWith(
          isFetchingDeliveryQuote: false,
          deliveryQuoteError: NetworkUtils.handleDioException(e).value.message,
        ),
      ));
    } catch (_) {
      emit(CheckoutIdle(
        form: _currentForm.copyWith(
          isFetchingDeliveryQuote: false,
          deliveryQuoteError: 'Could not fetch delivery fee. Please retry.',
        ),
      ));
    }
  }
}
