import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/states/cart_state.dart';

/// Persists the shopping cart to disk so it survives app restarts.
///
/// Failures while restoring (corrupt JSON, a menu-item shape that changed
/// since the cart was last saved, etc.) are swallowed — an unreadable cart
/// just behaves like no cart was ever saved, it never crashes the app.
class CartStorageService {
  CartStorageService({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;
  static const _key = 'cart_state';

  CartState? _cached;

  /// The cart restored from disk, if any. Populated by [hydrate].
  CartState? get cachedCart => _cached;

  /// Reads and parses the persisted cart. Call once, before the app renders.
  Future<void> hydrate() async {
    try {
      final raw = _prefs.getString(_key);
      if (raw == null) return;
      _cached = CartState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e, s) {
      appLogger.w(
        'CartStorageService.hydrate → could not restore persisted cart, starting empty',
        error: e,
        stackTrace: s,
      );
      _cached = null;
    }
  }

  Future<void> saveCart(CartState state) async {
    try {
      await _prefs.setString(_key, jsonEncode(state.toJson()));
    } catch (e, s) {
      appLogger.w(
        'CartStorageService.saveCart → failed to persist cart',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> clearCart() async {
    await _prefs.remove(_key);
  }
}
