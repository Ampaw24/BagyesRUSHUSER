import 'dart:async';

import 'package:bagyesrushappusernew/core/services/realtime_events.dart';
import 'package:bagyesrushappusernew/core/services/realtime_service.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/rider_location.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/repositories/consumer_orders_repository.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_state.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_model.dart';

class OrdersViewModel extends ViewModel<OrdersState> {
  OrdersViewModel(this._repository, this._realtimeService) : super(const OrdersLoading()) {
    _loadOrders();
    _orderStatusSub = _realtimeService.orderStatusEvents.listen(applyOrderStatusEvent);
    _riderLocationSub = _realtimeService.riderLocationEvents.listen(_applyRiderLocationEvent);
  }

  final ConsumerOrdersRepository _repository;
  final RealtimeService _realtimeService;
  StreamSubscription<OrderStatusEvent>? _orderStatusSub;
  StreamSubscription<RiderLocationEvent>? _riderLocationSub;

  Future<void> _loadOrders() async {
    try {
      final result = await _repository.getOrdersPaged(page: 1);
      emit(OrdersLoaded(
        orders: result.orders,
        hasMore: result.hasMore,
        currentPage: result.page,
      ));
    } catch (e) {
      emit(OrdersError(message: e.toString()));
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

    emit(OrdersLoaded(
      orders: current.orders,
      hasMore: current.hasMore,
      isLoadingMore: true,
      currentPage: current.currentPage,
    ));

    try {
      final result = await _repository.getOrdersPaged(page: current.currentPage + 1);
      emit(OrdersLoaded(
        orders: [...current.orders, ...result.orders],
        hasMore: result.hasMore,
        currentPage: result.page,
      ));
    } catch (_) {
      // Keep existing data; clear loading flag so the user can retry by
      // scrolling again.
      emit(OrdersLoaded(
        orders: current.orders,
        hasMore: current.hasMore,
        currentPage: current.currentPage,
      ));
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
    final order = await _repository.placeOrder(
      cart: cart,
      deliveryAddress: deliveryAddress,
      deliveryInstructions: deliveryInstructions,
      paymentMethod: paymentMethod,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
    );

    final current = state;
    if (current is OrdersLoaded) {
      emit(OrdersLoaded(
        orders: [order, ...current.orders],
        hasMore: current.hasMore,
        currentPage: current.currentPage,
      ));
    } else {
      emit(OrdersLoaded(orders: [order]));
    }

    return order;
  }

  Future<void> _replaceOrder(ConsumerOrder updated) async {
    final current = state;
    if (current is! OrdersLoaded) return;
    emit(OrdersLoaded(
      orders: current.orders
          .map((o) => o.id == updated.id ? updated : o)
          .toList(),
      hasMore: current.hasMore,
      currentPage: current.currentPage,
    ));
  }

  Future<void> cancelOrder(String orderId, {required String reason}) async {
    final updated = await _repository.cancelOrder(orderId, reason: reason);
    await _replaceOrder(updated);
  }

  Future<void> reorder(String orderId) async {
    final newOrder = await _repository.reorder(orderId);
    final current = state;
    if (current is OrdersLoaded) {
      emit(OrdersLoaded(
        orders: [newOrder, ...current.orders],
        hasMore: current.hasMore,
        currentPage: current.currentPage,
      ));
    } else {
      emit(OrdersLoaded(orders: [newOrder]));
    }
  }

  Future<void> trackOrder(String orderId) async {
    final current = state;
    ConsumerOrder? previous;
    if (current is OrdersLoaded) {
      for (final o in current.orders) {
        if (o.id == orderId) {
          previous = o;
          break;
        }
      }
    }
    final updated = await _repository.trackOrder(orderId, previous: previous);
    // With no cached `previous`, the repo falls back to parsing the slim
    // track payload directly, which carries no `id` — stamp it so
    // `_replaceOrder` can still match this order.
    await _replaceOrder(previous == null ? updated.copyWith(id: orderId) : updated);
  }

  Future<Map<String, dynamic>> payOrder(
    String orderId, {
    required String paymentMethod,
    String? phone,
    String? mobileMoneyProvider,
  }) =>
      _repository.payOrder(
        orderId,
        paymentMethod: paymentMethod,
        phone: phone,
        mobileMoneyProvider: mobileMoneyProvider,
      );

  Future<void> verifyPayment(String orderId, {required String reference}) async {
    final updated = await _repository.verifyPayment(orderId, reference: reference);
    await _replaceOrder(updated);
  }

  /// Returns a single order by ID, or null if not found / still loading.
  ConsumerOrder? orderById(String orderId) {
    final s = state;
    if (s is! OrdersLoaded) return null;
    for (final o in s.orders) {
      if (o.id == orderId) return o;
    }
    return null;
  }

  /// Applies a realtime `order.status` event onto the cached order, if any
  /// — a no-op if this order isn't cached yet (e.g. no screen has fetched
  /// it this session). Reuses the same status-string parser the REST path
  /// uses, so socket-driven and REST-driven status stay consistent.
  void applyOrderStatusEvent(OrderStatusEvent event) {
    final current = orderById(event.orderId);
    if (current == null) return;
    _replaceOrder(current.copyWith(
      status: orderStatusFromString(event.status),
      estimatedDelivery: event.estimatedDeliveryAt,
    ));
  }

  /// Applies a realtime `rider.location` event for [orderId] onto the
  /// cached order, if any.
  void applyRiderLocation(String orderId, RiderLocationEvent event) {
    final current = orderById(orderId);
    if (current == null) return;
    _replaceOrder(current.copyWith(riderLocation: RiderLocation.fromEvent(event)));
  }

  /// `riderLocationEvents` is a single stream shared by both the
  /// `private-order.{id}` and `private-admin.riders` feeds — [sourceOrderId]
  /// is null for the latter, which isn't order-scoped and is dropped here.
  void _applyRiderLocationEvent(RiderLocationEvent event) {
    final orderId = event.sourceOrderId;
    if (orderId == null) return;
    applyRiderLocation(orderId, event);
  }

  @override
  void dispose() {
    _orderStatusSub?.cancel();
    _riderLocationSub?.cancel();
    super.dispose();
  }
}
