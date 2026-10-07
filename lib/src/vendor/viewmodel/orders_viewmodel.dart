import '../../../core/common/app/current_user_provider.dart';
import '../../../core/common/app/session_aware.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failure.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/viewmodel/viewmodel.dart';
import '../model/vendor_order.dart';
import '../repository/vendor_dashboard_repository.dart';

enum OrdersStatus { initial, loading, loaded, error }

class OrdersState extends Equatable {
  final OrdersStatus status;
  final List<VendorOrder> orders;
  final String? activeFilter; // null = all
  final String? errorMessage;

  const OrdersState({
    this.status = OrdersStatus.initial,
    this.orders = const [],
    this.activeFilter,
    this.errorMessage,
  });

  OrdersState copyWith({
    OrdersStatus? status,
    List<VendorOrder>? orders,
    String? activeFilter,
    String? errorMessage,
    bool clearFilter = false,
  }) {
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, orders, activeFilter, errorMessage];
}

class OrdersViewModel extends ViewModel<OrdersState> with SessionAware {
  final VendorDashboardRepository _repository;

  OrdersViewModel(this._repository, CurrentUserProvider session)
      : super(const OrdersState()) {
    bindSession(session);
  }

  /// Bumped by every [loadOrders]; only the newest request's response is
  /// applied, so a slow poll overtaken by a search (or a pull-to-refresh)
  /// can't overwrite the fresher result.
  int _loadGeneration = 0;

  /// Orders changed locally since a refresh may have started — an action's
  /// response, or an order accepted from the dashboard — stamped with the
  /// [_loadGeneration] current at the time. A refresh that started at or
  /// before that stamp fetched the pre-change version, so the local copy
  /// wins when its response lands. Without this, a 15s poll already in
  /// flight when the vendor taps "Mark Ready" would flip the card back.
  final _localEdits = <String, ({int generation, VendorOrder order})>{};

  void reset() {
    _loadGeneration++;
    _localEdits.clear();
    emit(const OrdersState());
  }

  /// Drops the previous account's data on logout (see [SessionAware]).
  @override
  void onSignedOut() => reset();

  /// With [silent], the refresh happens in the background: no loading state
  /// while orders are already on screen (so the list doesn't flash a
  /// spinner on every poll), and a failure keeps the current list instead
  /// of surfacing an error. Falls back to a normal load when there's
  /// nothing to show yet.
  Future<void> loadOrders({
    String? status,
    String? type,
    String? paymentStatus,
    String? search,
    DateTime? from,
    DateTime? to,
    int? perPage,
    bool silent = false,
  }) async {
    final generation = ++_loadGeneration;
    final background = silent && state.orders.isNotEmpty;
    if (!background) emit(state.copyWith(status: OrdersStatus.loading));

    final result = await _repository.fetchAllOrders(
      status: status,
      type: type,
      paymentStatus: paymentStatus,
      search: search,
      from: from,
      to: to,
      perPage: perPage,
    );
    if (generation != _loadGeneration) return;

    result.fold(
      (failure) {
        // A background failure keeps the list as-is — unless this request
        // superseded a foreground load, whose loading state must not be
        // left hanging.
        if (background && state.status != OrdersStatus.loading) {
          appLogger.w(
            'OrdersViewModel.loadOrders → background refresh failed '
            '(keeping current list): ${failure.message}',
          );
          return;
        }
        emit(state.copyWith(
          status: OrdersStatus.error,
          errorMessage: failure.message,
        ));
      },
      (orders) => emit(state.copyWith(
        status: OrdersStatus.loaded,
        orders: _withLocalEdits(
          orders,
          since: generation,
          unfiltered: status == null &&
              type == null &&
              paymentStatus == null &&
              search == null &&
              from == null &&
              to == null,
        ),
        activeFilter: status,
        clearFilter: status == null,
      )),
    );
  }

  /// Overlays [_localEdits] made after the refresh at [since] started onto
  /// its [fetched] list, and forgets the older ones — the server already
  /// reflected those when it answered. An edited order missing from an
  /// [unfiltered] response is still added; a filtered one (search, status,
  /// ...) is left alone since the order may simply not match.
  List<VendorOrder> _withLocalEdits(
    List<VendorOrder> fetched, {
    required int since,
    required bool unfiltered,
  }) {
    _localEdits.removeWhere((_, edit) => edit.generation < since);
    if (_localEdits.isEmpty) return fetched;

    final merged = [
      for (final order in fetched) _localEdits[order.id]?.order ?? order,
    ];
    if (unfiltered) {
      final fetchedIds = fetched.map((o) => o.id).toSet();
      merged.insertAll(0, [
        for (final edit in _localEdits.values)
          if (!fetchedIds.contains(edit.order.id)) edit.order,
      ]);
    }
    return merged;
  }

  void _recordLocalEdit(VendorOrder order) {
    _localEdits[order.id] = (generation: _loadGeneration, order: order);
  }

  /// Puts an order that changed elsewhere (e.g. accepted from the dashboard)
  /// into the list right away — replacing it if present, otherwise adding it
  /// to the top — so the Orders tab shows it before the next refresh lands.
  void upsertOrder(VendorOrder order) {
    _recordLocalEdit(order);
    final exists = state.orders.any((o) => o.id == order.id);
    final updatedList = exists
        ? state.orders.map((o) => o.id == order.id ? order : o).toList()
        : [order, ...state.orders];
    emit(state.copyWith(
      status: state.status == OrdersStatus.loading
          ? OrdersStatus.loading
          : OrdersStatus.loaded,
      orders: updatedList,
      errorMessage: null,
    ));
  }

  Future<void> _apply(
    String orderId,
    Future<Either<Failure, VendorOrder>> Function() call,
  ) async {
    final result = await call();
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      _replaceOrder,
    );
  }

  void _replaceOrder(VendorOrder updated) {
    _recordLocalEdit(updated);
    final updatedList =
        state.orders.map((o) => o.id == updated.id ? updated : o).toList();
    emit(state.copyWith(orders: updatedList, errorMessage: null));
  }

  Future<void> accept(String orderId, {int? estimatedPrepMinutes}) => _apply(
        orderId,
        () => _repository.acceptOrder(
          orderId,
          estimatedPrepMinutes: estimatedPrepMinutes,
        ),
      );

  Future<void> reject(String orderId, {required String reason}) => _apply(
        orderId,
        () => _repository.rejectOrder(orderId, reason: reason),
      );

  Future<void> markPreparing(String orderId) =>
      _apply(orderId, () => _repository.markPreparing(orderId));

  Future<void> markReady(String orderId) =>
      _apply(orderId, () => _repository.markReady(orderId));

  Future<void> markOutForDelivery(String orderId) =>
      _apply(orderId, () => _repository.markOutForDelivery(orderId));

  /// Returns the failure message for the PIN sheet to show inline (e.g. a
  /// wrong PIN), or null on success.
  Future<String?> markDelivered(
    String orderId, {
    required String deliveryPin,
  }) async {
    final result = await _repository.markDelivered(
      orderId,
      deliveryPin: deliveryPin,
    );
    return result.fold((failure) => failure.message, (updated) {
      _replaceOrder(updated);
      return null;
    });
  }

  Future<void> cancel(String orderId, {required String reason}) => _apply(
        orderId,
        () => _repository.cancelOrder(orderId, reason: reason),
      );
}
