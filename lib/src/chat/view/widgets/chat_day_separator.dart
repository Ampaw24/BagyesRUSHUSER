import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'message_grouping.dart';

/// Centered "Today" / "Yesterday" / date pill between days in a thread.
class ChatDaySeparator extends StatelessWidget {
  const ChatDaySeparator({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.03),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.03,
            vertical: w * 0.01,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(w),
            border: Border.all(color: AppColors.divider),
          ),
          child: Text(
            chatDayLabel(date),
            style: TextStyle(
              fontSize: w * 0.028,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
