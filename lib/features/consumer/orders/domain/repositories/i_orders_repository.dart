import 'package:bagyesrushappusernew/features/consumer/orders/domain/entities/consumer_order.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/entities/delivery_quote.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_model.dart';

class OrdersPage {
  final List<ConsumerOrder> orders;
  final int page;
  final int totalPages;
  final int total;

  const OrdersPage({
    required this.orders,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  bool get hasMore => page < totalPages;
}

abstract interface class IOrdersRepository {
  /// Paginated order history (chronological — not filtered by active/past).
  Future<OrdersPage> getOrdersPaged({int page = 1, int limit = 20});
  Future<ConsumerOrder> getOrderById(String orderId);
  Future<ConsumerOrder> placeOrder({
    required CartModel cart,
    required String deliveryAddress,
    String? deliveryInstructions,
    required String paymentMethod,
    double? deliveryLat,
    double? deliveryLng,
  });
  Future<ConsumerOrder> cancelOrder(String orderId);
  Future<ConsumerOrder> reorder(String orderId);
  Future<ConsumerOrder> trackOrder(String orderId);
  Future<Map<String, dynamic>> payOrder(String orderId, {required String paymentMethod});
  Future<ConsumerOrder> verifyPayment(String orderId, {required String reference});
  Future<DeliveryQuote> getDeliveryQuote({
    required String vendorId,
    String? addressId,
  });
}
