import 'package:equatable/equatable.dart';

class Parcel extends Equatable {
  const Parcel({
    required this.id,
    required this.deliveryQuoteId,
    required this.paymentMethod,
    required this.paymentMethodId,
    required this.itemDescription,
    required this.quantity,
    required this.isFragile,
    required this.declaredValue,
    required this.pickupAddress,
    required this.pickupContactName,
    required this.pickupContactPhone,
    required this.pickupInstructions,
    required this.dropoffAddress,
    required this.recipientName,
    required this.recipientPhone,
    required this.deliveryInstructions,
    required this.photoIds,
    required this.status,
    required this.trackingNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int? deliveryQuoteId;
  final String paymentMethod;
  final int? paymentMethodId;
  final String itemDescription;
  final int quantity;
  final bool isFragile;
  final double? declaredValue;
  final String pickupAddress;
  final String? pickupContactName;
  final String? pickupContactPhone;
  final String? pickupInstructions;
  final String dropoffAddress;
  final String? recipientName;
  final String? recipientPhone;
  final String? deliveryInstructions;
  final List<int> photoIds;
  final String status;
  final String? trackingNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Parcel copyWith({
    String? id,
    int? deliveryQuoteId,
    String? paymentMethod,
    int? paymentMethodId,
    String? itemDescription,
    int? quantity,
    bool? isFragile,
    double? declaredValue,
    String? pickupAddress,
    String? pickupContactName,
    String? pickupContactPhone,
    String? pickupInstructions,
    String? dropoffAddress,
    String? recipientName,
    String? recipientPhone,
    String? deliveryInstructions,
    List<int>? photoIds,
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
      itemDescription: itemDescription ?? this.itemDescription,
      quantity: quantity ?? this.quantity,
      isFragile: isFragile ?? this.isFragile,
      declaredValue: declaredValue ?? this.declaredValue,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupContactName: pickupContactName ?? this.pickupContactName,
      pickupContactPhone: pickupContactPhone ?? this.pickupContactPhone,
      pickupInstructions: pickupInstructions ?? this.pickupInstructions,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      photoIds: photoIds ?? this.photoIds,
      status: status ?? this.status,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Parcel.fromJson(Map<String, dynamic> json) {
    final rawPhotoIds = json['photo_ids'] as List<dynamic>? ?? [];
    return Parcel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      deliveryQuoteId: (json['delivery_quote_id'] as num?)?.toInt(),
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentMethodId: (json['payment_method_id'] as num?)?.toInt(),
      itemDescription: json['item_description']?.toString() ?? '',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      isFragile: json['is_fragile'] as bool? ?? false,
      declaredValue: (json['declared_value'] as num?)?.toDouble(),
      pickupAddress: json['pickup_address']?.toString() ?? '',
      pickupContactName: json['pickup_contact_name']?.toString(),
      pickupContactPhone: json['pickup_contact_phone']?.toString(),
      pickupInstructions: json['pickup_instructions']?.toString(),
      dropoffAddress: json['dropoff_address']?.toString() ?? '',
      recipientName: json['recipient_name']?.toString(),
      recipientPhone: json['recipient_phone']?.toString(),
      deliveryInstructions: json['delivery_instructions']?.toString(),
      photoIds: rawPhotoIds.map((e) => (e as num).toInt()).toList(),
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
        'item_description': itemDescription,
        'quantity': quantity,
        'is_fragile': isFragile,
        'declared_value': declaredValue,
        'pickup_address': pickupAddress,
        'pickup_contact_name': pickupContactName,
        'pickup_contact_phone': pickupContactPhone,
        'pickup_instructions': pickupInstructions,
        'dropoff_address': dropoffAddress,
        'recipient_name': recipientName,
        'recipient_phone': recipientPhone,
        'delivery_instructions': deliveryInstructions,
        'photo_ids': photoIds,
        'status': status,
        'tracking_number': trackingNumber,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  @override
  String toString() => '$id, $status, $pickupAddress → $dropoffAddress';

  @override
  List<Object?> get props => [
        id,
        deliveryQuoteId,
        paymentMethod,
        paymentMethodId,
        itemDescription,
        quantity,
        isFragile,
        declaredValue,
        pickupAddress,
        pickupContactName,
        pickupContactPhone,
        pickupInstructions,
        dropoffAddress,
        recipientName,
        recipientPhone,
        deliveryInstructions,
        photoIds,
        status,
        trackingNumber,
        createdAt,
        updatedAt,
      ];
}
