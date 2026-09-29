/// Result of `POST customer/orders/:id/verify-payment`.
///
/// The success shape is undocumented, so [fromPayload] looks for a payment
/// status everywhere it plausibly lives: top-level `status` /
/// `payment_status`, a `payment` block, or a nested `order`. Anything
/// unrecognised (including an empty body) is neither paid nor failed — the
/// charge is still being confirmed.
class OrderPaymentVerification {
  const OrderPaymentVerification({this.isPaid = false, this.isFailed = false});

  final bool isPaid;
  final bool isFailed;

  bool get isPending => !isPaid && !isFailed;

  static const _paidValues = {'paid', 'success', 'successful'};
  static const _failedValues = {'failed', 'failure', 'abandoned', 'reversed'};

  factory OrderPaymentVerification.fromPayload(Map<String, dynamic> data) {
    if (_reports(data, _paidValues) ||
        data['paid'] == true ||
        data['is_paid'] == true) {
      return const OrderPaymentVerification(isPaid: true);
    }
    return OrderPaymentVerification(isFailed: _reports(data, _failedValues));
  }

  static bool _reports(Map<String, dynamic> data, Set<String> values) {
    for (final key in ['payment_status', 'status']) {
      final value = data[key];
      if (value != null && values.contains(value.toString().toLowerCase())) {
        return true;
      }
    }
    for (final key in ['payment', 'order']) {
      final nested = data[key];
      if (nested is Map<String, dynamic> && _reports(nested, values)) {
        return true;
      }
    }
    return false;
  }
}
