/// The rider the backend has matched to a delivery quote — returned
/// embedded in `ParcelQuote.rider`. There is no client-side rider list or
/// pricing to choose from; the backend picks the nearest available rider
/// and prices the quote around them.
class RiderModel {
  final String id;
  final String name;
  final String? photoUrl;
  final double rating;
  final int reviewCount;
  final int deliveriesCompleted;
  final String? vehicleType;
  final String? vehicleTypeLabel;
  final double? distanceAwayKm;

  const RiderModel({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.rating,
    required this.reviewCount,
    required this.deliveriesCompleted,
    this.vehicleType,
    this.vehicleTypeLabel,
    this.distanceAwayKm,
  });

  factory RiderModel.fromJson(Map<String, dynamic> json) => RiderModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        photoUrl: json['photo_url']?.toString(),
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
        deliveriesCompleted:
            (json['deliveries_completed'] as num?)?.toInt() ?? 0,
        vehicleType: json['vehicle_type']?.toString(),
        vehicleTypeLabel: json['vehicle_type_label']?.toString(),
        distanceAwayKm: (json['distance_away_km'] as num?)?.toDouble(),
      );

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
