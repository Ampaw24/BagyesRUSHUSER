import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/src/chat/model/chat_message.dart';
import 'chat_avatar.dart';
import 'chat_dimensions.dart';

String _formatTime(DateTime dt) {
  final local = dt.toLocal();
  final hour24 = local.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = hour24 < 12 ? 'AM' : 'PM';
  return '$hour12:$minute $period';
}

/// Diameter of the peer avatar beside their bubbles, as a fraction of the
/// chat scale width.
const double peerAvatarSizeFactor = 0.075;

/// A single chat bubble — right-aligned/primary for [ChatMessage.isMine],
/// left-aligned/white otherwise. Own messages carry a small delivery
/// indicator (sending/sent/read/failed) instead of a sender label.
///
/// Consecutive bubbles from the same side form a group: they sit close
/// together and join with tight corners on the sender's side. The peer's
/// avatar sits beside the last bubble of their group (other bubbles in the
/// group reserve its space so the column stays aligned).
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.peerName,
    this.peerPhotoUrl,
    this.isRead = false,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.animateIn = false,
    this.onRetry,
  });

  final ChatMessage message;
  final String peerName;
  final String? peerPhotoUrl;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  /// Plays the arrival animation — only for messages that appear while the
  /// thread is open, never for history.
  final bool animateIn;

  /// True once the peer's `conversation.read` timestamp is at/after this
  /// (own) message's `createdAt` — swaps the sent tick for a read tick.
  final bool isRead;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final w = chatScaleWidth(context);
    final isMine = message.isMine;
    final failed = message.deliveryStatus == MessageDeliveryStatus.failed;
    final round = Radius.circular(w * 0.045);
    final tight = Radius.circular(w * 0.012);
    // Sender's side: the top corner joins the bubble above within a group;
    // the bottom corner is always tight (joined, or the group's tail).
    final senderTop = isFirstInGroup ? round : tight;
    final foreground = isMine && !failed ? Colors.white : AppColors.textPrimary;

    Widget bubble = Container(
      constraints: BoxConstraints(maxWidth: w * 0.72),
      padding: EdgeInsets.fromLTRB(w * 0.035, w * 0.022, w * 0.035, w * 0.018),
      decoration: BoxDecoration(
        color: failed
            ? AppColors.error.withValues(alpha: 0.08)
            : isMine
                ? AppColors.primary
                : AppColors.card,
        borderRadius: BorderRadius.only(
          topLeft: isMine ? round : senderTop,
          topRight: isMine ? senderTop : round,
          bottomLeft: isMine ? round : tight,
          bottomRight: isMine ? tight : round,
        ),
        border: failed
            ? Border.all(color: AppColors.error, width: 0.8)
            : isMine
                ? null
                : Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: isMine ? 0.1 : 0.04),
            blurRadius: w * 0.02,
            offset: Offset(0, w * 0.005),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.body,
            style: TextStyle(fontSize: w * 0.037, height: 1.35, color: foreground),
          ),
          SizedBox(height: w * 0.008),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: w * 0.025,
                  color: isMine && !failed
                      ? Colors.white.withValues(alpha: 0.75)
                      : AppColors.textHint,
                ),
              ),
              if (isMine) ...[
                SizedBox(width: w * 0.01),
                _DeliveryIcon(
                  status: message.deliveryStatus,
                  isRead: isRead,
                  size: w * 0.034,
                ),
              ],
            ],
          ),
        ],
      ),
    );

    if (failed && onRetry != null) {
      bubble = GestureDetector(
        onTap: onRetry,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            bubble,
            SizedBox(height: w * 0.008),
            Text(
              'Not sent · Tap to retry',
              style: TextStyle(
                fontSize: w * 0.026,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      );
    }

    final avatarSize = w * peerAvatarSizeFactor;
    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? w * 0.025 : w * 0.006,
        bottom: isLastInGroup ? w * 0.004 : 0,
      ),
      child: _BubbleEntrance(
        animate: animateIn,
        isMine: isMine,
        child: Row(
          mainAxisAlignment:
              isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMine) ...[
              SizedBox.square(
                dimension: avatarSize,
                child: isLastInGroup
                    ? ChatAvatar(
                        name: peerName,
                        photoUrl: peerPhotoUrl,
                        size: avatarSize,
                      )
                    : null,
              ),
              SizedBox(width: w * 0.02),
            ],
            Flexible(child: bubble),
          ],
        ),
      ),
    );
  }
}

/// Fades a new bubble in while it slides up from its sender's side and
/// scales out of its tail corner.
class _BubbleEntrance extends StatefulWidget {
  const _BubbleEntrance({
    required this.animate,
    required this.isMine,
    required this.child,
  });

  final bool animate;
  final bool isMine;
  final Widget child;

  @override
  State<_BubbleEntrance> createState() => _BubbleEntranceState();
}

class _BubbleEntranceState extends State<_BubbleEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: widget.animate ? 0 : 1,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(widget.isMine ? 0.08 : -0.08, 0.3),
    end: Offset.zero,
  ).animate(_curve);
  late final Animation<double> _scale =
      Tween<double>(begin: 0.92, end: 1).animate(_curve);

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.forward();
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          alignment:
              widget.isMine ? Alignment.bottomRight : Alignment.bottomLeft,
          child: widget.child,
        ),
      ),
    );
  }
}

class _DeliveryIcon extends StatelessWidget {
  const _DeliveryIcon({
    required this.status,
    required this.isRead,
    required this.size,
  });

  final MessageDeliveryStatus status;
  final bool isRead;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (status) {
      MessageDeliveryStatus.sending => (
          HugeIcons.strokeRoundedClock01,
          Colors.white.withValues(alpha: 0.75),
        ),
      // One tick once the server has it, two once the peer has read it.
      MessageDeliveryStatus.sent => (
          isRead
              ? HugeIcons.strokeRoundedTickDouble01
              : HugeIcons.strokeRoundedTick01,
          Colors.white.withValues(alpha: isRead ? 1 : 0.75),
        ),
      MessageDeliveryStatus.failed => (
          HugeIcons.strokeRoundedAlertCircle,
          AppColors.error,
        ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          ScaleTransition(scale: animation, child: child),
      child: HugeIcon(
        key: ValueKey((status, isRead)),
        icon: icon,
        size: size,
        color: color,
      ),
    );
  }
}
