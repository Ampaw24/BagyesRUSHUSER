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

  @override
  bool operator ==(Object other) =>
      other is Restaurant && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
