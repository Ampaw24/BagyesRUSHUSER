import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'review_target.dart';

/// A 1–5 star rating plus optional comment for one [ReviewSubject].
class SubjectRating extends Equatable {
  const SubjectRating({required this.rating, this.comment});

  final int rating;
  final String? comment;

  @override
  List<Object?> get props => [rating, comment];
}

/// `POST customer/orders/:id/review` body. Only rated subjects are sent, and
/// a missing comment is omitted rather than sent as null.
DataMap reviewRequestBody(Map<ReviewSubject, SubjectRating> ratings) => {
  for (final MapEntry(key: subject, value: rating) in ratings.entries) ...{
    subject.ratingKey: rating.rating,
    subject.commentKey: ?rating.comment,
  },
};

/// The customer's review of one order: a rating per subject they rated,
/// plus the vendor's optional public reply.
class OrderReview extends Equatable {
  const OrderReview({
    required this.id,
    required this.orderId,
    required this.ratings,
    this.vendorReply,
    this.createdAt,
  });

  final String id;
  final String orderId;
  final Map<ReviewSubject, SubjectRating> ratings;
  final String? vendorReply;
  final DateTime? createdAt;

  SubjectRating? ratingFor(ReviewSubject subject) => ratings[subject];

  /// Headline number for compact badges — the vendor's when rated.
  int? get primaryRating =>
      (ratings[ReviewSubject.vendor] ?? ratings[ReviewSubject.rider])?.rating;

  bool get hasVendorReply => vendorReply?.trim().isNotEmpty ?? false;

  /// The response shape is undocumented, so this reads the same
  /// `vendor_*` / `rider_*` keys the request sends. [orderId] fills in for a
  /// payload that doesn't echo it back.
  factory OrderReview.fromJson(DataMap json, {String? orderId}) {
    final order = json['order'];
    return OrderReview(
      id: JsonUtils.asString(json['id']),
      orderId: orderId ??
          JsonUtils.asString(
            json['order_id'] ?? (order is DataMap ? order['id'] : null),
          ),
      ratings: {
        for (final subject in ReviewSubject.values)
          if (json[subject.ratingKey] != null)
            subject: SubjectRating(
              rating: JsonUtils.asInt(json[subject.ratingKey]),
              comment: JsonUtils.asStringOrNull(json[subject.commentKey]),
            ),
      },
      vendorReply: JsonUtils.asStringOrNull(
        json['vendor_reply'] ?? json['reply'],
      ),
      createdAt: JsonUtils.asDateTime(json['created_at']),
    );
  }

  @override
  List<Object?> get props => [id, orderId, ratings, vendorReply, createdAt];
}
