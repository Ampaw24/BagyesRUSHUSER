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

/// Immutable snapshot of the entire cart.
class CartState {
  final String? restaurantId;
  final String? restaurantName;
  final String? restaurantImageUrl;
  final List<CartItem> items;
  final double deliveryFee;

  const CartState({
    this.restaurantId,
    this.restaurantName,
    this.restaurantImageUrl,
    this.items = const [],
    this.deliveryFee = 0,
  });

  const CartState.empty()
      : restaurantId = null,
        restaurantName = null,
        restaurantImageUrl = null,
        items = const [],
        deliveryFee = 0;

  bool get isEmpty => items.isEmpty;
  int get totalItems => items.fold(0, (sum, e) => sum + e.quantity);

  double get subtotal => items.fold(0, (sum, e) => sum + e.lineTotal);
  double get serviceFee => subtotal * 0.05; // 5 % service charge
  double get total => subtotal + deliveryFee + serviceFee;

  CartState copyWith({
    String? restaurantId,
    String? restaurantName,
    String? restaurantImageUrl,
    List<CartItem>? items,
    double? deliveryFee,
  }) {
    return CartState(
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantImageUrl: restaurantImageUrl ?? this.restaurantImageUrl,
      items: items ?? this.items,
      deliveryFee: deliveryFee ?? this.deliveryFee,
    );
  }
}
