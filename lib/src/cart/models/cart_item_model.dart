import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
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
  /// One portion *including* the chosen addons — `options[].additional_price`
  /// is display-only and must never be added on top.
  final double price;
  final int quantity;
  final String? notes;
  final List<SelectedAddon> addonOptions;

  /// False once the item went unavailable while the cart sat idle.
  final bool isAvailable;

  /// Backend-computed line total. Null when the response omits it or the
  /// item was changed optimistically and not yet reconciled.
  final double? lineTotal;

  const CartItemModel({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    this.notes,
    this.addonOptions = const [],
    this.isAvailable = true,
    this.lineTotal,
  });

  /// A quantity change invalidates [lineTotal] until the server reconciles.
  CartItemModel copyWith({int? quantity, String? notes}) => CartItemModel(
        id: id,
        menuItemId: menuItemId,
        name: name,
        imageUrl: imageUrl,
        price: price,
        quantity: quantity ?? this.quantity,
        notes: notes ?? this.notes,
        addonOptions: addonOptions,
        isAvailable: isAvailable,
        lineTotal: quantity == null ? lineTotal : null,
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
      isAvailable: JsonUtils.asBool(json['is_available'], true),
      lineTotal: JsonUtils.firstDoubleOrNull(
        json,
        const ['line_total', 'total_price', 'total'],
      ),
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
