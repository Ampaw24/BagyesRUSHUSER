/// Menu item domain entity.
library;

import 'package:bagyesrushappusernew/src/restaurant/models/addon.dart';

class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String category;
  final bool isAvailable;
  final bool isPopular;
  final List<AddonGroup> addonGroups;
  final int minimumOrderQty;
  final int? maximumOrderQty;

  const MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.category,
    this.isAvailable = true,
    this.isPopular = false,
    this.addonGroups = const [],
    this.minimumOrderQty = 1,
    this.maximumOrderQty,
  });

  bool get hasAddons => addonGroups.isNotEmpty;

  factory MenuItem.fromJson(Map<String, dynamic> json, {String? restaurantId}) => MenuItem(
        id: json['id']?.toString() ?? '',
        restaurantId: json['restaurant_id']?.toString() ?? restaurantId ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        imageUrl: json['image_url'] as String? ?? '',
        price: (json['price'] as num? ?? 0).toDouble(),
        category: json['category'] is Map
            ? ((json['category'] as Map)['name'] as String? ?? '')
            : json['category'] as String? ?? '',
        isAvailable: json['is_available'] as bool? ?? true,
        isPopular: json['is_popular'] as bool? ?? false,
        addonGroups: (json['addon_groups'] as List<dynamic>? ?? [])
            .map((e) => AddonGroup.fromJson(e as Map<String, dynamic>))
            .toList(),
        minimumOrderQty: json['minimum_order_qty'] as int? ?? 1,
        maximumOrderQty: json['maximum_order_qty'] as int?,
      );

  @override
  bool operator ==(Object other) =>
      other is MenuItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
