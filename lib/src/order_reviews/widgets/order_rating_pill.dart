import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_target.dart';
import 'package:bagyesrushappusernew/src/order_reviews/viewmodels/order_reviews_viewmodel.dart';
import 'package:bagyesrushappusernew/src/order_reviews/views/order_review_sheet.dart';

/// Order-history pill for a delivered order: "Rate" opens the review sheet;
/// once rated it becomes a read-only "★ 4" badge (the restaurant's rating
/// when given, else the rider's). Only this pill rebuilds when the reviews
/// cache changes.
class OrderRatingPill extends StatelessWidget {
  const OrderRatingPill({super.key, required this.order});

  final ConsumerOrder order;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final (isRated, rating) = context.select<OrderReviewsViewModel, (bool, int?)>(
      (vm) => (vm.isReviewed(order.id), vm.reviewFor(order.id)?.primaryRating),
    );
    final color = isRated ? AppColors.accent : AppColors.primary;

    final pill = Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.025, vertical: w * 0.01),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(w * 0.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRated ? Icons.star_rounded : Icons.star_outline_rounded,
            size: w * 0.038,
            color: color,
          ),
          SizedBox(width: w * 0.01),
          Text(
            isRated ? (rating == null ? 'Rated' : '$rating') : 'Rate',
            style: TextStyle(
              fontSize: w * 0.031,
              fontWeight: FontWeight.w700,
              color: isRated ? AppColors.textPrimary : color,
            ),
          ),
        ],
      ),
    );

    if (isRated) {
      return Semantics(
        label: rating == null
            ? 'You rated this order'
            : 'You rated this $rating stars',
        child: pill,
      );
    }
    return Semantics(
      button: true,
      label: 'Rate this order',
      child: GestureDetector(
        onTap: () => OrderReviewSheet.show(
          context,
          target: ReviewTarget.fromOrder(order),
        ),
        child: pill,
      ),
    );
  }
}
