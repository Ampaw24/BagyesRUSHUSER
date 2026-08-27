import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/addon.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/menu_item.dart';

/// A single item in the cart, wrapping a [MenuItem] with quantity and addons.
class CartItem {
  final MenuItem item;
  final int quantity;
  final String? specialInstructions;
  final List<SelectedAddon> selectedAddons;

  const CartItem({
    required this.item,
    required this.quantity,
    this.specialInstructions,
    this.selectedAddons = const [],
  });

  double get addonsTotalPerUnit =>
      selectedAddons.fold(0.0, (sum, a) => sum + a.totalPrice);

  double get lineTotal => (item.price + addonsTotalPerUnit) * quantity;

  CartItem copyWith({
    int? quantity,
    String? specialInstructions,
    List<SelectedAddon>? selectedAddons,
  }) {
    return CartItem(
      item: item,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      selectedAddons: selectedAddons ?? this.selectedAddons,
    );
  }

  /// Local cart persistence only — never sent to the backend.
  Map<String, dynamic> toJson() => {
        'item': item.toJson(),
        'quantity': quantity,
        'special_instructions': specialInstructions,
        'selected_addons': selectedAddons.map((a) => a.toJson()).toList(),
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        item: MenuItem.fromJson(json['item'] as Map<String, dynamic>),
        quantity: json['quantity'] as int? ?? 1,
        specialInstructions: json['special_instructions'] as String?,
        selectedAddons: (json['selected_addons'] as List<dynamic>? ?? [])
            .map((e) => SelectedAddon.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      other is CartItem && other.item.id == item.id;

  @override
  int get hashCode => item.id.hashCode;
}
