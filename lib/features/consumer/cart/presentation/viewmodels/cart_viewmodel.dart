import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/core/services/cart_storage_service.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/domain/entities/cart_item.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/states/cart_state.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/addon.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/menu_item.dart';
import 'package:bagyesrushappusernew/features/consumer/restaurant/domain/entities/restaurant.dart';

// ─── Cart ViewModel ────────────────────────────────────────────────────────

final cartStorageServiceProvider =
    Provider<CartStorageService>((_) => sl<CartStorageService>());

class CartViewModel extends Notifier<CartState> {
  /// Maximum length for special instructions to prevent abuse.
  static const int _maxInstructionLength = 500;

  CartStorageService get _storage => ref.read(cartStorageServiceProvider);

  /// Fire-and-forget: cart mutations shouldn't block on a disk write.
  void _persist() => unawaited(_storage.saveCart(state));

  @override
  CartState build() => _storage.cachedCart ?? const CartState.empty();

  /// Returns true if added, false if the user must confirm clearing the cart
  /// (different restaurant). Caller decides UI flow.
  bool addItem(
    Restaurant restaurant,
    MenuItem item, {
    int quantity = 1,
    String? instructions,
    List<SelectedAddon> selectedAddons = const [],
  }) {
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
          selectedAddons: selectedAddons,
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
    _persist();
    return true;
  }

  void removeItem(String itemId) {
    final updated = state.items.where((ci) => ci.item.id != itemId).toList();
    if (updated.isEmpty) {
      state = const CartState.empty();
    } else {
      state = state.copyWith(items: updated);
    }
    _persist();
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
    _persist();
  }

  /// Update the restaurant-level special instructions / note.
  /// Input is sanitized: trimmed, capped at [_maxInstructionLength] chars,
  /// and control characters are stripped.
  void updateSpecialInstructions(String value) {
    final sanitized = value
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '') // strip control chars
        .trim();
    final capped = sanitized.length > _maxInstructionLength
        ? sanitized.substring(0, _maxInstructionLength)
        : sanitized;
    state = state.copyWith(specialInstructions: capped);
    _persist();
  }

  void clearAndAdd(
    Restaurant restaurant,
    MenuItem item, {
    int quantity = 1,
    String? instructions,
    List<SelectedAddon> selectedAddons = const [],
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
          selectedAddons: selectedAddons,
        ),
      ],
    );
    _persist();
  }

  void clear() {
    state = const CartState.empty();
    unawaited(_storage.clearCart());
  }
}

final cartProvider =
    NotifierProvider<CartViewModel, CartState>(CartViewModel.new);

/// Convenience: total items badge count for the nav bar.
final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).totalItems;
});

