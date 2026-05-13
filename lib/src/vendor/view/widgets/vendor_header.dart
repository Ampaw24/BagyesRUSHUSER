import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../constant/app_theme.dart';

class VendorHeader extends StatelessWidget {
  final String initials;
  final VoidCallback? onDrawerTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const VendorHeader({
    super.key,
    required this.initials,
    this.onDrawerTap,
    this.onNotificationTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Row(
      children: [
        GestureDetector(
          onTap: onDrawerTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, w * 0.01, w * 0.03, w * 0.01),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedMenu02,
              color: AppColors.textPrimary,
              size: w * 0.062,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onNotificationTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.025,
              vertical: w * 0.01,
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedNotification01,
              color: AppColors.textPrimary,
              size: w * 0.062,
            ),
          ),
        ),
        SizedBox(width: w * 0.01),
        GestureDetector(
          onTap: onAvatarTap,
          child: CircleAvatar(
            radius: w * 0.05,
            backgroundColor: AppColors.primary,
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: w * 0.036,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
