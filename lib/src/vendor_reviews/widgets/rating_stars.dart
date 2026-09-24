import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';

/// Row of 5 stars for an integer 1–5 rating. `size` is caller-supplied so
/// the same widget serves both the summary header (large) and each review
/// row (small).
class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, required this.size});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: filled ? AppColors.accent : AppColors.border,
        );
      }),
    );
  }
}
