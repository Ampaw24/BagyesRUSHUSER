import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../constant/app_theme.dart';

class KYCPromptBanner extends StatelessWidget {
  final VoidCallback onTap;

  const KYCPromptBanner({
    super.key,
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
          gradient: LinearGradient(
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(w * 0.04),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(w * 0.025),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedLockPassword,
                color: Colors.white,
                size: w * 0.055,
              ),
            ),
            SizedBox(width: w * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Your Profile',
                    style: TextStyle(
                      fontSize: w * 0.038,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Mukta',
                    ),
                  ),
                  SizedBox(height: w * 0.005),
                  Text(
                    'Verify your identity and setup payouts to start receiving orders.',
                    style: TextStyle(
                      fontSize: w * 0.029,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: w * 0.02),
            Container(
              padding: EdgeInsets.all(w * 0.015),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(w * 0.02),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.primary,
                size: w * 0.035,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
