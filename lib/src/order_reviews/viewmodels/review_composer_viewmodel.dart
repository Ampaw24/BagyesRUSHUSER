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

  void setRating(ReviewSubject subject, int rating) {
    final draft = state.draftFor(subject);
    if (state.isSubmitting || rating == draft.rating) return;
    // Crossing the praise/complaint line swaps the chip set, so selections
    // from the other set no longer apply.
    final sentimentChanged =
        !draft.hasRating ||
        isPositiveRating(rating) != isPositiveRating(draft.rating);
    _updateDraft(
      subject,
      draft.copyWith(
        rating: rating,
        selectedTags: sentimentChanged ? const [] : null,
      ),
    );
  }

  void toggleTag(ReviewSubject subject, String tag) {
    if (state.isSubmitting) return;
    final draft = state.draftFor(subject);
    final tags = [...draft.selectedTags];
    tags.contains(tag) ? tags.remove(tag) : tags.add(tag);
    // A new chip shrinks the free-text budget — trim rather than overflow.
    final max = remainingCommentLength(tags);
    final comment = draft.comment.length > max
        ? draft.comment.substring(0, max)
        : draft.comment;
    _updateDraft(subject, draft.copyWith(selectedTags: tags, comment: comment));
  }

  void setComment(ReviewSubject subject, String comment) {
    final draft = state.draftFor(subject);
    if (comment == draft.comment) return;
    _updateDraft(subject, draft.copyWith(comment: comment));
  }

  void _updateDraft(ReviewSubject subject, SubjectDraft draft) => emit(
    state.copyWith(drafts: {...state.drafts, subject: draft}, clearError: true),
  );

  Future<void> submit() async {
    if (!state.canSubmit) return;
    emit(
      state.copyWith(status: ReviewSubmitStatus.submitting, clearError: true),
    );

    final result = await _reviews.submitReview(
      orderId: state.target.orderId,
      ratings: state.submission,
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
