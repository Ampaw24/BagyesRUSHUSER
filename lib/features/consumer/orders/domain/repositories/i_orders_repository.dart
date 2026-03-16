import 'package:bagyesrushappusernew/features/consumer/cart/presentation/states/cart_state.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/entities/consumer_order.dart';

abstract interface class IOrdersRepository {
  Future<List<ConsumerOrder>> getOrders();
  Future<ConsumerOrder> placeOrder({
    required CartState cart,
    required String deliveryAddress,
    String? deliveryInstructions,
    required String paymentMethod,
  });
  Future<ConsumerOrder> updateOrderStatus(String orderId, OrderStatus status);
}
