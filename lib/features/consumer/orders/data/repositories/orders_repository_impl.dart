import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/features/consumer/cart/presentation/states/cart_state.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/entities/consumer_order.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/repositories/i_orders_repository.dart';

class OrdersRepositoryImpl implements IOrdersRepository {
  OrdersRepositoryImpl({required Dio client}) : _client = client;

  final Dio _client;

  @override
  Future<List<ConsumerOrder>> getOrders() async {
    final response = await _client.get(ApiEndpoints.customerOrders);
    final list = _dataList(response);
    return list
        .map((e) => ConsumerOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ConsumerOrder> getOrderById(String orderId) async {
    final response = await _client.get(ApiEndpoints.customerOrderById(orderId));
    return ConsumerOrder.fromJson(_dataMap(response));
  }

  @override
  Future<ConsumerOrder> placeOrder({
    required CartState cart,
    required String deliveryAddress,
    String? deliveryInstructions,
    required String paymentMethod,
  }) async {
    final body = {
      'vendor_id': cart.restaurantId,
      'items': cart.items
          .map(
            (ci) => {
              'menu_item_id': ci.item.id,
              'quantity': ci.quantity,
              'addons': ci.selectedAddons.map((a) => a.toJson()).toList(),
              if (ci.specialInstructions != null &&
                  ci.specialInstructions!.isNotEmpty)
                'special_instructions': ci.specialInstructions,
            },
          )
          .toList(),
      'delivery_address': deliveryAddress,
      if (deliveryInstructions != null && deliveryInstructions.isNotEmpty)
        'delivery_instructions': deliveryInstructions,
      'payment_method': paymentMethod,
    };
    final response = await _client.post(
      ApiEndpoints.customerOrders,
      data: body,
    );
    return ConsumerOrder.fromJson(_dataMap(response));
  }

  @override
  Future<ConsumerOrder> cancelOrder(String orderId) async {
    final response = await _client.patch(
      ApiEndpoints.customerOrderCancel(orderId),
    );
    return ConsumerOrder.fromJson(_dataMap(response));
  }

  @override
  Future<ConsumerOrder> reorder(String orderId) async {
    final response = await _client.post(
      ApiEndpoints.customerOrderReorder(orderId),
    );
    return ConsumerOrder.fromJson(_dataMap(response));
  }

  @override
  Future<ConsumerOrder> trackOrder(String orderId) async {
    final response = await _client.get(
      ApiEndpoints.customerOrderTrack(orderId),
    );
    return ConsumerOrder.fromJson(_dataMap(response));
  }

  @override
  Future<Map<String, dynamic>> payOrder(
    String orderId, {
    required String paymentMethod,
  }) async {
    final response = await _client.post(
      ApiEndpoints.customerOrderPay(orderId),
      data: {'payment_method': paymentMethod},
    );
    return _dataMap(response);
  }

  @override
  Future<ConsumerOrder> verifyPayment(
    String orderId, {
    required String reference,
  }) async {
    final response = await _client.post(
      ApiEndpoints.customerOrderVerifyPayment(orderId),
      data: {'reference': reference},
    );
    return ConsumerOrder.fromJson(_dataMap(response));
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  Map<String, dynamic> _dataMap(Response response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final d = body['data'];
      if (d is Map<String, dynamic>) {
        final inner = d['data'];
        if (inner is Map<String, dynamic>) return inner;
        return d;
      }
    }
    return const {};
  }

  List<dynamic> _dataList(Response response) {
    final body = response.data;
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final d = body['data'];
      if (d is List) return d;
      if (d is Map<String, dynamic>) {
        final items = d['items'];
        if (items is List) return items;
        final inner = d['data'];
        if (inner is List) return inner;
        final orders = d['orders'];
        if (orders is List) return orders;
      }
    }
    return const [];
  }
}
