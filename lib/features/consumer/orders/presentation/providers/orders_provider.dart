import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/domain/entities/cart_item.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/entities/consumer_order.dart';

// ─── Orders Notifier ──────────────────────────────────────────────────────

class OrdersNotifier extends Notifier<List<ConsumerOrder>> {
  @override
  List<ConsumerOrder> build() => _mockOrders;

  /// Place a new order from the current cart state.
  Future<ConsumerOrder> placeOrder({
    required CartState cart,
    required String deliveryAddress,
    String? deliveryInstructions,
    required String paymentMethod,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    final order = ConsumerOrder(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      restaurantId: cart.restaurantId!,
      restaurantName: cart.restaurantName!,
      restaurantImageUrl: cart.restaurantImageUrl!,
      items: cart.items.map((ci) => OrderItem(
        menuItemId: ci.item.id,
        name: ci.item.name,
        quantity: ci.quantity,
        unitPrice: ci.item.price,
      )).toList(),
      status: OrderStatus.pending,
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      serviceFee: cart.serviceFee,
      discount: 0,
      total: cart.total,
      deliveryAddress: deliveryAddress,
      deliveryInstructions: deliveryInstructions,
      placedAt: DateTime.now(),
      estimatedDelivery: DateTime.now().add(
        const Duration(minutes: 35),
      ),
      paymentMethod: paymentMethod,
    );

    state = [order, ...state];
    return order;
  }

  /// Simulate a status progression for demo purposes.
  void progressOrderStatus(String orderId) {
    state = state.map((o) {
      if (o.id != orderId) return o;
      final next = _nextStatus(o.status);
      if (next == null) return o;
      return ConsumerOrder(
        id: o.id,
        restaurantId: o.restaurantId,
        restaurantName: o.restaurantName,
        restaurantImageUrl: o.restaurantImageUrl,
        items: o.items,
        status: next,
        subtotal: o.subtotal,
        deliveryFee: o.deliveryFee,
        serviceFee: o.serviceFee,
        discount: o.discount,
        total: o.total,
        deliveryAddress: o.deliveryAddress,
        deliveryInstructions: o.deliveryInstructions,
        placedAt: o.placedAt,
        estimatedDelivery: o.estimatedDelivery,
        driverName: next == OrderStatus.pickedUp ? 'Kwame Mensah' : o.driverName,
        driverPhone: next == OrderStatus.pickedUp ? '+233 20 123 4567' : o.driverPhone,
        paymentMethod: o.paymentMethod,
      );
    }).toList();
  }

  OrderStatus? _nextStatus(OrderStatus s) {
    final flow = [
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
    NotifierProvider<OrdersNotifier, List<ConsumerOrder>>(OrdersNotifier.new);

final activeOrdersProvider = Provider<List<ConsumerOrder>>((ref) {
  return ref.watch(ordersProvider).where((o) => o.status.isActive).toList();
});

final pastOrdersProvider = Provider<List<ConsumerOrder>>((ref) {
  return ref.watch(ordersProvider)
      .where((o) => !o.status.isActive)
      .toList();
});

// ─── Mock seed data ───────────────────────────────────────────────────────

final _mockOrders = [
  ConsumerOrder(
    id: 'ORD-001',
    restaurantId: 'r2',
    restaurantName: 'Papaye Fast Food',
    restaurantImageUrl:
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',
    items: const [
      OrderItem(menuItemId: 'r2_m1', name: 'Jollof Rice + Chicken', quantity: 2, unitPrice: 55),
      OrderItem(menuItemId: 'r2_m6', name: 'Malta Guinness', quantity: 2, unitPrice: 10),
    ],
    status: OrderStatus.onTheWay,
    subtotal: 130,
    deliveryFee: 7,
    serviceFee: 6.50,
    discount: 0,
    total: 143.50,
    deliveryAddress: '12 Osu Badu St, Accra',
    placedAt: DateTime.now().subtract(const Duration(minutes: 28)),
    estimatedDelivery: DateTime.now().add(const Duration(minutes: 12)),
    driverName: 'Kwame Mensah',
    driverPhone: '+233 20 123 4567',
    paymentMethod: 'Mobile Money',
  ),
  ConsumerOrder(
    id: 'ORD-002',
    restaurantId: 'r1',
    restaurantName: 'KFC Ghana',
    restaurantImageUrl:
        'https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=600',
    items: const [
      OrderItem(menuItemId: 'r1_m3', name: 'Bucket for 4', quantity: 1, unitPrice: 195),
    ],
    status: OrderStatus.delivered,
    subtotal: 195,
    deliveryFee: 8,
    serviceFee: 9.75,
    discount: 39, // 20% off
    total: 173.75,
    deliveryAddress: '12 Osu Badu St, Accra',
    placedAt: DateTime.now().subtract(const Duration(days: 2)),
    paymentMethod: 'Card',
  ),
];
