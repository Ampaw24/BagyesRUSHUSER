import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/core/router/app_navigator.dart';
import 'tracking_card.dart';

/// "Track order" title bar: outlined back button, title + subtitle, and
/// optional trailing [actions].
class TrackingHeader extends StatelessWidget {
  const TrackingHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  void _goBack(BuildContext context) {
    HapticFeedback.lightImpact();
    context.canPop() ? context.pop() : AppNavigator.toHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final subtitle = this.subtitle;

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.03),
      child: Row(
        children: [
          TrackingCircleButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: () => _goBack(context),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: w * 0.052,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.031,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          for (final action in actions) ...[
            SizedBox(width: w * 0.02),
            action,
          ],
        ],
      ),
    );
  }
}
