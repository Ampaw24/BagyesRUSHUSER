import 'package:google_maps_flutter/google_maps_flutter.dart';

class ParcelOrderModel {
  final String packageType; // 'document' | 'parcel'
  final String imageBase64;
  final double weightKg;
  final LatLng? pickupLatLng;
  final String pickupAddress;
  final LatLng? deliveryLatLng;
  final String deliveryAddress;
  final String? selectedRiderId;
  final double distanceKm;

  const ParcelOrderModel({
    this.packageType = '',
    this.imageBase64 = '',
    this.weightKg = 0.0,
    this.pickupLatLng,
    this.pickupAddress = '',
    this.deliveryLatLng,
    this.deliveryAddress = '',
    this.selectedRiderId,
    this.distanceKm = 0.0,
  });

  ParcelOrderModel copyWith({
    String? packageType,
    String? imageBase64,
    double? weightKg,
    LatLng? pickupLatLng,
    String? pickupAddress,
    LatLng? deliveryLatLng,
    String? deliveryAddress,
    String? selectedRiderId,
    double? distanceKm,
  }) =>
      ParcelOrderModel(
        packageType: packageType ?? this.packageType,
        imageBase64: imageBase64 ?? this.imageBase64,
        weightKg: weightKg ?? this.weightKg,
        pickupLatLng: pickupLatLng ?? this.pickupLatLng,
        pickupAddress: pickupAddress ?? this.pickupAddress,
        deliveryLatLng: deliveryLatLng ?? this.deliveryLatLng,
        deliveryAddress: deliveryAddress ?? this.deliveryAddress,
        selectedRiderId: selectedRiderId ?? this.selectedRiderId,
        distanceKm: distanceKm ?? this.distanceKm,
      );
}
