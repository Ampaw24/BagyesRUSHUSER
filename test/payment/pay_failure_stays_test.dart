import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/router/app_routes.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/repositories/consumer_orders_repository.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/views/order_payment_launcher.dart';

import '../consumer_orders/support/order_test_support.dart';
import '../core/support/auth_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OrdersViewModel orders;
  late ScriptedAdapter adapter;
  String? failure;
  var finished = false;

  /// The order's payment status as the server reports it, and the answer to
  /// `POST .../pay`.
  Future<void> open(
    WidgetTester tester, {
    required String paymentStatus,
    required bool stayOnFailure,
    (int, Object)? payAnswer,
  }) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);

    adapter = ScriptedAdapter((o) {
      return switch ('${o.method} ${o.path}') {
        'POST /customer/orders/1/pay' =>
          payAnswer ?? (422, {'message': 'This order has nothing to pay.'}),
        'GET /customer/orders' => (
            200,
            {
              'data': [fullOrder(paymentStatus: paymentStatus)],
              'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
            },
          ),
        'GET /customer/orders/1/track' => (
            200,
            {
              'data': {
                'status': 'accepted',
                'payment': {'status': paymentStatus},
              },
            },
          ),
        _ => (404, {'message': 'unexpected ${o.method} ${o.path}'}),
      };
    });
    orders = OrdersViewModel(
      ConsumerOrdersRepository(client: Dio()..httpClientAdapter = adapter),
      FakeRealtime(),
      CurrentUserProvider(),
    );
    await tester.runAsync(() => pumpEventQueue());
    addTearDown(() async {
      await pumpEventQueue();
      orders.dispose();
    });

    failure = null;
    finished = false;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  failure = await OrderPaymentLauncher.payThenTrack(
                    context,
                    orderId: '1',
                    requiresPayment: true,
                    settledMessage: 'Paid with your wallet.',
                    stayOnFailure: stayOnFailure,
                  );
                  finished = true;
                },
                child: const Text('pay'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.trackOrder,
          builder: (_, _) => const Scaffold(body: Text('TRACKING')),
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: orders,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('pay'));
    // Let the scripted requests (5 ms each) complete.
    for (var i = 0; i < 20 && !finished; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('a refused payment keeps the customer here with the server\'s reason',
      (tester) async {
    await open(tester, paymentStatus: 'pending', stayOnFailure: true);

    expect(failure, 'This order has nothing to pay.');
    expect(find.text('TRACKING'), findsNothing);
    expect(find.text('pay'), findsOneWidget);
  });

  testWidgets('a refusal on an already-paid order (wallet) still goes to tracking',
      (tester) async {
    await open(tester, paymentStatus: 'paid', stayOnFailure: true);

    expect(failure, isNull);
    expect(find.text('TRACKING'), findsOneWidget);
    expect(find.text('Paid with your wallet.'), findsOneWidget);
  });

  testWidgets('without stayOnFailure the old behaviour holds: tracking, with the reason',
      (tester) async {
    await open(tester, paymentStatus: 'pending', stayOnFailure: false);

    expect(failure, isNull);
    expect(find.text('TRACKING'), findsOneWidget);
    expect(
      find.textContaining('This order has nothing to pay. You can retry'),
      findsOneWidget,
    );
  });
}
