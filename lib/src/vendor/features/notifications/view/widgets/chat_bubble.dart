import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../../constant/app_theme.dart';
import '../../models/vendor_chat_message.dart';

/// Single Responsibility: renders a single chat message bubble.
class ChatBubble extends StatelessWidget {
  final VendorChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isVendor = message.isFromVendor;

    return Padding(
      padding: EdgeInsets.only(
        left: isVendor ? w * 0.2 : w * 0.05,
        right: isVendor ? w * 0.05 : w * 0.2,
        bottom: w * 0.025,
      ),
      child: Column(
        crossAxisAlignment:
            isVendor ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.04,
              vertical: w * 0.03,
            ),
            decoration: BoxDecoration(
              color: isVendor ? AppColors.primary : AppColors.surfaceVariant,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(w * 0.04),
                topRight: Radius.circular(w * 0.04),
                bottomLeft:
                    isVendor ? Radius.circular(w * 0.04) : Radius.zero,
                bottomRight:
                    isVendor ? Radius.zero : Radius.circular(w * 0.04),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.035,
                color: isVendor ? Colors.white : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(height: w * 0.01),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.sentAt),
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: w * 0.027,
                  color: AppColors.textHint,
                ),
              ),
              if (isVendor) ...[
                SizedBox(width: w * 0.01),
                HugeIcon(
                  icon: _statusIcon(message.status),
                  size: w * 0.03,
                  color: message.status == MessageStatus.read
                      ? AppColors.info
                      : AppColors.textHint,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  List<List<dynamic>> _statusIcon(MessageStatus s) {
    return switch (s) {
      MessageStatus.read => HugeIcons.strokeRoundedTick02,
      MessageStatus.delivered => HugeIcons.strokeRoundedTick02,
      _ => HugeIcons.strokeRoundedClock01,
    };
  }
}
