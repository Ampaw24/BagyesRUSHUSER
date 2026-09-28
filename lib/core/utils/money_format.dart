/// Formats a backend-supplied amount for display. Money figures are never
/// computed client-side, so a missing value renders as a dash rather than
/// a locally derived number.
String formatMoney(double? amount, {String currency = 'GHS'}) =>
    amount == null ? '—' : '$currency ${amount.toStringAsFixed(2)}';

/// Debug-only check of the backend identity
/// `subtotal − discount + delivery_fee + service_fee = total`. Skipped while
/// any figure is null (e.g. no delivery quote yet). Always returns true so
/// it can sit inside an `assert`; a mismatch throws with the figures.
bool debugCheckTotalsIdentity({
  required double? subtotal,
  required double? discount,
  required double? deliveryFee,
  required double? serviceFee,
  required double? total,
}) {
  if ([subtotal, deliveryFee, serviceFee, total].contains(null)) return true;
  final expected = subtotal! - (discount ?? 0) + deliveryFee! + serviceFee!;
  if ((expected - total!).abs() > 0.011) {
    throw StateError(
      'Totals identity broken: $subtotal − ${discount ?? 0} + $deliveryFee + '
      '$serviceFee = ${expected.toStringAsFixed(2)}, backend total = $total',
    );
  }
  return true;
}
