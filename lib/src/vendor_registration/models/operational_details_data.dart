import 'package:equatable/equatable.dart';

/// Data model for Step 3 - Operational Details
///
/// Store hours, operating days, and estimated prep time are collected later
/// during KYC (see `VendorKycState`) rather than at registration time.
class OperationalDetailsData extends Equatable {
  /// Lowercase category names sent to the API (e.g. ["local", "continental"]).
  final List<String> cuisineTypes;
  final double deliveryRadiusKm;

  const OperationalDetailsData({
    this.cuisineTypes = const [],
    this.deliveryRadiusKm = 5.0,
  });

  OperationalDetailsData copyWith({
    List<String>? cuisineTypes,
    double? deliveryRadiusKm,
  }) {
    return OperationalDetailsData(
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      deliveryRadiusKm: deliveryRadiusKm ?? this.deliveryRadiusKm,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cuisine_types': cuisineTypes,
      'delivery_radius_km': deliveryRadiusKm,
    };
  }

  @override
  List<Object?> get props => [cuisineTypes, deliveryRadiusKm];
}
