import 'package:bagyesrushappusernew/src/checkout/models/checkout_model.dart';

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

/// Order was placed successfully — carries the new order ID.
class CheckoutSuccess extends CheckoutState {
  final String orderId;
  const CheckoutSuccess({required this.orderId});
}

/// Order placement failed.
class CheckoutError extends CheckoutState {
  final CheckoutForm form;
  final String message;
  const CheckoutError({required this.form, required this.message});
}
