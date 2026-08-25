import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:bagyesrushappusernew/constant/app_theme.dart';
import 'package:bagyesrushappusernew/features/report/domain/entities/report.dart';

List<List<dynamic>> targetTypeIcon(ReportTargetType type) => switch (type) {
      ReportTargetType.vendor => HugeIcons.strokeRoundedStore01,
      ReportTargetType.rider => HugeIcons.strokeRoundedMotorbike01,
      ReportTargetType.customer => HugeIcons.strokeRoundedUserBlock01,
      ReportTargetType.orderIssue => HugeIcons.strokeRoundedReceiptDollar,
      ReportTargetType.general => HugeIcons.strokeRoundedMessageQuestion,
    };

/// Icon shown in a report card's leading badge — a checkmark/cancel glyph
/// once a report is closed, the target-type icon while it's still open.
List<List<dynamic>> _cardIcon(Report report) => switch (report.status) {
      ReportStatus.resolved => HugeIcons.strokeRoundedCheckmarkCircle01,
      ReportStatus.dismissed => HugeIcons.strokeRoundedCancelCircle,
      _ => targetTypeIcon(report.targetType),
    };

/// Leading-badge tint — status-driven so "what state is this in" reads at a
/// glance, independent of the status enum's own (slightly different) color
/// used for the inline status label.
Color _badgeColor(ReportStatus status) => switch (status) {
      ReportStatus.pending => AppColors.primary,
      ReportStatus.inReview => AppColors.info,
      ReportStatus.resolved => AppColors.success,
      ReportStatus.dismissed => AppColors.textHint,
    };

/// One-line "who/what this is about" — varies by target type since a rider
/// or customer report has no vendor-style id, only a name (+ order, when
/// there is one).
String reportContextLine(Report r) {
  final orderPart = r.orderId != null ? 'Order #${r.orderId}' : null;
  switch (r.targetType) {
    case ReportTargetType.vendor:
      return [orderPart, r.targetName].whereType<String>().join(' · ');
    case ReportTargetType.rider:
      return [
        'Rider ${r.targetName}',
        if (r.orderId != null) '#${r.orderId}',
      ].join(' · ');
    case ReportTargetType.customer:
      return [
        'Customer ${r.targetName}',
        if (r.orderId != null) '#${r.orderId}',
      ].join(' · ');
    case ReportTargetType.orderIssue:
      final hasRealName =
          r.targetName.isNotEmpty && !r.targetName.startsWith('Order #');
      if (orderPart != null && hasRealName) return '$orderPart · ${r.targetName}';
      return orderPart ?? 'Order issue';
    case ReportTargetType.general:
      return orderPart ?? 'General · No order attached';
  }
}

/// Short "what's happening now" message for the status row.
String reportNextStepMessage(Report r) {
  switch (r.status) {
    case ReportStatus.pending:
      final minutesAgo = DateTime.now().difference(r.createdAt).inMinutes;
      return minutesAgo < 30 ? 'Just submitted' : 'Reply expected today';
    case ReportStatus.inReview:
      return 'Support is looking into it';
    case ReportStatus.resolved:
      return r.resolutionNote ?? 'Resolved';
    case ReportStatus.dismissed:
      return r.resolutionNote ?? 'Dismissed';
  }
}

String reportRelativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

/// Row in the "My Reports" list.
class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const ReportCard({super.key, required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final badgeColor = _badgeColor(report.status);
    final statusColor = report.status.color;

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
                  color: badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                child: HugeIcon(
                  icon: _cardIcon(report),
                  color: badgeColor,
                  size: w * 0.05,
                ),
              ),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            report.reasonLabel,
                            style: TextStyle(
                              fontSize: w * 0.038,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: w * 0.02),
                        Text(
                          reportRelativeTime(report.createdAt),
                          style: TextStyle(
                            fontSize: w * 0.027,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: w * 0.006),
                    Text(
                      reportContextLine(report),
                      style: TextStyle(
                        fontSize: w * 0.031,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: w * 0.02),
                    Row(
                      children: [
                        Container(
                          width: w * 0.016,
                          height: w * 0.016,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: w * 0.014),
                        Text(
                          report.status.label,
                          style: TextStyle(
                            fontSize: w * 0.031,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          ' · ',
                          style: TextStyle(
                            fontSize: w * 0.031,
                            color: AppColors.textHint,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            reportNextStepMessage(report),
                            style: TextStyle(
                              fontSize: w * 0.031,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
