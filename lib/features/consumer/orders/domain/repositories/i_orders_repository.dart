import 'package:bagyesrushappusernew/features/consumer/cart/presentation/states/cart_state.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/entities/consumer_order.dart';

abstract interface class IOrdersRepository {
  Future<List<ConsumerOrder>> getOrders();
  Future<ConsumerOrder> getOrderById(String orderId);
  Future<ConsumerOrder> placeOrder({
    required CartState cart,
    required String deliveryAddress,
    String? deliveryInstructions,
    required String paymentMethod,
  });
  Future<ConsumerOrder> cancelOrder(String orderId);
  Future<ConsumerOrder> reorder(String orderId);
  Future<ConsumerOrder> trackOrder(String orderId);
  Future<Map<String, dynamic>> payOrder(String orderId, {required String paymentMethod});
  Future<ConsumerOrder> verifyPayment(String orderId, {required String reference});
}
