import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/menu_item.dart';

/// A single item in the cart, wrapping a [MenuItem] with quantity and options.
class CartItem {
  final MenuItem item;
  final int quantity;
  final String? specialInstructions;
  final List<String> selectedCustomizationIds;

  const CartItem({
    required this.item,
    required this.quantity,
    this.specialInstructions,
    this.selectedCustomizationIds = const [],
  });

  double get lineTotal => item.price * quantity;

  CartItem copyWith({
    int? quantity,
    String? specialInstructions,
    List<String>? selectedCustomizationIds,
  }) {
    return CartItem(
      item: item,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      selectedCustomizationIds:
          selectedCustomizationIds ?? this.selectedCustomizationIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CartItem && other.item.id == item.id;

  @override
  int get hashCode => item.id.hashCode;
}

