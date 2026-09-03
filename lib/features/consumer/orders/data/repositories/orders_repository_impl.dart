import 'package:dio/dio.dart';

import 'package:bagyesrushappusernew/core/network/api_endpoints.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/entities/consumer_order.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/entities/delivery_quote.dart';
import 'package:bagyesrushappusernew/features/consumer/orders/domain/repositories/i_orders_repository.dart';
import 'package:bagyesrushappusernew/src/cart/models/cart_model.dart';

class OrdersRepositoryImpl implements IOrdersRepository {
  OrdersRepositoryImpl({required Dio client}) : _client = client;

  final Dio _client;

  @override
  Future<OrdersPage> getOrdersPaged({int page = 1, int limit = 20}) async {
    final response = await _client.get(
      ApiEndpoints.customerOrders,
      queryParameters: {'page': page, 'limit': limit},
    );
    final (list, meta) = _extractPagedList(response);
    final orders = list
        .map((e) => ConsumerOrder.fromJson(e as Map<String, dynamic>))
        .toList();

    final currentPage = (meta['current_page'] ?? meta['page']) as num? ?? page;
    final lastPage = (meta['last_page'] ?? meta['totalPages']) as num? ?? 1;
    final total = meta['total'] as num? ?? orders.length;

    return OrdersPage(
      orders: orders,
      page: currentPage.toInt(),
      totalPages: lastPage.toInt(),
      total: total.toInt(),
    );
  }

  @override
  Future<ConsumerOrder> getOrderById(String orderId) async {
    final response = await _client.get(ApiEndpoints.customerOrderById(orderId));
    return ConsumerOrder.fromJson(_dataMap(response));
  }

  @override
  Future<ConsumerOrder> placeOrder({
    required CartModel cart,
    required String deliveryAddress,
    String? deliveryInstructions,
    required String paymentMethod,
    double? deliveryLat,
    double? deliveryLng,
  }) async {
    final body = {
      'vendor_id': int.tryParse(cart.vendorId) ?? cart.vendorId,
      'items': cart.items
          .map(
            (ci) => {
              'menu_item_id': ci.menuItemId,
              'quantity': ci.quantity,
              'addons': ci.addonOptions.map((a) => a.toJson()).toList(),
              if (ci.notes != null && ci.notes!.isNotEmpty)
                'special_instructions': ci.notes,
            },
          )
          .toList(),
      'delivery_address': deliveryAddress,
      if (deliveryInstructions != null && deliveryInstructions.isNotEmpty)
        'delivery_instructions': deliveryInstructions,
      'payment_method': paymentMethod,
      // Best-effort: only sent when resolved via GPS/map-pick. Omitted
      // entirely (not sent as null) when the user hand-typed the address.
      if (deliveryLat != null && deliveryLng != null) ...{
        'latitude': deliveryLat,
        'longitude': deliveryLng,
      },
    };
    final response = await _client.post(
      ApiEndpoints.customerOrders,
      data: body,
    );
    return ConsumerOrder.fromJson(_dataMap(response));
  }

  @override
  Future<ConsumerOrder> cancelOrder(String orderId, {required String reason}) async {
    final response = await _client.patch(
      ApiEndpoints.customerOrderCancel(orderId),
      data: {'reason': reason},
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
  Future<ConsumerOrder> trackOrder(String orderId, {ConsumerOrder? previous}) async {
    final response = await _client.get(
      ApiEndpoints.customerOrderTrack(orderId),
    );
    final data = _dataMap(response);
    // The track payload carries no `id`/items/totals/address, only the
    // live status fields — parsing it straight into ConsumerOrder.fromJson
    // would blank those out, so merge onto the last known full order.
    final tracked = ConsumerOrder.fromJson(data);
    if (previous == null) return tracked;
    return previous.copyWith(
      status: tracked.status,
      paymentStatus: tracked.paymentStatus,
      estimatedPrepMinutes: tracked.estimatedPrepMinutes,
      estimatedDelivery: tracked.estimatedDelivery,
      driverName: tracked.driverName,
      driverPhone: tracked.driverPhone,
    );
  }

  /// Retries only on connection-level failures — the request never left the
  /// device, so re-sending can't double-charge. A timeout/5xx *after* the
  /// request reached the server is ambiguous (the charge may have already
  /// been initiated), so those are surfaced to the caller instead of being
  /// silently retried; the UI offers a manual retry for that case.
  static const _payOrderMaxAttempts = 3;
  static const _payOrderRetryDelay = Duration(milliseconds: 500);

  @override
  Future<Map<String, dynamic>> payOrder(
    String orderId, {
    required String paymentMethod,
    String? phone,
    String? mobileMoneyProvider,
  }) async {
    for (var attempt = 1; attempt <= _payOrderMaxAttempts; attempt++) {
      try {
        final response = await _client.post(
          ApiEndpoints.customerOrderPay(orderId),
          data: {
            'payment_method': paymentMethod,
            if (phone != null) 'phone': phone,
            if (mobileMoneyProvider != null) 'mobile_money_provider': mobileMoneyProvider,
          },
        );
        return _dataMap(response);
      } on DioException catch (e) {
        final retryable = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout;
        if (!retryable || attempt == _payOrderMaxAttempts) rethrow;
        await Future.delayed(_payOrderRetryDelay * attempt);
      }
    }
    // Unreachable: the loop above always returns or rethrows.
    throw StateError('payOrder: exhausted retries without a result');
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

  @override
  Future<DeliveryQuote> getDeliveryQuote({
    required String vendorId,
    String? addressId,
  }) async {
    final response = await _client.get(
      ApiEndpoints.customerDeliveryQuote,
      queryParameters: {
        'vendor_id': vendorId,
        if (addressId != null) 'address_id': addressId,
      },
    );
    return DeliveryQuote.fromJson(_dataMap(response));
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

  /// Handles the response shapes seen across this backend's paginated
  /// endpoints (mirrors `RestaurantRepositoryImpl._extractPagedList`):
  ///   Shape A (flat):        { "data": [...], "meta": {...} }
  ///   Shape B (nested):      { "data": { "data": [...], "meta": {...} } }
  ///   Shape C (bare list):   [...]
  ///   Shape D (items/page):  { "data": { "items": [...], "pagination": {...} } }
  (List<dynamic>, Map<String, dynamic>) _extractPagedList(Response response) {
    final body = response.data;

    if (body is List) return (body, {});

    if (body is Map<String, dynamic>) {
      final outer = body['data'];

      if (outer is Map<String, dynamic>) {
        final items = outer['items'];
        if (items is List) {
          final pagination = outer['pagination'] as Map<String, dynamic>? ?? {};
          return (items, pagination);
        }

        final inner = outer['data'];
        final meta = outer['meta'] as Map<String, dynamic>? ?? {};
        if (inner is List) return (inner, meta);

        final orders = outer['orders'];
        if (orders is List) return (orders, meta);
      }

      if (outer is List) {
        final meta = body['meta'] as Map<String, dynamic>? ?? {};
        return (outer, meta);
      }
    }

    return (const [], {});
  }
}
