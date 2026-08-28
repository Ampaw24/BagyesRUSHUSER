import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/features/consumer/checkout/domain/entities/checkout_model.dart';
import 'package:bagyesrushappusernew/features/consumer/checkout/presentation/states/checkout_state.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/presentation/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_model.dart';
import 'package:bagyesrushappusernew/src/payment/model/payment_method.dart';

// ─── Checkout ViewModel ────────────────────────────────────────────────────

class CheckoutViewModel extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutIdle(
        form: CheckoutForm(),
      );

  CheckoutForm get _currentForm {
    final s = state;
    if (s is CheckoutIdle) return s.form;
    if (s is CheckoutPlacing) return s.form;
    if (s is CheckoutError) return s.form;
    return const CheckoutForm();
  }

  /// For hand-typed address input. Explicitly drops any previously-resolved
  /// coordinates (rebuilds `CheckoutForm` directly rather than via
  /// `copyWith`, since `copyWith`'s `??` semantics can't null a field back
  /// out) — editing the text after a GPS/map pick means the pin no longer
  /// matches, so a stale coordinate must not silently ride along.
  void updateAddress(String address) {
    final form = _currentForm;
    state = CheckoutIdle(
      form: CheckoutForm(
        deliveryAddress: address,
        deliveryInstructions: form.deliveryInstructions,
        selectedPaymentMethod: form.selectedPaymentMethod,
      ),
    );
  }

  /// For GPS ("use current location") or the map picker, where a real
  /// coordinate is available alongside the resolved address string.
  void updateAddressWithCoordinates(
    String address, {
    required double latitude,
    required double longitude,
  }) {
    final form = _currentForm;
    state = CheckoutIdle(
      form: CheckoutForm(
        deliveryAddress: address,
        deliveryInstructions: form.deliveryInstructions,
        selectedPaymentMethod: form.selectedPaymentMethod,
        deliveryLat: latitude,
        deliveryLng: longitude,
      ),
    );
  }

  void updateInstructions(String instructions) {
    state = CheckoutIdle(
        form: _currentForm.copyWith(deliveryInstructions: instructions));
  }

  void selectPaymentMethod(PaymentMethod method) {
    state = CheckoutIdle(
        form: _currentForm.copyWith(selectedPaymentMethod: method));
  }

  Future<void> placeOrder(CartModel cart) async {
    if (cart.isEmpty) return;
    final form = _currentForm;
    final method = form.selectedPaymentMethod;
    if (method == null) {
      state = CheckoutError(
        form: form,
        message: 'Please select a payment method',
      );
      return;
    }
    state = CheckoutPlacing(form: form);

    try {
      final order = await ref.read(ordersProvider.notifier).placeOrder(
            cart: cart,
            deliveryAddress: form.deliveryAddress,
            deliveryInstructions: form.deliveryInstructions.isEmpty
                ? null
                : form.deliveryInstructions,
            // The backend's payment_method enum only accepts 'card' or
            // 'mobile_money' — checkout only ever offers saved mobile-money
            // accounts (see checkoutPaymentMethodsProvider), so this is
            // always 'mobile_money'. method.displayTitle is a human-readable
            // nickname/provider name and isn't a valid value here.
            paymentMethod: 'mobile_money',
            deliveryLat: form.deliveryLat,
            deliveryLng: form.deliveryLng,
          );
      // Cart clearing is handled by the view (CartViewModel lives in the
      // `provider` ecosystem, not reachable from this Riverpod Notifier).
      state = CheckoutSuccess(orderId: order.id);
    } on DioException catch (e) {
      state = CheckoutError(
        form: form,
        message: NetworkUtils.handleDioException(e).value.message,
      );
    } catch (e) {
      state = CheckoutError(
        form: form,
        message: 'Failed to place order. Please try again.',
      );
    }
  }

  void resetAfterError() {
    final s = state;
    if (s is CheckoutError) {
      state = CheckoutIdle(form: s.form);
    }
  }

  /// Fetches a live delivery-fee quote for [vendorId] via
  /// `GET /customer/delivery-quote` so checkout shows the authoritative fee
  /// instead of the (possibly stale) one embedded in the cart response.
  /// Display-only: what's actually charged is still decided by the backend
  /// when the order is created, so a failure here doesn't block checkout —
  /// the UI falls back to the cart's fee and offers a manual retry.
  Future<void> fetchDeliveryQuote(String vendorId) async {
    state = CheckoutIdle(
      form: _currentForm.copyWith(
        isFetchingDeliveryQuote: true,
        deliveryQuoteError: null,
      ),
    );

    try {
      final quote = await ref
          .read(ordersRepositoryProvider)
          .getDeliveryQuote(vendorId: vendorId);
      state = CheckoutIdle(
        form: _currentForm.copyWith(
          isFetchingDeliveryQuote: false,
          deliveryQuoteFee: quote.fee,
          deliveryQuoteCurrency: quote.currency,
        ),
      );
    } on DioException catch (e) {
      state = CheckoutIdle(
        form: _currentForm.copyWith(
          isFetchingDeliveryQuote: false,
          deliveryQuoteError: NetworkUtils.handleDioException(e).value.message,
        ),
      );
    } catch (_) {
      state = CheckoutIdle(
        form: _currentForm.copyWith(
          isFetchingDeliveryQuote: false,
          deliveryQuoteError: 'Could not fetch delivery fee. Please retry.',
        ),
      );
    }
  }
}

final checkoutProvider =
    NotifierProvider<CheckoutViewModel, CheckoutState>(CheckoutViewModel.new);
