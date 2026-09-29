import 'package:equatable/equatable.dart';

import 'package:bagyesrushappusernew/src/order_reviews/models/order_review.dart';

enum OrderReviewsStatus { initial, loading, loaded, error }

/// The customer's own reviews, keyed by order id. A load error keeps any
/// reviews recorded this session — rating still works, only the
/// "already rated" hint for older orders is missing.
class OrderReviewsState extends Equatable {
  const OrderReviewsState({
    this.status = OrderReviewsStatus.initial,
    this.byOrderId = const {},
  });

  final OrderReviewsStatus status;
  final Map<String, OrderReview> byOrderId;

  OrderReviewsState copyWith({
    OrderReviewsStatus? status,
    Map<String, OrderReview>? byOrderId,
  }) => OrderReviewsState(
    status: status ?? this.status,
    byOrderId: byOrderId ?? this.byOrderId,
  );

  @override
  List<Object?> get props => [status, byOrderId];
}
