import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../../constant/app_theme.dart';
import '../../models/consumer_notification.dart';

class ConsumerNotificationTile extends StatelessWidget {
  final ConsumerNotification notification;
  final VoidCallback? onTap;

  const ConsumerNotificationTile({
    super.key,
    required this.notification,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.05,
          vertical: w * 0.038,
        ),
        decoration: BoxDecoration(
          color: isUnread
              ? AppColors.primary.withValues(alpha: 0.04)
              : Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with unread dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: w * 0.055,
                  backgroundColor: _avatarBg(notification.type),
                  child: Text(
                    notification.senderInitials,
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: w * 0.033,
                      fontWeight: FontWeight.w700,
                      color: _avatarFg(notification.type),
                    ),
                  ),
                ),
                if (isUnread)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: w * 0.025,
                      height: w * 0.025,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: w * 0.035),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.senderName,
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: w * 0.038,
                            fontWeight: isUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: w * 0.02),
                      Text(
                        _formatTime(notification.createdAt),
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: w * 0.028,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: w * 0.008),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: w * 0.032,
                      color: AppColors.textSecondary,
                      fontWeight:
                          isUnread ? FontWeight.w500 : FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: w * 0.025),
            // Type icon badge
            Container(
              padding: EdgeInsets.all(w * 0.018),
              decoration: BoxDecoration(
                color: _iconBg(notification.type),
                borderRadius: BorderRadius.circular(w * 0.025),
              ),
              child: HugeIcon(
                icon: _typeIcon(notification.type),
                size: w * 0.04,
                color: _iconColor(notification.type),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _avatarBg(ConsumerNotificationType t) {
    return switch (t) {
      ConsumerNotificationType.orderPlaced =>
        AppColors.primary.withValues(alpha: 0.12),
      ConsumerNotificationType.delivery =>
        AppColors.success.withValues(alpha: 0.12),
      ConsumerNotificationType.promo =>
        AppColors.accent.withValues(alpha: 0.15),
      _ => AppColors.secondary.withValues(alpha: 0.1),
    };
  }

  Color _avatarFg(ConsumerNotificationType t) {
    return switch (t) {
      ConsumerNotificationType.orderPlaced => AppColors.primary,
      ConsumerNotificationType.delivery => AppColors.success,
      ConsumerNotificationType.promo => AppColors.warning,
      _ => AppColors.secondary,
    };
  }

  Color _iconBg(ConsumerNotificationType t) {
    return switch (t) {
      ConsumerNotificationType.orderPlaced =>
        AppColors.primary.withValues(alpha: 0.1),
      ConsumerNotificationType.delivery =>
        AppColors.success.withValues(alpha: 0.1),
      ConsumerNotificationType.promo =>
        AppColors.accent.withValues(alpha: 0.12),
      _ => AppColors.surfaceVariant,
    };
  }

  Color _iconColor(ConsumerNotificationType t) {
    return switch (t) {
      ConsumerNotificationType.orderPlaced => AppColors.primary,
      ConsumerNotificationType.delivery => AppColors.success,
      ConsumerNotificationType.promo => AppColors.warning,
      _ => AppColors.textSecondary,
    };
  }

  List<List<dynamic>> _typeIcon(ConsumerNotificationType t) {
    return switch (t) {
      ConsumerNotificationType.orderPlaced =>
        HugeIcons.strokeRoundedReceiptDollar,
      ConsumerNotificationType.orderUpdate =>
        HugeIcons.strokeRoundedDeliveryBox01,
      ConsumerNotificationType.delivery =>
        HugeIcons.strokeRoundedDeliveryTracking01,
      ConsumerNotificationType.promo => HugeIcons.strokeRoundedTag01,
      _ => HugeIcons.strokeRoundedNotification01,
    };
  }
}
