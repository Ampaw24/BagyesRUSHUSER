/// Restaurant domain entity — pure Dart, no Flutter/framework dependencies.
library;

class Restaurant {
  final String id;
  final String name;
  final String imageUrl;
  final String cuisineType;
  final List<String> categories; // e.g. ["Burgers", "Sides", "Drinks"]
  final double rating;
  final int reviewCount;
  final int deliveryTimeMin; // minutes
  final int deliveryTimeMax;
  final double deliveryFee; // GHS
  final double minOrder; // GHS
  final bool isOpen;
  final bool isFeatured;
  final String address;
  final double latitude;
  final double longitude;
  final String? promoText; // e.g. "20% off first order"
  final double? discountPercent;

  const Restaurant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.cuisineType,
    required this.categories,
    required this.rating,
    required this.reviewCount,
    required this.deliveryTimeMin,
    required this.deliveryTimeMax,
    required this.deliveryFee,
    required this.minOrder,
    required this.isOpen,
    required this.isFeatured,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.promoText,
    this.discountPercent,
  });

  String get deliveryTimeLabel => '$deliveryTimeMin–$deliveryTimeMax min';

  factory Restaurant.fromJson(Map<String, dynamic> json) => Restaurant(
        id: json['id'] as String? ?? json['_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        imageUrl: json['image_url'] as String? ??
            json['logo_url'] as String? ??
            json['banner_url'] as String? ??
            '',
        cuisineType: json['cuisine_type'] as String? ?? '',
        categories: (json['categories'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        rating: (json['rating'] as num? ?? 0).toDouble(),
        reviewCount: json['review_count'] as int? ?? 0,
        deliveryTimeMin: json['delivery_time_min'] as int? ?? 0,
        deliveryTimeMax: json['delivery_time_max'] as int? ?? 0,
        deliveryFee: (json['delivery_fee'] as num? ?? 0).toDouble(),
        minOrder: (json['min_order'] as num? ?? 0).toDouble(),
        isOpen: json['is_open'] as bool? ?? false,
        isFeatured: json['is_featured'] as bool? ?? false,
        address: json['address'] as String? ??
            json['business_address'] as String? ??
            '',
        latitude: (json['latitude'] as num? ?? 0).toDouble(),
        longitude: (json['longitude'] as num? ?? 0).toDouble(),
        promoText: json['promo_text'] as String?,
        discountPercent: (json['discount_percent'] as num?)?.toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      other is Restaurant && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
