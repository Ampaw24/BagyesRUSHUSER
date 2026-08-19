import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../../constant/app_theme.dart';
import '../../../../../src/notification/model/notification.model.dart';

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
                  backgroundColor: _avatarBg(notification.type),
                  child: Text(
                    _initials,
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

  void _showDeleteSheet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.05)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: w * 0.03),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: w * 0.12,
                  height: 4,
                  margin: EdgeInsets.only(bottom: w * 0.05),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    color: AppColors.error,
                    size: w * 0.055,
                  ),
                  title: Text(
                    'Delete notification',
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: w * 0.038,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    onDelete?.call();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _avatarBg(String type) {
    return switch (type) {
      'order_placed' => AppColors.primary.withValues(alpha: 0.12),
      'delivery' => AppColors.success.withValues(alpha: 0.12),
      'promo' => AppColors.accent.withValues(alpha: 0.15),
      _ => AppColors.secondary.withValues(alpha: 0.1),
    };
  }

  Color _avatarFg(String type) {
    return switch (type) {
      'order_placed' => AppColors.primary,
      'delivery' => AppColors.success,
      'promo' => AppColors.warning,
      _ => AppColors.secondary,
    };
  }

  Color _iconBg(String type) {
    return switch (type) {
      'order_placed' => AppColors.primary.withValues(alpha: 0.1),
      'delivery' => AppColors.success.withValues(alpha: 0.1),
      'promo' => AppColors.accent.withValues(alpha: 0.12),
      _ => AppColors.surfaceVariant,
    };
  }

  Color _iconColor(String type) {
    return switch (type) {
      'order_placed' => AppColors.primary,
      'delivery' => AppColors.success,
      'promo' => AppColors.warning,
      _ => AppColors.textSecondary,
    };
  }

  List<List<dynamic>> _typeIcon(String type) {
    return switch (type) {
      'order_placed' => HugeIcons.strokeRoundedReceiptDollar,
      'order_update' => HugeIcons.strokeRoundedDeliveryBox01,
      'delivery' => HugeIcons.strokeRoundedDeliveryTracking01,
      'promo' => HugeIcons.strokeRoundedTag01,
      _ => HugeIcons.strokeRoundedNotification01,
    };
  }
}
