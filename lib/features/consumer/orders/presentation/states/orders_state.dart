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

  /// Pagination over the chronological order-history feed (used by the
  /// Past tab's infinite scroll — Active orders are always few, so they're
  /// never paginated, just derived from whatever's already loaded).
  final bool hasMore;
  final bool isLoadingMore;
  final int currentPage;

  const OrdersLoaded({
    required this.orders,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.currentPage = 1,
  });

  List<ConsumerOrder> get active =>
      orders.where((o) => o.status.isActive).toList();
  List<ConsumerOrder> get past =>
      orders.where((o) => !o.status.isActive).toList();
}

class OrdersError extends OrdersState {
  final String message;
  const OrdersError({required this.message});
}
