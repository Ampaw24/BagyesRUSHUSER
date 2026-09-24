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
    this.serviceFee,
    this.id,
  });

  final double fee;
  final String currency;
  final double? distanceKm;
  final DateTime? expiresAt;

  /// `service_fee` on the quote response, when the backend sends one.
  final double? serviceFee;

  /// `id` (aka `delivery_quote_id`) — this quote's identifier, needed when
  /// referencing it from another endpoint (e.g. promo-code validation's
  /// optional `delivery_quote_id`). Mirrors the same fallback already proven
  /// for `ParcelQuote.id` on this backend's sibling quote endpoint.
  final int? id;

  factory DeliveryQuote.fromJson(Map<String, dynamic> json) {
    final rawFee = json['fee'] ??
        json['delivery_fee'] ??
        json['price'] ??
        json['amount'] ??
        json['total'] ??
        json['cost'];
    final rawId = json['id'] ?? json['delivery_quote_id'];
    return DeliveryQuote(
      fee: (rawFee as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'GHS',
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      serviceFee: (json['service_fee'] as num?)?.toDouble(),
      id: (rawId as num?)?.toInt(),
    );
  }

  @override
  List<Object?> get props =>
      [fee, currency, distanceKm, expiresAt, serviceFee, id];
}
