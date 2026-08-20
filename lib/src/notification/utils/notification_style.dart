import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../constant/app_theme.dart';

/// Maps a [NotificationModel.type] to its display color, icon and label.
/// Shared by the notification list tile and the notification details screen
/// so the two stay visually consistent.
abstract final class NotificationStyle {
  static Color avatarBg(String type) => switch (type) {
        'order_placed' || 'new_order' => AppColors.primary.withValues(alpha: 0.12),
        'delivery' || 'payment' => AppColors.success.withValues(alpha: 0.12),
        'promo' => AppColors.accent.withValues(alpha: 0.15),
        _ => AppColors.secondary.withValues(alpha: 0.1),
      };

  static Color avatarFg(String type) => switch (type) {
        'order_placed' || 'new_order' => AppColors.primary,
        'delivery' || 'payment' => AppColors.success,
        'promo' => AppColors.warning,
        _ => AppColors.secondary,
      };

  static Color iconBg(String type) => switch (type) {
        'order_placed' || 'new_order' => AppColors.primary.withValues(alpha: 0.1),
        'delivery' || 'payment' => AppColors.success.withValues(alpha: 0.1),
        'promo' => AppColors.accent.withValues(alpha: 0.12),
        _ => AppColors.surfaceVariant,
      };

  static Color iconColor(String type) => switch (type) {
        'order_placed' || 'new_order' => AppColors.primary,
        'delivery' || 'payment' => AppColors.success,
        'promo' => AppColors.warning,
        _ => AppColors.textSecondary,
      };

  static List<List<dynamic>> icon(String type) => switch (type) {
        'order_placed' || 'new_order' => HugeIcons.strokeRoundedReceiptDollar,
        'order_update' => HugeIcons.strokeRoundedDeliveryBox01,
        'delivery' => HugeIcons.strokeRoundedDeliveryTracking01,
        'payment' => HugeIcons.strokeRoundedMoneyBag01,
        'promo' => HugeIcons.strokeRoundedTag01,
        _ => HugeIcons.strokeRoundedNotification01,
      };

  static String label(String type) => switch (type) {
        'order_placed' => 'Order Placed',
        'new_order' => 'New Order',
        'order_update' => 'Order Update',
        'delivery' => 'Delivery',
        'payment' => 'Payment',
        'promo' => 'Promotion',
        _ => 'Notification',
      };

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', //
  ];

  /// Compact relative time e.g. "5m ago", "3h ago", "2d ago".
  static String relativeTime(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Full absolute timestamp e.g. "Aug 19, 2026 · 3:45 PM".
  static String fullTimestamp(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final minute = local.minute.toString().padLeft(2, '0');
    return '${_months[local.month - 1]} ${local.day}, ${local.year} · '
        '$hour12:$minute $period';
  }
}
