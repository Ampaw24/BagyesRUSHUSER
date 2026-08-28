import 'package:equatable/equatable.dart';
import 'parcel_stop.dart';

class Parcel extends Equatable {
  const Parcel({
    required this.id,
    required this.deliveryQuoteId,
    required this.paymentMethod,
    required this.paymentMethodId,
    required this.pickupAddress,
    required this.pickupContactName,
    required this.pickupContactPhone,
    required this.pickupInstructions,
    required this.stops,
    required this.status,
    required this.trackingNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int? deliveryQuoteId;
  final String paymentMethod;
  final int? paymentMethodId;
  final String pickupAddress;
  final String? pickupContactName;
  final String? pickupContactPhone;
  final String? pickupInstructions;
  final List<ParcelStop> stops;
  final String status;
  final String? trackingNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Parcel copyWith({
    String? id,
    int? deliveryQuoteId,
    String? paymentMethod,
    int? paymentMethodId,
    String? pickupAddress,
    String? pickupContactName,
    String? pickupContactPhone,
    String? pickupInstructions,
    List<ParcelStop>? stops,
    String? status,
    String? trackingNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Parcel(
      id: id ?? this.id,
      deliveryQuoteId: deliveryQuoteId ?? this.deliveryQuoteId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupContactName: pickupContactName ?? this.pickupContactName,
      pickupContactPhone: pickupContactPhone ?? this.pickupContactPhone,
      pickupInstructions: pickupInstructions ?? this.pickupInstructions,
      stops: stops ?? this.stops,
      status: status ?? this.status,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Parcel.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops'] as List<dynamic>? ?? [];
    return Parcel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      deliveryQuoteId: (json['delivery_quote_id'] as num?)?.toInt(),
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentMethodId: (json['payment_method_id'] as num?)?.toInt(),
      pickupAddress: json['pickup_address']?.toString() ?? '',
      pickupContactName: json['pickup_contact_name']?.toString(),
      pickupContactPhone: json['pickup_contact_phone']?.toString(),
      pickupInstructions: json['pickup_instructions']?.toString(),
      stops: rawStops
          .map((e) => ParcelStop.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status']?.toString() ?? '',
      trackingNumber: json['tracking_number']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'delivery_quote_id': deliveryQuoteId,
        'payment_method': paymentMethod,
        'payment_method_id': paymentMethodId,
        'pickup_address': pickupAddress,
        'pickup_contact_name': pickupContactName,
        'pickup_contact_phone': pickupContactPhone,
        'pickup_instructions': pickupInstructions,
        'stops': stops.map((s) => s.toJson()).toList(),
        'status': status,
        'tracking_number': trackingNumber,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  @override
  String toString() => '$id, $status, $pickupAddress → ${stops.length} stop(s)';

  @override
  List<Object?> get props => [
        id,
        deliveryQuoteId,
        paymentMethod,
        paymentMethodId,
        pickupAddress,
        pickupContactName,
        pickupContactPhone,
        pickupInstructions,
        stops,
        status,
        trackingNumber,
        createdAt,
        updatedAt,
      ];
}
