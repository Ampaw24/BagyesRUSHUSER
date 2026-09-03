import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/core/di/service_locator.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/data/repositories/orders_repository_impl.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/entities/consumer_order.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/repositories/i_orders_repository.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/presentation/states/orders_state.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_model.dart';

// ─── Repository provider ──────────────────────────────────────────────────

final ordersRepositoryProvider = Provider<IOrdersRepository>(
  (_) => OrdersRepositoryImpl(client: sl<Dio>()),
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
      final result = await _repo.getOrdersPaged(page: 1);
      state = OrdersLoaded(
        orders: result.orders,
        hasMore: result.hasMore,
        currentPage: result.page,
      );
    } catch (e) {
      state = OrdersError(message: e.toString());
    }
  }

  /// Pull-to-refresh: re-fetch page 1 and replace the list.
  Future<void> refresh() => _loadOrders();

  /// Infinite scroll on the Past tab.
  Future<void> loadMore() async {
    final current = state;
    if (current is! OrdersLoaded ||
        current.isLoadingMore ||
        !current.hasMore) {
      return;
    }

    state = OrdersLoaded(
      orders: current.orders,
      hasMore: current.hasMore,
      isLoadingMore: true,
      currentPage: current.currentPage,
    );

    try {
      final result = await _repo.getOrdersPaged(page: current.currentPage + 1);
      state = OrdersLoaded(
        orders: [...current.orders, ...result.orders],
        hasMore: result.hasMore,
        currentPage: result.page,
      );
    } catch (_) {
      // Keep existing data; clear loading flag so the user can retry by
      // scrolling again.
      state = OrdersLoaded(
        orders: current.orders,
        hasMore: current.hasMore,
        currentPage: current.currentPage,
      );
    }
  }

  Future<ConsumerOrder> placeOrder({
    required CartModel cart,
    required String deliveryAddress,
    String? deliveryInstructions,
    required String paymentMethod,
    double? deliveryLat,
    double? deliveryLng,
  }) async {
    final order = await _repo.placeOrder(
      cart: cart,
      deliveryAddress: deliveryAddress,
      deliveryInstructions: deliveryInstructions,
      paymentMethod: paymentMethod,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
    );

    final current = state;
    if (current is OrdersLoaded) {
      state = OrdersLoaded(
        orders: [order, ...current.orders],
        hasMore: current.hasMore,
        currentPage: current.currentPage,
      );
    } else {
      state = OrdersLoaded(orders: [order]);
    }

    return order;
  }

  Future<void> _replaceOrder(ConsumerOrder updated) async {
    final current = state;
    if (current is! OrdersLoaded) return;
    state = OrdersLoaded(
      orders: current.orders
          .map((o) => o.id == updated.id ? updated : o)
          .toList(),
      hasMore: current.hasMore,
      currentPage: current.currentPage,
    );
  }

  Future<void> cancelOrder(String orderId) async {
    final updated = await _repo.cancelOrder(orderId);
    await _replaceOrder(updated);
  }

  Future<void> reorder(String orderId) async {
    final newOrder = await _repo.reorder(orderId);
    final current = state;
    if (current is OrdersLoaded) {
      state = OrdersLoaded(
        orders: [newOrder, ...current.orders],
        hasMore: current.hasMore,
        currentPage: current.currentPage,
      );
    } else {
      state = OrdersLoaded(orders: [newOrder]);
    }
  }

  Future<void> trackOrder(String orderId) async {
    final updated = await _repo.trackOrder(orderId);
    await _replaceOrder(updated);
  }

  Future<Map<String, dynamic>> payOrder(
    String orderId, {
    required String paymentMethod,
    String? phone,
    String? mobileMoneyProvider,
  }) =>
      _repo.payOrder(
        orderId,
        paymentMethod: paymentMethod,
        phone: phone,
        mobileMoneyProvider: mobileMoneyProvider,
      );

  Future<void> verifyPayment(String orderId, {required String reference}) async {
    final updated = await _repo.verifyPayment(orderId, reference: reference);
    await _replaceOrder(updated);
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
