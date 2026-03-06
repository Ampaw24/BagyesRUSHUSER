import 'package:flutter/material.dart';
import '../../../../constant/app_theme.dart';
import '../../models/vendor_enums.dart';

/// Animated horizontal step progress indicator
class StepProgressBar extends StatelessWidget {
  final VendorRegistrationStep currentStep;
  final Map<VendorRegistrationStep, bool> completedSteps;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.completedSteps,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final steps = VendorRegistrationStep.values;

    return Column(
      children: [
        Row(
          children: List.generate(steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              // Connector line between dots
              final stepBefore = steps[i ~/ 2];
              final isCompleted = completedSteps[stepBefore] == true;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  height: size.height * 0.003,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(size.height * 0.002),
                  ),
                ),
              );
            }

            // Step dot
            final step = steps[i ~/ 2];
            final isCurrent = step == currentStep;
            final isCompleted = completedSteps[step] == true;
            final dotSize = size.width * 0.07;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.primary
                    : isCurrent
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surfaceVariant,
                border: Border.all(
                  color: isCurrent || isCompleted
                      ? AppColors.primary
                      : AppColors.border,
                  width: isCurrent ? 2.0 : 1.5,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: dotSize * 0.55,
                      )
                    : Text(
                        '${step.index + 1}',
                        style: TextStyle(
                          fontSize: dotSize * 0.38,
                          fontWeight: FontWeight.w600,
                          color: isCurrent
                              ? AppColors.primary
                              : AppColors.textHint,
                        ),
                      ),
              ),
            );
          }),
        ),
        SizedBox(height: size.height * 0.012),
        // Step title
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            currentStep.title,
            key: ValueKey(currentStep),
            style: TextStyle(
              fontSize: size.width * 0.035,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: size.height * 0.004),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            currentStep.subtitle,
            key: ValueKey('${currentStep}_sub'),
            style: TextStyle(
              fontSize: size.width * 0.03,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
