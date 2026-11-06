import 'package:flutter/material.dart';

import 'package:gopady/constant/app_theme.dart';
import 'package:gopady/src/order_reviews/models/review_target.dart';
import 'package:gopady/core/widgets/app_status_animation.dart';

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
          AppStatusAnimation(
            AppStatus.success,
            size: (w * 0.3).clamp(96.0, 160.0),
            semanticLabel: 'Review submitted',
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
            switch (target.partyFor(ReviewSubject.vendor)) {
              final vendor? =>
                'Your review helps ${vendor.name} and other customers.',
              null => 'Your rating helps keep deliveries great.',
            },
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
