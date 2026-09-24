import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/core/utils/json_utils.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';

/// Aggregate rating stats for `GET /vendor/me/reviews/summary`.
///
/// The doc ships no success example for this endpoint either, so every
/// field is read defensively with multiple key aliases and defaults to a
/// neutral empty value rather than throwing mid-parse.
class ReviewSummary extends Equatable {
  const ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingBreakdown,
    required this.unansweredCount,
  });

  final double averageRating;
  final int totalReviews;

  /// Star (1..5) → count of reviews at that star.
  final Map<int, int> ratingBreakdown;
  final int unansweredCount;

  factory ReviewSummary.empty() => const ReviewSummary(
        averageRating: 0,
        totalReviews: 0,
        ratingBreakdown: {},
        unansweredCount: 0,
      );

  factory ReviewSummary.fromJson(DataMap json) {
    final breakdownRaw =
        json['rating_breakdown'] ?? json['distribution'] ?? json['breakdown'];
    final breakdown = <int, int>{};
    if (breakdownRaw is DataMap) {
      for (final entry in breakdownRaw.entries) {
        final star = int.tryParse(entry.key.toString());
        if (star != null) breakdown[star] = JsonUtils.asInt(entry.value);
      }
    } else if (breakdownRaw is List) {
      for (final entry in breakdownRaw) {
        if (entry is DataMap) {
          final star = JsonUtils.asInt(entry['star'] ?? entry['rating']);
          if (star > 0) breakdown[star] = JsonUtils.asInt(entry['count']);
        }
      }
    }

    return ReviewSummary(
      averageRating: JsonUtils.asDouble(
        json['average_rating'] ?? json['average'] ?? json['avg_rating'],
      ),
      totalReviews: JsonUtils.asInt(
        json['total_reviews'] ?? json['total'] ?? json['count'],
      ),
      ratingBreakdown: breakdown,
      unansweredCount: JsonUtils.asInt(
        json['unanswered_count'] ?? json['unanswered'],
      ),
    );
  }

  @override
  List<Object?> get props => [
        averageRating,
        totalReviews,
        ratingBreakdown,
        unansweredCount,
      ];
}
