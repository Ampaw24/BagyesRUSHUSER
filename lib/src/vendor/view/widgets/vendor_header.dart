import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../constant/app_theme.dart';

class VendorHeader extends StatelessWidget {
  final String title;
  final String? location;
  final String initials;
  final VoidCallback? onDrawerTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;

  const VendorHeader({
    super.key,
    required this.title,
    this.location,
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
          child: Container(
            padding: EdgeInsets.all(w * 0.022),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(w * 0.03),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedMenu02,
              color: AppColors.textPrimary,
              size: w * 0.055,
            ),
          ),
        ),
        SizedBox(width: w * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: w * 0.04,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: w * 0.008),
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedLocation01,
                    color: AppColors.textSecondary,
                    size: w * 0.035,
                  ),
                  SizedBox(width: w * 0.01),
                  Expanded(
                    child: Text(
                      location ?? 'Fetching location...',
                      style: TextStyle(
                        fontSize: w * 0.03,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: onNotificationTap,
          child: Container(
            padding: EdgeInsets.all(w * 0.022),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(w * 0.03),
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedNotification01,
              color: AppColors.textPrimary,
              size: w * 0.055,
            ),
          ),
        ),
        SizedBox(width: w * 0.025),
        GestureDetector(
          onTap: onAvatarTap,
          child: CircleAvatar(
            radius: w * 0.05,
            backgroundColor: AppColors.primary,
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: w * 0.035,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
