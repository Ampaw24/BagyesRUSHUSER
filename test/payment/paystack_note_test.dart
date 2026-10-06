import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/payment/views/widgets/paystack_note.dart';

void main() {
  Future<void> pump(WidgetTester tester, {bool walletCoversFully = false}) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PaystackNote(walletCoversFully: walletCoversFully)),
      ),
    );
  }

  testWidgets('tells the customer Paystack handles how they pay', (tester) async {
    await pump(tester);

    expect(find.textContaining('secure Paystack page'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('when the wallet pays in full, Paystack is not mentioned',
      (tester) async {
    await pump(tester, walletCoversFully: true);

    expect(find.textContaining('wallet covers this order'), findsOneWidget);
    expect(find.textContaining('Paystack'), findsNothing);
  });
}
