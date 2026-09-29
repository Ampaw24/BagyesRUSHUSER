import 'package:bagyesrushappusernew/src/checkout/models/checkout_model.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';

/// Sealed states for the checkout flow.
sealed class CheckoutState {
  const CheckoutState();
}

/// User is editing the checkout form — idle state.
class CheckoutIdle extends CheckoutState {
  final CheckoutForm form;
  const CheckoutIdle({required this.form});
}

/// Order is being placed (network/async in progress).
class CheckoutPlacing extends CheckoutState {
  final CheckoutForm form;
  const CheckoutPlacing({required this.form});
}

/// Order was placed — carries the created order (`201` body), the form it
/// was placed with (its payment method is charged next), and whether any
/// amount is left to pay after the wallet.
class CheckoutSuccess extends CheckoutState {
  final ConsumerOrder order;
  final CheckoutForm form;
  final bool requiresPayment;
  const CheckoutSuccess({
    required this.order,
    required this.form,
    required this.requiresPayment,
  });
}

/// Order placement failed.
class CheckoutError extends CheckoutState {
  final CheckoutForm form;
  final String message;
  const CheckoutError({required this.form, required this.message});
}
