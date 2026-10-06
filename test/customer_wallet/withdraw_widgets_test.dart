import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/src/customer-wallet/models/customer_withdrawal_model.dart';
import 'package:bagyesrushappusernew/src/customer-wallet/views/widgets/customer_withdrawal_tile.dart';
import 'package:bagyesrushappusernew/src/transaction/views/widgets/withdraw_sheet.dart';

import '../core/support/auth_test_support.dart';
import 'support/withdrawal_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void phone(WidgetTester tester) {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);
  }

  group('CustomerWithdrawalTile', () {
    Future<void> pump(
      WidgetTester tester,
      CustomerWithdrawalModel withdrawal, {
      VoidCallback? onCancel,
      bool isCancelling = false,
    }) async {
      phone(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerWithdrawalTile(
              withdrawal: withdrawal,
              onCancel: onCancel,
              isCancelling: isCancelling,
            ),
          ),
        ),
      );
    }

    CustomerWithdrawalModel model(String status) =>
        CustomerWithdrawalModel.tryFromJson(withdrawalJson(1, status: status))!;

    testWidgets('a pending request offers Cancel, which fires the callback',
        (tester) async {
      var cancelled = 0;
      await pump(tester, model('pending'), onCancel: () => cancelled++);

      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('-GHS 50.00'), findsOneWidget);
      await tester.tap(find.text('Cancel request'));

      expect(cancelled, 1);
    });

    testWidgets('settled requests never offer Cancel', (tester) async {
      for (final status in ['processing', 'completed', 'failed', 'cancelled']) {
        await pump(tester, model(status), onCancel: () {});
        expect(find.text('Cancel request'), findsNothing, reason: status);
      }
    });

    testWidgets('while cancelling, a spinner replaces the button',
        (tester) async {
      await pump(tester, model('pending'), onCancel: () {}, isCancelling: true);

      expect(find.text('Cancel request'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('WithdrawSheet', () {
    late WithdrawalHarness h;
    var openedResult = Object();

    ScriptedAdapter backend({int postStatus = 201}) => ScriptedAdapter((o) {
          final key = '${o.method} ${o.path}';
          if (key == 'POST $withdrawalsPath') {
            return postStatus == 201
                ? (201, {'data': withdrawalJson(9, amount: 40)})
                : (postStatus, {'message': 'Amount exceeds your limit.'});
          }
          return (
            200,
            {
              'data': {'items': [withdrawalJson(9, amount: 40)]},
            },
          );
        });

    /// Opens the sheet from a button, like the wallet screen does.
    Future<void> open(WidgetTester tester, {double withdrawable = 150}) async {
      phone(tester);
      h = WithdrawalHarness(backend);
      addTearDown(h.dispose);
      openedResult = Object();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: h.vm,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async => openedResult =
                      (await WithdrawSheet.show(
                        context,
                        wallet: wallet(withdrawable: withdrawable),
                      )) ??
                      'dismissed',
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Finder withdrawButton() => find.widgetWithText(ElevatedButton, 'Withdraw');

    testWidgets('has no payout-method card — the server picks the destination',
        (tester) async {
      await open(tester);

      expect(find.text('Paying out to'), findsNothing);
      expect(find.text('Change'), findsNothing);
      expect(find.text('Mobile money number'), findsNothing);
      expect(find.text('Account name'), findsNothing);
    });

    testWidgets('no payout details: offers the add flow, which closes the sheet',
        (tester) async {
      phone(tester);
      h = WithdrawalHarness(backend);
      addTearDown(h.dispose);
      var addOpened = 0;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: h.vm,
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => WithdrawSheet.show(
                    context,
                    wallet: wallet(hasPayoutDetails: false),
                    onAddPayoutMethod: () => addOpened++,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.textContaining('no payout details on file'), findsOneWidget);
      await tester.tap(find.text('Add payout method'));
      await tester.pumpAndSettle();

      expect(addOpened, 1);
      expect(find.text('Withdraw funds'), findsNothing, reason: 'sheet closed');
    });

    testWidgets('with payout details there is no add button', (tester) async {
      await open(tester);

      expect(find.text('Add payout method'), findsNothing);
    });

    testWidgets('blocks only what the API itself would refuse', (tester) async {
      await open(tester);

      await tester.enterText(find.byType(TextField), '0.5');
      await tester.pump();
      expect(find.text('Minimum withdrawal is GHS 1.00'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '2000000');
      await tester.pump();
      expect(find.text('Maximum withdrawal is GHS 1000000.00'), findsOneWidget);
    });

    testWidgets('wallet limits are a heads-up, not a wall — the server decides',
        (tester) async {
      await open(tester);

      // More than the withdrawable balance (150).
      await tester.enterText(find.byType(TextField), '999');
      await tester.pump();
      expect(find.textContaining('more than your withdrawable balance'), findsOneWidget);
      var button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Withdraw GHS 999.00'),
      );
      expect(button.onPressed, isNotNull);

      // Under the wallet's minimum (5) but over the API's own (1).
      await tester.enterText(find.byType(TextField), '2');
      await tester.pump();
      expect(find.textContaining('Below the minimum of GHS 5.00'), findsOneWidget);
      button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Withdraw GHS 2.00'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('an amount over the withdrawable balance is sent, and the '
        'server\'s refusal is shown', (tester) async {
      phone(tester);
      h = WithdrawalHarness(() => backend(postStatus: 422));
      addTearDown(h.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: h.vm,
          child: MaterialApp(home: Scaffold(body: WithdrawSheet(wallet: wallet()))),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '999');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Withdraw GHS 999.00'));
      await tester.pumpAndSettle();

      final post = h.adapter.requests.firstWhere((r) => r.method == 'POST');
      expect(post.data, {'amount': 999.0});
      expect(find.text('Amount exceeds your limit.'), findsOneWidget);
    });

    testWidgets('a wallet with nothing withdrawable still opens, with a notice',
        (tester) async {
      await open(tester, withdrawable: 0);

      expect(find.text('You have no withdrawable balance yet.'), findsOneWidget);
      // Still usable: the customer can enter an amount and try.
      await tester.enterText(find.byType(TextField), '10');
      await tester.pump();
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Withdraw GHS 10.00'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('percentage chips fill the amount', (tester) async {
      await open(tester);

      await tester.tap(find.text('Max'));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '150.00',
      );
    });

    testWidgets('a valid request posts the amount and closes the sheet',
        (tester) async {
      await open(tester);

      await tester.enterText(find.byType(TextField), '40');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Withdraw GHS 40.00'));
      await tester.pumpAndSettle();

      final post = h.adapter.requests.firstWhere((r) => r.method == 'POST');
      expect(post.data, {'amount': 40.0});
      expect(openedResult, true);
    });

    testWidgets('a server rejection stays on the sheet with the reason',
        (tester) async {
      phone(tester);
      h = WithdrawalHarness(() => backend(postStatus: 422));
      addTearDown(h.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: h.vm,
          child: MaterialApp(home: Scaffold(body: WithdrawSheet(wallet: wallet()))),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '40');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Withdraw GHS 40.00'));
      await tester.pumpAndSettle();

      expect(find.text('Amount exceeds your limit.'), findsOneWidget);
      expect(find.byType(WithdrawSheet), findsOneWidget);
      expect(withdrawButton(), findsNothing, reason: 'label now shows the amount');
    });
  });
}
