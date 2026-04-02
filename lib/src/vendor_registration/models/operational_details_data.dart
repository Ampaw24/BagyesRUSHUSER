import 'package:equatable/equatable.dart';

/// Data model for Step 3 - Operational Details
class OperationalDetailsData extends Equatable {
  /// Lowercase category names sent to the API (e.g. ["local", "continental"]).
  final List<String> cuisineTypes;
  final double deliveryRadiusKm;
  final String openingTime;
  final String closingTime;
  final List<String> operatingDays;
  final int estimatedPrepTimeMinutes;

  const OperationalDetailsData({
    this.cuisineTypes = const [],
    this.deliveryRadiusKm = 5.0,
    this.openingTime = '08:00',
    this.closingTime = '22:00',
    this.operatingDays = const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ],
    this.estimatedPrepTimeMinutes = 30,
  });

  OperationalDetailsData copyWith({
    List<String>? cuisineTypes,
    double? deliveryRadiusKm,
    String? openingTime,
    String? closingTime,
    List<String>? operatingDays,
    int? estimatedPrepTimeMinutes,
  }) {
    return OperationalDetailsData(
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      deliveryRadiusKm: deliveryRadiusKm ?? this.deliveryRadiusKm,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      operatingDays: operatingDays ?? this.operatingDays,
      estimatedPrepTimeMinutes:
          estimatedPrepTimeMinutes ?? this.estimatedPrepTimeMinutes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cuisine_types': cuisineTypes,
      'delivery_radius_km': deliveryRadiusKm,
      'opening_time': openingTime,
      'closing_time': closingTime,
      'operating_days': operatingDays.map((d) => d.toLowerCase()).toList(),
      'estimated_prep_time_minutes': estimatedPrepTimeMinutes,
    };
  }

  @override
  List<Object?> get props => [
    cuisineTypes,
    deliveryRadiusKm,
    openingTime,
    closingTime,
    operatingDays,
    estimatedPrepTimeMinutes,
  ];
}
