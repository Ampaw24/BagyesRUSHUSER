import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/addon.dart';

class MenuItem extends Equatable {
  final String id;
  final String name;
  final String description;
  final String price;
  final String? imageUrl;
  final String category;
  final bool isAvailable;
  final List<String> tags;
  final int prepTimeMinutes;
  final bool isFeatured;
  final bool isOutOfStock;
  final List<AddonGroup> addonGroups;
  final int minimumOrderQty;
  final int? maximumOrderQty;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    this.isAvailable = true,
    this.tags = const [],
    this.prepTimeMinutes = 15,
    this.isFeatured = false,
    this.isOutOfStock = false,
    this.addonGroups = const [],
    this.minimumOrderQty = 1,
    this.maximumOrderQty,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price'] is num
          ? (json['price'] as num).toString()
          : json['price'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      category: json['category'] is Map
          ? ((json['category'] as Map)['name'] as String? ?? '')
          : json['category'] as String? ?? '',
      isAvailable: json['is_available'] as bool? ?? true,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      prepTimeMinutes: json['prep_time_minutes'] as int? ?? 15,
      isFeatured: json['is_featured'] as bool? ?? false,
      isOutOfStock: json['is_out_of_stock'] as bool? ?? false,
      addonGroups: (json['addon_groups'] as List<dynamic>? ?? [])
          .map((e) => AddonGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
      minimumOrderQty: json['minimum_order_qty'] as int? ?? 1,
      maximumOrderQty: json['maximum_order_qty'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category': category,
      'is_available': isAvailable,
      'tags': tags,
      'prep_time_minutes': prepTimeMinutes,
      'is_featured': isFeatured,
      'is_out_of_stock': isOutOfStock,
      'addon_groups': addonGroups.map((g) => g.toJson()).toList(),
      'minimum_order_qty': minimumOrderQty,
      if (maximumOrderQty != null) 'maximum_order_qty': maximumOrderQty,
    };
  }

  MenuItem copyWith({
    String? id,
    String? name,
    String? description,
    String? price,
    String? imageUrl,
    String? category,
    bool? isAvailable,
    List<String>? tags,
    int? prepTimeMinutes,
    bool? isFeatured,
    bool? isOutOfStock,
    List<AddonGroup>? addonGroups,
    int? minimumOrderQty,
    int? maximumOrderQty,
    bool clearMaxOrderQty = false,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      tags: tags ?? this.tags,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      isFeatured: isFeatured ?? this.isFeatured,
      isOutOfStock: isOutOfStock ?? this.isOutOfStock,
      addonGroups: addonGroups ?? this.addonGroups,
      minimumOrderQty: minimumOrderQty ?? this.minimumOrderQty,
      maximumOrderQty: clearMaxOrderQty
          ? null
          : (maximumOrderQty ?? this.maximumOrderQty),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    imageUrl,
    category,
    isAvailable,
    tags,
    prepTimeMinutes,
    isFeatured,
    isOutOfStock,
    addonGroups,
    minimumOrderQty,
    maximumOrderQty,
  ];
}
