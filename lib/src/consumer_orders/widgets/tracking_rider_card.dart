import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/utils/phone_launcher.dart';
import 'package:bagyesrushappusernew/src/consumer_orders/models/consumer_order.dart';
import 'tracking_card.dart';

/// Assigned rider with chat and call actions. Only built once the order
/// has a [ConsumerOrder.driverName].
class TrackingRiderCard extends StatelessWidget {
  const TrackingRiderCard({
    super.key,
    required this.order,
    required this.onChat,
  });

  final ConsumerOrder order;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final name = order.driverName!.trim();
    final phone = order.driverPhone?.trim() ?? '';

    return TrackingCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: w * 0.07,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: TextStyle(
                fontSize: w * 0.055,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: w * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: w * 0.042,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.006),
                Text(
                  'Your delivery rider',
                  style: TextStyle(
                    fontSize: w * 0.031,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TrackingCircleButton(
            icon: Icons.chat_bubble_outline_rounded,
            tooltip: 'Chat',
            background: AppColors.success.withValues(alpha: 0.1),
            foreground: AppColors.success,
            bordered: false,
            sizeFactor: 0.12,
            onTap: () {
              HapticFeedback.lightImpact();
              onChat();
            },
          ),
          if (phone.isNotEmpty) ...[
            SizedBox(width: w * 0.025),
            TrackingCircleButton(
              icon: Icons.phone_in_talk_rounded,
              tooltip: 'Call',
              background: AppColors.primary,
              foreground: Colors.white,
              bordered: false,
              sizeFactor: 0.12,
              onTap: () {
                HapticFeedback.lightImpact();
                launchPhoneCall(context, phone);
              },
            ),
          ],
        ],
      ),
    );
  }
}
