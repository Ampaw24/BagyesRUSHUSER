import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/parcel/viewmodel/send_parcel_viewmodel.dart';

class ParcelStepIndicator extends StatelessWidget {
  final ParcelStep currentStep;

  static const _labels = [
    'Type',
    'Details',
    'Pickup',
    'Delivery',
    'Riders',
    'Confirm',
  ];

  const ParcelStepIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final total = ParcelStep.values.length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.04),
      child: Row(
        children: List.generate(total * 2 - 1, (index) {
          if (index.isOdd) return _connector(index ~/ 2, w);
          final stepIndex = index ~/ 2;
          return _stepDot(stepIndex, w);
        }),
      ),
    );
  }

  Widget _stepDot(int stepIndex, double w) {
    final current = currentStep.index;
    final isDone = stepIndex < current;
    final isActive = stepIndex == current;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: w * 0.07,
          height: w * 0.07,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? AppColors.success
                : isActive
                    ? AppColors.primary
                    : AppColors.surfaceVariant,
            border: Border.all(
              color: isDone
                  ? AppColors.success
                  : isActive
                      ? AppColors.primary
                      : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isDone
                ? HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                    color: Colors.white,
                    size: w * 0.038,
                  )
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      fontSize: w * 0.03,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppColors.textHint,
                    ),
                  ),
          ),
        ),
        SizedBox(height: w * 0.012),
        Text(
          _labels[stepIndex],
          style: TextStyle(
            fontSize: w * 0.024,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive ? AppColors.primary : AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _connector(int precedingStep, double w) {
    final isDone = precedingStep < currentStep.index;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(bottom: w * 0.046),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 1.5,
          decoration: BoxDecoration(
            color: isDone ? AppColors.success : AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
