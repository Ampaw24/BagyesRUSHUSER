import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/consumer_orders/models/order_payment_outcome.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/payment_confirmation_dialog.dart';

/// How the dialog ended — recorded instead of awaited, so a dialog that
/// never closes fails the assertion rather than hanging the test.
class _Opened {
  OrderPaymentOutcome? outcome;
  Object? error;
}

/// Logical screen sizes the dialog must fit without overflowing.
const _screens = {
  'portrait phone': Size(360, 640),
  'landscape phone': Size(640, 360),
  'tablet': Size(800, 1280),
};

Future<_Opened> _open(
  WidgetTester tester,
  Future<bool> Function() verification, {
  Size screen = const Size(360, 640),
}) async {
  tester.view
    ..physicalSize = screen * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final opened = _Opened();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () =>
                PaymentConfirmationDialog.show(
                  context,
                  // Created at tap time, as the launcher does.
                  verification: verification(),
                ).then<void>(
                  (outcome) {
                    opened.outcome = outcome;
                  },
                  onError: (Object error) {
                    opened.error = error;
                  },
                ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump();
  return opened;
}

void main() {
  testWidgets('shows a confirming state that cannot be dismissed', (
    tester,
  ) async {
    final verification = Completer<bool>();
    final opened = await _open(tester, () => verification.future);

    expect(find.text('Confirming your payment…'), findsOneWidget);
    await tester.tapAt(const Offset(5, 5)); // barrier tap
    await tester.pump();
    expect(find.text('Confirming your payment…'), findsOneWidget);
    expect(opened.outcome, isNull);

    verification.complete(true);
    await tester.pump();
    await tester.pump(PaymentConfirmationDialog.successHold);
    await tester.pump(const Duration(milliseconds: 500));
    expect(opened.outcome, OrderPaymentOutcome.paid);
  });

  for (final MapEntry(key: label, value: screen) in _screens.entries) {
    testWidgets('success fits and closes by itself on a $label', (
      tester,
    ) async {
      final opened = await _open(
        tester,
        () => Future.value(true),
        screen: screen,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Payment successful'), findsOneWidget);
      expect(opened.outcome, isNull);

      await tester.pump(PaymentConfirmationDialog.successHold);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Payment successful'), findsNothing);
      expect(opened.outcome, OrderPaymentOutcome.paid);
    });

    testWidgets('processing waits for acknowledgement on a $label', (
      tester,
    ) async {
      final opened = await _open(
        tester,
        () => Future.value(false),
        screen: screen,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Payment processing'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      expect(opened.outcome, isNull);

      await tester.ensureVisible(find.text('Got it'));
      await tester.tap(find.text('Got it'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(opened.outcome, OrderPaymentOutcome.processing);
    });
  }

  testWidgets('a verification error closes the dialog and reaches the caller', (
    tester,
  ) async {
    final opened = await _open(
      tester,
      () => Future<bool>.error(StateError('declined')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(PaymentConfirmationDialog), findsNothing);
    expect(opened.error, isA<StateError>());
    expect(opened.outcome, isNull);
  });
}
