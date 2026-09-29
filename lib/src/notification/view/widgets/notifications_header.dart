import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:bagyesrushappusernew/constant/app_theme.dart';

/// Title bar for the notifications screens: back button, animated unread
/// summary, and a "Mark all read" pill that only shows while there is
/// something unread. Pass a null [unreadCount] while the list is loading.
class NotificationsHeader extends StatelessWidget {
  const NotificationsHeader({
    super.key,
    required this.unreadCount,
    this.onBack,
    this.onMarkAllRead,
  });

  final int? unreadCount;
  final VoidCallback? onBack;
  final VoidCallback? onMarkAllRead;

  static const _switchDuration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final count = unreadCount;
    final showMarkAll = onMarkAllRead != null && (count ?? 0) > 0;

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, 0),
      child: Row(
        children: [
          _BackButton(onTap: onBack),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Notifications',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: w * 0.048,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                AnimatedSwitcher(
                  duration: _switchDuration,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  child: count == null
                      ? const SizedBox.shrink()
                      : Text(
                          count > 0 ? '$count unread' : "You're all caught up",
                          key: ValueKey(count),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: w * 0.03,
                            fontWeight: FontWeight.w500,
                            color: count > 0
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: _switchDuration,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: showMarkAll
                ? _MarkAllReadButton(
                    key: const ValueKey('mark-all'),
                    onTap: onMarkAllRead!,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final radius = BorderRadius.circular(w * 0.03);

    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(w * 0.022),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft02,
            color: AppColors.textPrimary,
            size: w * 0.055,
          ),
        ),
      ),
    );
  }
}

class _MarkAllReadButton extends StatelessWidget {
  const _MarkAllReadButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.03,
            vertical: w * 0.018,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedTickDouble02,
                color: AppColors.primary,
                size: w * 0.042,
              ),
              SizedBox(width: w * 0.012),
              Text(
                'Mark all read',
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: w * 0.03,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
