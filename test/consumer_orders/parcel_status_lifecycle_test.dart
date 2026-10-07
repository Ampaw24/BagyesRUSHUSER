import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/widgets/parcel_tracking_timeline.dart';

ConsumerOrder _parcel(String status, [Map<String, dynamic> extra = const {}]) =>
    ConsumerOrder.fromJson({
      'id': 31,
      'type': 'parcel',
      'status': status,
      'created_at': '2026-10-07T09:00:00Z',
      ...extra,
    });

Future<void> _pumpTimeline(WidgetTester tester, ConsumerOrder order) =>
    tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: ParcelTrackingTimeline(order: order)),
        ),
      ),
    );

void main() {
  group('backend status strings', () {
    test('map each lifecycle status distinctly', () {
      expect(orderStatusFromString('pending_payment'), OrderStatus.pending);
      expect(orderStatusFromString('pending'), OrderStatus.pending);
      expect(orderStatusFromString('accepted'), OrderStatus.accepted);
      expect(orderStatusFromString('out_for_delivery'), OrderStatus.onTheWay);
      expect(orderStatusFromString('delivered'), OrderStatus.delivered);
      expect(orderStatusFromString('cancelled'), OrderStatus.cancelled);
      expect(orderStatusFromString('rejected'), OrderStatus.rejected);
      expect(orderStatusFromString('refunded'), OrderStatus.refunded);
    });

    test('only in-progress statuses are active', () {
      for (final s in [OrderStatus.pending, OrderStatus.accepted, OrderStatus.onTheWay]) {
        expect(s.isActive, isTrue, reason: '$s');
      }
      for (final s in [
        OrderStatus.delivered,
        OrderStatus.cancelled,
        OrderStatus.rejected,
        OrderStatus.refunded,
      ]) {
        expect(s.isActive, isFalse, reason: '$s');
      }
    });

    test('declined and refunded orders never ask for payment', () {
      expect(_parcel('rejected').needsPayment, isFalse);
      expect(_parcel('refunded').needsPayment, isFalse);
      expect(_parcel('pending').needsPayment, isTrue);
    });
  });

  group('cancel rule', () {
    test('a parcel can be cancelled until delivered, including on the road', () {
      expect(_parcel('pending').canCancel, isTrue);
      expect(_parcel('accepted').canCancel, isTrue);
      expect(_parcel('out_for_delivery').canCancel, isTrue);
      expect(_parcel('delivered').canCancel, isFalse);
      expect(_parcel('cancelled').canCancel, isFalse);
      expect(_parcel('refunded').canCancel, isFalse);
    });

    test('food cannot be cancelled once it is out for delivery', () {
      ConsumerOrder food(String status) => ConsumerOrder.fromJson({
            'id': 7,
            'status': status,
            'vendor': {'id': 1, 'name': 'KFC'},
          });
      expect(food('preparing').canCancel, isTrue);
      expect(food('out_for_delivery').canCancel, isFalse);
    });

    test("the backend's can_cancel wins when present", () {
      expect(_parcel('out_for_delivery', {'can_cancel': false}).canCancel, isFalse);
      expect(_parcel('delivered', {'can_cancel': true}).canCancel, isTrue);
    });
  });

  group('parcel timeline', () {
    testWidgets('in transit: no "picked up" step, out for delivery is current',
        (tester) async {
      await _pumpTimeline(
        tester,
        _parcel('out_for_delivery', {
          'rider': {'name': 'Musah M.'},
        }),
      );
      expect(find.text('Request placed'), findsOneWidget);
      expect(find.text('Rider assigned'), findsOneWidget);
      expect(find.text('Out for delivery'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.textContaining('picked up', findRichText: true), findsNothing);
      expect(find.textContaining('Package collected'), findsOneWidget);
    });

    testWidgets('declined: stops at the request, shows the declined step',
        (tester) async {
      await _pumpTimeline(tester, _parcel('rejected'));
      expect(find.text('Request placed'), findsOneWidget);
      expect(find.text('Request declined'), findsOneWidget);
      expect(find.text('Rider assigned'), findsNothing);
      expect(find.text('Delivered'), findsNothing);
    });

    testWidgets('cancelled after a rider was assigned keeps that step',
        (tester) async {
      await _pumpTimeline(
        tester,
        _parcel('cancelled', {
          'rider': {'name': 'Musah M.'},
        }),
      );
      expect(find.text('Rider assigned'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Out for delivery'), findsNothing);
    });

    testWidgets('refunded after delivery shows delivered then refunded',
        (tester) async {
      await _pumpTimeline(
        tester,
        _parcel('refunded', {'delivered_at': '2026-10-07T10:00:00Z'}),
      );
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('Refunded'), findsOneWidget);
      expect(find.text('Cancelled'), findsNothing);
    });

    testWidgets('refunded after a decline shows the declined step too',
        (tester) async {
      await _pumpTimeline(
        tester,
        _parcel('refunded', {'rejected_at': '2026-10-07T09:10:00Z'}),
      );
      expect(find.text('Request declined'), findsOneWidget);
      expect(find.text('Refunded'), findsOneWidget);
    });
  });
}
