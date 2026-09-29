import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/services/realtime_events.dart';
import 'package:bagyesrushappusernew/core/services/realtime_service.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_outcome.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_verification.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/repositories/consumer_orders_repository.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';

/// Serves canned JSON per `METHOD path`, so the real repository parsing and
/// view-model merging run against realistic payloads.
class _StubAdapter implements HttpClientAdapter {
  final Map<String, Object> routes = {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.path}';
    final body = routes[key];
    if (body == null) {
      return ResponseBody.fromString(
        '{"message":"not found"}',
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FakeRealtime extends Fake implements RealtimeService {
  @override
  Stream<OrderStatusEvent> get orderStatusEvents => const Stream.empty();

  @override
  Stream<RiderLocationEvent> get riderLocationEvents => const Stream.empty();
}

Map<String, dynamic> _fullOrder({
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OrderPaymentVerification.fromPayload', () {
    test('an empty or unrecognised body is still pending, never paid', () {
      expect(OrderPaymentVerification.fromPayload({}).isPending, isTrue);
      expect(
        OrderPaymentVerification.fromPayload({'message': 'ok'}).isPaid,
        isFalse,
      );
    });

    test('reads a settled status wherever the backend puts it', () {
      for (final payload in <Map<String, dynamic>>[
        {'status': 'success'},
        {'status': 'SUCCESS'},
        {'payment_status': 'paid'},
        {
          'payment': {'status': 'successful'},
        },
        {
          'order': {
            'payment': {'status': 'paid'},
          },
        },
        {'paid': true},
      ]) {
        expect(
          OrderPaymentVerification.fromPayload(payload).isPaid,
          isTrue,
          reason: '$payload',
        );
      }
    });

    test('an order payload with a pending payment is not paid', () {
      final result = OrderPaymentVerification.fromPayload(_fullOrder());
      expect(result.isPaid, isFalse);
      expect(result.isFailed, isFalse);
    });

    test('recognises an explicit failure', () {
      expect(
        OrderPaymentVerification.fromPayload({'status': 'failed'}).isFailed,
        isTrue,
      );
      expect(
        OrderPaymentVerification.fromPayload({
          'payment': {'status': 'abandoned'},
        }).isFailed,
        isTrue,
      );
    });
  });

  group('payment status merging', () {
    test('a missing status keeps the current one', () {
      expect(paymentStatusFromJson({'status': 'accepted'}), isNull);
      expect(mergePaymentStatus(PaymentStatus.paid, null), PaymentStatus.paid);
    });

    test('a confirmed payment never regresses to pending', () {
      expect(
        mergePaymentStatus(PaymentStatus.paid, PaymentStatus.pending),
        PaymentStatus.paid,
      );
    });

    test('real transitions still apply', () {
      expect(
        mergePaymentStatus(PaymentStatus.pending, PaymentStatus.paid),
        PaymentStatus.paid,
      );
      expect(
        mergePaymentStatus(PaymentStatus.paid, PaymentStatus.failed),
        PaymentStatus.failed,
      );
    });
  });

  test('only non-paid outcomes carry a follow-up message', () {
    expect(OrderPaymentOutcome.paid.followUpMessage, isNull);
    expect(OrderPaymentOutcome.processing.followUpMessage, isNotNull);
    expect(OrderPaymentOutcome.dismissed.followUpMessage, isNotNull);
  });

  group('OrdersViewModel payment state', () {
    late _StubAdapter adapter;
    late OrdersViewModel vm;

    setUp(() async {
      adapter = _StubAdapter()
        ..routes['GET /customer/orders'] = {
          'data': [_fullOrder()],
          'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
        }
        ..routes['GET /customer/orders/1/track'] = {
          'data': {'status': 'accepted'},
        };
      final dio = Dio()..httpClientAdapter = adapter;
      vm = OrdersViewModel(
        ConsumerOrdersRepository(client: dio),
        _FakeRealtime(),
      );
      await pumpEventQueue();
      expect(vm.orderById('1')?.needsPayment, isTrue);
    });

    // Let verifyPayment's background re-sync finish before disposing.
    tearDown(() async {
      await pumpEventQueue();
      vm.dispose();
    });

    test('a verified payment hides "Pay Now" immediately', () async {
      adapter.routes['POST /customer/orders/1/verify-payment'] = {
        'data': {'status': 'success', 'reference': 'ref_1'},
      };

      final result = await vm.verifyPayment('1', reference: 'ref_1');
      expect(result.isPaid, isTrue);
      expect(vm.orderById('1')?.paymentStatus, PaymentStatus.paid);
      expect(vm.orderById('1')?.needsPayment, isFalse);
    });

    test('a lagging "pending" read cannot bring "Pay Now" back', () async {
      adapter.routes['POST /customer/orders/1/verify-payment'] = {
        'data': {'status': 'success'},
      };
      await vm.verifyPayment('1', reference: 'ref_1');

      // Both the track poll and the order list lag behind the verify call.
      adapter.routes['GET /customer/orders/1/track'] = {
        'data': {'status': 'accepted', 'payment_status': 'pending'},
      };
      adapter.routes['GET /customer/orders'] = {
        'data': [_fullOrder(status: 'accepted')],
      };
      await vm.trackOrder('1');
      await vm.refresh();

      expect(vm.orderById('1')?.status, OrderStatus.accepted);
      expect(vm.orderById('1')?.needsPayment, isFalse);
    });

    test(
      'a track payload without payment info keeps the known status',
      () async {
        adapter.routes['GET /customer/orders'] = {
          'data': [_fullOrder(paymentStatus: 'paid')],
        };
        await vm.refresh();
        expect(vm.orderById('1')?.paymentStatus, PaymentStatus.paid);

        await vm.trackOrder('1'); // track payload has no payment block
        expect(vm.orderById('1')?.paymentStatus, PaymentStatus.paid);
        expect(vm.orderById('1')?.items, isNotEmpty);
      },
    );

    test('an unconfirmed payment locks "Pay Now" until it settles', () async {
      adapter.routes['POST /customer/orders/1/verify-payment'] = {
        'data': {'status': 'pending'},
      };
      final result = await vm.verifyPayment('1', reference: 'ref_1');
      expect(result.isPending, isTrue);
      expect(vm.isAwaitingPaymentConfirmation('1'), isFalse);

      vm.markAwaitingPaymentConfirmation('1');
      expect(vm.isAwaitingPaymentConfirmation('1'), isTrue);

      adapter.routes['GET /customer/orders/1/track'] = {
        'data': {
          'status': 'accepted',
          'payment': {'status': 'paid'},
        },
      };
      await vm.trackOrder('1');
      expect(vm.isAwaitingPaymentConfirmation('1'), isFalse);
      expect(vm.orderById('1')?.needsPayment, isFalse);
    });

    test('a failed verification reports failure and clears the lock', () async {
      vm.markAwaitingPaymentConfirmation('1');
      adapter.routes['POST /customer/orders/1/verify-payment'] = {
        'data': {'status': 'failed'},
      };
      final result = await vm.verifyPayment('1', reference: 'ref_1');
      expect(result.isFailed, isTrue);
      expect(vm.isAwaitingPaymentConfirmation('1'), isFalse);
      expect(vm.orderById('1')?.needsPayment, isTrue);
    });
  });
}
