import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/chat/model/conversation.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/tracking_rider_card.dart';

ConsumerOrder _orderWithRider(String status) => ConsumerOrder.fromJson({
      'id': 1,
      'status': status,
      'vendor': {'id': 7, 'name': 'Auntie Muni'},
      'items': const [],
      'totals': {'subtotal': 50.0, 'delivery_fee': 10.0, 'total': 60.0},
      'delivery': {'address': 'East Legon'},
      'payment': {'method': 'cash'},
      'rider': {'name': 'Kofi', 'phone': '+233241234567'},
      'created_at': '2026-09-29T10:00:00Z',
    });

void main() {
  test('chat is only available while the order is in progress', () {
    for (final status in [
      'pending_payment',
      'pending',
      'accepted',
      'preparing',
      'ready',
      'picked_up',
      'out_for_delivery',
    ]) {
      expect(orderStatusFromString(status).isActive, isTrue, reason: status);
    }
    for (final status in ['delivered', 'cancelled', 'rejected', 'refunded']) {
      expect(orderStatusFromString(status).isActive, isFalse, reason: status);
    }
  });

  test('a refunded order drops out of the chat inbox', () {
    ConversationOrderSummary order(String status) =>
        ConversationOrderSummary.fromJson({'id': 1, 'status': status});
    expect(order('out_for_delivery').isActive, isTrue);
    expect(order('refunded').isActive, isFalse);
    expect(order('delivered').isActive, isFalse);
  });

  Future<void> pumpCard(WidgetTester tester, VoidCallback? onChat) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackingRiderCard(
              order: _orderWithRider('delivered'),
              onChat: onChat,
            ),
          ),
        ),
      );

  testWidgets('rider card hides chat for a finished order, keeps call',
      (tester) async {
    await pumpCard(tester, null);
    expect(find.byTooltip('Chat'), findsNothing);
    expect(find.byTooltip('Call'), findsOneWidget);

    await pumpCard(tester, () {});
    expect(find.byTooltip('Chat'), findsOneWidget);
  });
}
