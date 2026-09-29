import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_tag.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_target.dart';
import 'package:bagyesrushappusernew/src/order_reviews/viewmodels/order_reviews_viewmodel.dart';
import 'package:bagyesrushappusernew/src/order_reviews/viewmodels/review_composer_state.dart';

/// Form state for one review sheet. Submission goes through the shared
/// [OrderReviewsViewModel] so every screen learns the order is rated.
class ReviewComposerViewModel extends ViewModel<ReviewComposerState> {
  ReviewComposerViewModel({
    required ReviewTarget target,
    required OrderReviewsViewModel reviewsViewModel,
  }) : _reviews = reviewsViewModel,
       super(ReviewComposerState(target: target));

  final OrderReviewsViewModel _reviews;

  /// The sheet may be dismissed mid-submit; the review is still recorded by
  /// [OrderReviewsViewModel], but this form must not notify once disposed.
  bool _disposed = false;

  @override
  void emit(ReviewComposerState newState) {
    if (!_disposed) super.emit(newState);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void setRating(int rating) {
    if (state.isSubmitting || rating == state.rating) return;
    // Crossing the praise/complaint line swaps the chip set, so selections
    // from the other set no longer apply.
    final sentimentChanged =
        !state.hasRating ||
        isPositiveRating(rating) != isPositiveRating(state.rating);
    emit(
      state.copyWith(
        rating: rating,
        selectedTags: sentimentChanged ? const [] : null,
        clearError: true,
      ),
    );
  }

  void toggleTag(String tag) {
    if (state.isSubmitting) return;
    final tags = [...state.selectedTags];
    tags.contains(tag) ? tags.remove(tag) : tags.add(tag);
    // A new chip shrinks the free-text budget — trim rather than overflow.
    final max = remainingCommentLength(tags);
    final comment = state.comment.length > max
        ? state.comment.substring(0, max)
        : state.comment;
    emit(
      state.copyWith(selectedTags: tags, comment: comment, clearError: true),
    );
  }

  void setComment(String comment) {
    if (comment == state.comment) return;
    emit(state.copyWith(comment: comment, clearError: true));
  }

  Future<void> submit() async {
    if (!state.canSubmit) return;
    emit(
      state.copyWith(status: ReviewSubmitStatus.submitting, clearError: true),
    );

    final result = await _reviews.submitReview(
      orderId: state.target.orderId,
      rating: state.rating,
      comment: state.composedComment,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ReviewSubmitStatus.error,
          errorMessage: failure.message,
        ),
      ),
      (review) => emit(
        state.copyWith(
          status: ReviewSubmitStatus.success,
          submittedReview: review,
        ),
      ),
    );
  }
}
