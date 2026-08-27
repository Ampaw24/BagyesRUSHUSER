import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/core/utils/network_utils.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/states/cart_state.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/viewmodels/cart_viewmodel.dart';
import 'package:bagyesrushappusernew/features/consumer/checkout/domain/entities/checkout_model.dart';
import 'package:bagyesrushappusernew/features/consumer/checkout/presentation/states/checkout_state.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/presentation/viewmodels/orders_viewmodel.dart';

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
        paymentMethod: form.paymentMethod,
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
        paymentMethod: form.paymentMethod,
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
    state =
        CheckoutIdle(form: _currentForm.copyWith(paymentMethod: method));
  }

  Future<void> placeOrder(CartState cart) async {
    if (cart.isEmpty) return;
    final form = _currentForm;
    state = CheckoutPlacing(form: form);

    try {
      final order = await ref.read(ordersProvider.notifier).placeOrder(
            cart: cart,
            deliveryAddress: form.deliveryAddress,
            deliveryInstructions: form.deliveryInstructions.isEmpty
                ? null
                : form.deliveryInstructions,
            paymentMethod: form.paymentMethod.label,
            deliveryLat: form.deliveryLat,
            deliveryLng: form.deliveryLng,
          );
      ref.read(cartProvider.notifier).clear();
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
}

final checkoutProvider =
    NotifierProvider<CheckoutViewModel, CheckoutState>(CheckoutViewModel.new);
