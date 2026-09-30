import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'chat_dimensions.dart';

/// Server-supplied `quick_replies` as one horizontally scrolling row of
/// compact chips. A single line keeps the message history visible above
/// it — the earlier two-column tile grid grew with every reply and, with
/// the keyboard open, left almost no room for the conversation.
class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({
    super.key,
    required this.replies,
    required this.onSelected,
  });

  final List<String> replies;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();
    final w = chatScaleWidth(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(w * 0.04, w * 0.025, w * 0.04, w * 0.02),
      child: Row(
        children: [
          for (final reply in replies)
            Padding(
              padding: EdgeInsets.only(right: w * 0.02),
              child: _QuickReplyChip(
                label: reply,
                onTap: () => onSelected(reply),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = chatScaleWidth(context);
    final shape = StadiumBorder(
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
    );

    return ConstrainedBox(
      // Long replies ellipsize rather than stretching one chip past the
      // screen edge.
      constraints: BoxConstraints(maxWidth: w * 0.7),
      child: Material(
        color: AppColors.primary.withValues(alpha: 0.05),
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.035,
              vertical: w * 0.02,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: w * 0.032,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
