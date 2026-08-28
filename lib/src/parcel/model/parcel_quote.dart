import 'package:equatable/equatable.dart';
import 'parcel_stop.dart';

class ParcelQuote extends Equatable {
  const ParcelQuote({
    required this.id,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.stops,
    required this.price,
    required this.currency,
    required this.distanceKm,
    required this.expiresAt,
  });

  final int id;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final List<ParcelStop> stops;
  final double price;
  final String currency;
  final double? distanceKm;
  final DateTime? expiresAt;

  factory ParcelQuote.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['delivery_quote_id'];
    final rawPrice = json['price'] ??
        json['amount'] ??
        json['fee'] ??
        json['total'] ??
        json['cost'];
    final rawStops = json['stops'] as List<dynamic>? ?? [];
    return ParcelQuote(
      id: (rawId as num?)?.toInt() ?? 0,
      pickupAddress: json['pickup_address']?.toString() ?? '',
      pickupLatitude: (json['pickup_latitude'] as num?)?.toDouble() ?? 0.0,
      pickupLongitude: (json['pickup_longitude'] as num?)?.toDouble() ?? 0.0,
      stops: rawStops
          .map((e) => ParcelStop.fromJson(e as Map<String, dynamic>))
          .toList(),
      price: (rawPrice as num?)?.toDouble() ?? 0.0,
      currency: json['currency']?.toString() ?? 'GHS',
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pickup_address': pickupAddress,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'stops': stops.map((s) => s.toQuoteJson()).toList(),
        'price': price,
        'currency': currency,
        'distance_km': distanceKm,
        'expires_at': expiresAt?.toIso8601String(),
      };

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
        currency,
        distanceKm,
        expiresAt,
      ];
}
