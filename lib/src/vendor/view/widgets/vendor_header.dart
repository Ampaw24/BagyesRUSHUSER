import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../constant/app_theme.dart';

class VendorHeader extends StatelessWidget {
  final String initials;
  final String? imageUrl;
  final VoidCallback? onDrawerTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onAvatarTap;
  final bool hasUnreadNotifications;

  const VendorHeader({
    super.key,
    required this.initials,
    this.imageUrl,
    this.onDrawerTap,
    this.onNotificationTap,
    this.onAvatarTap,
    this.hasUnreadNotifications = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Row(
      children: [
        GestureDetector(
          onTap: onDrawerTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.all(w * 0.022),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(w * 0.028),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedMenu02,
              color: AppColors.textPrimary,
              size: w * 0.052,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onNotificationTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: EdgeInsets.all(w * 0.022),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(w * 0.028),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedNotification01,
                  color: AppColors.textPrimary,
                  size: w * 0.052,
                ),
                if (hasUnreadNotifications)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: w * 0.018,
                      height: w * 0.018,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(width: w * 0.03),
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
            ),
            child: CircleAvatar(
              radius: w * 0.045,
              backgroundColor: AppColors.primary,
              backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? NetworkImage(imageUrl!)
                  : null,
              child: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? null
                  : Text(
                      initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: w * 0.032,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Mukta',
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
