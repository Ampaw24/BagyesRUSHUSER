import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/consumer_orders/widgets/tracking_reveal.dart';

double _opacity(WidgetTester tester) =>
    tester.widget<Opacity>(find.byType(Opacity).first).opacity;

Widget _app({bool disableAnimations = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: const TrackingReveal(
      delay: Duration(milliseconds: 200),
      child: Text('hello'),
    ),
  ),
);

void main() {
  testWidgets('fades in after its delay', (tester) async {
    await tester.pumpWidget(_app());
    expect(_opacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 150));
    expect(_opacity(tester), 0, reason: 'still waiting out the delay');

    await tester.pump(const Duration(milliseconds: 600));
    expect(_opacity(tester), 1);
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('shows instantly when animations are disabled', (tester) async {
    await tester.pumpWidget(_app(disableAnimations: true));
    expect(_opacity(tester), 1);
  });
}
