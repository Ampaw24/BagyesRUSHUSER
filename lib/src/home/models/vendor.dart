import 'package:equatable/equatable.dart';

class Vendor extends Equatable {
  const Vendor({
    required this.id,
    required this.name,
    required this.address,
    required this.categoryId,
    required this.rating,
    required this.isOpen,
    required this.deliveryTime,
    required this.logoUrl,
    required this.bannerUrl,
  });

  final String id;
  final String name;
  final String address;
  final String categoryId;
  final double rating;
  final bool isOpen;
  final String deliveryTime;
  final String? logoUrl;
  final String? bannerUrl;

  Vendor copyWith({
    String? id,
    String? name,
    String? address,
    String? categoryId,
    double? rating,
    bool? isOpen,
    String? deliveryTime,
    String? logoUrl,
    String? bannerUrl,
  }) {
    return Vendor(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      categoryId: categoryId ?? this.categoryId,
      rating: rating ?? this.rating,
      isOpen: isOpen ?? this.isOpen,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
    );
  }

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      categoryId: json['category_id'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isOpen: json['is_open'] ?? false,
      deliveryTime: json['delivery_time'] ?? '',
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'address': address,
        'category_id': categoryId,
        'rating': rating,
        'is_open': isOpen,
        'delivery_time': deliveryTime,
        'logo_url': logoUrl,
        'banner_url': bannerUrl,
      };

  @override
  String toString() =>
      '$id, $name, $address, $categoryId, $rating, $isOpen, $deliveryTime';

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        categoryId,
        rating,
        isOpen,
        deliveryTime,
        logoUrl,
        bannerUrl,
      ];
}
