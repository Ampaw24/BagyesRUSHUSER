import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/core/errors/failure.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_model.dart';

sealed class CartState extends Equatable {
  const CartState();
  @override
  List<Object?> get props => [];
}

final class CartInitial extends CartState {
  const CartInitial();
}

final class CartLoading extends CartState {
  const CartLoading();
}

final class CartLoaded extends CartState {
  const CartLoaded({required this.cart, this.isMutating = false, this.errorMessage});

  final CartModel cart;

  /// True while an add/update/remove/clear request is in flight — the UI
  /// keeps showing [cart] but can disable controls or show a small spinner.
  final bool isMutating;

  /// A mutation or background refresh just failed, but [cart] still holds
  /// the last known-good data — the UI should surface this as a transient
  /// toast/snackbar (then call [CartViewModel.clearError]) rather than
  /// replacing the cart view with an error screen.
  final String? errorMessage;

  CartLoaded copyWith({
    CartModel? cart,
    bool? isMutating,
    String? errorMessage,
    bool clearError = false,
  }) =>
      CartLoaded(
        cart: cart ?? this.cart,
        isMutating: isMutating ?? this.isMutating,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [cart, isMutating, errorMessage];
}

/// No cart could be loaded at all yet — reserved for a *first* load failure
/// with no prior data to fall back on. Once any [CartLoaded] has been shown,
/// later failures roll back to it (via [CartLoaded.errorMessage]) instead of
/// reaching this state, since destroying a valid cart over a transient
/// mutation error would be worse than just reporting it.
final class CartError extends CartState {
  const CartError({required this.message, required this.title});

  CartError.fromFailure(Failure failure)
      : this(message: failure.message, title: failure.title);

  final String message;
  final String title;

  @override
  List<Object?> get props => [message, title];
}
