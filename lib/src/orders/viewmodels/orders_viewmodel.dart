import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import '../repositories/orders_repository.dart';
import 'orders_state.dart';

class OrderViewModel extends ViewModel<OrdersState> {
  OrderViewModel({
    required OrdersRepository repository,
  })  : _repository = repository,
        super(const OrdersInitial());

  final OrdersRepository _repository;

  Future<void> getCustomerOrders() async {
    appLogger.d('OrdersViewModel.getCustomerOrders → initiated');
    emit(const OrdersLoading());

    final result = await _repository.getCustomerOrders();

    result.fold(
      (failure) {
        appLogger.w('OrdersViewModel.getCustomerOrders → error: ${failure.message}');
        emit(OrdersError.fromFailure(failure));
      },
      (orders) {
        appLogger.i('OrdersViewModel.getCustomerOrders → loaded ${orders.length} orders');
        emit(OrdersLoaded(orders));
      },
    );
  }

  Future<void> getOrderById(String orderId) async {
    appLogger.d('OrdersViewModel.getOrderById → id=$orderId');
    emit(const OrdersLoading());

    final result = await _repository.getOrderById(orderId: orderId);

    result.fold(
      (failure) {
        appLogger.w('OrdersViewModel.getOrderById → error: ${failure.message}');
        emit(OrdersError.fromFailure(failure));
      },
      (order) {
        appLogger.i('OrdersViewModel.getOrderById → success');
        emit(OrderDetailsLoaded(order));
      },
    );
  }
}
