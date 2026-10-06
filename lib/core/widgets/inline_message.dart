import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';

enum InlineMessageKind { error, notice }

/// A tinted, in-flow message with an icon: a failure the customer should fix
/// ([InlineMessageKind.error]) or a heads-up that doesn't block them
/// ([InlineMessageKind.notice]).
class InlineMessage extends StatelessWidget {
  const InlineMessage({
    super.key,
    required this.message,
    this.kind = InlineMessageKind.error,
  });

  final String message;
  final InlineMessageKind kind;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isError = kind == InlineMessageKind.error;
    final color = isError ? AppColors.error : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.03),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isError ? 0.08 : 0.1),
        borderRadius: BorderRadius.circular(w * 0.03),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: color,
            size: w * 0.05,
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: w * 0.032,
                height: 1.35,
                color: isError ? AppColors.error : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
