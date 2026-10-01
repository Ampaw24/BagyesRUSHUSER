/// How a gateway payment attempt ended, from the customer's point of view.
enum OrderPaymentOutcome {
  /// The server confirmed the charge — the order is paid.
  paid,

  /// The customer finished at the gateway but the server hasn't confirmed
  /// the charge yet. "Pay Now" stays disabled meanwhile to avoid a double
  /// charge.
  processing,

  /// The gateway or server reported the charge as failed.
  failed,

  /// The customer closed the checkout without paying.
  dismissed;

  /// Snackbar copy to show once the flow ends; null when the receipt has
  /// already told the customer.
  String? get followUpMessage => switch (this) {
    OrderPaymentOutcome.paid => null,
    OrderPaymentOutcome.processing =>
      'We\'re confirming your payment — your order will update shortly.',
    OrderPaymentOutcome.failed ||
    OrderPaymentOutcome.dismissed =>
      'Payment not completed. Tap "Pay Now" to finish.',
  };
}

/// Where the customer asked to go when leaving the payment receipt.
enum PaymentExit {
  /// The order's tracking screen — the default, also for back/close.
  track,
  home,

  /// Failed payments only: start the payment again.
  retry,
}

/// What [OrderPaymentLauncher.pay] reports back: how the payment ended and
/// where the customer wants to go next.
class OrderPaymentResult {
  const OrderPaymentResult(this.outcome, [this.exit = PaymentExit.track]);

  final OrderPaymentOutcome outcome;
  final PaymentExit exit;
}
