/// How a gateway payment attempt ended, from the customer's point of view.
enum OrderPaymentOutcome {
  /// The server confirmed the charge — the order is paid.
  paid,

  /// The customer finished at the gateway but the server hasn't confirmed
  /// the charge yet. "Pay Now" stays disabled meanwhile to avoid a double
  /// charge.
  processing,

  /// The customer closed the checkout without paying.
  dismissed;

  /// Snackbar copy to show once the flow ends; null when the confirmation
  /// dialog has already told the customer.
  String? get followUpMessage => switch (this) {
    OrderPaymentOutcome.paid => null,
    OrderPaymentOutcome.processing =>
      'We\'re confirming your payment — your order will update shortly.',
    OrderPaymentOutcome.dismissed =>
      'Payment not completed. Tap "Pay Now" to finish.',
  };
}
