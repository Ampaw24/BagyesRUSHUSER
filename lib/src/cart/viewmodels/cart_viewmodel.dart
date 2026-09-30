import 'package:dartz/dartz.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/common/app/session_aware.dart';
import 'package:bagyesrushappusernew/core/errors/failure.dart';
import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/restaurant/models/addon.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_item_model.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_model.dart';
import 'package:bagyesrushappusernew/src/cart/repositories/cart_repository.dart';
import 'package:bagyesrushappusernew/src/cart/viewmodels/cart_state.dart';

class CartViewModel extends ViewModel<CartState> with SessionAware {
  CartViewModel({
    required CartRepository repository,
    required CurrentUserProvider session,
  })  : _repository = repository,
        super(const CartInitial()) {
    bindSession(session);
  }

  final CartRepository _repository;

  CartModel? get cart => switch (state) {
        CartLoaded(:final cart) => cart,
        _ => null,
      };

  bool get isEmpty => cart?.isEmpty ?? true;
  int get totalItems => cart?.totalItems ?? 0;
  double? get total => cart?.total;
  bool get isMutating => switch (state) {
        CartLoaded(:final isMutating) => isMutating,
        _ => false,
      };

  /// A transient load/mutation failure to surface as a toast, while [cart]
  /// still holds valid data. The view should show it once and then call
  /// [clearError].
  String? get errorMessage => switch (state) {
        CartLoaded(:final errorMessage) => errorMessage,
        _ => null,
      };

  bool get isApplyingPromo => switch (state) {
        CartLoaded(:final isApplyingPromo) => isApplyingPromo,
        _ => false,
      };

  String? get promoError => switch (state) {
        CartLoaded(:final promoError) => promoError,
        _ => null,
      };

  void clearError() {
    final s = state;
    if (s is CartLoaded && s.errorMessage != null) {
      emit(s.copyWith(clearError: true));
    }
  }

  Future<void> loadCart(String vendorId) async {
    appLogger.d('CartViewModel.loadCart → vendorId=$vendorId');
    final previous = state;
    // Only showing this vendor's cart already counts as "have data" — keep
    // it on screen while refreshing instead of blanking to a spinner.
    final hasExistingCart = previous is CartLoaded && previous.cart.vendorId == vendorId;
    if (!hasExistingCart) emit(const CartLoading());

    final result = await _repository.getCart(vendorId);
    result.fold(
      (failure) {
        appLogger.w('CartViewModel.loadCart → error: ${failure.message}');
        if (hasExistingCart) {
          emit(previous.copyWith(errorMessage: failure.message));
        } else {
          emit(CartError.fromFailure(failure));
        }
      },
      (cart) {
        appLogger.i(
          'CartViewModel.loadCart → loaded ${cart.items.length} items',
        );
        emit(CartLoaded(cart: cart));
      },
    );
  }

  /// Adds an item and shows it in the cart **immediately** (optimistic),
  /// without waiting on the network — [name]/[imageUrl]/[price]/[addonOptions]
  /// are only used to render that instant preview line; the server sync
  /// afterwards replaces it with the authoritative item (real id/price).
  ///
  /// Previously this only re-fetched the cart from the server after the
  /// `POST` succeeded, which meant the FAB/cart badge stayed at its old
  /// count until that second round-trip finished (and would silently show
  /// stale data if that read happened before the write had fully
  /// propagated). Updating local state first fixes both.
  Future<bool> addItem({
    required String vendorId,
    required int menuItemId,
    int quantity = 1,
    String? notes,
    List<int> addonOptionIds = const [],
    String name = '',
    String imageUrl = '',
    double price = 0,
    List<SelectedAddon> addonOptions = const [],
  }) async {
    appLogger.d('CartViewModel.addItem → vendorId=$vendorId item=$menuItemId');
    final previous = state;
    final base = previous is CartLoaded ? previous.cart : CartModel.empty(vendorId);

    emit(CartLoaded(
      cart: _withAddedItem(
        base,
        menuItemId: menuItemId,
        quantity: quantity,
        notes: notes,
        name: name,
        imageUrl: imageUrl,
        price: price,
        addonOptions: addonOptions,
      ),
      isMutating: true,
    ));

    // The backend merges a repeat of the same item/options/notes into the
    // existing line, so a plain POST is always correct.
    final result = await _repository.addItem(
      vendorId: vendorId,
      menuItemId: menuItemId,
      quantity: quantity,
      notes: notes,
      addonOptionIds: addonOptionIds,
    );

    return _finishMutation(result, previous: previous, vendorId: vendorId);
  }

  Future<void> updateItemQuantity(String itemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(itemId);
      return;
    }

    final previous = state;
    if (previous is CartLoaded) {
      emit(CartLoaded(
        cart: previous.cart.copyWith(
          items: previous.cart.items
              .map((i) => i.id == itemId ? i.copyWith(quantity: quantity) : i)
              .toList(),
        ),
        isMutating: true,
      ));
    }

    final result = await _repository.updateItem(itemId, quantity: quantity);
    await _finishMutation(result, previous: previous, vendorId: cart?.vendorId);
  }

  Future<void> updateItemNotes(String itemId, String notes) async {
    final previous = state;
    if (previous is CartLoaded) {
      emit(CartLoaded(
        cart: previous.cart.copyWith(
          items: previous.cart.items
              .map((i) => i.id == itemId ? i.copyWith(notes: notes) : i)
              .toList(),
        ),
        isMutating: true,
      ));
    }

    final result = await _repository.updateItem(itemId, notes: notes);
    await _finishMutation(result, previous: previous, vendorId: cart?.vendorId);
  }

  Future<void> removeItem(String itemId) async {
    final previous = state;
    if (previous is CartLoaded) {
      emit(CartLoaded(
        cart: previous.cart.copyWith(
          items: previous.cart.items.where((i) => i.id != itemId).toList(),
        ),
        isMutating: true,
      ));
    }

    final result = await _repository.removeItem(itemId);
    await _finishMutation(result, previous: previous, vendorId: cart?.vendorId);
  }

  Future<void> clearCart() async {
    final previous = state;
    if (previous is! CartLoaded) return;
    final vendorId = previous.cart.vendorId;

    emit(CartLoaded(cart: previous.cart.copyWith(items: const []), isMutating: true));

    final result = await _repository.clearCart(vendorId);
    await _finishMutation(result, previous: previous, vendorId: vendorId);
  }

  // ─── Promo code ────────────────────────────────────────────────────────────

  /// Stores [code] on the server cart; discount and totals come back from
  /// the backend. A rejection is surfaced inline via [promoError].
  Future<bool> applyPromoCode(String code) async {
    final current = state;
    final trimmed = code.trim().toUpperCase();
    if (current is! CartLoaded || trimmed.isEmpty || current.isApplyingPromo) {
      return false;
    }

    emit(current.copyWith(isApplyingPromo: true, clearPromoError: true));

    final result = await _repository.applyPromoCode(
      vendorId: current.cart.vendorId,
      code: trimmed,
    );

    return result.fold(
      (failure) {
        appLogger.w('CartViewModel.applyPromoCode → ${failure.message}');
        final latest = state is CartLoaded ? state as CartLoaded : current;
        emit(latest.copyWith(isApplyingPromo: false, promoError: failure.message));
        return false;
      },
      (cart) {
        emit(CartLoaded(cart: cart));
        return true;
      },
    );
  }

  Future<void> removePromoCode() async {
    final previous = state;
    if (previous is! CartLoaded || previous.cart.promo == null) return;

    emit(CartLoaded(
      cart: previous.cart.withoutPromo(),
      isApplyingPromo: true,
    ));

    final result = await _repository.removePromoCode(previous.cart.vendorId);
    result.fold(
      (failure) => emit(previous.copyWith(
        isApplyingPromo: false,
        errorMessage: failure.message,
      )),
      (cart) => emit(CartLoaded(cart: cart)),
    );
  }

  void clearPromoError() {
    final s = state;
    if (s is CartLoaded && s.promoError != null) {
      emit(s.copyWith(clearPromoError: true));
    }
  }

  Future<void> refresh() async {
    final vendorId = cart?.vendorId;
    if (vendorId != null) await loadCart(vendorId);
  }

  /// Resets to [CartInitial] — call on logout so a new session doesn't
  /// briefly see the previous customer's cart.
  void reset() => emit(const CartInitial());

  @override
  void onSignedOut() => reset();

  /// Common tail of every mutation: on failure, rolls back to [previous]
  /// (never destroying already-good cart data over a transient mutation
  /// error — [CartError] is only reachable when there was no prior cart to
  /// fall back on) and surfaces the error as [CartLoaded.errorMessage]; on
  /// success, silently reconciles with the server in the background (no
  /// loading flash — the optimistic cart already showing is correct as far
  /// as the user can tell).
  Future<bool> _finishMutation(
    Either<Failure, void> result, {
    required CartState previous,
    required String? vendorId,
  }) async {
    String? errorMessage;
    var success = false;
    result.fold(
      (failure) {
        appLogger.w('CartViewModel → mutation error: ${failure.message}');
        errorMessage = failure.message;
      },
      (_) => success = true,
    );

    if (!success) {
      if (previous is CartLoaded) {
        emit(previous.copyWith(errorMessage: errorMessage));
      } else {
        emit(CartError(message: errorMessage ?? 'Something went wrong', title: 'Error'));
      }
      return false;
    }

    if (vendorId != null) await _reconcile(vendorId);
    return true;
  }

  /// Re-fetches [vendorId]'s cart to correct any drift from the optimistic
  /// update (real ids/prices, server-computed totals) without clearing the
  /// screen first — a failed background reconcile just leaves the last
  /// known-good optimistic cart on screen instead of erroring the user out.
  Future<void> _reconcile(String vendorId) async {
    final result = await _repository.getCart(vendorId);
    result.fold(
      (failure) => appLogger.w(
        'CartViewModel → reconcile failed: ${failure.message}',
      ),
      (cart) => emit(CartLoaded(cart: cart)),
    );
  }

  CartModel _withAddedItem(
    CartModel base, {
    required int menuItemId,
    required int quantity,
    String? notes,
    required String name,
    required String imageUrl,
    required double price,
    required List<SelectedAddon> addonOptions,
  }) {
    final menuItemIdStr = menuItemId.toString();
    final mergeIndex = notes == null && addonOptions.isEmpty
        ? base.items.indexWhere(
            (i) => i.menuItemId == menuItemIdStr && i.addonOptions.isEmpty && i.notes == null,
          )
        : -1;

    final items = [...base.items];
    if (mergeIndex >= 0) {
      items[mergeIndex] =
          items[mergeIndex].copyWith(quantity: items[mergeIndex].quantity + quantity);
    } else {
      items.add(CartItemModel(
        // Replaced by the server-assigned id on the next reconcile.
        id: 'local_${DateTime.now().microsecondsSinceEpoch}',
        menuItemId: menuItemIdStr,
        name: name,
        imageUrl: imageUrl,
        price: price,
        quantity: quantity,
        notes: notes,
        addonOptions: addonOptions,
      ));
    }

    return base.copyWith(items: items);
  }
}
