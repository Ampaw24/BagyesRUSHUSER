import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/features/report/domain/entities/report.dart';
import 'package:bagyesrushappusernew/features/report/presentation/widgets/report_status_badge.dart';

List<List<dynamic>> targetTypeIcon(ReportTargetType type) => switch (type) {
      ReportTargetType.vendor => HugeIcons.strokeRoundedStore01,
      ReportTargetType.rider => HugeIcons.strokeRoundedMotorbike01,
      ReportTargetType.customer => HugeIcons.strokeRoundedUserBlock01,
      ReportTargetType.orderIssue => HugeIcons.strokeRoundedReceiptDollar,
      ReportTargetType.general => HugeIcons.strokeRoundedMessageQuestion,
    };

/// Row in the "My Reports" list.
class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const ReportCard({super.key, required this.report, required this.onTap});

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(w * 0.04),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(w * 0.04),
        child: Container(
          padding: EdgeInsets.all(w * 0.04),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(w * 0.04),
            border: Border.all(color: AppColors.border, width: 0.7),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.028),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                child: HugeIcon(
                  icon: targetTypeIcon(report.targetType),
                  color: AppColors.primary,
                  size: w * 0.05,
                ),
              ),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.reasonLabel,
                      style: TextStyle(
                        fontSize: w * 0.037,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: w * 0.005),
                    Text(
                      report.targetName,
                      style: TextStyle(
                        fontSize: w * 0.031,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: w * 0.02),
                    Row(
                      children: [
                        ReportStatusBadge(status: report.status),
                        const Spacer(),
                        Text(
                          _formatDate(report.createdAt),
                          style: TextStyle(
                            fontSize: w * 0.028,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
