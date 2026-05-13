import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/errors/failure.dart';
import 'package:bagyesrushappusernew/src/vendor/model/menu_item.dart';
import 'package:bagyesrushappusernew/src/vendor/model/vendor_order.dart';
import 'package:bagyesrushappusernew/src/vendor/model/vendor_profile.dart';

sealed class VendorState extends Equatable {
  const VendorState();

  @override
  List<Object?> get props => [];
}

// ── Idle / Loading ────────────────────────────────────────────────────────────

final class VendorInitial extends VendorState {
  const VendorInitial();
}

final class VendorLoading extends VendorState {
  const VendorLoading();
}

// ── Profile ───────────────────────────────────────────────────────────────────

final class VendorProfileLoaded extends VendorState {
  const VendorProfileLoaded(this.profile);
  final VendorProfile profile;

  @override
  List<Object?> get props => [profile];
}

final class VendorProfileUpdated extends VendorState {
  const VendorProfileUpdated(this.profile);
  final VendorProfile profile;

  @override
  List<Object?> get props => [profile];
}

// ── Menu Items ────────────────────────────────────────────────────────────────

final class MenuItemsLoaded extends VendorState {
  const MenuItemsLoaded(this.items);
  final List<MenuItem> items;

  @override
  List<Object?> get props => [items];
}

final class MenuItemCreated extends VendorState {
  const MenuItemCreated(this.item);
  final MenuItem item;

  @override
  List<Object?> get props => [item];
}

final class MenuItemUpdated extends VendorState {
  const MenuItemUpdated(this.item);
  final MenuItem item;

  @override
  List<Object?> get props => [item];
}

final class MenuItemAvailabilityToggled extends VendorState {
  const MenuItemAvailabilityToggled(this.item);
  final MenuItem item;

  @override
  List<Object?> get props => [item];
}

final class MenuItemDeleted extends VendorState {
  /// [deletedId] lets the UI remove the item from its local list without
  /// refetching the entire menu.
  const MenuItemDeleted(this.deletedId);
  final String deletedId;

  @override
  List<Object?> get props => [deletedId];
}

// ── Orders ────────────────────────────────────────────────────────────────────

final class VendorOrdersLoaded extends VendorState {
  const VendorOrdersLoaded(this.orders);
  final List<VendorOrder> orders;

  @override
  List<Object?> get props => [orders];
}

final class VendorOrderLoaded extends VendorState {
  const VendorOrderLoaded(this.order);
  final VendorOrder order;

  @override
  List<Object?> get props => [order];
}

final class VendorOrderStatusUpdated extends VendorState {
  const VendorOrderStatusUpdated(this.order);
  final VendorOrder order;

  @override
  List<Object?> get props => [order];
}

// ── Error ─────────────────────────────────────────────────────────────────────

final class VendorError extends VendorState {
  const VendorError({required this.message, required this.title});

  VendorError.fromFailure(Failure failure)
      : this(message: failure.message, title: failure.title);

  final String message;
  final String title;

  @override
  List<Object?> get props => [message, title];
}
