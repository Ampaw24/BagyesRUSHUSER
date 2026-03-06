import 'package:equatable/equatable.dart';

class VendorProfile extends Equatable {
  final String id;
  final String businessName;
  final String ownerName;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String? logoUrl;
  final String openingTime;
  final String closingTime;
  final List<String> operatingDays;
  final double deliveryRadiusKm;

  const VendorProfile({
    required this.id,
    required this.businessName,
    required this.ownerName,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    this.logoUrl,
    this.openingTime = '08:00',
    this.closingTime = '22:00',
    this.operatingDays = const [],
    this.deliveryRadiusKm = 5.0,
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    return VendorProfile(
      id: json['id'] as String? ?? '',
      businessName: json['business_name'] as String? ?? '',
      ownerName: json['owner_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      openingTime: json['opening_time'] as String? ?? '08:00',
      closingTime: json['closing_time'] as String? ?? '22:00',
      operatingDays: (json['operating_days'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      deliveryRadiusKm:
          (json['delivery_radius_km'] as num?)?.toDouble() ?? 5.0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        businessName,
        ownerName,
        phone,
        email,
        address,
        city,
        logoUrl,
        openingTime,
        closingTime,
        operatingDays,
        deliveryRadiusKm,
      ];
}
