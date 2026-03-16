import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/states/cart_state.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/data/repositories/orders_repository_impl.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/entities/consumer_order.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/repositories/i_orders_repository.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/presentation/states/orders_state.dart';

// ─── Repository provider ──────────────────────────────────────────────────

final ordersRepositoryProvider = Provider<IOrdersRepository>(
  (_) => OrdersRepositoryImpl(),
);

// ─── Orders ViewModel ─────────────────────────────────────────────────────

class OrdersViewModel extends Notifier<OrdersState> {
  IOrdersRepository get _repo => ref.read(ordersRepositoryProvider);

  @override
  OrdersState build() {
    _loadOrders();
    return const OrdersLoading();
  }

  Future<void> _loadOrders() async {
    try {
      final orders = await _repo.getOrders();
      state = OrdersLoaded(orders: orders);
    } catch (e) {
      state = OrdersError(message: e.toString());
    }
  }

  Future<ConsumerOrder> placeOrder({
    required CartState cart,
    required String deliveryAddress,
    String? deliveryInstructions,
    required String paymentMethod,
  }) async {
    final order = await _repo.placeOrder(
      cart: cart,
      deliveryAddress: deliveryAddress,
      deliveryInstructions: deliveryInstructions,
      paymentMethod: paymentMethod,
    );

    final current = state;
    if (current is OrdersLoaded) {
      state = OrdersLoaded(orders: [order, ...current.orders]);
    } else {
      state = OrdersLoaded(orders: [order]);
    }

    return order;
  }

  Future<void> progressOrderStatus(String orderId) async {
    final current = state;
    if (current is! OrdersLoaded) return;

    final order = current.orders.firstWhere((o) => o.id == orderId);
    final next = _nextStatus(order.status);
    if (next == null) return;

    final updated = await _repo.updateOrderStatus(orderId, next);
    state = OrdersLoaded(
      orders: current.orders
          .map((o) => o.id == orderId ? updated : o)
          .toList(),
    );
  }

  OrderStatus? _nextStatus(OrderStatus s) {
    const flow = [
      OrderStatus.pending,
      OrderStatus.accepted,
      OrderStatus.preparing,
      OrderStatus.readyForPickup,
      OrderStatus.pickedUp,
      OrderStatus.onTheWay,
      OrderStatus.delivered,
    ];
    final idx = flow.indexOf(s);
    if (idx < 0 || idx >= flow.length - 1) return null;
    return flow[idx + 1];
  }
}

final ordersProvider =
    NotifierProvider<OrdersViewModel, OrdersState>(OrdersViewModel.new);

final activeOrdersProvider = Provider<List<ConsumerOrder>>((ref) {
  final s = ref.watch(ordersProvider);
  if (s is OrdersLoaded) return s.active;
  return [];
});

final pastOrdersProvider = Provider<List<ConsumerOrder>>((ref) {
  final s = ref.watch(ordersProvider);
  if (s is OrdersLoaded) return s.past;
  return [];
});

/// Returns a single order by ID, or null if not found / still loading.
final orderByIdProvider =
    Provider.family<ConsumerOrder?, String>((ref, orderId) {
  final s = ref.watch(ordersProvider);
  if (s is! OrdersLoaded) return null;
  try {
    return s.orders.firstWhere((o) => o.id == orderId);
  } catch (_) {
    return null;
  }
});
