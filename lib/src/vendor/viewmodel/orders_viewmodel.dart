import 'package:equatable/equatable.dart';
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

class OrdersViewModel extends ViewModel<OrdersState> {
  final VendorDashboardRepository _repository;

  OrdersViewModel(this._repository) : super(const OrdersState());

  Future<void> loadOrders({String? status}) async {
    emit(state.copyWith(status: OrdersStatus.loading));

    final result = await _repository.fetchAllOrders(status: status);
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

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    final result = await _repository.updateOrderStatus(orderId, newStatus);
    result.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (updated) {
        final updatedList = state.orders
            .map((o) => o.id == updated.id ? updated : o)
            .toList();
        emit(state.copyWith(orders: updatedList));
      },
    );
  }
}
