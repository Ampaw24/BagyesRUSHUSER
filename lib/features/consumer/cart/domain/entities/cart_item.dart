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

  @override
  bool operator ==(Object other) =>
      other is CartItem && other.item.id == item.id;

  @override
  int get hashCode => item.id.hashCode;
}
