import 'package:equatable/equatable.dart';
import '../../../core/errors/failure.dart';
import '../model/vendor_order.dart';

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
  const OrdersLoaded({
    required this.orders,
    this.activeFilter,
  });

  final List<VendorOrder> orders;
  final String? activeFilter;

  OrdersLoaded copyWith({
    List<VendorOrder>? orders,
    String? activeFilter,
    bool clearFilter = false,
  }) =>
      OrdersLoaded(
        orders: orders ?? this.orders,
        activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      );

  @override
  List<Object?> get props => [orders, activeFilter];
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
