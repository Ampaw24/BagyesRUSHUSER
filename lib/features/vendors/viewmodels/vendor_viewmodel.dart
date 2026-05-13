import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/features/vendors/repositories/i_vendor_repository.dart';
import 'package:bagyesrushappusernew/features/vendors/viewmodels/vendor_state.dart';

class VendorViewmodel extends ViewModel<VendorState> {
  VendorViewmodel({required IVendorRepository repository})
      : _repository = repository,
        super(const VendorInitial());

  final IVendorRepository _repository;

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<void> getVendorProfile() async {
    appLogger.d('VendorViewmodel.getVendorProfile → initiated');
    emit(const VendorLoading());

    final result = await _repository.getVendorProfile();

    result.fold(
      (failure) {
        appLogger.w('VendorViewmodel.getVendorProfile → error: ${failure.message}');
        emit(VendorError.fromFailure(failure));
      },
      (profile) {
        appLogger.i('VendorViewmodel.getVendorProfile → loaded id=${profile.id}');
        emit(VendorProfileLoaded(profile));
      },
    );
  }

  Future<void> updateVendorProfile(Map<String, dynamic> data) async {
    appLogger.d(
        'VendorViewmodel.updateVendorProfile → fields=${data.keys.join(', ')}');
    emit(const VendorLoading());

    final result = await _repository.updateVendorProfile(data);

    result.fold(
      (failure) {
        appLogger
            .w('VendorViewmodel.updateVendorProfile → error: ${failure.message}');
        emit(VendorError.fromFailure(failure));
      },
      (profile) {
        appLogger.i(
            'VendorViewmodel.updateVendorProfile → updated id=${profile.id}');
        emit(VendorProfileUpdated(profile));
      },
    );
  }

  // ── Menu Items ────────────────────────────────────────────────────────────

  Future<void> getMenuItems() async {
    appLogger.d('VendorViewmodel.getMenuItems → initiated');
    emit(const VendorLoading());

    final result = await _repository.getMenuItems();

    result.fold(
      (failure) {
        appLogger.w('VendorViewmodel.getMenuItems → error: ${failure.message}');
        emit(VendorError.fromFailure(failure));
      },
      (items) {
        appLogger.i('VendorViewmodel.getMenuItems → loaded ${items.length} items');
        emit(MenuItemsLoaded(items));
      },
    );
  }

  Future<void> createMenuItem(Map<String, dynamic> data) async {
    appLogger.d('VendorViewmodel.createMenuItem → name=${data['name']}');
    emit(const VendorLoading());

    final result = await _repository.createMenuItem(data);

    result.fold(
      (failure) {
        appLogger
            .w('VendorViewmodel.createMenuItem → error: ${failure.message}');
        emit(VendorError.fromFailure(failure));
      },
      (item) {
        appLogger.i('VendorViewmodel.createMenuItem → created id=${item.id}');
        emit(MenuItemCreated(item));
      },
    );
  }

  Future<void> updateMenuItem(String id, Map<String, dynamic> data) async {
    appLogger.d('VendorViewmodel.updateMenuItem → id=$id');
    emit(const VendorLoading());

    final result = await _repository.updateMenuItem(id, data);

    result.fold(
      (failure) {
        appLogger
            .w('VendorViewmodel.updateMenuItem → error: ${failure.message}');
        emit(VendorError.fromFailure(failure));
      },
      (item) {
        appLogger.i('VendorViewmodel.updateMenuItem → updated id=${item.id}');
        emit(MenuItemUpdated(item));
      },
    );
  }

  Future<void> toggleMenuItemAvailability(String id, bool isAvailable) async {
    appLogger.d(
        'VendorViewmodel.toggleMenuItemAvailability → id=$id isAvailable=$isAvailable');
    emit(const VendorLoading());

    final result = await _repository.toggleMenuItemAvailability(id, isAvailable);

    result.fold(
      (failure) {
        appLogger.w(
            'VendorViewmodel.toggleMenuItemAvailability → error: ${failure.message}');
        emit(VendorError.fromFailure(failure));
      },
      (item) {
        appLogger.i(
            'VendorViewmodel.toggleMenuItemAvailability → id=${item.id} isAvailable=${item.isAvailable}');
        emit(MenuItemAvailabilityToggled(item));
      },
    );
  }

  Future<void> deleteMenuItem(String id) async {
    appLogger.d('VendorViewmodel.deleteMenuItem → id=$id');
    emit(const VendorLoading());

    final result = await _repository.deleteMenuItem(id);

    result.fold(
      (failure) {
        appLogger
            .w('VendorViewmodel.deleteMenuItem → error: ${failure.message}');
        emit(VendorError.fromFailure(failure));
      },
      (_) {
        appLogger.i('VendorViewmodel.deleteMenuItem → deleted id=$id');
        emit(MenuItemDeleted(id));
      },
    );
  }

  // ── Orders ────────────────────────────────────────────────────────────────

  Future<void> getOrders({String? status}) async {
    appLogger.d('VendorViewmodel.getOrders → status=${status ?? 'all'}');
    emit(const VendorLoading());

    final result = await _repository.getOrders(status: status);

    result.fold(
      (failure) {
        appLogger.w('VendorViewmodel.getOrders → error: ${failure.message}');
        emit(VendorError.fromFailure(failure));
      },
      (orders) {
        appLogger
            .i('VendorViewmodel.getOrders → loaded ${orders.length} orders');
        emit(VendorOrdersLoaded(orders));
      },
    );
  }

  Future<void> getOrderById(String orderId) async {
    appLogger.d('VendorViewmodel.getOrderById → orderId=$orderId');
    emit(const VendorLoading());

    final result = await _repository.getOrderById(orderId);

    result.fold(
      (failure) {
        appLogger
            .w('VendorViewmodel.getOrderById → error: ${failure.message}');
        emit(VendorError.fromFailure(failure));
      },
      (order) {
        appLogger
            .i('VendorViewmodel.getOrderById → loaded order id=${order.id}');
        emit(VendorOrderLoaded(order));
      },
    );
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    appLogger.d(
        'VendorViewmodel.updateOrderStatus → orderId=$orderId status=$status');
    emit(const VendorLoading());

    final result = await _repository.updateOrderStatus(orderId, status);

    result.fold(
      (failure) {
        appLogger.w(
            'VendorViewmodel.updateOrderStatus → error: ${failure.message}');
        emit(VendorError.fromFailure(failure));
      },
      (order) {
        appLogger.i(
            'VendorViewmodel.updateOrderStatus → order id=${order.id} status=${order.status}');
        emit(VendorOrderStatusUpdated(order));
      },
    );
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  /// Reset to idle after a one-shot action (create / update / delete) has
  /// been handled by the UI so the state doesn't replay on rebuild.
  void resetState() => emit(const VendorInitial());
}
