import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/order_reviews/repositories/order_review_repository.dart';
import 'package:bagyesrushappusernew/src/order_reviews/viewmodels/order_reviews_state.dart';
import 'package:bagyesrushappusernew/src/vendor_reviews/models/review.dart';

/// App-wide cache of which orders the customer has rated — read by order
/// history, the tracking screen and the review sheet. Keyed by order id, so
/// a previous account's entries never match the next account's orders.
class OrderReviewsViewModel extends ViewModel<OrderReviewsState> {
  OrderReviewsViewModel(this._repository) : super(const OrderReviewsState());

  final OrderReviewRepository _repository;

  /// Loads once; a failed load is retried on the next call.
  Future<void> ensureLoaded() async {
    if (state.status == OrderReviewsStatus.loading ||
        state.status == OrderReviewsStatus.loaded) {
      return;
    }
    emit(state.copyWith(status: OrderReviewsStatus.loading));
    final result = await _repository.getMyReviews();
    result.fold(
      (_) => emit(state.copyWith(status: OrderReviewsStatus.error)),
      (reviews) => emit(
        state.copyWith(
          status: OrderReviewsStatus.loaded,
          // Reviews recorded this session win over the fetched list.
          byOrderId: {
            for (final r in reviews) r.orderId!: r,
            ...state.byOrderId,
          },
        ),
      ),
    );
  }

  Review? reviewFor(String orderId) => state.byOrderId[orderId];

  bool isReviewed(String orderId) => state.byOrderId.containsKey(orderId);

  ResultFuture<Review> submitReview({
    required String orderId,
    required int rating,
    String? comment,
  }) async {
    final result = await _repository.submitReview(
      orderId: orderId,
      rating: rating,
      comment: comment,
    );
    result.fold((_) {}, (review) {
      emit(state.copyWith(byOrderId: {...state.byOrderId, orderId: review}));
    });
    return result;
  }
}
