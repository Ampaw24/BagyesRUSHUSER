import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A single delivery destination within a multi-stop parcel order.
///
/// **Location** (`latLng` + `address`) determines [isComplete].
/// **Item details** (`itemDescription`, `quantity`, `recipientName`,
/// `recipientPhone`) are fully optional — the rider uses them to know what
/// to hand over and who to call at each door, matching the pattern used by
/// Lalamove, GrabExpress, Kwik, and Bosta.
class DeliveryStop {
  final String id;
  final LatLng? latLng;
  final String address;

  /// Short description of what is being dropped at this stop.
  /// e.g. "2 sealed envelopes", "1 electronics package".
  final String itemDescription;

  /// Number of units being dropped. Defaults to 1.
  final int quantity;

  /// Name of the person who will receive the delivery at this stop.
  final String recipientName;

  /// Phone number the rider can call when arriving at this stop.
  final String recipientPhone;

  /// Free-text instructions for the rider at this stop.
  /// e.g. "Leave at front desk", "Call before arriving", "Fragile — handle with care".
  final String specialInstructions;

  /// Indices into the booking-level [packageImages] list.
  /// Lets the user tag which photos belong to this specific stop.
  final List<int> selectedImageIndices;

  const DeliveryStop({
    required this.id,
    this.latLng,
    this.address = '',
    this.itemDescription = '',
    this.quantity = 1,
    this.recipientName = '',
    this.recipientPhone = '',
    this.specialInstructions = '',
    this.selectedImageIndices = const [],
  });

  /// A stop is complete when it has a confirmed location.
  /// Item details are optional and do not affect completeness.
  bool get isComplete => latLng != null && address.isNotEmpty;

  /// Returns true when any optional detail field has been filled in.
  bool get hasDetails =>
      itemDescription.isNotEmpty ||
      recipientName.isNotEmpty ||
      recipientPhone.isNotEmpty ||
      specialInstructions.isNotEmpty ||
      selectedImageIndices.isNotEmpty;

  DeliveryStop copyWith({
    LatLng? latLng,
    String? address,
    String? itemDescription,
    int? quantity,
    String? recipientName,
    String? recipientPhone,
    String? specialInstructions,
    List<int>? selectedImageIndices,
  }) =>
      DeliveryStop(
        id: id,
        latLng: latLng ?? this.latLng,
        address: address ?? this.address,
        itemDescription: itemDescription ?? this.itemDescription,
        quantity: quantity ?? this.quantity,
        recipientName: recipientName ?? this.recipientName,
        recipientPhone: recipientPhone ?? this.recipientPhone,
        specialInstructions: specialInstructions ?? this.specialInstructions,
        selectedImageIndices: selectedImageIndices ?? this.selectedImageIndices,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryStop &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          latLng == other.latLng &&
          address == other.address &&
          itemDescription == other.itemDescription &&
          quantity == other.quantity &&
          recipientName == other.recipientName &&
          recipientPhone == other.recipientPhone &&
          specialInstructions == other.specialInstructions &&
          selectedImageIndices == other.selectedImageIndices;

  @override
  int get hashCode => Object.hash(
        id,
        latLng,
        address,
        itemDescription,
        quantity,
        recipientName,
        recipientPhone,
        specialInstructions,
        Object.hashAll(selectedImageIndices),
      );
}
