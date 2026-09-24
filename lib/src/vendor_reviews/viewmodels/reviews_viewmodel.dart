import 'package:bagyesrushappusernew/core/utils/app_logger.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import '../models/review.dart';
import '../repositories/review_repository.dart';
import 'reviews_state.dart';

class ReviewsViewModel extends ViewModel<ReviewsState> {
  ReviewsViewModel(this._repository) : super(const ReviewsState.initial()) {
    loadSummary();
    loadReviews();
  }

  final ReviewRepository _repository;

  static const _perPage = 20;

  Future<void> loadSummary() async {
    appLogger.d('ReviewsViewModel.loadSummary → initiated');
    final result = await _repository.getReviewsSummary();
    result.fold(
      (failure) => appLogger.w(
        'ReviewsViewModel.loadSummary → error: ${failure.message}',
      ),
      (summary) => emit(state.copyWith(summary: summary)),
    );
  }

  /// Reloads page 1 with the current filters — used for the initial load,
  /// pull-to-refresh, and whenever a filter changes.
  Future<void> loadReviews({bool reset = true}) async {
    appLogger.d('ReviewsViewModel.loadReviews → reset=$reset');
    if (reset) {
      emit(
        state.copyWith(
          status: ReviewsStatus.loading,
          currentPage: 1,
          clearError: true,
        ),
      );
    }

    final result = await _repository.getReviews(
      rating: state.ratingFilter,
      unanswered: state.unansweredOnly ? true : null,
      // Doc's own recommendation for the reply queue: pair `unanswered`
      // with `with_comment` so a bare star rating with no text isn't shown
      // as something needing a reply.
      withComment: state.unansweredOnly ? true : null,
      page: 1,
      perPage: _perPage,
    );

    result.fold(
      (failure) {
        appLogger.w(
          'ReviewsViewModel.loadReviews → error: ${failure.message}',
        );
        emit(
          state.copyWith(
            status: ReviewsStatus.error,
            errorMessage: failure.message,
          ),
        );
      },
      (page) {
        appLogger.i(
          'ReviewsViewModel.loadReviews → loaded ${page.items.length} reviews',
        );
        emit(
          state.copyWith(
            status: ReviewsStatus.loaded,
            reviews: page.items,
            currentPage: page.currentPage,
            hasMore: page.hasMore,
          ),
        );
      },
    );
  }

  Future<void> loadMore() async {
    if (state.status == ReviewsStatus.loadingMore || !state.hasMore) return;
    emit(state.copyWith(status: ReviewsStatus.loadingMore));

    final nextPage = state.currentPage + 1;
    final result = await _repository.getReviews(
      rating: state.ratingFilter,
      unanswered: state.unansweredOnly ? true : null,
      withComment: state.unansweredOnly ? true : null,
      page: nextPage,
      perPage: _perPage,
    );

    result.fold(
      // Load-more failures don't show an error state — the user can just
      // scroll again, matching consumer_orders' loadMore behaviour.
      (failure) {
        appLogger.w('ReviewsViewModel.loadMore → error: ${failure.message}');
        emit(state.copyWith(status: ReviewsStatus.loaded));
      },
      (page) => emit(
        state.copyWith(
          status: ReviewsStatus.loaded,
          reviews: [...state.reviews, ...page.items],
          currentPage: page.currentPage,
          hasMore: page.hasMore,
        ),
      ),
    );
  }

  Future<void> refresh() async {
    await Future.wait([loadSummary(), loadReviews(reset: true)]);
  }

  void setRatingFilter(int? rating) {
    emit(
      state.copyWith(ratingFilter: rating, clearRatingFilter: rating == null),
    );
    loadReviews(reset: true);
  }

  void setUnansweredOnly(bool value) {
    emit(state.copyWith(unansweredOnly: value));
    loadReviews(reset: true);
  }

  /// Client-side gate matching the backend's `reply` rule: `min:2,max:1000`.
  bool canSubmitReply(String text) {
    final trimmed = text.trim();
    return trimmed.length >= 2 && trimmed.length <= 1000;
  }

  /// Returns true on success, false on failure (state.replyError carries the
  /// message so the composer sheet can show it inline and stay open).
  Future<bool> submitReply({
    required Review review,
    required String reply,
  }) async {
    final trimmed = reply.trim();
    appLogger.d('ReviewsViewModel.submitReply → id=${review.id}');
    emit(state.copyWith(replyingReviewId: review.id, clearReplyError: true));

    final result = await _repository.replyToReview(
      reviewId: review.id,
      reply: trimmed,
    );

    return result.fold(
      (failure) {
        appLogger.w('ReviewsViewModel.submitReply → error: ${failure.message}');
        emit(
          state.copyWith(
            clearReplyingReviewId: true,
            replyError: failure.message,
          ),
        );
        return false;
      },
      (updated) {
        // The doc doesn't say whether the response carries the updated
        // review — patch locally with what was just sent when it doesn't.
        final patched =
            updated ?? review.copyWith(reply: trimmed, repliedAt: DateTime.now());
        final updatedList = state.reviews
            .map((r) => r.id == patched.id ? patched : r)
            .toList();
        appLogger.i('ReviewsViewModel.submitReply → success, id=${review.id}');
        emit(
          state.copyWith(
            reviews: updatedList,
            clearReplyingReviewId: true,
            clearReplyError: true,
          ),
        );
        return true;
      },
    );
  }
}
