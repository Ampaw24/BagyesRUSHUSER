import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failure.dart';
import '../../../core/viewmodel/viewmodel.dart';
import '../model/vendor_order.dart';
import '../model/vendor_order_stats.dart';
import '../repository/vendor_dashboard_repository.dart';

enum OrdersStatus { initial, loading, loaded, error }

class OrdersState extends Equatable {
  final OrdersStatus status;
  final List<VendorOrder> orders;
  final String? activeFilter; // null = all
  final String? errorMessage;
  final VendorOrderStats? stats;

  const OrdersState({
    this.status = OrdersStatus.initial,
    this.orders = const [],
    this.activeFilter,
    this.errorMessage,
    this.stats,
  });

  OrdersState copyWith({
    OrdersStatus? status,
    List<VendorOrder>? orders,
    String? activeFilter,
    String? errorMessage,
    VendorOrderStats? stats,
    bool clearFilter = false,
  }) {
    return OrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      errorMessage: errorMessage,
      stats: stats ?? this.stats,
    );
  }

  @override
  List<Object?> get props =>
      [status, orders, activeFilter, errorMessage, stats];
}

class OrdersViewModel extends ViewModel<OrdersState> {
  final VendorDashboardRepository _repository;

  OrdersViewModel(this._repository) : super(const OrdersState());

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

  Future<void> loadStats() async {
    final result = await _repository.fetchOrderStats();
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (stats) => emit(state.copyWith(stats: stats)),
    );
  }

  Future<void> _apply(
    String orderId,
    Future<Either<Failure, VendorOrder>> Function() call,
  ) async {
    final result = await call();
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (updated) {
        final updatedList = state.orders
            .map((o) => o.id == updated.id ? updated : o)
            .toList();
        emit(state.copyWith(orders: updatedList, errorMessage: null));
      },
    );
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

  Future<void> markDelivered(String orderId) =>
      _apply(orderId, () => _repository.markDelivered(orderId));

  Future<void> cancel(String orderId, {required String reason}) => _apply(
        orderId,
        () => _repository.cancelOrder(orderId, reason: reason),
      );
}
