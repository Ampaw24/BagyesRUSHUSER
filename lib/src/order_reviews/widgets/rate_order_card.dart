import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_target.dart';
import 'package:bagyesrushappusernew/src/order_reviews/viewmodels/order_reviews_viewmodel.dart';
import 'package:bagyesrushappusernew/src/order_reviews/views/order_review_sheet.dart';
import 'package:bagyesrushappusernew/src/order_reviews/widgets/star_rating_input.dart';
import 'package:bagyesrushappusernew/src/vendor_reviews/models/review.dart';
import 'package:bagyesrushappusernew/src/vendor_reviews/widgets/rating_stars.dart';

/// Tracking-screen card for a delivered order: tap-to-rate stars that open
/// [OrderReviewSheet] pre-filled, or — once rated — the customer's review
/// and any public reply from the vendor.
class RateOrderCard extends StatelessWidget {
  const RateOrderCard({super.key, required this.order});

  final ConsumerOrder order;

  @override
  Widget build(BuildContext context) {
    final review = context.select<OrderReviewsViewModel, Review?>(
      (vm) => vm.reviewFor(order.id),
    );
    final target = ReviewTarget.fromOrder(order);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: review == null
          ? _RatePrompt(key: const ValueKey('prompt'), target: target)
          : _YourReview(
              key: const ValueKey('review'),
              target: target,
              review: review,
            ),
    );
  }
}

BoxDecoration _cardDecoration(double w, {Color? tint}) => BoxDecoration(
  color: tint ?? AppColors.card,
  borderRadius: BorderRadius.circular(w * 0.04),
  border: Border.all(color: AppColors.border, width: 0.6),
  boxShadow: [
    BoxShadow(
      color: AppColors.secondary.withValues(alpha: 0.06),
      blurRadius: w * 0.025,
      offset: Offset(0, w * 0.008),
    ),
  ],
);

class _RatePrompt extends StatelessWidget {
  const _RatePrompt({super.key, required this.target});

  final ReviewTarget target;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: w * 0.05, horizontal: w * 0.04),
      decoration: _cardDecoration(
        w,
        tint: AppColors.accent.withValues(alpha: 0.06),
      ),
      child: Column(
        children: [
          Text(
            target.isRider ? 'How was your delivery?' : 'How was your order?',
            style: TextStyle(
              fontSize: w * 0.045,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.01),
          Text(
            target.hasNamedRider
                ? 'Tap a star to rate ${target.name}, your rider'
                : 'Tap a star to rate ${target.name}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: w * 0.033,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: w * 0.03),
          StarRatingInput(
            rating: 0,
            starSizeFactor: 0.09,
            showCaption: false,
            onChanged: (rating) => OrderReviewSheet.show(
              context,
              target: target,
              initialRating: rating,
            ),
          ),
        ],
      ),
    );
  }
}

class _YourReview extends StatelessWidget {
  const _YourReview({super.key, required this.target, required this.review});

  final ReviewTarget target;
  final Review review;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final comment = review.comment?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: _cardDecoration(w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_rounded,
                color: AppColors.success,
                size: w * 0.05,
              ),
              SizedBox(width: w * 0.02),
              Expanded(
                child: Text(
                  target.isRider
                      ? 'You rated your rider'
                      : 'You rated this order',
                  style: TextStyle(
                    fontSize: w * 0.038,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              RatingStars(rating: review.rating, size: w * 0.045),
            ],
          ),
          if (comment.isNotEmpty) ...[
            SizedBox(height: w * 0.025),
            Text(
              '“$comment”',
              style: TextStyle(
                fontSize: w * 0.035,
                height: 1.4,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (review.hasReply) ...[
            SizedBox(height: w * 0.03),
            _VendorReply(vendorName: target.name, reply: review.reply!),
          ],
        ],
      ),
    );
  }
}

class _VendorReply extends StatelessWidget {
  const _VendorReply({required this.vendorName, required this.reply});

  final String vendorName;
  final String reply;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.035),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border(
          left: BorderSide(color: AppColors.primary, width: w * 0.008),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Response from $vendorName',
            style: TextStyle(
              fontSize: w * 0.032,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.01),
          Text(
            reply,
            style: TextStyle(
              fontSize: w * 0.033,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
