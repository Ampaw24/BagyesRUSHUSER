import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/services/realtime_events.dart';
import 'package:bagyesrushappusernew/core/services/realtime_service.dart';

/// Serves canned JSON per `METHOD path`, so the real repository parsing and
/// view-model merging run against realistic payloads. [statusCodes] overrides
/// the 200 a registered route answers with.
class StubAdapter implements HttpClientAdapter {
  final Map<String, Object> routes = {};
  final Map<String, int> statusCodes = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.path}';
    final body = routes[key];
    return ResponseBody.fromString(
      body == null ? '{"message":"not found"}' : jsonEncode(body),
      body == null ? 404 : statusCodes[key] ?? 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeRealtime extends Fake implements RealtimeService {
  @override
  Stream<OrderStatusEvent> get orderStatusEvents => const Stream.empty();

  @override
  Stream<RiderLocationEvent> get riderLocationEvents => const Stream.empty();
}

Map<String, dynamic> fullOrder({
  String status = 'pending',
  String paymentStatus = 'pending',
}) => {
  'id': 1,
  'status': status,
  'vendor': {'id': 7, 'name': 'Auntie Muni', 'logo_url': ''},
  'items': [
    {'id': 1, 'name': 'Jollof', 'quantity': 2, 'unit_price': 25.0},
  ],
  'totals': {
    'subtotal': 50.0,
    'delivery_fee': 10.0,
    'service_fee': 0.0,
    'discount': 0.0,
    'total': 60.0,
  },
  'delivery': {'address': 'East Legon'},
  'payment': {'method': 'mobile_money', 'status': paymentStatus},
  'created_at': '2026-09-29T10:00:00Z',
};
