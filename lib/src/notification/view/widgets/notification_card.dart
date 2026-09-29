import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/widgets/delete_action_sheet.dart';
import 'package:bagyesrushappusernew/src/notification/model/notification.model.dart';
import 'package:bagyesrushappusernew/src/notification/utils/notification_style.dart';

/// Card-style notification row with press feedback and an animated
/// unread → read transition. Long-press opens the delete sheet.
class NotificationCard extends StatefulWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDelete,
  });

  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  static const _stateDuration = Duration(milliseconds: 300);

  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _onLongPress() {
    HapticFeedback.mediumImpact();
    DeleteActionSheet.show(context, onDelete: () => widget.onDelete?.call());
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final notification = widget.notification;
    final isUnread = !notification.isRead;
    final radius = BorderRadius.circular(w * 0.045);
    final accent = NotificationStyle.avatarFg(notification.type);

    return AnimatedScale(
      scale: _pressed ? 0.975 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: _stateDuration,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isUnread
              ? Color.alphaBlend(
                  AppColors.primary.withValues(alpha: 0.035),
                  AppColors.card,
                )
              : AppColors.card,
          borderRadius: radius,
          border: Border.all(
            color: isUnread
                ? AppColors.primary.withValues(alpha: 0.18)
                : AppColors.divider,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary
                  .withValues(alpha: isUnread ? 0.07 : 0.04),
              blurRadius: w * 0.04,
              offset: Offset(0, w * 0.01),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: widget.onTap,
            onLongPress: widget.onDelete == null ? null : _onLongPress,
            onHighlightChanged: _setPressed,
            splashColor: accent.withValues(alpha: 0.08),
            highlightColor: accent.withValues(alpha: 0.04),
            child: Padding(
              padding: EdgeInsets.all(w * 0.035),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TypeIcon(type: notification.type, isUnread: isUnread),
                  SizedBox(width: w * 0.032),
                  Expanded(
                    child: _CardContent(
                      notification: notification,
                      isUnread: isUnread,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Leading type icon with unread dot ───────────────────────────────────────

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type, required this.isUnread});

  final String type;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = w * 0.115;
    final dotSize = w * 0.03;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: NotificationStyle.avatarBg(type),
                borderRadius: BorderRadius.circular(w * 0.032),
              ),
              child: Center(
                child: HugeIcon(
                  icon: NotificationStyle.icon(type),
                  color: NotificationStyle.avatarFg(type),
                  size: w * 0.055,
                ),
              ),
            ),
          ),
          Positioned(
            top: -dotSize * 0.25,
            right: -dotSize * 0.25,
            child: AnimatedScale(
              scale: isUnread ? 1 : 0,
              duration: const Duration(milliseconds: 260),
              curve: isUnread ? Curves.easeOutBack : Curves.easeIn,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.card, width: w * 0.005),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Title, body, type chip and timestamp ────────────────────────────────────

class _CardContent extends StatelessWidget {
  const _CardContent({required this.notification, required this.isUnread});

  final NotificationModel notification;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final title =
        notification.title.isNotEmpty ? notification.title : 'Notification';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: w * 0.037,
            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (notification.body.isNotEmpty) ...[
          SizedBox(height: w * 0.006),
          Text(
            notification.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: w * 0.032,
              height: 1.35,
              fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ],
        SizedBox(height: w * 0.022),
        Row(
          children: [
            Flexible(child: _TypeChip(type: notification.type)),
            const Spacer(),
            AnimatedDefaultTextStyle(
              duration: _NotificationCardState._stateDuration,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.028,
                fontWeight: isUnread ? FontWeight.w600 : FontWeight.w400,
                color: isUnread ? AppColors.primary : AppColors.textHint,
              ),
              child: Text(
                NotificationStyle.relativeTime(notification.createdAt),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.022,
        vertical: w * 0.004,
      ),
      decoration: BoxDecoration(
        color: NotificationStyle.iconBg(type),
        borderRadius: BorderRadius.circular(w),
      ),
      child: Text(
        NotificationStyle.label(type),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Mukta',
          fontSize: w * 0.026,
          fontWeight: FontWeight.w600,
          color: NotificationStyle.iconColor(type),
        ),
      ),
    );
  }
}
