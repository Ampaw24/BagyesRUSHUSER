import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/domain/entities/cart_item.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/menu_item.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/restaurant.dart';

// ─── Cart Notifier ────────────────────────────────────────────────────────

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState.empty();

  /// Returns true if added, false if the user must confirm clearing the cart
  /// (different restaurant). Caller decides UI flow.
  bool addItem(
    Restaurant restaurant,
    MenuItem item, {
    int quantity = 1,
    String? instructions,
    List<String> customizations = const [],
  }) {
    // Cart already has items from a DIFFERENT restaurant → signal conflict
    if (state.restaurantId != null && state.restaurantId != restaurant.id) {
      return false;
    }

    final existing = state.items.indexWhere((ci) => ci.item.id == item.id);
    List<CartItem> updated;

    if (existing >= 0) {
      updated = [...state.items];
      updated[existing] = updated[existing].copyWith(
        quantity: updated[existing].quantity + quantity,
      );
    } else {
      updated = [
        ...state.items,
        CartItem(
          item: item,
          quantity: quantity,
          specialInstructions: instructions,
          selectedCustomizationIds: customizations,
        ),
      ];
    }

    state = state.copyWith(
      restaurantId: restaurant.id,
      restaurantName: restaurant.name,
      restaurantImageUrl: restaurant.imageUrl,
      items: updated,
      deliveryFee: restaurant.deliveryFee,
    );
    return true;
  }

  void removeItem(String itemId) {
    final updated = state.items.where((ci) => ci.item.id != itemId).toList();
    if (updated.isEmpty) {
      state = const CartState.empty();
    } else {
      state = state.copyWith(items: updated);
    }
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    final updated = state.items.map((ci) {
      if (ci.item.id == itemId) return ci.copyWith(quantity: quantity);
      return ci;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void clearAndAdd(
    Restaurant restaurant,
    MenuItem item, {
    int quantity = 1,
    String? instructions,
  }) {
    state = CartState(
      restaurantId: restaurant.id,
      restaurantName: restaurant.name,
      restaurantImageUrl: restaurant.imageUrl,
      deliveryFee: restaurant.deliveryFee,
      items: [
        CartItem(
          item: item,
          quantity: quantity,
          specialInstructions: instructions,
        ),
      ],
    );
  }

  void clear() => state = const CartState.empty();
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

/// Convenience: total items badge count for the nav bar.
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).totalItems;
});
