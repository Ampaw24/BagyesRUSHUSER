import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/vendor/view/widgets/accept_order_dialog.dart';

void main() {
  Future<void> openDialog(
    WidgetTester tester,
    void Function(int? minutes) onAccept,
  ) async {
    // The dialog sizes itself relative to screen width — use a phone.
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(390 * 3, 844 * 3);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAcceptOrderDialog(context, onAccept: onAccept),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('passes the entered prep time to onAccept', (tester) async {
    int? accepted = -1;
    await openDialog(tester, (minutes) => accepted = minutes);

    await tester.enterText(find.byType(TextField), ' 20 ');
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(accepted, 20);
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a blank or non-numeric prep time means "no estimate"',
      (tester) async {
    int? accepted = -1;
    await openDialog(tester, (minutes) => accepted = minutes);

    await tester.enterText(find.byType(TextField), 'soon');
    await tester.tap(find.text('Accept'));
    await tester.pumpAndSettle();

    expect(accepted, isNull);
  });

  testWidgets('cancelling accepts nothing and disposes cleanly',
      (tester) async {
    var accepted = false;
    await openDialog(tester, (_) => accepted = true);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(accepted, isFalse);
    expect(tester.takeException(), isNull);
  });
}
