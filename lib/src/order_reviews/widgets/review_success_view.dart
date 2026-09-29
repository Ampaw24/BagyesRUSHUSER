import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/order_reviews/models/review_target.dart';

/// Confirmation shown in place of the form once the review is saved.
class ReviewSuccessView extends StatelessWidget {
  const ReviewSuccessView({super.key, required this.target});

  final ReviewTarget target;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.06),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: w * 0.32,
            height: w * 0.32,
            child: Lottie.asset(
              'assets/success_loader.json',
              repeat: false,
              errorBuilder: (_, _, _) => Icon(
                Icons.check_circle_rounded,
                size: w * 0.24,
                color: AppColors.success,
              ),
            ),
          ),
          SizedBox(height: w * 0.03),
          Text(
            'Thanks for your feedback!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: w * 0.05,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.015),
          Text(
            target.isRider
                ? 'Your rating helps ${target.name} and keeps deliveries great.'
                : 'Your review helps ${target.name} and other customers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: w * 0.035,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
