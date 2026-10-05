import '../../../core/common/app/current_user_provider.dart';
import '../../../core/common/app/session_aware.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failure.dart';
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

  void reset() => emit(const OrdersState());

  /// Drops the previous account's data on logout (see [SessionAware]).
  @override
  void onSignedOut() => reset();

  Future<void> loadOrders({
    String? status,
    String? type,
    String? paymentStatus,
    String? search,
    DateTime? from,
    DateTime? to,
    int? perPage,
  }) async {
    emit(state.copyWith(status: OrdersStatus.loading));

    final result = await _repository.fetchAllOrders(
      status: status,
      type: type,
      paymentStatus: paymentStatus,
      search: search,
      from: from,
      to: to,
      perPage: perPage,
    );
    result.fold(
      (failure) => emit(state.copyWith(
        status: OrdersStatus.error,
        errorMessage: failure.message,
      )),
      (orders) => emit(state.copyWith(
        status: OrdersStatus.loaded,
        orders: orders,
        activeFilter: status,
        clearFilter: status == null,
      )),
    );
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
