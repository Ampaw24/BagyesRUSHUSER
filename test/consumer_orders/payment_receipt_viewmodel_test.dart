import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_verification.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/payment_receipt.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/repositories/consumer_orders_repository.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/orders_viewmodel.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/viewmodels/payment_receipt_viewmodel.dart';
import 'package:bagyesrushappusernew/src/transaction/repositories/transaction_repository.dart';

import 'support/order_test_support.dart';

Map<String, dynamic> _transaction({String reference = 'ref_tx'}) => {
  'id': 5,
  'reference': reference,
  'provider': 'paystack',
  'method': 'mobile_money',
  'method_label': 'MTN Mobile Money',
  'status': 'success',
  'status_label': 'Successful',
  'amount': 60,
  'currency': 'GHS',
  'paid_at': '2026-10-01T12:30:00Z',
  'created_at': '2026-10-01T12:29:00Z',
  'order': {'id': 1, 'order_number': 'BR-1', 'type': 'food'},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StubAdapter adapter;
  late OrdersViewModel orders;
  PaymentReceiptViewModel? vm;

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
    orders = OrdersViewModel(
      ConsumerOrdersRepository(client: dio),
      FakeRealtime(),
      CurrentUserProvider(),
    );
    await pumpEventQueue();
    vm = null;
    addTearDown(() async {
      await pumpEventQueue();
      vm?.dispose();
      orders.dispose();
    });
  });

  PaymentReceiptViewModel build(PaymentReceiptArgs args) {
    final dio = Dio()..httpClientAdapter = adapter;
    return vm = PaymentReceiptViewModel(
      args,
      orders,
      TransactionRepository(client: dio),
      pollInterval: const Duration(milliseconds: 20),
    );
  }

  Future<void> until(bool Function() condition) async {
    for (var i = 0; i < 100 && !condition(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(condition(), isTrue, reason: 'condition never became true');
  }

  PaymentReceipt receiptOf(PaymentReceiptViewModel vm) =>
      (vm.state as ReceiptReady).receipt;

  test('starts out verifying', () {
    final vm = build(const PaymentReceiptArgs(orderId: '1'));
    expect(vm.state, isA<ReceiptVerifying>());
    expect(vm.status, isNull);
  });

  test('a verified payment becomes a paid receipt from the order', () async {
    adapter.routes['POST /customer/orders/1/verify-payment'] = {
      'data': {
        'status': 'success',
        'reference': 'ref_1',
        'paid_at': '2026-10-01T12:30:00Z',
      },
    };
    final vm = build(const PaymentReceiptArgs(orderId: '1', reference: 'ref_1'));
    await vm.start();

    final receipt = receiptOf(vm);
    expect(receipt.status, ReceiptStatus.paid);
    expect(receipt.title, 'Auntie Muni');
    expect(receipt.total, 60);
    expect(receipt.items.single.name, 'Jollof');
    expect(receipt.reference, 'ref_1');
    expect(receipt.paidAt, DateTime.utc(2026, 10, 1, 12, 30));
    expect(receipt.dateLabel, 'Paid on');
    // Nothing from the transaction record: it isn't invented.
    expect(receipt.amountPaid, isNull);
  });

  test('missing payment details are filled in from the transaction', () async {
    adapter.routes['GET /customer/transactions'] = {
      'data': [_transaction()],
    };
    final vm = build(const PaymentReceiptArgs(orderId: '1', knownPaid: true));
    await vm.start();

    final receipt = receiptOf(vm);
    expect(receipt.status, ReceiptStatus.paid);
    expect(receipt.reference, 'ref_tx');
    expect(receipt.channelLabel, 'MTN Mobile Money');
    expect(receipt.amountPaid, 60);
    expect(receipt.paidAt, DateTime.utc(2026, 10, 1, 12, 30));
  });

  test('an unrelated transaction is never used', () async {
    adapter.routes['GET /customer/transactions'] = {
      'data': [
        {
          ..._transaction(reference: 'someone_else'),
          'order': {'id': 99},
        },
      ],
    };
    final vm = build(const PaymentReceiptArgs(orderId: '1', knownPaid: true));
    await vm.start();

    final receipt = receiptOf(vm);
    expect(receipt.reference, isNull);
    expect(receipt.amountPaid, isNull);
    expect(receipt.dateLabel, 'Ordered on');
    // The order's own method is the honest fallback.
    expect(receipt.channelLabel, 'mobile_money');
  });

  test('a failed transaction lookup leaves the receipt as it is', () async {
    final vm = build(const PaymentReceiptArgs(orderId: '1', knownPaid: true));
    await vm.start(); // no transactions route → 404

    expect(receiptOf(vm).status, ReceiptStatus.paid);
  });

  test('a pending payment is processing, then flips to paid by polling',
      () async {
    adapter.routes['POST /customer/orders/1/verify-payment'] = {
      'data': {'status': 'pending'},
    };
    final vm = build(const PaymentReceiptArgs(orderId: '1', reference: 'ref_1'));
    await vm.start();
    expect(vm.status, ReceiptStatus.processing);

    adapter.routes['POST /customer/orders/1/verify-payment'] = {
      'data': {'status': 'success'},
    };
    await until(() => vm.status == ReceiptStatus.paid);
    expect(receiptOf(vm).reference, 'ref_1');
  });

  test('a definitive rejection is a failed receipt with the server message',
      () async {
    adapter
      ..routes['POST /customer/orders/1/verify-payment'] = {
        'message': 'Payment was declined',
      }
      ..statusCodes['POST /customer/orders/1/verify-payment'] = 422;
    final vm = build(const PaymentReceiptArgs(orderId: '1', reference: 'ref_1'));
    await vm.start();

    final receipt = receiptOf(vm);
    expect(receipt.status, ReceiptStatus.failed);
    expect(receipt.failureMessage, isNotEmpty);
    expect(receipt.paidAt, isNull);
    expect(receipt.amountPaid, isNull);
  });

  test('an unreachable server leaves the payment processing, not failed',
      () async {
    // No verify route → 404, i.e. nothing conclusive.
    final vm = build(const PaymentReceiptArgs(orderId: '1', reference: 'ref_1'));
    await vm.start();

    expect(vm.status, ReceiptStatus.processing);
  });

  test('a check the caller already ran is not repeated', () async {
    final vm = build(
      const PaymentReceiptArgs(
        orderId: '1',
        reference: 'ref_1',
        initialCheck: OrderPaymentVerification(isFailed: true),
      ),
    );
    await vm.start(); // no verify route registered: a repeat would be pending

    expect(vm.status, ReceiptStatus.failed);
  });

  test('an order that cannot be loaded still reports the payment status',
      () async {
    adapter.routes
      ..['GET /customer/orders'] = {'data': []}
      ..remove('GET /customer/orders/1/track');
    await orders.refresh();
    final vm = build(const PaymentReceiptArgs(orderId: '1', knownPaid: true));
    await vm.start();

    expect(vm.state, isA<ReceiptUnavailable>());
    expect(vm.status, ReceiptStatus.paid);
  });
}
