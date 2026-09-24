import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import '../models/review_summary.dart';
import 'rating_stars.dart';

/// Big average-rating number + star breakdown, for the top of the Reviews
/// screen — the vendor's at-a-glance reputation snapshot.
class ReviewSummaryHeader extends StatelessWidget {
  const ReviewSummaryHeader({super.key, required this.summary});

  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final maxCount = summary.ratingBreakdown.values.isEmpty
        ? 0
        : summary.ratingBreakdown.values.reduce((a, b) => a > b ? a : b);

    return Container(
      margin: EdgeInsets.fromLTRB(w * 0.04, w * 0.03, w * 0.04, w * 0.02),
      padding: EdgeInsets.all(w * 0.045),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(w * 0.045),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: w * 0.11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.0,
                      fontFamily: 'Mukta',
                    ),
                  ),
                  SizedBox(height: w * 0.014),
                  RatingStars(
                    rating: summary.averageRating.round(),
                    size: w * 0.042,
                  ),
                  SizedBox(height: w * 0.012),
                  Text(
                    '${summary.totalReviews} review${summary.totalReviews == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: w * 0.03,
                      color: AppColors.textSecondary,
                      fontFamily: 'Mukta',
                    ),
                  ),
                ],
              ),
              SizedBox(width: w * 0.06),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final star in [5, 4, 3, 2, 1])
                      Padding(
                        padding: EdgeInsets.only(bottom: w * 0.014),
                        child: _BreakdownRow(
                          star: star,
                          count: summary.ratingBreakdown[star] ?? 0,
                          maxCount: maxCount,
                          w: w,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (summary.unansweredCount > 0) ...[
            SizedBox(height: w * 0.035),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.032,
                vertical: w * 0.02,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(w * 0.03),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: w * 0.038,
                    color: AppColors.warning,
                  ),
                  SizedBox(width: w * 0.02),
                  Text(
                    '${summary.unansweredCount} awaiting reply',
                    style: TextStyle(
                      fontSize: w * 0.031,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                      fontFamily: 'Mukta',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.star,
    required this.count,
    required this.maxCount,
    required this.w,
  });

  final int star;
  final int count;
  final int maxCount;
  final double w;

  @override
  Widget build(BuildContext context) {
    final fraction = maxCount == 0 ? 0.0 : count / maxCount;
    return Row(
      children: [
        Text(
          '$star',
          style: TextStyle(
            fontSize: w * 0.028,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontFamily: 'Mukta',
          ),
        ),
        SizedBox(width: w * 0.01),
        Icon(Icons.star_rounded, size: w * 0.03, color: AppColors.accent),
        SizedBox(width: w * 0.018),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.01),
            child: Stack(
              children: [
                Container(height: w * 0.016, color: AppColors.divider),
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: Container(height: w * 0.016, color: AppColors.accent),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: w * 0.02),
        SizedBox(
          width: w * 0.065,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: w * 0.027,
              color: AppColors.textHint,
              fontFamily: 'Mukta',
            ),
          ),
        ),
      ],
    );
  }
}
