import 'package:equatable/equatable.dart';

import '../models/review.dart';
import '../models/review_summary.dart';

enum ReviewsStatus { initial, loading, loadingMore, loaded, error }

/// One composed state for the whole Reviews screen — a summary header, a
/// filtered/paginated list, and a per-row reply submission all load and
/// update independently, so this mirrors `DashboardState`'s single
/// `Equatable` + `copyWith` shape rather than `OrdersState`'s sealed
/// subclasses (which fit a single homogeneous resource, not this screen).
class ReviewsState extends Equatable {
  const ReviewsState({
    this.status = ReviewsStatus.initial,
    this.reviews = const [],
    this.summary = const ReviewSummary(
      averageRating: 0,
      totalReviews: 0,
      ratingBreakdown: {},
      unansweredCount: 0,
    ),
    this.ratingFilter,
    this.unansweredOnly = false,
    this.currentPage = 1,
    this.hasMore = false,
    this.replyingReviewId,
    this.errorMessage,
    this.replyError,
  });

  const ReviewsState.initial() : this();

  final ReviewsStatus status;
  final List<Review> reviews;
  final ReviewSummary summary;

  /// null = all stars.
  final int? ratingFilter;
  final bool unansweredOnly;
  final int currentPage;
  final bool hasMore;

  /// Non-null while a `POST .../reply` is in flight for that review id.
  final String? replyingReviewId;
  final String? errorMessage;

  /// Last reply-submit failure message, surfaced verbatim in the composer.
  final String? replyError;

  ReviewsState copyWith({
    ReviewsStatus? status,
    List<Review>? reviews,
    ReviewSummary? summary,
    int? ratingFilter,
    bool clearRatingFilter = false,
    bool? unansweredOnly,
    int? currentPage,
    bool? hasMore,
    String? replyingReviewId,
    bool clearReplyingReviewId = false,
    String? errorMessage,
    bool clearError = false,
    String? replyError,
    bool clearReplyError = false,
  }) {
    return ReviewsState(
      status: status ?? this.status,
      reviews: reviews ?? this.reviews,
      summary: summary ?? this.summary,
      ratingFilter:
          clearRatingFilter ? null : (ratingFilter ?? this.ratingFilter),
      unansweredOnly: unansweredOnly ?? this.unansweredOnly,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      replyingReviewId: clearReplyingReviewId
          ? null
          : (replyingReviewId ?? this.replyingReviewId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      replyError:
          clearReplyError ? null : (replyError ?? this.replyError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        reviews,
        summary,
        ratingFilter,
        unansweredOnly,
        currentPage,
        hasMore,
        replyingReviewId,
        errorMessage,
        replyError,
      ];
}
