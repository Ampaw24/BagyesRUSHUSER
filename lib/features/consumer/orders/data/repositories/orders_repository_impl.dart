import 'package:bagyesrushappusernew/features/consumer/cart/presentation/states/cart_state.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/entities/consumer_order.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/repositories/i_orders_repository.dart';

class OrdersRepositoryImpl implements IOrdersRepository {
  // In-memory store — replace with real API/DB calls later.
  final List<ConsumerOrder> _store = List.from(_seedOrders);

  @override
  Future<List<ConsumerOrder>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_store);
  }

  @override
  Future<ConsumerOrder> placeOrder({
    required CartState cart,
    required String deliveryAddress,
    String? deliveryInstructions,
    required String paymentMethod,
  }) async {
    await Future.delayed(const Duration(seconds: 2));

    final order = ConsumerOrder(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
      restaurantId: cart.restaurantId!,
      restaurantName: cart.restaurantName!,
      restaurantImageUrl: cart.restaurantImageUrl!,
      items: cart.items
          .map((ci) => OrderItem(
                menuItemId: ci.item.id,
                name: ci.item.name,
                quantity: ci.quantity,
                unitPrice: ci.item.price,
                addons: ci.selectedAddons,
              ))
          .toList(),
      status: OrderStatus.pending,
      subtotal: cart.subtotal,
      deliveryFee: cart.deliveryFee,
      serviceFee: cart.serviceFee,
      discount: 0,
      total: cart.total,
      deliveryAddress: deliveryAddress,
      deliveryInstructions: deliveryInstructions,
      placedAt: DateTime.now(),
      estimatedDelivery: DateTime.now().add(const Duration(minutes: 35)),
      paymentMethod: paymentMethod,
    );

    _store.insert(0, order);
    return order;
  }

  @override
  Future<ConsumerOrder> updateOrderStatus(
      String orderId, OrderStatus status) async {
    final index = _store.indexWhere((o) => o.id == orderId);
    if (index < 0) throw Exception('Order not found: $orderId');

    final updated = ConsumerOrder(
      id: _store[index].id,
      restaurantId: _store[index].restaurantId,
      restaurantName: _store[index].restaurantName,
      restaurantImageUrl: _store[index].restaurantImageUrl,
      items: _store[index].items,
      status: status,
      subtotal: _store[index].subtotal,
      deliveryFee: _store[index].deliveryFee,
      serviceFee: _store[index].serviceFee,
      discount: _store[index].discount,
      total: _store[index].total,
      deliveryAddress: _store[index].deliveryAddress,
      deliveryInstructions: _store[index].deliveryInstructions,
      placedAt: _store[index].placedAt,
      estimatedDelivery: _store[index].estimatedDelivery,
      driverName: status == OrderStatus.pickedUp
          ? 'Kwame Mensah'
          : _store[index].driverName,
      driverPhone: status == OrderStatus.pickedUp
          ? '+233 20 123 4567'
          : _store[index].driverPhone,
      paymentMethod: _store[index].paymentMethod,
    );

    _store[index] = updated;
    return updated;
  }
}

// ─── Seed data ─────────────────────────────────────────────────────────────

final _seedOrders = [
  ConsumerOrder(
    id: 'ORD-001',
    restaurantId: 'r2',
    restaurantName: 'Papaye Fast Food',
    restaurantImageUrl:
        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=600',
    items: const [
      OrderItem(
          menuItemId: 'r2_m1',
          name: 'Jollof Rice + Chicken',
          quantity: 2,
          unitPrice: 55),
      OrderItem(
          menuItemId: 'r2_m6',
          name: 'Malta Guinness',
          quantity: 2,
          unitPrice: 10),
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
      OrderItem(
          menuItemId: 'r1_m3',
          name: 'Bucket for 4',
          quantity: 1,
          unitPrice: 195),
    ],
    status: OrderStatus.delivered,
    subtotal: 195,
    deliveryFee: 8,
    serviceFee: 9.75,
    discount: 39,
    total: 173.75,
    deliveryAddress: '12 Osu Badu St, Accra',
    placedAt: DateTime.now().subtract(const Duration(days: 2)),
    paymentMethod: 'Card',
  ),
];
