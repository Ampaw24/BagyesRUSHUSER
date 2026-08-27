import 'package:bagyesrushappusernew/features/consumer/cart/domain/entities/cart_item.dart';

/// Immutable snapshot of the entire cart.
class CartState {
  final String? restaurantId;
  final String? restaurantName;
  final String? restaurantImageUrl;
  final List<CartItem> items;
  final double deliveryFee;

  /// Restaurant-level special instructions / note entered by the user.
  /// Sanitized before being sent to the API.
  final String specialInstructions;

  const CartState({
    this.restaurantId,
    this.restaurantName,
    this.restaurantImageUrl,
    this.items = const [],
    this.deliveryFee = 0,
    this.specialInstructions = '',
  });

  const CartState.empty()
      : restaurantId = null,
        restaurantName = null,
        restaurantImageUrl = null,
        items = const [],
        deliveryFee = 0,
        specialInstructions = '';

  bool get isEmpty => items.isEmpty;
  int get totalItems => items.fold(0, (sum, e) => sum + e.quantity);

  double get subtotal => items.fold(0, (sum, e) => sum + e.lineTotal);

  /// Client-side estimate only (no backend fee-quote endpoint exists yet).
  /// The authoritative total is whatever `ConsumerOrder` returns after
  /// `placeOrder` — this may not match exactly.
  double get serviceFee => subtotal * 0.05;
  double get total => subtotal + deliveryFee + serviceFee;

  /// Whether the user has entered a restaurant note.
  bool get hasSpecialInstructions => specialInstructions.trim().isNotEmpty;

  CartState copyWith({
    String? restaurantId,
    String? restaurantName,
    String? restaurantImageUrl,
    List<CartItem>? items,
    double? deliveryFee,
    String? specialInstructions,
  }) {
    return CartState(
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantImageUrl: restaurantImageUrl ?? this.restaurantImageUrl,
      items: items ?? this.items,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      specialInstructions: specialInstructions ?? this.specialInstructions,
    );
  }

  /// Local cart persistence only — never sent to the backend.
  Map<String, dynamic> toJson() => {
        'restaurant_id': restaurantId,
        'restaurant_name': restaurantName,
        'restaurant_image_url': restaurantImageUrl,
        'items': items.map((i) => i.toJson()).toList(),
        'delivery_fee': deliveryFee,
        'special_instructions': specialInstructions,
      };

  factory CartState.fromJson(Map<String, dynamic> json) => CartState(
        restaurantId: json['restaurant_id'] as String?,
        restaurantName: json['restaurant_name'] as String?,
        restaurantImageUrl: json['restaurant_image_url'] as String?,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        deliveryFee: (json['delivery_fee'] as num? ?? 0).toDouble(),
        specialInstructions: json['special_instructions'] as String? ?? '',
      );
}
