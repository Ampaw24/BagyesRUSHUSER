import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_target.dart';
import 'package:bagyesrushappusernew/src/order_reviews/viewmodels/order_reviews_viewmodel.dart';
import 'package:bagyesrushappusernew/src/order_reviews/views/order_review_sheet.dart';
import 'package:bagyesrushappusernew/src/order_reviews/widgets/star_rating_input.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/order_review.dart';
import 'package:bagyesrushappusernew/src/vendor_reviews/widgets/rating_stars.dart';

/// Tracking-screen card for a delivered order: tap-to-rate stars that open
/// [OrderReviewSheet] pre-filled, or — once rated — the customer's rating
/// for each party and any public reply from the vendor.
class RateOrderCard extends StatelessWidget {
  const RateOrderCard({super.key, required this.order});

  final ConsumerOrder order;

  @override
  Widget build(BuildContext context) {
    final review = context.select<OrderReviewsViewModel, OrderReview?>(
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
    final primary = target.primary;
    final rider = target.parties.length > 1
        ? target.partyFor(ReviewSubject.rider)
        : null;
    final primaryName = primary.hasNamedRider
        ? '${primary.name}, your rider'
        : primary.name;

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
            target.isParcel ? 'How was your delivery?' : 'How was your order?',
            style: TextStyle(
              fontSize: w * 0.045,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.01),
          Text(
            rider == null
                ? 'Tap a star to rate $primaryName'
                : 'Tap a star to rate $primaryName — you can rate '
                    '${rider.name} too',
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
  final OrderReview review;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final vendor = target.partyFor(ReviewSubject.vendor);
    final rated = [
      for (final party in target.parties)
        if (review.ratingFor(party.subject) case final rating?)
          (party, rating),
    ];

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
              Text(
                'You rated this ${target.isParcel ? 'delivery' : 'order'}',
                style: TextStyle(
                  fontSize: w * 0.038,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          for (final (party, rating) in rated) ...[
            SizedBox(height: w * 0.03),
            _PartyRating(party: party, rating: rating),
          ],
          if (review.hasVendorReply && vendor != null) ...[
            SizedBox(height: w * 0.03),
            _VendorReply(vendorName: vendor.name, reply: review.vendorReply!),
          ],
        ],
      ),
    );
  }
}

class _PartyRating extends StatelessWidget {
  const _PartyRating({required this.party, required this.rating});

  final ReviewParty party;
  final SubjectRating rating;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final comment = rating.comment?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                party.isRider
                    ? (party.hasNamedRider ? party.name : 'Your rider')
                    : party.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: w * 0.034,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            RatingStars(rating: rating.rating, size: w * 0.042),
          ],
        ),
        if (comment.isNotEmpty) ...[
          SizedBox(height: w * 0.012),
          Text(
            '“$comment”',
            style: TextStyle(
              fontSize: w * 0.034,
              height: 1.4,
              fontStyle: FontStyle.italic,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
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
