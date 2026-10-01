
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_outcome.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_verification.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/repositories/consumer_orders_repository.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';

import 'support/order_test_support.dart';

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
      final result = OrderPaymentVerification.fromPayload(fullOrder());
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
    expect(OrderPaymentOutcome.failed.followUpMessage, isNotNull);
  });

  group('OrderPaymentVerification receipt details', () {
    test('reads reference, paid time and channel from the top level', () {
      final result = OrderPaymentVerification.fromPayload({
        'status': 'success',
        'reference': 'ref_1',
        'paid_at': '2026-10-01T12:30:00Z',
        'channel': 'mobile_money',
      });
      expect(result.reference, 'ref_1');
      expect(result.paidAt, DateTime.utc(2026, 10, 1, 12, 30));
      expect(result.channelLabel, 'mobile_money');
    });

    test('finds them inside a nested payment / transaction block', () {
      final result = OrderPaymentVerification.fromPayload({
        'payment': {
          'status': 'paid',
          'reference': 'ref_2',
          'method_label': 'MTN Mobile Money',
        },
        'transaction': {'paid_at': '2026-10-01T12:30:00Z'},
      });
      expect(result.isPaid, isTrue);
      expect(result.reference, 'ref_2');
      expect(result.channelLabel, 'MTN Mobile Money');
      expect(result.paidAt, isNotNull);
    });

    test('anything the backend omits stays null', () {
      final result = OrderPaymentVerification.fromPayload({'status': 'success'});
      expect(result.reference, isNull);
      expect(result.paidAt, isNull);
      expect(result.channelLabel, isNull);
      expect(result.walletApplied, isNull);
    });
  });

  group('OrdersViewModel payment state', () {
    late StubAdapter adapter;
    late OrdersViewModel vm;

    setUp(() async {
      adapter = StubAdapter()
        ..routes['GET /customer/orders'] = {
          'data': [fullOrder()],
          'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
        }
        ..routes['GET /customer/orders/1/track'] = {
          'data': {'status': 'accepted'},
        };
      final dio = Dio()..httpClientAdapter = adapter;
      vm = OrdersViewModel(
        ConsumerOrdersRepository(client: dio),
        FakeRealtime(),
        CurrentUserProvider(),
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
        'data': [fullOrder(status: 'accepted')],
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
          'data': [fullOrder(paymentStatus: 'paid')],
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
