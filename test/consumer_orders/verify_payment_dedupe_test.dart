import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/repositories/consumer_orders_repository.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';

import '../core/support/auth_test_support.dart';
import 'support/order_test_support.dart';

const _verifyPath = 'POST /customer/orders/1/verify-payment';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScriptedAdapter adapter;
  late OrdersViewModel orders;

  setUp(() async {
    adapter = ScriptedAdapter((options) {
      return switch ('${options.method} ${options.path}') {
        _verifyPath => (200, {'data': {'status': 'pending'}}),
        'GET /customer/orders' => (
            200,
            {
              'data': [fullOrder()],
              'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
            },
          ),
        _ => (200, {'data': {'status': 'accepted'}}),
      };
    });
    orders = OrdersViewModel(
      ConsumerOrdersRepository(client: Dio()..httpClientAdapter = adapter),
      FakeRealtime(),
      CurrentUserProvider(),
    );
    await pumpEventQueue();
    addTearDown(() async {
      await pumpEventQueue();
      orders.dispose();
    });
  });

  int verifyCalls() => adapter.calls.where((c) => c == _verifyPath).length;

  test('overlapping checks for one reference share a single request',
      () async {
    final results = await Future.wait([
      orders.verifyPayment('1', reference: 'ref_1'),
      orders.verifyPayment('1', reference: 'ref_1'),
      orders.checkPayment('1', reference: 'ref_1'),
    ]);

    expect(verifyCalls(), 1);
    expect(results.every((r) => r.isPending), isTrue);
  });

  test('a later check, once the first finished, asks the server again',
      () async {
    await orders.verifyPayment('1', reference: 'ref_1');
    await orders.verifyPayment('1', reference: 'ref_1');

    expect(verifyCalls(), 2);
  });

  test('different references are never merged', () async {
    await Future.wait([
      orders.verifyPayment('1', reference: 'ref_1'),
      orders.verifyPayment('1', reference: 'ref_2'),
    ]);

    expect(verifyCalls(), 2);
  });
}
