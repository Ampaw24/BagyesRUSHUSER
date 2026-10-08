import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/repositories/consumer_orders_repository.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';

import '../core/support/auth_test_support.dart';
import 'support/order_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsumerOrder.canCancel', () {
    ConsumerOrder order(String status, {bool? canCancel}) =>
        ConsumerOrder.fromJson({
          ...fullOrder(status: status),
          'can_cancel': ?canCancel,
        });

    test('an open order follows the backend flag', () {
      expect(order('pending', canCancel: true).canCancel, isTrue);
      expect(order('pending', canCancel: false).canCancel, isFalse);
    });

    test('a cancelled or declined order is never cancellable, even if the flag is stale',
        () {
      for (final status in ['cancelled', 'rejected']) {
        expect(order(status, canCancel: true).canCancel, isFalse, reason: status);
      }
    });
  });

  group('OrdersViewModel.cancelOrder', () {
    late ScriptedAdapter adapter;
    late OrdersViewModel orders;

    Future<void> setUpOrders({
      bool parcel = false,
      bool trackFails = false,
      bool cancelRefused = false,
    }) async {
      final parcelFields = parcel
          ? {'order_type': 'parcel', 'direction': 'send'}
          : <String, dynamic>{};
      adapter = ScriptedAdapter((o) {
        return switch ('${o.method} ${o.path}') {
          'GET /customer/orders' => (
              200,
              {
                'data': [
                  {...fullOrder(), ...parcelFields, 'can_cancel': true},
                ],
                'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
              },
            ),
          // The server accepts the cancel but its payload still says open.
          'PATCH /customer/orders/1/cancel' => cancelRefused
              ? (422, {'message': 'Too late.'})
              : (
                  200,
                  {
                    'data': {...fullOrder(), 'can_cancel': true},
                  },
                ),
          'PATCH /customer/parcels/1/cancel' => (200, {'data': {}}),
          'GET /customer/orders/1/track' => trackFails
              ? (500, {'message': 'boom'})
              : (200, {'data': {'status': 'pending', 'can_cancel': true}}),
          _ => (404, {'message': 'unexpected ${o.method} ${o.path}'}),
        };
      });
      orders = OrdersViewModel(
        ConsumerOrdersRepository(client: Dio()..httpClientAdapter = adapter),
        FakeRealtime(),
        CurrentUserProvider(),
      );
      // The scripted server answers after a short real delay.
      await Future<void>.delayed(const Duration(milliseconds: 60));
      addTearDown(() async {
        await pumpEventQueue();
        orders.dispose();
      });
      expect(orders.orderById('1')!.canCancel, isTrue);
    }

    test('after a successful cancel the button is gone, even if the server '
        'payload still says can_cancel', () async {
      await setUpOrders();

      await orders.cancelOrder('1', reason: 'Changed my mind');

      expect(orders.orderById('1')!.canCancel, isFalse);
    });

    test('a parcel cancel hides it too, and a failed re-read is not an error',
        () async {
      await setUpOrders(parcel: true, trackFails: true);
      expect(orders.orderById('1')!.isParcel, isTrue);

      await orders.cancelOrder('1', reason: 'Changed my mind');

      expect(orders.orderById('1')!.canCancel, isFalse);
    });

    test('a rejected cancel keeps the button', () async {
      await setUpOrders(cancelRefused: true);

      await expectLater(
        orders.cancelOrder('1', reason: 'x'),
        throwsA(isA<DioException>()),
      );

      expect(orders.orderById('1')!.canCancel, isTrue);
    });
  });
}
