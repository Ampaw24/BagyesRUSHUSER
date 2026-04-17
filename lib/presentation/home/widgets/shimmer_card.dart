import 'package:flutter/material.dart';
import '../../../constant/app_theme.dart';

class ShimmerCard extends StatelessWidget {
  final double width;
  final double? height;

  const ShimmerCard({super.key, required this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      width: width,
      height: height ?? w * 0.62,
      decoration: BoxDecoration(
        color: AppColors.shimmerBase,
        borderRadius: BorderRadius.circular(w * 0.04),
      ),
    );
  }
}
