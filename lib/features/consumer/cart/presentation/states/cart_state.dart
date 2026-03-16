import 'package:bagyesrushappusernew/features/consumer/cart/domain/entities/cart_item.dart';

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
  double get serviceFee => subtotal * 0.05;
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
