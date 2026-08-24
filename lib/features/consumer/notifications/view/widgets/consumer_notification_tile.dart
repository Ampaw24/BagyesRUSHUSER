import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../../constant/app_theme.dart';
import '../../../../../core/widgets/delete_action_sheet.dart';
import '../../../../../src/notification/model/notification.model.dart';
import '../../../../../src/notification/utils/notification_style.dart';

class ConsumerNotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ConsumerNotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  String get _displayTitle =>
      notification.title.isNotEmpty ? notification.title : 'Notification';

  String get _initials =>
      _displayTitle.isNotEmpty ? _displayTitle[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isUnread = !notification.isRead;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete == null ? null : () => _showDeleteSheet(context),
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
                  backgroundColor: NotificationStyle.avatarBg(notification.type),
                  child: Text(
                    _initials,
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: w * 0.033,
                      fontWeight: FontWeight.w700,
                      color: NotificationStyle.avatarFg(notification.type),
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
                          _displayTitle,
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
                        NotificationStyle.relativeTime(notification.createdAt),
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
                color: NotificationStyle.iconBg(notification.type),
                borderRadius: BorderRadius.circular(w * 0.025),
              ),
              child: HugeIcon(
                icon: NotificationStyle.icon(notification.type),
                size: w * 0.04,
                color: NotificationStyle.iconColor(notification.type),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteSheet(BuildContext context) {
    DeleteActionSheet.show(context, onDelete: () => onDelete?.call());
  }
}
