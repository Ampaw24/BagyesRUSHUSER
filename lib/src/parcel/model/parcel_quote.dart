import 'package:equatable/equatable.dart';
import 'parcel_stop.dart';
import 'rider_model.dart';

class ParcelQuote extends Equatable {
  const ParcelQuote({
    required this.id,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.stops,
    required this.price,
    this.deliveryFee,
    this.serviceFee,
    required this.currency,
    required this.distanceKm,
    required this.etaMinutes,
    required this.expiresAt,
    required this.rider,
  });

  final int id;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final List<ParcelStop> stops;

  /// What the customer is charged — the backend's `total` (delivery fee +
  /// service fee). Never computed client-side.
  final double price;

  /// Breakdown of [price]: `fee` and `service_fee`. Null when the response
  /// omits them.
  final double? deliveryFee;
  final double? serviceFee;
  final String currency;
  final double? distanceKm;
  final int? etaMinutes;
  final DateTime? expiresAt;

  /// The rider the backend matched to this quote, or null when no rider
  /// is available nearby right now.
  final RiderModel? rider;

  factory ParcelQuote.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['delivery_quote_id'];
    // `total` first: `fee` alone leaves out the service fee.
    final rawPrice = json['total'] ??
        json['price'] ??
        json['amount'] ??
        json['fee'] ??
        json['cost'];
    final rawStops = json['stops'] as List<dynamic>? ?? [];
    final rawRider = json['rider'];
    return ParcelQuote(
      id: (rawId as num?)?.toInt() ?? 0,
      pickupAddress: json['pickup_address']?.toString() ?? '',
      pickupLatitude: (json['pickup_latitude'] as num?)?.toDouble() ?? 0.0,
      pickupLongitude: (json['pickup_longitude'] as num?)?.toDouble() ?? 0.0,
      stops: rawStops
          .map((e) => ParcelStop.fromJson(e as Map<String, dynamic>))
          .toList(),
      price: (rawPrice as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['fee'] as num?)?.toDouble(),
      serviceFee: (json['service_fee'] as num?)?.toDouble(),
      currency: json['currency']?.toString() ?? 'GHS',
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      rider: rawRider is Map<String, dynamic>
          ? RiderModel.fromJson(rawRider)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pickup_address': pickupAddress,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'stops': stops.map((s) => s.toQuoteJson()).toList(),
        'total': price,
        'fee': deliveryFee,
        'service_fee': serviceFee,
        'currency': currency,
        'distance_km': distanceKm,
        'eta_minutes': etaMinutes,
        'expires_at': expiresAt?.toIso8601String(),
      };

  /// Still bookable at [now], with [margin] to spare for the create call.
  /// A quote without an expiry is never assumed valid.
  bool isBookableAt(
    DateTime now, {
    Duration margin = const Duration(seconds: 30),
  }) {
    final expires = expiresAt;
    return expires != null && expires.isAfter(now.add(margin));
  }

  @override
  String toString() => '$id, ${stops.length} stop(s), $currency $price';

  @override
  List<Object?> get props => [
        id,
        pickupAddress,
        pickupLatitude,
        pickupLongitude,
        stops,
        price,
        deliveryFee,
        serviceFee,
        currency,
        distanceKm,
        etaMinutes,
        expiresAt,
        rider,
      ];
}
