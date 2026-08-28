import 'package:equatable/equatable.dart';

/// A live delivery-fee quote for a food order, from
/// `GET /customer/delivery-quote`.
///
/// The response shape isn't documented beyond the request params, so
/// [fromJson] parses tolerantly across the same key variants already
/// proven for this backend's other quote endpoint (`ParcelQuote` —
/// `lib/src/parcel/model/parcel_quote.dart`), whose controller-adjacent
/// `delivery_quote_id` fallback suggests a shared naming convention.
class DeliveryQuote extends Equatable {
  const DeliveryQuote({
    required this.fee,
    required this.currency,
    this.distanceKm,
    this.expiresAt,
  });

  final double fee;
  final String currency;
  final double? distanceKm;
  final DateTime? expiresAt;

  factory DeliveryQuote.fromJson(Map<String, dynamic> json) {
    final rawFee = json['fee'] ??
        json['delivery_fee'] ??
        json['price'] ??
        json['amount'] ??
        json['total'] ??
        json['cost'];
    return DeliveryQuote(
      fee: (rawFee as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'GHS',
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
    );
  }

  @override
  List<Object?> get props => [fee, currency, distanceKm, expiresAt];
}
