import 'package:equatable/equatable.dart';

/// A single destination within a multi-stop parcel order (1–8 per parcel).
///
/// Used both for `POST customer/parcels` (full shape, via [toJson]) and
/// `POST customer/parcels/quotes` (lighter shape — location, size, weight
/// and fragility only, via [toQuoteJson]).
class ParcelStop extends Equatable {
  const ParcelStop({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.recipientName,
    this.recipientPhone,
    this.instructions,
    this.itemDescription,
    required this.size,
    this.quantity,
    this.isFragile,
    this.declaredValue,
    this.weightKg,
    this.photoIds,
  });

  final String address;
  final double latitude;
  final double longitude;
  final String? recipientName;
  final String? recipientPhone;
  final String? instructions;
  final String? itemDescription;
  final String size;
  final int? quantity;
  final bool? isFragile;
  final double? declaredValue;
  final double? weightKg;
  final List<int>? photoIds;

  ParcelStop copyWith({
    String? address,
    double? latitude,
    double? longitude,
    String? recipientName,
    String? recipientPhone,
    String? instructions,
    String? itemDescription,
    String? size,
    int? quantity,
    bool? isFragile,
    double? declaredValue,
    double? weightKg,
    List<int>? photoIds,
  }) {
    return ParcelStop(
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      instructions: instructions ?? this.instructions,
      itemDescription: itemDescription ?? this.itemDescription,
      size: size ?? this.size,
      quantity: quantity ?? this.quantity,
      isFragile: isFragile ?? this.isFragile,
      declaredValue: declaredValue ?? this.declaredValue,
      weightKg: weightKg ?? this.weightKg,
      photoIds: photoIds ?? this.photoIds,
    );
  }

  factory ParcelStop.fromJson(Map<String, dynamic> json) {
    final rawPhotoIds = json['photo_ids'] as List<dynamic>?;
    return ParcelStop(
      address: json['address']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      recipientName: json['recipient_name']?.toString(),
      recipientPhone: json['recipient_phone']?.toString(),
      instructions: json['instructions']?.toString(),
      itemDescription: json['item_description']?.toString(),
      size: json['size']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt(),
      isFragile: json['is_fragile'] as bool?,
      declaredValue: (json['declared_value'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      photoIds: rawPhotoIds?.map((e) => (e as num).toInt()).toList(),
    );
  }

  /// Full shape for `POST customer/parcels`.
  Map<String, dynamic> toJson() => {
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'recipient_name': recipientName,
        'recipient_phone': recipientPhone,
        'instructions': instructions,
        'item_description': itemDescription,
        'size': size,
        'quantity': quantity,
        'is_fragile': isFragile,
        'declared_value': declaredValue,
        'weight_kg': weightKg,
        'photo_ids': photoIds,
      };

  /// Lighter shape for `POST customer/parcels/quotes`.
  Map<String, dynamic> toQuoteJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'size': size,
        'is_fragile': isFragile,
        'weight_kg': weightKg,
      };

  @override
  String toString() => '$address ($size)';

  @override
  List<Object?> get props => [
        address,
        latitude,
        longitude,
        recipientName,
        recipientPhone,
        instructions,
        itemDescription,
        size,
        quantity,
        isFragile,
        declaredValue,
        weightKg,
        photoIds,
      ];
}
