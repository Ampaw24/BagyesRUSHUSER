import 'package:flutter/material.dart';

import 'package:bagyesrushappusernew/src/report/model/report.dart';

class ReportStatusBadge extends StatelessWidget {
  final ReportStatus status;

  const ReportStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final color = status.color;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.024, vertical: w * 0.01),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(w * 0.05),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: w * 0.016,
            height: w * 0.016,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: w * 0.012),
          Text(
            status.label,
            style: TextStyle(
              fontSize: w * 0.028,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
