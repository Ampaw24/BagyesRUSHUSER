import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_tag.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_target.dart';

ConsumerOrder _order({
  String? parcelDirection,
  String? driverName,
  String restaurantName = 'Auntie Muni',
}) => ConsumerOrder(
  id: '42',
  restaurantId: '7',
  restaurantName: restaurantName,
  restaurantImageUrl: '',
  items: const [],
  status: OrderStatus.delivered,
  subtotal: 0,
  deliveryFee: 0,
  serviceFee: 0,
  discount: 0,
  total: 0,
  deliveryAddress: '',
  placedAt: DateTime(2026),
  paymentMethod: 'mobile_money',
  parcelDirection: parcelDirection,
  driverName: driverName,
);

void main() {
  group('composeReviewComment', () {
    test('returns null when there are no tags and no text', () {
      expect(composeReviewComment(const [], '   '), isNull);
    });

    test('uses the text alone, trimmed', () {
      expect(composeReviewComment(const [], '  Loved it '), 'Loved it');
    });

    test('joins tags alone with a middle dot', () {
      expect(
        composeReviewComment(const ['Hot & fresh', 'Tasty food'], ''),
        'Hot & fresh · Tasty food',
      );
    });

    test('puts tags before the text', () {
      expect(
        composeReviewComment(const ['Fast delivery'], 'Thank you!'),
        'Fast delivery — Thank you!',
      );
    });

    test('never exceeds the backend limit', () {
      final comment = composeReviewComment(const [
        'Tasty food',
      ], 'a' * (maxReviewCommentLength * 2));
      expect(comment!.length, maxReviewCommentLength);
    });

    test('free-text budget shrinks by the tag prefix and separator', () {
      expect(remainingCommentLength(const []), maxReviewCommentLength);
      expect(
        remainingCommentLength(const ['Great value']),
        maxReviewCommentLength - 'Great value'.length - ' — '.length,
      );
    });
  });

  group('reviewTagsFor', () {
    test('switches between praise and complaint sets at 4 stars', () {
      final positive = reviewTagsFor(ReviewSubject.vendor, 4);
      final negative = reviewTagsFor(ReviewSubject.vendor, 3);
      expect(positive, contains('Tasty food'));
      expect(negative, contains('Missing items'));
      expect(positive.toSet().intersection(negative.toSet()), isEmpty);
    });
  });

  group('ReviewTarget.fromOrder', () {
    test('food orders review the vendor', () {
      final target = ReviewTarget.fromOrder(_order());
      expect(target.subject, ReviewSubject.vendor);
      expect(target.name, 'Auntie Muni');
      expect(target.orderId, '42');
    });

    test('parcels review the rider', () {
      final target = ReviewTarget.fromOrder(
        _order(parcelDirection: 'send', driverName: 'Kwame'),
      );
      expect(target.subject, ReviewSubject.rider);
      expect(target.name, 'Kwame');
      expect(target.hasNamedRider, isTrue);
    });

    test('parcels without a rider name fall back', () {
      final target = ReviewTarget.fromOrder(_order(parcelDirection: 'receive'));
      expect(target.name, ReviewTarget.riderFallbackName);
      expect(target.hasNamedRider, isFalse);
    });
  });
}
