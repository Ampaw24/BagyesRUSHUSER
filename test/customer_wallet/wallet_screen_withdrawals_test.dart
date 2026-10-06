import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/singletons/cache.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/repositories/customer_wallet_repository.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/customer_wallet_viewmodel.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/viewmodels/customer_withdrawals_viewmodel.dart';
import 'package:bagyesrushappusernew/src/transaction/repositories/transaction_repository.dart';
import 'package:bagyesrushappusernew/src/transaction/viewmodels/transaction_viewmodel.dart';
import 'package:bagyesrushappusernew/src/transaction/views/transaction_view.dart';

import '../core/support/auth_test_support.dart';
import 'support/withdrawal_test_support.dart';

Map<String, dynamic> _walletJson({
  bool hasPayoutDetails = true,
  bool canWithdraw = true,
  double pending = 0,
}) => {
  'balance': 200,
  'currency': 'GHS',
  'withdrawable': 150,
  'spendable_only': 50,
  'lifetime_earned': 0,
  'lifetime_withdrawn': 0,
  'pending_earnings': 0,
  'pending_withdrawal': pending,
  'minimum_withdrawal': 5,
  'can_withdraw': canWithdraw,
  'has_payout_details': hasPayoutDetails,
  'withdrawals_enabled': true,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScriptedAdapter adapter;
  late List<Map<String, dynamic>> withdrawals;

  Future<void> openScreen(
    WidgetTester tester, {
    bool hasPayoutDetails = true,
    bool canWithdraw = true,
    double pending = 0,
  }) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);

    Cache.instance.setSessionToken('token');
    addTearDown(Cache.instance.resetSession);
    final session = CurrentUserProvider()..setUser(signedInUser());

    adapter = ScriptedAdapter((o) {
      final key = '${o.method} ${o.path}';
      if (key == 'GET /customer/wallet') {
        return (
          200,
          {
            'data': _walletJson(
              hasPayoutDetails: hasPayoutDetails,
              canWithdraw: canWithdraw,
              pending: pending,
            ),
          },
        );
      }
      if (key == 'GET /customer/transactions') {
        return (200, {'data': [], 'meta': {'page': 1, 'pages': 1, 'total': 0}});
      }
      if (key == 'GET $withdrawalsPath') {
        return (200, {'data': {'items': withdrawals}});
      }
      if (key == 'PATCH $withdrawalsPath/1/cancel') {
        withdrawals = [withdrawalJson(1, status: 'cancelled')];
        return (200, {'message': 'Cancelled'});
      }
      return (404, {'message': 'not found'});
    });
    final dio = Dio()..httpClientAdapter = adapter;
    final wallet = CustomerWalletViewmodel(
      repository: CustomerWalletRepository(client: dio),
      session: session,
    );
    final withdrawalsVm = CustomerWithdrawalsViewModel(
      repository: CustomerWalletRepository(client: dio),
      session: session,
    );
    final transactions = TransactionViewmodel(
      repository: TransactionRepository(client: dio),
      session: session,
    );
    addTearDown(() {
      wallet.dispose();
      withdrawalsVm.dispose();
      transactions.dispose();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: wallet),
          ChangeNotifierProvider.value(value: withdrawalsVm),
          ChangeNotifierProvider.value(value: transactions),
        ],
        child: const MaterialApp(home: TransactionView()),
      ),
    );
    await _settle(tester);
  }

  setUp(() => withdrawals = [withdrawalJson(1)]);

  testWidgets('the Withdrawals tab lists requests, newest first', (tester) async {
    await openScreen(tester);

    await tester.tap(find.text('Withdrawals'));
    await _settle(tester);

    expect(find.text('Withdrawal'), findsOneWidget);
    expect(find.text('-GHS 50.00'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Cancel request'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('cancelling asks first, then cancels and reports it',
      (tester) async {
    await openScreen(tester);
    await tester.tap(find.text('Withdrawals'));
    await _settle(tester);

    await tester.tap(find.text('Cancel request'));
    await _settle(tester);
    expect(find.text('Cancel this withdrawal?'), findsOneWidget);
    expect(adapter.calls.where((c) => c.startsWith('PATCH')), isEmpty,
        reason: 'nothing is sent before the customer confirms');

    await tester.tap(find.text('Cancel withdrawal'));
    await _settle(tester);

    expect(adapter.calls, contains('PATCH $withdrawalsPath/1/cancel'));
    expect(find.text('Cancelled'), findsWidgets);
    expect(find.text('Cancel request'), findsNothing);
    expect(find.text('Withdrawal cancelled'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('"Keep it" leaves the request alone', (tester) async {
    await openScreen(tester);
    await tester.tap(find.text('Withdrawals'));
    await _settle(tester);

    await tester.tap(find.text('Cancel request'));
    await _settle(tester);
    await tester.tap(find.text('Keep it'));
    await _settle(tester);

    expect(adapter.calls.where((c) => c.startsWith('PATCH')), isEmpty);
    expect(find.text('Cancel request'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('Withdraw opens the sheet when withdrawing is possible',
      (tester) async {
    await openScreen(tester);

    await tester.tap(find.text('Withdraw'));
    await _settle(tester);

    expect(find.text('Withdraw funds'), findsOneWidget);
    expect(find.text('Paying out to'), findsNothing);
    await _unmount(tester);
  });

  testWidgets('Withdraw is live even when the wallet flags say otherwise — '
      'the sheet opens and the server decides', (tester) async {
    await openScreen(tester, hasPayoutDetails: false, canWithdraw: false);

    await tester.tap(find.text('Withdraw'));
    await _settle(tester);

    expect(find.text('Withdraw funds'), findsOneWidget);
    expect(
      find.textContaining('no payout details on file'),
      findsOneWidget,
    );
    await _unmount(tester);
  });

  testWidgets('the card mentions money already on its way', (tester) async {
    await openScreen(tester, pending: 50);

    expect(find.text('GHS 50.00 withdrawal pending'), findsOneWidget);
    await _unmount(tester);
  });
}

/// Pumps through async work and animations without waiting on the balance
/// card's endless shimmer (which `pumpAndSettle` would never see end).
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

/// Removes the tree and lets the card's looping timers and the toast's
/// auto-dismiss run out, so the test ends with nothing pending.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 5));
}
