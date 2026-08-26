import 'package:equatable/equatable.dart';

class ParcelQuote extends Equatable {
  const ParcelQuote({
    required this.id,
    required this.pickupAddress,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.dropoffAddress,
    required this.dropoffLatitude,
    required this.dropoffLongitude,
    required this.size,
    required this.isFragile,
    required this.price,
    required this.currency,
    required this.distanceKm,
    required this.expiresAt,
  });

  final int id;
  final String pickupAddress;
  final double pickupLatitude;
  final double pickupLongitude;
  final String dropoffAddress;
  final double dropoffLatitude;
  final double dropoffLongitude;
  final String size;
  final bool isFragile;
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
    return ParcelQuote(
      id: (rawId as num?)?.toInt() ?? 0,
      pickupAddress: json['pickup_address']?.toString() ?? '',
      pickupLatitude:
          (json['pickup_latitude'] as num?)?.toDouble() ?? 0.0,
      pickupLongitude:
          (json['pickup_longitude'] as num?)?.toDouble() ?? 0.0,
      dropoffAddress: json['dropoff_address']?.toString() ?? '',
      dropoffLatitude:
          (json['dropoff_latitude'] as num?)?.toDouble() ?? 0.0,
      dropoffLongitude:
          (json['dropoff_longitude'] as num?)?.toDouble() ?? 0.0,
      size: json['size']?.toString() ?? '',
      isFragile: json['is_fragile'] as bool? ?? false,
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
        'dropoff_address': dropoffAddress,
        'dropoff_latitude': dropoffLatitude,
        'dropoff_longitude': dropoffLongitude,
        'size': size,
        'is_fragile': isFragile,
        'price': price,
        'currency': currency,
        'distance_km': distanceKm,
        'expires_at': expiresAt?.toIso8601String(),
      };

  @override
  String toString() => '$id, $size, $currency $price';

  @override
  List<Object?> get props => [
        id,
        pickupAddress,
        pickupLatitude,
        pickupLongitude,
        dropoffAddress,
        dropoffLatitude,
        dropoffLongitude,
        size,
        isFragile,
        price,
        currency,
        distanceKm,
        expiresAt,
      ];
}
