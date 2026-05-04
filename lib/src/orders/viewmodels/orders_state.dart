import 'package:equatable/equatable.dart';
import 'package:bagyesrushappusernew/core/errors/failure.dart';
import '../models/order.dart';

sealed class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

final class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

final class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

final class OrdersLoaded extends OrdersState {
  const OrdersLoaded(this.orders);
  final List<Order> orders;

  @override
  List<Object?> get props => [orders];
}

final class OrderDetailsLoaded extends OrdersState {
  const OrderDetailsLoaded(this.order);
  final Order order;

  @override
  List<Object?> get props => [order];
}

final class OrdersError extends OrdersState {
  const OrdersError({required this.message, required this.title});

  OrdersError.fromFailure(Failure failure)
      : this(message: failure.message, title: failure.title);

  final String message;
  final String title;

  @override
  List<Object?> get props => [message, title];
}
