/// Result of `POST customer/orders/:id/verify-payment`.
///
/// The success shape is undocumented, so [fromPayload] looks for a payment
/// status everywhere it plausibly lives: top-level `status` /
/// `payment_status`, a `payment` block, or a nested `order`. Anything
/// unrecognised (including an empty body) is neither paid nor failed — the
/// charge is still being confirmed.
///
/// Receipt details ([reference], [paidAt], [channelLabel], [walletApplied])
/// are read from the same places when the backend sends them, and are null
/// otherwise — never derived.
class OrderPaymentVerification {
  const OrderPaymentVerification({
    this.isPaid = false,
    this.isFailed = false,
    this.reference,
    this.paidAt,
    this.channelLabel,
    this.walletApplied,
    this.message,
  });

  final bool isPaid;
  final bool isFailed;

  final String? reference;
  final DateTime? paidAt;

  /// Raw backend channel/method text (e.g. `mobile_money`, `MTN Mobile Money`).
  final String? channelLabel;
  final double? walletApplied;

  /// A server-worded reason, set when a definitive rejection carried one.
  final String? message;

  bool get isPending => !isPaid && !isFailed;

  static const _paidValues = {'paid', 'success', 'successful'};
  static const _failedValues = {'failed', 'failure', 'abandoned', 'reversed'};
  static const _nestedKeys = ['payment', 'transaction', 'order'];

  factory OrderPaymentVerification.fromPayload(Map<String, dynamic> data) {
    final isPaid =
        _reports(data, _paidValues) ||
        data['paid'] == true ||
        data['is_paid'] == true;
    return OrderPaymentVerification(
      isPaid: isPaid,
      isFailed: !isPaid && _reports(data, _failedValues),
      reference: _firstString(data, const ['reference', 'payment_reference']),
      paidAt: DateTime.tryParse(
        _firstString(data, const ['paid_at', 'paidAt']) ?? '',
      ),
      channelLabel: _firstString(data, const [
        'channel_label',
        'method_label',
        'channel',
        'payment_channel',
        'payment_method',
      ]),
      walletApplied: double.tryParse(
        _firstString(data, const ['wallet_amount', 'wallet_applied']) ?? '',
      ),
    );
  }

  static bool _reports(Map<String, dynamic> data, Set<String> values) {
    for (final key in ['payment_status', 'status']) {
      final value = data[key];
      if (value != null && values.contains(value.toString().toLowerCase())) {
        return true;
      }
    }
    for (final key in _nestedKeys) {
      final nested = data[key];
      if (nested is Map<String, dynamic> && _reports(nested, values)) {
        return true;
      }
    }
    return false;
  }

  /// First non-empty value for any of [keys], at the top level and then in
  /// the nested blocks.
  static String? _firstString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    for (final key in _nestedKeys) {
      final nested = data[key];
      if (nested is Map<String, dynamic>) {
        final value = _firstString(nested, keys);
        if (value != null) return value;
      }
    }
    return null;
  }
}
