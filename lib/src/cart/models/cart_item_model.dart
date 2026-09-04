import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/src/restaurant/models/addon.dart';

/// A single line item on a server-side vendor cart, returned by
/// `GET customer/carts/:vendorId` and embedded in every cart mutation
/// response.
class CartItemModel {
  final String id;
  final String menuItemId;
  final String name;
  final String imageUrl;
  final double price;
  final int quantity;
  final String? notes;
  final List<SelectedAddon> addonOptions;

  const CartItemModel({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.notes,
    this.addonOptions = const [],
  });

  double get addonsUnitTotal =>
      addonOptions.fold(0.0, (sum, a) => sum + a.totalPrice);

  double get lineTotal => (price + addonsUnitTotal) * quantity;

  CartItemModel copyWith({int? quantity, String? notes}) => CartItemModel(
        id: id,
        menuItemId: menuItemId,
        name: name,
        imageUrl: imageUrl,
        price: price,
        quantity: quantity ?? this.quantity,
        notes: notes ?? this.notes,
        addonOptions: addonOptions,
      );

  factory CartItemModel.fromJson(DataMap json) {
    final menuItem = json['menu_item'] as DataMap?;
    return CartItemModel(
      id: json['id'].toString(),
      menuItemId:
          (json['menu_item_id'] ?? menuItem?['id'])?.toString() ?? '',
      name: menuItem?['name'] as String? ?? json['name'] as String? ?? '',
      imageUrl: menuItem?['image_url'] as String? ??
          json['image_url'] as String? ??
          '',
      price: ((json['unit_price'] ?? menuItem?['price'] ?? json['price'])
                  as num? ??
              0)
          .toDouble(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      notes: json['notes'] as String?,
      addonOptions: _parseAddons(json),
    );
  }

  /// The backend may return addon selections under `addon_options`,
  /// `addons`, or `options` — accept all rather than assuming one.
  static List<SelectedAddon> _parseAddons(DataMap json) {
    final raw = json['addon_options'] ?? json['addons'] ?? json['options'];
    if (raw is! List) return const [];
    return raw
        .map((e) => SelectedAddon.fromJson(e as DataMap))
        .toList();
  }
}
