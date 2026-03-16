import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/states/cart_state.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/viewmodels/cart_viewmodel.dart';
import 'package:bagyesrushappusernew/features/consumer/checkout/domain/entities/checkout_model.dart';
import 'package:bagyesrushappusernew/features/consumer/checkout/presentation/states/checkout_state.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/presentation/viewmodels/orders_viewmodel.dart';

// ─── Checkout ViewModel ────────────────────────────────────────────────────

class CheckoutViewModel extends Notifier<CheckoutState> {
  @override
  CheckoutState build() => const CheckoutIdle(
        form: CheckoutForm(deliveryAddress: '12 Osu Badu St, Accra'),
      );

  CheckoutForm get _currentForm {
    final s = state;
    if (s is CheckoutIdle) return s.form;
    if (s is CheckoutPlacing) return s.form;
    if (s is CheckoutError) return s.form;
    return const CheckoutForm(deliveryAddress: '12 Osu Badu St, Accra');
  }

  void updateAddress(String address) {
    state = CheckoutIdle(form: _currentForm.copyWith(deliveryAddress: address));
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
          );
      ref.read(cartProvider.notifier).clear();
      state = CheckoutSuccess(orderId: order.id);
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
