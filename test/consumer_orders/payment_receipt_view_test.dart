import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_outcome.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/payment_receipt.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/repositories/consumer_orders_repository.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/payment_receipt_viewmodel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/views/payment_receipt_view.dart';
import 'package:bagyesrushappusernew/src/transaction/repositories/transaction_repository.dart';

import 'support/order_test_support.dart';

/// Logical screen sizes the receipt must fit without overflowing.
const _screens = {
  'portrait phone': Size(360, 640),
  'small phone': Size(320, 568),
  'landscape phone': Size(640, 360),
  'tablet': Size(800, 1280),
};

/// Lets the test run the (real-async) verification up front, so the widget
/// under test only ever renders settled state — Dio calls never advance
/// inside a widget test's fake-async zone.
class _TestViewModel extends PaymentReceiptViewModel {
  _TestViewModel(super.args, super.orders, super.transactions)
    : super(pollInterval: const Duration(hours: 1));

  Future<void> runStart() => super.start();

  @override
  Future<void> start() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StubAdapter adapter;
  PaymentReceiptViewModel? vm;
  OrderPaymentResult? popped;

  setUp(() {
    popped = null;
    vm = null;
    adapter = StubAdapter()
      ..routes['GET /customer/orders'] = {
        'data': [fullOrder()],
      }
      ..routes['GET /customer/orders/1/track'] = {
        'data': {'status': 'accepted'},
      };
  });

  // `orders` is deliberately not disposed: ViewModel.emit defers its notify
  // to a post-frame callback, which can land after a test that ends without a
  // further pump.
  tearDown(() => vm?.dispose());

  /// [settled] false leaves the receipt on its initial checking state.
  Future<void> openReceipt(
    WidgetTester tester,
    PaymentReceiptArgs args, {
    Size screen = const Size(360, 640),
    bool settled = true,
  }) async {
    tester.view
      ..physicalSize = screen * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final testVm = await tester.runAsync(() async {
      final dio = Dio()..httpClientAdapter = adapter;
      final ordersVm = OrdersViewModel(
        ConsumerOrdersRepository(client: dio),
        FakeRealtime(),
        CurrentUserProvider(),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final created = _TestViewModel(
        args,
        ordersVm,
        TransactionRepository(client: dio),
      );
      if (settled) await created.runStart();
      return created;
    });
    vm = testVm;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                popped = await Navigator.of(context).push(
                  MaterialPageRoute<OrderPaymentResult>(
                    builder: (_) =>
                        PaymentReceiptView(args: args, viewModel: testVm),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('shows a checking state first, and back is blocked meanwhile',
      (tester) async {
    await openReceipt(
      tester,
      const PaymentReceiptArgs(orderId: '1', knownPaid: true),
      settled: false,
    );

    expect(find.text('Confirming your payment…'), findsOneWidget);
    expect(find.text('Track order'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Confirming your payment…'), findsOneWidget);
    expect(popped, isNull);
    await settle(tester);
  });

  for (final entry in _screens.entries) {
    testWidgets('a paid receipt fits on a ${entry.key}', (tester) async {
      await openReceipt(
        tester,
        const PaymentReceiptArgs(orderId: '1', knownPaid: true),
        screen: entry.value,
      );
      await settle(tester);

      expect(find.text('Payment successful'), findsOneWidget);
      expect(find.text('GHS 60.00'), findsWidgets);
      expect(find.text('Paid to Auntie Muni'), findsOneWidget);
      expect(find.text('1 × Jollof'), findsNothing); // qty is 2
      expect(find.text('2 × Jollof'), findsOneWidget);
      expect(find.text('Track order'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a processing receipt explains and offers no share',
      (tester) async {
    adapter.routes['POST /customer/orders/1/verify-payment'] = {
      'data': {'status': 'pending'},
    };
    await openReceipt(
      tester,
      const PaymentReceiptArgs(orderId: '1', reference: 'ref_1'),
    );
    await settle(tester);

    expect(find.text('Payment processing'), findsOneWidget);
    expect(find.textContaining('no need to pay again'), findsOneWidget);
    final share = tester.widget<OutlinedButton>(
      find.ancestor(of: find.text('Share'), matching: find.byType(OutlinedButton)),
    );
    expect(share.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failed receipt leads with "Try again"', (tester) async {
    adapter
      ..routes['POST /customer/orders/1/verify-payment'] = {
        'message': 'Payment was declined',
      }
      ..statusCodes['POST /customer/orders/1/verify-payment'] = 422;
    await openReceipt(
      tester,
      const PaymentReceiptArgs(orderId: '1', reference: 'ref_1'),
    );
    await settle(tester);

    expect(find.text('Payment not completed'), findsOneWidget);
    expect(find.text('Payment was declined'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await settle(tester);
    expect(popped?.exit, PaymentExit.retry);
    expect(popped?.outcome, OrderPaymentOutcome.failed);
  });

  testWidgets('"Track order" and "Home" report where to go', (tester) async {
    await openReceipt(tester, const PaymentReceiptArgs(orderId: '1', knownPaid: true));
    await settle(tester);
    await tester.tap(find.text('Track order'));
    await settle(tester);
    expect(popped?.exit, PaymentExit.track);
    expect(popped?.outcome, OrderPaymentOutcome.paid);
  });

  testWidgets('"Home" reports home', (tester) async {
    await openReceipt(tester, const PaymentReceiptArgs(orderId: '1', knownPaid: true));
    await settle(tester);
    await tester.tap(find.text('Home'));
    await settle(tester);
    expect(popped?.exit, PaymentExit.home);
  });

  testWidgets('system back means "track"', (tester) async {
    await openReceipt(tester, const PaymentReceiptArgs(orderId: '1', knownPaid: true));
    await settle(tester);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(popped?.exit, PaymentExit.track);
  });

  testWidgets('a receipt without loadable order details still exits cleanly',
      (tester) async {
    adapter.routes['GET /customer/orders'] = {'data': []};
    adapter.routes.remove('GET /customer/orders/1/track');
    await openReceipt(tester, const PaymentReceiptArgs(orderId: '1', knownPaid: true));
    await settle(tester);

    expect(find.text('Payment successful'), findsOneWidget);
    expect(find.textContaining('find your order in tracking'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
