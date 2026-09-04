import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_model.dart';
import 'package:bagyesrushappusernew/src/checkout/models/checkout_model.dart';
import 'package:bagyesrushappusernew/src/checkout/viewmodels/checkout_state.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/repositories/consumer_orders_repository.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/payment/model/payment_method.dart';
import 'package:bagyesrushappusernew/src/payment/repository/payment_repository.dart';

enum PaymentMethodsStatus { loading, error, loaded }

// ─── Checkout ViewModel ────────────────────────────────────────────────────

class CheckoutViewModel extends ViewModel<CheckoutState> {
  CheckoutViewModel({
    required OrdersViewModel ordersViewModel,
    required ConsumerOrdersRepository ordersRepository,
    required PaymentRepository paymentRepository,
  })  : _ordersViewModel = ordersViewModel,
        _ordersRepository = ordersRepository,
        _paymentRepository = paymentRepository,
        super(const CheckoutIdle(form: CheckoutForm())) {
    _loadPaymentMethods();
  }

  final OrdersViewModel _ordersViewModel;
  final ConsumerOrdersRepository _ordersRepository;
  final PaymentRepository _paymentRepository;

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

  /// For hand-typed address input. Keeps any previously-resolved GPS/map
  /// coordinates in place — a text edit (e.g. adding "Apt 4B") doesn't mean
  /// the pin moved, so the picked location should still be sent with the
  /// order. Coordinates are only cleared when the user explicitly picks a
  /// new location (see `updateAddressWithCoordinates`) or clears the field.
  void updateAddress(String address) {
    emit(CheckoutIdle(form: _currentForm.copyWith(deliveryAddress: address)));
  }

  /// For GPS ("use current location") or the map picker, where a real
  /// coordinate is available alongside the resolved address string.
  void updateAddressWithCoordinates(
    String address, {
    required double latitude,
    required double longitude,
  }) {
    final form = _currentForm;
    emit(CheckoutIdle(
      form: CheckoutForm(
        deliveryAddress: address,
        deliveryInstructions: form.deliveryInstructions,
        selectedPaymentMethod: form.selectedPaymentMethod,
        deliveryLat: latitude,
        deliveryLng: longitude,
      ),
    ));
  }

  void updateInstructions(String instructions) {
    emit(CheckoutIdle(
        form: _currentForm.copyWith(deliveryInstructions: instructions)));
  }

  void selectPaymentMethod(PaymentMethod method) {
    emit(CheckoutIdle(
        form: _currentForm.copyWith(selectedPaymentMethod: method)));
  }

  Future<void> placeOrder(CartModel cart) async {
    if (cart.isEmpty) return;
    final form = _currentForm;
    final method = form.selectedPaymentMethod;
    if (method == null) {
      emit(CheckoutError(
        form: form,
        message: 'Please select a payment method',
      ));
      return;
    }
    emit(CheckoutPlacing(form: form));

    try {
      final order = await _ordersViewModel.placeOrder(
        cart: cart,
        deliveryAddress: form.deliveryAddress,
        deliveryInstructions: form.deliveryInstructions.isEmpty
            ? null
            : form.deliveryInstructions,
        // The backend's payment_method enum only accepts 'card' or
        // 'mobile_money' — checkout only ever offers saved mobile-money
        // accounts (see [paymentMethods]), so this is always 'mobile_money'.
        // method.displayTitle is a human-readable nickname/provider name and
        // isn't a valid value here.
        paymentMethod: 'mobile_money',
        deliveryLat: form.deliveryLat,
        deliveryLng: form.deliveryLng,
      );
      // Cart clearing stays in the view (not here) — it's a one-shot
      // navigation-adjacent side effect, not checkout submission state.
      emit(CheckoutSuccess(orderId: order.id));
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

  void resetAfterError() {
    final s = state;
    if (s is CheckoutError) {
      emit(CheckoutIdle(form: s.form));
    }
  }

  /// Fetches a live delivery-fee quote for [vendorId] via
  /// `GET /customer/delivery-quote` so checkout shows the authoritative fee
  /// instead of the (possibly stale) one embedded in the cart response.
  /// Display-only: what's actually charged is still decided by the backend
  /// when the order is created, so a failure here doesn't block checkout —
  /// the UI falls back to the cart's fee and offers a manual retry.
  Future<void> fetchDeliveryQuote(String vendorId) async {
    emit(CheckoutIdle(
      form: _currentForm.copyWith(
        isFetchingDeliveryQuote: true,
        deliveryQuoteError: null,
      ),
    ));

    try {
      final form = _currentForm;
      final quote = await _ordersRepository.getDeliveryQuote(
        vendorId: vendorId,
        latitude: form.deliveryLat,
        longitude: form.deliveryLng,
        deliveryAddress:
            form.deliveryAddress.isEmpty ? null : form.deliveryAddress,
      );
      emit(CheckoutIdle(
        form: _currentForm.copyWith(
          isFetchingDeliveryQuote: false,
          deliveryQuoteFee: quote.fee,
          deliveryQuoteCurrency: quote.currency,
          deliveryQuoteServiceFee: quote.serviceFee,
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
