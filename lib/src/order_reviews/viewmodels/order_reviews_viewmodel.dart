import 'package:bagyesrushappusernew/core/common/app/current_user_provider.dart';
import 'package:bagyesrushappusernew/core/common/app/session_aware.dart';
import 'package:bagyesrushappusernew/core/utils/typedefs.dart';
import 'package:bagyesrushappusernew/core/viewmodel/viewmodel.dart';
import 'package:bagyesrushappusernew/src/order_reviews/repositories/order_review_repository.dart';
import 'package:bagyesrushappusernew/src/order_reviews/viewmodels/order_reviews_state.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/order_review.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_target.dart';

/// App-wide cache of which orders the customer has rated — read by order
/// history, the tracking screen and the review sheet. Keyed by order id, so
/// a previous account's entries never match the next account's orders.
class OrderReviewsViewModel extends ViewModel<OrderReviewsState>
    with SessionAware {
  OrderReviewsViewModel(this._repository, CurrentUserProvider session)
      : super(const OrderReviewsState()) {
    bindSession(session);
  }

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
            for (final r in reviews) r.orderId: r,
            ...state.byOrderId,
          },
        ),
      ),
    );
  }

  /// Back to not-loaded, so the next account's [ensureLoaded] fetches its
  /// own reviews instead of keeping the previous account's.
  @override
  void onSignedOut() => emit(const OrderReviewsState());

  OrderReview? reviewFor(String orderId) => state.byOrderId[orderId];

  bool isReviewed(String orderId) => state.byOrderId.containsKey(orderId);

  ResultFuture<OrderReview> submitReview({
    required String orderId,
    required Map<ReviewSubject, SubjectRating> ratings,
  }) async {
    final result = await _repository.submitReview(
      orderId: orderId,
      ratings: ratings,
    );
    result.fold((_) {}, (review) {
      emit(state.copyWith(byOrderId: {...state.byOrderId, orderId: review}));
    });
    return result;
  }
}
