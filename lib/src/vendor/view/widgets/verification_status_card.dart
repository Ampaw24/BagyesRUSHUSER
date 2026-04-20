import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../constant/app_theme.dart';

class VerificationStatusCard extends StatelessWidget {
  final bool isVerified;
  final VoidCallback onTap;

  const VerificationStatusCard({
    super.key,
    required this.isVerified,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(w * 0.04),
        decoration: BoxDecoration(
          color: isVerified
              ? AppColors.success.withValues(alpha: 0.08)
              : AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(
            color: isVerified
                ? AppColors.success.withValues(alpha: 0.2)
                : AppColors.warning.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.02),
              decoration: BoxDecoration(
                color: isVerified ? AppColors.success : AppColors.warning,
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: isVerified
                    ? HugeIcons.strokeRoundedCheckmarkBadge01
                    : HugeIcons.strokeRoundedAlert01,
                color: Colors.white,
                size: w * 0.045,
              ),
            ),
            SizedBox(width: w * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVerified ? 'Account Verified' : 'Action Required',
                    style: TextStyle(
                      fontSize: w * 0.038,
                      fontWeight: FontWeight.w700,
                      color: isVerified ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  SizedBox(height: w * 0.005),
                  Text(
                    isVerified
                        ? 'Your business is fully verified and compliant.'
                        : 'Please complete your document verification.',
                    style: TextStyle(
                      fontSize: w * 0.03,
                      color: isVerified
                          ? AppColors.success
                          : AppColors.warning.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (!isVerified)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.warning,
                size: w * 0.035,
              ),
          ],
        ),
      ),
    );
  }
}
