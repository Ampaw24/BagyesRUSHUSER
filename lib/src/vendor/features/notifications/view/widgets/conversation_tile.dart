import 'package:flutter/material.dart';
import '../../../../../../constant/app_theme.dart';
import '../../models/vendor_conversation.dart';

/// Single Responsibility: renders one conversation row.
class ConversationTile extends StatelessWidget {
  final VendorConversation conversation;
  final VoidCallback? onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hasUnread = conversation.unreadCount > 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.05,
          vertical: w * 0.038,
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: w * 0.055,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
              child: Text(
                conversation.participantInitials,
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: w * 0.033,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ),
            SizedBox(width: w * 0.035),
            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.participantName,
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: w * 0.038,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessageAt),
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: w * 0.028,
                          color: hasUnread
                              ? AppColors.primary
                              : AppColors.textHint,
                          fontWeight: hasUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: w * 0.008),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: w * 0.032,
                            color: hasUnread
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread) ...[
                        SizedBox(width: w * 0.02),
                        AnimatedScale(
                          scale: 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            constraints: BoxConstraints(
                              minWidth: w * 0.048,
                              minHeight: w * 0.048,
                            ),
                            padding: EdgeInsets.all(w * 0.008),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${conversation.unreadCount}',
                                style: TextStyle(
                                  fontFamily: 'Mukta',
                                  fontSize: w * 0.026,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (conversation.participantRole != null) ...[
                    SizedBox(height: w * 0.005),
                    Text(
                      conversation.participantRole!,
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: w * 0.027,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
