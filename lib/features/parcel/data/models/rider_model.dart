enum VehicleType { motorbike, bicycle, car }

class RiderModel {
  final String id;
  final String name;
  final VehicleType vehicle;
  final double rating;
  final int reviewCount;
  final double baseFeeGhs;
  final double perKmFeeGhs;
  final int etaMinutes;
  final String initials;

  const RiderModel({
    required this.id,
    required this.name,
    required this.vehicle,
    required this.rating,
    required this.reviewCount,
    required this.baseFeeGhs,
    required this.perKmFeeGhs,
    required this.etaMinutes,
    required this.initials,
  });

  double totalCost(double distanceKm) =>
      baseFeeGhs + (perKmFeeGhs * distanceKm);

  String get vehicleLabel {
    switch (vehicle) {
      case VehicleType.motorbike:
        return 'Motorbike';
      case VehicleType.bicycle:
        return 'Bicycle';
      case VehicleType.car:
        return 'Car';
    }
  }
}
