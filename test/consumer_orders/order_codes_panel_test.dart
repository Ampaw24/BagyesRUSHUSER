import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/order_codes_panel.dart';

Map<String, dynamic> _receiveParcel({
  String status = 'accepted',
  Map<String, dynamic> pickup = const {},
}) => {
  'id': 91,
  'type': 'parcel',
  'direction': 'receive',
  'status': status,
  'pickup': {
    'address': '12 Oxford Street, Osu',
    'contact_name': 'Yaw Boateng',
    'code': '4821',
    ...pickup,
  },
  'stops': [
    {'address': '4 Boundary Road', 'size': 'medium', 'delivery_pin': '7314'},
  ],
};

Future<void> _pump(WidgetTester tester, Map<String, dynamic> json) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: OrderCodesPanel(order: ConsumerOrder.fromJson(json)),
          ),
        ),
      ),
    );

void main() {
  testWidgets('receive parcel shows both the pickup and drop-off codes', (
    tester,
  ) async {
    await _pump(tester, _receiveParcel());

    expect(find.text('Pickup code'), findsOneWidget);
    expect(find.text('4821'), findsOneWidget);
    expect(find.text('Drop-off code'), findsOneWidget);
    expect(find.text('7314'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Pickup code')).dy,
      lessThan(tester.getTopLeft(find.text('Drop-off code')).dy),
      reason: 'the pickup happens first, so its code comes first',
    );
  });

  testWidgets('the pickup code goes once the rider has collected', (
    tester,
  ) async {
    await _pump(
      tester,
      _receiveParcel(
        status: 'out_for_delivery',
        pickup: {'code_verified_at': '2026-09-26T09:15:00Z'},
      ),
    );

    expect(find.text('Pickup code'), findsNothing);
    expect(find.text('Drop-off code'), findsOneWidget);
  });

  testWidgets('a failed collection shows the banner, not the pickup code', (
    tester,
  ) async {
    await _pump(
      tester,
      _receiveParcel(
        pickup: {
          'collection_failed_at': '2026-09-26T09:15:00Z',
          'collection_failure_reason': 'Sender not reachable',
        },
      ),
    );

    expect(find.text("The rider couldn't collect the package"), findsOneWidget);
    expect(find.text('Sender not reachable'), findsOneWidget);
    expect(find.text('Pickup code'), findsNothing);
  });

  testWidgets('a send parcel keeps the single Delivery PIN', (tester) async {
    await _pump(tester, {
      'id': 5,
      'type': 'parcel',
      'direction': 'send',
      'status': 'accepted',
      'stops': [
        {'address': 'East Legon', 'size': 'small', 'delivery_pin': '1234'},
      ],
    });

    expect(find.text('Delivery PIN'), findsOneWidget);
    expect(find.text('1234'), findsOneWidget);
    expect(find.text('Pickup code'), findsNothing);
    expect(find.text('Drop-off code'), findsNothing);
  });
}
