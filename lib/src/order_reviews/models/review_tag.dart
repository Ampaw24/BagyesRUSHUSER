import 'review_target.dart';

/// Backend cap on `comment` (`nullable, string, max:1000`).
const int maxReviewCommentLength = 1000;

/// Ratings at or above this read as positive feedback.
const int positiveRatingThreshold = 4;

const _tagSeparator = ' · ';
const _textSeparator = ' — ';

/// Short caption shown under the stars for [rating] (1–5).
String ratingCaption(int rating) => switch (rating) {
  1 => 'Terrible',
  2 => 'Bad',
  3 => 'Okay',
  4 => 'Good',
  5 => 'Excellent!',
  _ => 'Tap a star to rate',
};

bool isPositiveRating(int rating) => rating >= positiveRatingThreshold;

/// Quick-feedback chips for [subject], swapped between praise and
/// "what went wrong" depending on [rating]. The API has no tags field, so
/// selected chips are folded into the comment by [composeReviewComment].
List<String> reviewTagsFor(ReviewSubject subject, int rating) {
  final positive = isPositiveRating(rating);
  return switch (subject) {
    ReviewSubject.vendor =>
      positive
          ? const [
              'Tasty food',
              'Hot & fresh',
              'Well packaged',
              'Generous portions',
              'Great value',
              'Order was accurate',
            ]
          : const [
              'Food was cold',
              'Missing items',
              'Wrong order',
              'Poor packaging',
              'Small portions',
              'Took too long',
            ],
    ReviewSubject.rider =>
      positive
          ? const [
              'Fast delivery',
              'Friendly rider',
              'Handled with care',
              'Great communication',
              'Followed instructions',
            ]
          : const [
              'Late delivery',
              'Parcel damaged',
              'Rude rider',
              'Hard to reach',
              'Ignored instructions',
            ],
  };
}

/// Chip prefix as it will appear in the comment, e.g. "Hot & fresh · Tasty
/// food". Empty when no chips are selected.
String reviewTagPrefix(List<String> tags) => tags.join(_tagSeparator);

/// Characters left for free text once [tags] have been merged in.
int remainingCommentLength(List<String> tags) {
  final prefix = reviewTagPrefix(tags);
  final used = prefix.isEmpty ? 0 : prefix.length + _textSeparator.length;
  final remaining = maxReviewCommentLength - used;
  return remaining < 0 ? 0 : remaining;
}

/// Builds the `comment` payload: selected chips first, then the customer's
/// own words — "Hot & fresh · Well packaged — Loved the jollof". Returns
/// null when there's nothing to send; never exceeds [maxReviewCommentLength].
String? composeReviewComment(List<String> tags, String text) {
  final prefix = reviewTagPrefix(tags);
  final body = text.trim();
  final String comment;
  if (prefix.isEmpty) {
    comment = body;
  } else if (body.isEmpty) {
    comment = prefix;
  } else {
    comment = '$prefix$_textSeparator$body';
  }
  if (comment.isEmpty) return null;
  return comment.length > maxReviewCommentLength
      ? comment.substring(0, maxReviewCommentLength)
      : comment;
}
