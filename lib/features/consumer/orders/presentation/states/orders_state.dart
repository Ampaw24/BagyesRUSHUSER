import 'package:bagyesrushappusernew/features/consumer/orders/domain/entities/consumer_order.dart';

/// Sealed states for the orders list.
sealed class OrdersState {
  const OrdersState();
}

class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

class OrdersLoaded extends OrdersState {
  final List<ConsumerOrder> orders;
  const OrdersLoaded({required this.orders});

  List<ConsumerOrder> get active =>
      orders.where((o) => o.status.isActive).toList();
  List<ConsumerOrder> get past =>
      orders.where((o) => !o.status.isActive).toList();
}

class OrdersError extends OrdersState {
  final String message;
  const OrdersError({required this.message});
}
