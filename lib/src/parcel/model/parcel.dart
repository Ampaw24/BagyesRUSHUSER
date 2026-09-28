import 'package:equatable/equatable.dart';

import 'parcel_direction.dart';
import 'parcel_pickup.dart';
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
    this.direction = ParcelDirection.send,
    this.directionLabel,
    this.pickup,
    this.canCancel = false,
    this.paymentStatus,
    this.amountDue,
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
  final ParcelDirection direction;
  final String? directionLabel;
  final ParcelPickup? pickup;
  final bool canCancel;

  /// Present when the backend reports it on create — lets the client skip
  /// the mobile-money step when the wallet already settled the charge.
  final String? paymentStatus;
  final double? amountDue;

  bool get isPaid =>
      const {'paid', 'success', 'successful'}.contains(paymentStatus) ||
      (amountDue != null && amountDue! <= 0);

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
    ParcelDirection? direction,
    String? directionLabel,
    ParcelPickup? pickup,
    bool? canCancel,
    String? paymentStatus,
    double? amountDue,
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
      direction: direction ?? this.direction,
      directionLabel: directionLabel ?? this.directionLabel,
      pickup: pickup ?? this.pickup,
      canCancel: canCancel ?? this.canCancel,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      amountDue: amountDue ?? this.amountDue,
    );
  }

  factory Parcel.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops'] as List<dynamic>? ?? [];
    final rawPickup = json['pickup'];
    final pickup =
        rawPickup is Map<String, dynamic> ? ParcelPickup.fromJson(rawPickup) : null;
    return Parcel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      deliveryQuoteId: (json['delivery_quote_id'] as num?)?.toInt(),
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentMethodId: (json['payment_method_id'] as num?)?.toInt(),
      pickupAddress: json['pickup_address']?.toString() ?? pickup?.address ?? '',
      pickupContactName:
          json['pickup_contact_name']?.toString() ?? pickup?.contactName,
      pickupContactPhone:
          json['pickup_contact_phone']?.toString() ?? pickup?.contactPhone,
      pickupInstructions: json['pickup_instructions']?.toString(),
      stops: rawStops
          .map((e) => ParcelStop.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status']?.toString() ?? '',
      trackingNumber: json['tracking_number']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      direction: ParcelDirection.fromApi(json['direction']?.toString()),
      directionLabel: json['direction_label']?.toString(),
      pickup: pickup,
      canCancel: json['can_cancel'] == true,
      paymentStatus: json['payment_status']?.toString(),
      amountDue: (json['amount_due'] as num?)?.toDouble(),
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
        'direction': direction.apiValue,
        'can_cancel': canCancel,
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
        direction,
        directionLabel,
        pickup,
        canCancel,
        paymentStatus,
        amountDue,
      ];
}
