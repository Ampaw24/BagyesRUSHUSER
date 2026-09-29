import 'package:flutter_test/flutter_test.dart';

import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/order_review.dart';
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
    test('food orders without a named rider review only the vendor', () {
      final target = ReviewTarget.fromOrder(_order());
      expect(target.orderId, '42');
      expect(target.isParcel, isFalse);
      expect(target.parties.map((p) => p.subject), [ReviewSubject.vendor]);
      expect(target.primary.name, 'Auntie Muni');
    });

    test('food orders with a rider review the vendor first, then the rider',
        () {
      final target = ReviewTarget.fromOrder(_order(driverName: 'Kwame'));
      expect(target.parties.map((p) => p.subject), [
        ReviewSubject.vendor,
        ReviewSubject.rider,
      ]);
      expect(target.partyFor(ReviewSubject.rider)!.name, 'Kwame');
    });

    test('parcels review only the rider', () {
      final target = ReviewTarget.fromOrder(
        _order(parcelDirection: 'send', driverName: 'Kwame'),
      );
      expect(target.isParcel, isTrue);
      expect(target.parties.map((p) => p.subject), [ReviewSubject.rider]);
      expect(target.primary.hasNamedRider, isTrue);
    });

    test('parcels without a rider name fall back', () {
      final target = ReviewTarget.fromOrder(_order(parcelDirection: 'receive'));
      expect(target.primary.name, ReviewParty.riderFallbackName);
      expect(target.primary.hasNamedRider, isFalse);
    });
  });

  group('reviewRequestBody', () {
    test('sends vendor_* and rider_* keys for each rated subject', () {
      expect(
        reviewRequestBody(const {
          ReviewSubject.vendor: SubjectRating(rating: 5, comment: 'Tasty'),
          ReviewSubject.rider: SubjectRating(rating: 3, comment: 'Late'),
        }),
        {
          'vendor_rating': 5,
          'vendor_comment': 'Tasty',
          'rider_rating': 3,
          'rider_comment': 'Late',
        },
      );
    });

    test('omits unrated subjects and missing comments', () {
      expect(
        reviewRequestBody(const {
          ReviewSubject.rider: SubjectRating(rating: 4),
        }),
        {'rider_rating': 4},
      );
    });
  });

  group('OrderReview.fromJson', () {
    test('reads per-subject ratings and the vendor reply', () {
      final review = OrderReview.fromJson({
        'id': 9,
        'order': {'id': 42},
        'vendor_rating': 4,
        'vendor_comment': 'Good',
        'rider_rating': null,
        'reply': 'Thanks!',
      });
      expect(review.orderId, '42');
      expect(review.ratingFor(ReviewSubject.vendor)?.rating, 4);
      expect(review.ratingFor(ReviewSubject.rider), isNull);
      expect(review.primaryRating, 4);
      expect(review.hasVendorReply, isTrue);
    });

    test('falls back to the rider rating for the headline number', () {
      final review = OrderReview.fromJson({'order_id': 1, 'rider_rating': 2});
      expect(review.primaryRating, 2);
    });
  });
}
